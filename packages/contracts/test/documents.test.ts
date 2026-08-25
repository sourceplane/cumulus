import { describe, expect, it } from "vitest";
import { isValidDocumentId, MAX_DOCUMENT_BYTES } from "../src/documents.js";

describe("isValidDocumentId", () => {
  it("accepts ordinary ids", () => {
    for (const id of ["a", "doc-1", "report.2026_final", "A1"]) {
      expect(isValidDocumentId(id), id).toBe(true);
    }
  });

  // Document ids become S3 key suffixes and URL path segments. Each of these
  // would either escape the configured prefix or break the key entirely.
  it("rejects ids that would escape the key prefix", () => {
    const bad = ["..", "../etc/passwd", "a/../b", "a/b", "", "-leading", "a b", "a\tb"];
    for (const id of bad) {
      expect(isValidDocumentId(id), JSON.stringify(id)).toBe(false);
    }
  });

  it("rejects ids past the length ceiling", () => {
    expect(isValidDocumentId("a".repeat(128))).toBe(true);
    expect(isValidDocumentId("a".repeat(129))).toBe(false);
  });

  it("pins the document size ceiling at 100 KB", () => {
    expect(MAX_DOCUMENT_BYTES).toBe(102400);
  });
});
