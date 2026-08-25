import { randomBytes, randomUUID } from "node:crypto";

/**
 * A prefixed, URL-safe public id.
 *
 * Prefixed because an opaque id in a log line or a support ticket should say
 * what it is without a lookup, and because a mistyped id fails at parse rather
 * than at a database round trip.
 */
export function generateId(prefix: string): string {
  return `${prefix}_${randomBytes(12).toString("hex")}`;
}

export function generateRequestId(): string {
  return randomUUID();
}

export function hasPrefix(id: string, prefix: string): boolean {
  return id.startsWith(`${prefix}_`);
}
