// Tenancy contract. Every resource is traceable to an organization; the seam is
// established in phase 1 even though phase 1 ships only three services, because
// retrofitting tenancy onto a fleet that grew without it is the expensive
// version of this decision.

export interface OrgScoped {
  orgId: string;
}

export type ActorKind = "user" | "api_key" | "service" | "system";

export interface TenantContext {
  orgId: string;
  actorId: string;
  actorKind: ActorKind;
  /** Correlation id minted by the gateway and propagated to every upstream. */
  requestId: string;
}

export type OrganizationRole = "owner" | "admin" | "member" | "viewer";

export interface RoleAssignment {
  orgId: string;
  subjectId: string;
  role: OrganizationRole;
}

/** Header names the fleet agrees on for propagating tenant context in-cluster. */
export const TENANCY_HEADERS = {
  ORG_ID: "x-cumulus-org-id",
  ACTOR_ID: "x-cumulus-actor-id",
  ACTOR_KIND: "x-cumulus-actor-kind",
  REQUEST_ID: "x-request-id",
} as const;
