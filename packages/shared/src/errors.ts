import { ERROR_CODES, ERROR_STATUS, type ErrorCode, type ErrorResponse } from "@cumulus/contracts/errors";

/**
 * An error that carries its own wire representation.
 *
 * Handlers throw these; one error hook serialises them. The alternative —
 * every handler building its own error body — is how two services end up
 * disagreeing about what a 404 looks like.
 */
export class ServiceError extends Error {
  readonly code: ErrorCode;
  readonly statusCode: number;
  readonly fields: Record<string, string[]> | undefined;

  constructor(code: ErrorCode, message: string, fields?: Record<string, string[]>) {
    super(message);
    this.name = "ServiceError";
    this.code = code;
    this.statusCode = ERROR_STATUS[code];
    this.fields = fields;
  }

  toResponse(requestId?: string): ErrorResponse {
    return { error: this.code, message: this.message, ...(requestId ? { requestId } : {}) };
  }
}

export function isServiceError(err: unknown): err is ServiceError {
  return err instanceof ServiceError;
}

export const badRequest = (m: string) => new ServiceError(ERROR_CODES.BAD_REQUEST, m);
export const notFound = (m: string) => new ServiceError(ERROR_CODES.NOT_FOUND, m);
export const unauthenticated = (m: string) => new ServiceError(ERROR_CODES.UNAUTHENTICATED, m);
export const forbidden = (m: string) => new ServiceError(ERROR_CODES.FORBIDDEN, m);
export const payloadTooLarge = (m: string) => new ServiceError(ERROR_CODES.PAYLOAD_TOO_LARGE, m);
export const upstreamUnavailable = (m: string) => new ServiceError(ERROR_CODES.UPSTREAM_UNAVAILABLE, m);
