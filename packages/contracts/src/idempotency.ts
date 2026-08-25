// Idempotency contract for unsafe methods at the edge.

export const IDEMPOTENCY_HEADER = "idempotency-key";

/** How long a replayable result is retained. */
export const IDEMPOTENCY_WINDOW_SECONDS = 24 * 60 * 60;

export interface IdempotencyRecord {
  key: string;
  orgId: string;
  /**
   * Fingerprint of method + path + body. A replayed key with a DIFFERENT
   * fingerprint is a client bug, not a retry, and must be rejected rather than
   * silently served the first response.
   */
  requestFingerprint: string;
  statusCode: number;
  responseBody: string;
  createdAt: string;
}

export type IdempotencyOutcome =
  | { kind: "fresh" }
  | { kind: "replay"; record: IdempotencyRecord }
  | { kind: "conflict" };
