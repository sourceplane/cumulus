// Health contract.
//
// Two endpoints with genuinely different meanings, served on the INTERNAL port
// only (see specs/core/repo.md § Health): `/health/live` answers "is this
// process wedged?" and must never consult a dependency — a liveness probe that
// fails when Redis is slow restarts a healthy pod and turns a degradation into
// an outage. `/health/ready` answers "should traffic come here?" and does
// consult dependencies, distinguishing required from optional.

export type HealthStatus = "ok" | "degraded" | "down";

export interface LivenessResponse {
  status: Extract<HealthStatus, "ok">;
  service: string;
  uptimeSeconds: number;
}

/** One dependency's contribution to readiness. */
export interface DependencyHealth {
  name: string;
  status: HealthStatus;
  /** Required dependencies force `down`; optional ones can only force `degraded`. */
  required: boolean;
  latencyMs?: number;
  detail?: string;
}

export interface ReadinessResponse {
  status: HealthStatus;
  service: string;
  environment: string;
  timestamp: string;
  version?: string;
  dependencies: DependencyHealth[];
}

/**
 * Fold dependency checks into one status.
 *
 * A failed *required* dependency means down. A failed *optional* dependency
 * means degraded — the service still serves, more slowly or with less. This is
 * what makes the cache genuinely optional rather than optional-until-it-breaks.
 */
export function rollUpReadiness(dependencies: readonly DependencyHealth[]): HealthStatus {
  let worst: HealthStatus = "ok";
  for (const dep of dependencies) {
    if (dep.status === "ok") continue;
    if (dep.required && dep.status === "down") return "down";
    worst = "degraded";
  }
  return worst;
}
