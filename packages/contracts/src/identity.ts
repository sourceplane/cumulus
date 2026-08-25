// Identity contract — the gateway's authN call and the org/API-key surface.

import type { OrganizationRole } from "./tenancy.js";

export interface Organization {
  id: string;
  name: string;
  slug: string;
  createdAt: string;
}

export interface CreateOrganizationRequest {
  name: string;
  slug: string;
}

export interface ApiKeySummary {
  id: string;
  orgId: string;
  name: string;
  /** Non-secret display prefix, e.g. `ck_live_a1b2`. The secret is returned once, at creation. */
  prefix: string;
  createdAt: string;
  lastUsedAt?: string;
  revokedAt?: string;
}

export interface CreateApiKeyRequest {
  orgId: string;
  name: string;
}

export interface CreateApiKeyResponse {
  key: ApiKeySummary;
  /** Returned exactly once. Never stored in plaintext, never logged. */
  secret: string;
}

export interface VerifyRequest {
  /** The bearer credential presented to the gateway. */
  token: string;
}

export type VerifyResponse =
  | {
      valid: true;
      orgId: string;
      actorId: string;
      role: OrganizationRole;
    }
  | {
      valid: false;
      /** Coarse on purpose: a precise reason is an oracle for credential probing. */
      reason: "invalid" | "revoked" | "expired";
    };
