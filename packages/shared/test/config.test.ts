import { describe, expect, it } from "vitest";
import { booleanEnv, ConfigError, numberEnv, optionalEnv, requireEnv } from "../src/config.js";

describe("config", () => {
  it("requireEnv throws on missing and on empty", () => {
    expect(() => requireEnv("A", {})).toThrow(ConfigError);
    // An empty string is the shape a forgotten Helm value takes; treating it as
    // present would let a service start with a blank bucket name.
    expect(() => requireEnv("A", { A: "" })).toThrow(ConfigError);
    expect(requireEnv("A", { A: "v" })).toBe("v");
  });

  it("optionalEnv falls back on unset and empty", () => {
    expect(optionalEnv("A", "d", {})).toBe("d");
    expect(optionalEnv("A", "d", { A: "" })).toBe("d");
    expect(optionalEnv("A", "d", { A: "v" })).toBe("v");
  });

  it("numberEnv rejects non-numeric rather than silently coercing", () => {
    expect(numberEnv("N", 5, {})).toBe(5);
    expect(numberEnv("N", 5, { N: "7" })).toBe(7);
    expect(() => numberEnv("N", 5, { N: "soon" })).toThrow(ConfigError);
  });

  it("booleanEnv accepts the usual truthy spellings", () => {
    expect(booleanEnv("B", false, { B: "true" })).toBe(true);
    expect(booleanEnv("B", false, { B: "1" })).toBe(true);
    expect(booleanEnv("B", false, { B: "ON" })).toBe(true);
    expect(booleanEnv("B", true, { B: "false" })).toBe(false);
    expect(booleanEnv("B", true, {})).toBe(true);
  });
});
