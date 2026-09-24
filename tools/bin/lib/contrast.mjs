// WCAG 2.x relative luminance and contrast ratio.
//
// Roblox has no contrast tooling, so a palette shipped in prose is an unchecked
// claim unless something recomputes it. This is that something.

/** @param {number} channel 0-255 */
function linearize(channel) {
  const c = channel / 255;
  return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

/** @param {[number, number, number]} rgb */
export function luminance([r, g, b]) {
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}

/**
 * Contrast ratio between two RGB triples, 1 to 21.
 * @param {[number, number, number]} a
 * @param {[number, number, number]} b
 */
export function contrast(a, b) {
  const la = luminance(a);
  const lb = luminance(b);
  const lighter = Math.max(la, lb);
  const darker = Math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/** Rounded the way the docs state it, so a doc and the tool cannot disagree. */
export function ratioText(a, b) {
  return `${contrast(a, b).toFixed(2)}:1`;
}

/**
 * Parse "12, 34, 56" or "12,34,56" into a triple.
 * @param {string} text
 * @returns {[number, number, number] | null}
 */
export function parseRgb(text) {
  const m = /^\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*$/.exec(text);
  if (!m) return null;
  const rgb = [Number(m[1]), Number(m[2]), Number(m[3])];
  if (rgb.some((v) => v > 255)) return null;
  return /** @type {[number, number, number]} */ (rgb);
}

// WCAG thresholds. Roblox UI is rendered over arbitrary 3D scenes, so body text
// is held to AA normal rather than AA large even when it is large.
export const AA_NORMAL = 4.5;
export const AA_LARGE = 3.0;
export const AA_NON_TEXT = 3.0;
