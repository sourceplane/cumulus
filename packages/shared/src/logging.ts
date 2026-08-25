/**
 * Structured JSON logging on stdout.
 *
 * One line, one JSON object — that is the contract a log pipeline needs.
 * Anything printed as free text becomes a line nobody can query later.
 */

export type LogLevel = "debug" | "info" | "warn" | "error";

const LEVEL_ORDER: Record<LogLevel, number> = { debug: 10, info: 20, warn: 30, error: 40 };

export interface LogFields {
  [key: string]: unknown;
}

export interface Logger {
  debug(message: string, fields?: LogFields): void;
  info(message: string, fields?: LogFields): void;
  warn(message: string, fields?: LogFields): void;
  error(message: string, fields?: LogFields): void;
  /** Derive a logger that stamps every line with additional fields. */
  child(fields: LogFields): Logger;
}

/**
 * Keys whose values never reach a log line. Redaction lives at the logger
 * rather than at each call site: a call site that forgets is the whole problem.
 */
const REDACTED_KEYS = new Set([
  "password",
  "secret",
  "token",
  "authorization",
  "apikey",
  "api_key",
  "cachepassword",
  "connectionstring",
]);

function redact(fields: LogFields): LogFields {
  const out: LogFields = {};
  for (const [key, value] of Object.entries(fields)) {
    out[key] = REDACTED_KEYS.has(key.toLowerCase()) ? "[redacted]" : value;
  }
  return out;
}

export function createLogger(
  service: string,
  options: { level?: LogLevel; base?: LogFields } = {}
): Logger {
  const threshold = LEVEL_ORDER[options.level ?? "info"];
  const base = options.base ?? {};

  const emit = (level: LogLevel, message: string, fields?: LogFields): void => {
    if (LEVEL_ORDER[level] < threshold) return;
    const line = JSON.stringify({
      timestamp: new Date().toISOString(),
      level,
      service,
      message,
      ...redact({ ...base, ...(fields ?? {}) }),
    });
    // Writing to the stream directly rather than through console keeps the
    // output a single write with no formatting applied to it.
    process.stdout.write(`${line}\n`);
  };

  const logger: Logger = {
    debug: (m, f) => emit("debug", m, f),
    info: (m, f) => emit("info", m, f),
    warn: (m, f) => emit("warn", m, f),
    error: (m, f) => emit("error", m, f),
    child: (fields) => createLogger(service, { ...options, base: { ...base, ...fields } }),
  };
  return logger;
}
