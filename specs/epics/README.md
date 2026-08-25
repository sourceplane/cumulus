# Epics

Status: Normative index

Orun-style work programs for the Kubernetes SaaS baseline. Each epic is a folder
carrying a canonical doc set. Durable per-bounded-context contracts live one
level up in `specs/components/`; epics are the cross-cutting programs that
*evolve* them.

## The epics

| Epic | Cluster | Status | Owner(s) | What it is |
|------|---------|--------|----------|------------|
| [`eks-baseline/`](./eks-baseline/) | **E** | Draft | stack-granite, infra/terraform/*, apps/*, deploy/helm/* | Phase 1: the composition catalog, the repo foundation, the Terraform AWS estate, three services with Helm charts, and one public endpoint — verified in CI without a live AWS bill. |

## Lifecycle & conventions

- **Status legend:** see [`../README.md`](../README.md) § Status legend.
- **As-built ≠ intent.** What actually shipped lives in each epic's
  `IMPLEMENTATION-STATUS.md`, kept distinct from the design/plan docs.
- **Milestone ✅, not archive.** A completed milestone inside an active epic is
  marked ✅ in `implementation-plan.md` and recorded in `IMPLEMENTATION-STATUS.md`
  — it is **not** deleted or archived. Only a fully-closed program moves to
  `../_archive/`.
- **Doc set per epic:** `README.md` (status table + thesis + read order +
  milestone-at-a-glance), `design.md`, `implementation-plan.md` (milestones with
  "done when"), `IMPLEMENTATION-STATUS.md` (as-built), plus
  `risks-and-open-questions.md` where it carries weight.
- **One milestone, one PR.** A milestone lands as a single reviewable PR whose
  body names its "done when" clauses and how each was verified.
