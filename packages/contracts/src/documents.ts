// Documents contract.

/** Hard ceiling on a document body. Enforced at the edge and again at the service. */
export const MAX_DOCUMENT_BYTES = 100 * 1024;

export interface DocumentRecord {
  id: string;
  content: string;
  createdAt: string;
  updatedAt: string;
}

export interface PutDocumentRequest {
  content: string;
}

export interface DocumentResponse {
  id: string;
  content: string;
  createdAt?: string;
  /**
   * Where the read was served from. Exposed deliberately: a cache-aside service
   * whose hit rate you cannot observe is a service whose cache you cannot tune.
   */
  source: "cache" | "origin";
}

/** Document ids appear in S3 keys and URLs — constrain them at the contract. */
const DOCUMENT_ID = /^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/;

export function isValidDocumentId(id: string): boolean {
  // Reject traversal explicitly rather than relying on the pattern alone, so the
  // intent is legible to whoever changes the pattern next.
  return !id.includes("..") && DOCUMENT_ID.test(id);
}
