# tests

Cross-cutting suites that are components in their own right, so they run in the
plan DAG rather than as an afterthought in a workflow step.

| Suite | Milestone | What it asserts |
|-------|-----------|-----------------|
| `endpoint-contract/` | E6 | Invariants over every rendered manifest in the fleet: exactly one Ingress and it belongs to `api-gateway`; no `/health` path rule; no `latest` tag; every ServiceAccount carries an IRSA annotation; every container sets resource requests/limits, `runAsNonRoot`, and a read-only root filesystem. |
