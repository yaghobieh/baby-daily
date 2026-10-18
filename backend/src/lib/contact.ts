/** Normalizes a phone number to "+digits" or "digits". Returns null if too short. */
export function normalizePhone(input?: string | null): string | null {
  if (!input) return null;
  const trimmed = input.trim();
  const digits = trimmed.replace(/\D/g, '');
  if (digits.length < 7) return null;
  return (trimmed.startsWith('+') ? '+' : '') + digits;
}

/**
 * Key used to match the same phone written in different formats
 * (e.g. "+972 50-123-4567" and "050 123 4567" both → "501234567").
 */
export function phoneKey(input?: string | null): string | null {
  const n = normalizePhone(input);
  if (!n) return null;
  const digits = n.replace(/\D/g, '');
  return digits.slice(-9);
}

export function normalizeEmail(input?: string | null): string | null {
  if (!input) return null;
  const e = input.trim().toLowerCase();
  return e.length ? e : null;
}

/**
 * Capitalizes the first letter of each word and lowercases the remainder.
 * e.g. "eYAER" -> "Eyaer", "john doe" -> "John Doe", "sARAH" -> "Sarah".
 */
export function formatName(input?: string | null): string {
  if (!input) return '';
  return input
    .trim()
    .split(/\s+/)
    .map((w) => (w.length > 0 ? w.charAt(0).toUpperCase() + w.slice(1).toLowerCase() : ''))
    .filter(Boolean)
    .join(' ');
}
