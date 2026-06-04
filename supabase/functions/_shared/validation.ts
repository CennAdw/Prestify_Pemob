export const allowedEmailDomain = "upi.edu";

export function normalizeEmail(value: unknown): string {
  return String(value ?? "").trim().toLowerCase();
}

export function isUpiEmail(email: string): boolean {
  return /^[^@\s]+@upi\.edu$/i.test(email);
}

export function normalizeIdentifier(value: unknown): string {
  return String(value ?? "").replace(/\s+/g, "").trim();
}

export function isAcademicIdentifier(value: string): boolean {
  return /^[0-9]{5,30}$/.test(value);
}

export function normalizeSkills(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value
      .map((item) => String(item).trim())
      .filter((item) => item.length > 0);
  }
  return String(value ?? "")
    .split(",")
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}
