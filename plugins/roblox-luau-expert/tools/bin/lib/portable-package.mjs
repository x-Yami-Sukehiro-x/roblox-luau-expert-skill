import { createHash } from "node:crypto";
import { deflateRawSync } from "node:zlib";
import { existsSync, lstatSync, mkdirSync, readFileSync, readdirSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";

const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");
const slash = (path) => path.replaceAll("\\", "/");

export function collectPackageFiles(root, entries, excluded = []) {
  const files = [];
  const omit = new Set(excluded.map(slash));
  function visit(path) {
    const name = slash(relative(root, path));
    if (omit.has(name)) return;
    for (const entry of readdirSync(path, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
      if ([".git", "node_modules", "__pycache__"].includes(entry.name)) continue;
      const full = join(path, entry.name);
      const rel = slash(relative(root, full));
      if (omit.has(rel) || /\.(?:pyc|zip)$/.test(entry.name)) continue;
      if (entry.isSymbolicLink()) throw new Error(`package source is a symlink: ${rel}`);
      if (entry.isDirectory()) visit(full);
      else if (entry.isFile()) files.push({ path: rel, bytes: readFileSync(full) });
    }
  }
  for (const entry of entries) {
    const path = join(root, entry);
    if (!existsSync(path)) throw new Error(`package source missing: ${entry}`);
    if (lstatSync(path).isSymbolicLink()) throw new Error(`package source is a symlink: ${entry}`);
    if (lstatSync(path).isFile()) {
      files.push({ path: slash(entry), bytes: readFileSync(path) });
    } else visit(path);
  }
  return files.sort((a, b) => a.path < b.path ? -1 : a.path > b.path ? 1 : 0);
}

const crcTable = Array.from({ length: 256 }, (_, value) => {
  for (let bit = 0; bit < 8; bit++) value = value & 1 ? 0xedb88320 ^ (value >>> 1) : value >>> 1;
  return value >>> 0;
});

function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) crc = crcTable[(crc ^ byte) & 0xff] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

// Fixed timestamps and sorted UTF-8 names make identical source bytes produce
// identical archives. Explicit enumeration includes hidden .claude directories.
export function createPackageZip(files) {
  if (files.length > 65535) throw new Error("package exceeds ZIP entry limit");
  const localParts = [];
  const centralParts = [];
  let offset = 0;
  for (const file of files) {
    const name = Buffer.from(file.path, "utf8");
    const compressed = deflateRawSync(file.bytes, { level: 9 });
    if (name.length > 65535 || file.bytes.length > 0xffffffff || offset > 0xffffffff) {
      throw new Error(`package exceeds ZIP size limit: ${file.path}`);
    }
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4);
    local.writeUInt16LE(0x800, 6);
    local.writeUInt16LE(8, 8);
    local.writeUInt16LE(33, 12);
    local.writeUInt32LE(crc32(file.bytes), 14);
    local.writeUInt32LE(compressed.length, 18);
    local.writeUInt32LE(file.bytes.length, 22);
    local.writeUInt16LE(name.length, 26);
    localParts.push(local, name, compressed);

    const central = Buffer.alloc(46);
    central.writeUInt32LE(0x02014b50, 0);
    central.writeUInt16LE(20, 4);
    local.copy(central, 6, 4, 30);
    central.writeUInt32LE(offset, 42);
    centralParts.push(central, name);
    offset += local.length + name.length + compressed.length;
  }
  const directory = Buffer.concat(centralParts);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(files.length, 8);
  end.writeUInt16LE(files.length, 10);
  end.writeUInt32LE(directory.length, 12);
  end.writeUInt32LE(offset, 16);
  return Buffer.concat([...localParts, directory, end]);
}

export function packageManifest(files, zip) {
  return {
    format: 1,
    archiveSha256: sha256(zip),
    files: files.map((file) => ({ path: file.path, bytes: file.bytes.length, sha256: sha256(file.bytes) })),
  };
}

export function checkPackage(files, archivePath, manifestPath, requireArchive = false) {
  if (!existsSync(manifestPath)) return ["package manifest missing; rebuild the portable files"];
  let manifest;
  try { manifest = JSON.parse(readFileSync(manifestPath, "utf8")); }
  catch { return ["package manifest is unreadable; rebuild the portable files"]; }
  const expected = packageManifest(files, Buffer.alloc(0));
  const problems = [];
  if (manifest.format !== 1 || JSON.stringify(manifest.files) !== JSON.stringify(expected.files)) {
    problems.push("package source hashes are stale; rebuild the portable files");
  }
  if (existsSync(archivePath)) {
    if (sha256(readFileSync(archivePath)) !== manifest.archiveSha256) problems.push("package archive hash differs from its manifest");
  } else if (requireArchive) problems.push("package archive missing; rebuild before uploading");
  return problems;
}

export function writePackage(files, archivePath, manifestPath) {
  // Build both in memory before touching the last good archive.
  const zip = createPackageZip(files);
  const manifest = JSON.stringify(packageManifest(files, zip), null, 2) + "\n";
  const archiveTemporary = `${archivePath}.tmp-${process.pid}`;
  const manifestTemporary = `${manifestPath}.tmp-${process.pid}`;
  mkdirSync(dirname(archivePath), { recursive: true });
  mkdirSync(dirname(manifestPath), { recursive: true });
  try {
    writeFileSync(archiveTemporary, zip);
    writeFileSync(manifestTemporary, manifest);
    renameSync(archiveTemporary, archivePath);
    renameSync(manifestTemporary, manifestPath);
  } finally {
    rmSync(archiveTemporary, { force: true });
    rmSync(manifestTemporary, { force: true });
  }
  return { bytes: zip.length, files: files.length };
}
