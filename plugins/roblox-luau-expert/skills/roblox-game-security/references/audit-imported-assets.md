# Auditing imported assets

A model from the Toolbox or Creator Store can carry scripts, and a backdoor in
one gives its author server-side control of the game, often waiting until a
particular player joins. Popularity is not proof of safety. Treat every
imported asset as untrusted until its scripts have been read.

Roblox's guidance: <https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities>.

## Before it goes in

1. Insert into a quarantine folder, not straight into `Workspace` or a
   service where its scripts run.
2. Never turn on HTTP requests, API access or `loadstring` because an asset
   or its instructions ask for it.
3. Keep only what the game needs. A decorative model needs its parts,
   meshes, textures and sounds; its scripts can usually go.
4. Note the asset id, creator, where it was inserted and the audit result
   in the project record.

## What to search for

With the Studio MCP server, `script_grep` over the quarantine folder, then
`script_read` every hit; without it, the same searches in Studio's Find All.

| Pattern | Why it matters in a decorative or single-purpose asset |
|---|---|
| `require(` with a number | loads code from another asset at run time; the audited file is not the code that runs |
| `getfenv`, `setfenv` | reaches into other scripts' environments |
| `loadstring` | runs text as code |
| `HttpService`, `InsertService`, `GetObjects` | fetches or inserts content from outside |
| `DataStore`, `MarketplaceService`, `TeleportService`, `MessagingService` | touches saves, purchases or other servers |
| new `RemoteEvent` or `RemoteFunction` | opens a door from clients to the server |
| `string.char`, `string.reverse`, long numeric tables, `\` escapes | assembled strings that hide the real call |
| long runs of spaces before code | code pushed off the right edge of the editor |
| names like `Loader`, `MainModule`, `AntiLag`, `Fix`, `Update` | disguise for scripts unrelated to the asset |

Also look for disabled scripts that something re-enables, scripts nested deep
inside unrelated objects, and code that clones or moves itself into services.

## Verdicts

- **Keep the visuals, drop the scripts**: the usual result for props and maps.
- **Keep, reviewed**: every script read, its purpose matches the asset, no
  pattern above without a reason the user accepts.
- **Remove**: obfuscation, remote code loading, or behaviour unrelated to
  the asset. Search the rest of the place for copies it may have made.

## Sandboxing what stays

Roblox can confine an asset's scripts. With `Workspace.SandboxedInstanceMode`
set to `Experimental` in Studio, a model marked `Sandboxed` runs only with the
`Capabilities` it is given. Grant the fewest: an asset should not get
`Network`, `DataStore`, `AssetRequire`, `LoadString` or `CapabilityControl`
without a reason you can state (`node tools/bin/verify-api.mjs Enum.SecurityCapability`).
Sandboxing narrows the damage; it does not replace reading the code.
