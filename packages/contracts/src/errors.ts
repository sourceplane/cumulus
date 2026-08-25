// Error contract. One shape for every error body the fleet emits, so a client
// never has to branch on which service answered.

export const ERROR_CODES = {
  BAD_REQUEST: "bad_request",
  UNAUTHENTICATED: "unauthenticated",
  FORBIDDEN: "forbidden",
  NOT_FOUND: "not_found",
  CONFLICT: "conflict",
  PAYLOAD_TOO_LARGE: "payload_too_large",
  RATE_LIMITED: "rate_limited",
  VALIDATION_FAILED: "validation_failed",
  PRECONDITION_FAILED: "precondition_failed",
  UPSTREAM_UNAVAILABLE: "upstream_unavailable",
  INTERNAL_ERROR: "internal_error",
} as const;

export type ErrorCode = (typeof ERROR_CODES)[keyof typeof ERROR_CODES];

export interface ErrorResponse {
  error: ErrorCode;
  message: string;
  /** Always present in a served response; echoed by the gateway for correlation. */
  requestId?: string;
}

export interface ValidationErrorResponse extends ErrorResponse {
  error: typeof ERROR_CODES.VALIDATION_FAILED;
  fields?: Record<string, string[]>;
}

/** The HTTP status each code is served as. Kept here so services cannot disagree. */
export const ERROR_STATUS: Record<ErrorCode, number> = {
  [ERROR_CODES.BAD_REQUEST]: 400,
  [ERROR_CODES.UNAUTHENTICATED]: 401,
  [ERROR_CODES.FORBIDDEN]: 403,
  [ERROR_CODES.NOT_FOUND]: 404,
  [ERROR_CODES.CONFLICT]: 409,
  [ERROR_CODES.PAYLOAD_TOO_LARGE]: 413,
  [ERROR_CODES.VALIDATION_FAILED]: 422,
  [ERROR_CODES.PRECONDITION_FAILED]: 428,
  [ERROR_CODES.RATE_LIMITED]: 429,
  [ERROR_CODES.INTERNAL_ERROR]: 500,
  [ERROR_CODES.UPSTREAM_UNAVAILABLE]: 503,
};
