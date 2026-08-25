# Roadmap

Status: Program register. One line per cluster; the per-milestone detail lives
in the epic plans under [`epics/`](./epics/).

| Cluster | Epic | Status | Thesis |
|---------|------|--------|--------|
| **E** | [`eks-baseline`](./epics/eks-baseline/) | Draft | Phase 1 — the composition catalog, the repo foundation, the Terraform AWS estate, three services with Helm charts, and one public endpoint, verified in CI without a live AWS bill. |

## Registered, not yet opened

| ID | What | Blocked on |
|----|------|------------|
| E7 | Live AWS apply — OIDC role, `vpc → eks → addons → deps`, a real ALB endpoint, destroy lane and cost guardrails | An AWS account (see `epics/eks-baseline/risks-and-open-questions.md`) |
| E8 | Observability — OpenTelemetry through the gateway, metrics, dashboards, SLO alarms | E7 |
| E9 | Progressive delivery — canary or blue/green Helm releases | E7 |
| E10 | Port further lumen bounded contexts (events, config, metering) onto the same rails | E6 |
