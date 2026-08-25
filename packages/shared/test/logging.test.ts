import { afterEach, describe, expect, it, vi } from "vitest";
import { createLogger } from "../src/logging.js";

function captureLines(fn: () => void): string[] {
  const lines: string[] = [];
  const spy = vi.spyOn(process.stdout, "write").mockImplementation((chunk: unknown) => {
    lines.push(String(chunk));
    return true;
  });
  try {
    fn();
  } finally {
    spy.mockRestore();
  }
  return lines;
}

afterEach(() => vi.restoreAllMocks());

describe("createLogger", () => {
  it("emits one JSON object per line", () => {
    const lines = captureLines(() => createLogger("svc").info("hello", { a: 1 }));
    expect(lines).toHaveLength(1);
    expect(lines[0]!.endsWith("\n")).toBe(true);
    const parsed = JSON.parse(lines[0]!);
    expect(parsed).toMatchObject({ level: "info", service: "svc", message: "hello", a: 1 });
  });

  it("suppresses lines below the threshold", () => {
    const lines = captureLines(() => createLogger("svc", { level: "warn" }).info("quiet"));
    expect(lines).toHaveLength(0);
  });

  // Redaction at the logger, not the call site: the call site that forgets is
  // exactly the one that leaks.
  it("redacts secret-shaped keys regardless of casing", () => {
    const lines = captureLines(() =>
      createLogger("svc").info("auth", {
        Authorization: "Bearer abc",
        cachePassword: "hunter2",
        orgId: "org_1",
      })
    );
    const parsed = JSON.parse(lines[0]!);
    expect(parsed.Authorization).toBe("[redacted]");
    expect(parsed.cachePassword).toBe("[redacted]");
    expect(parsed.orgId).toBe("org_1");
  });

  it("stamps child fields onto every line", () => {
    const lines = captureLines(() => createLogger("svc").child({ requestId: "r1" }).error("boom"));
    expect(JSON.parse(lines[0]!).requestId).toBe("r1");
  });
});
