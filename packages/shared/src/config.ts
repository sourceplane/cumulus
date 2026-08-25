/**
 * Environment configuration read once, at startup, and validated loudly.
 *
 * A service that discovers a missing bucket name on its first request has
 * already passed its readiness probe and taken traffic. Failing at construction
 * turns that into a CrashLoopBackOff, which is visible.
 */

export class ConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ConfigError";
  }
}

export function requireEnv(name: string, env: NodeJS.ProcessEnv = process.env): string {
  const value = env[name];
  if (value === undefined || value === "") {
    throw new ConfigError(`missing required environment variable: ${name}`);
  }
  return value;
}

export function optionalEnv(
  name: string,
  fallback: string,
  env: NodeJS.ProcessEnv = process.env
): string {
  const value = env[name];
  return value === undefined || value === "" ? fallback : value;
}

export function numberEnv(
  name: string,
  fallback: number,
  env: NodeJS.ProcessEnv = process.env
): number {
  const raw = env[name];
  if (raw === undefined || raw === "") return fallback;
  const parsed = Number(raw);
  if (!Number.isFinite(parsed)) {
    throw new ConfigError(`environment variable ${name} must be a number, got: ${raw}`);
  }
  return parsed;
}

export function booleanEnv(
  name: string,
  fallback: boolean,
  env: NodeJS.ProcessEnv = process.env
): boolean {
  const raw = env[name];
  if (raw === undefined || raw === "") return fallback;
  return ["1", "true", "yes", "on"].includes(raw.toLowerCase());
}
