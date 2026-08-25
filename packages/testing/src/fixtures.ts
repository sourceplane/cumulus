import type { DocumentRecord, Organization, TenantContext } from "@cumulus/contracts";

/**
 * Deterministic fixtures. Every field is fixed — a fixture with a random or
 * clock-derived value produces a test that fails on a Tuesday.
 */

export const FIXED_NOW = "2026-01-01T00:00:00.000Z";

export function anOrganization(overrides: Partial<Organization> = {}): Organization {
  return {
    id: "org_000000000000000000000001",
    name: "Acme",
    slug: "acme",
    createdAt: FIXED_NOW,
    ...overrides,
  };
}

export function aTenantContext(overrides: Partial<TenantContext> = {}): TenantContext {
  return {
    orgId: "org_000000000000000000000001",
    actorId: "usr_000000000000000000000001",
    actorKind: "user",
    requestId: "00000000-0000-4000-8000-000000000001",
    ...overrides,
  };
}

export function aDocument(overrides: Partial<DocumentRecord> = {}): DocumentRecord {
  return {
    id: "doc-fixture",
    content: "hello",
    createdAt: FIXED_NOW,
    updatedAt: FIXED_NOW,
    ...overrides,
  };
}
