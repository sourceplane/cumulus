import { describe, expect, it } from "vitest";
import { rollUpReadiness, type DependencyHealth } from "../src/health.js";

const dep = (o: Partial<DependencyHealth>): DependencyHealth => ({
  name: "x",
  status: "ok",
  required: true,
  ...o,
});

describe("rollUpReadiness", () => {
  it("is ok when everything is ok", () => {
    expect(rollUpReadiness([dep({}), dep({ required: false })])).toBe("ok");
  });

  it("is down when a required dependency is down", () => {
    expect(rollUpReadiness([dep({ status: "down" })])).toBe("down");
  });

  // The property the whole cache-aside design rests on: losing the cache must
  // cost latency, never availability.
  it("is degraded - not down - when an OPTIONAL dependency is down", () => {
    expect(
      rollUpReadiness([dep({}), dep({ name: "cache", status: "down", required: false })])
    ).toBe("degraded");
  });

  it("is degraded when a required dependency is merely degraded", () => {
    expect(rollUpReadiness([dep({ status: "degraded" })])).toBe("degraded");
  });

  it("prefers down over degraded regardless of ordering", () => {
    expect(
      rollUpReadiness([
        dep({ name: "cache", status: "degraded", required: false }),
        dep({ status: "down" }),
      ])
    ).toBe("down");
  });
});
