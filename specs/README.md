# Cumulus — Spec Pack

Status: Normative index

This directory is the authoritative spec pack for the Kubernetes multi-tenant
SaaS baseline. It is organised into three tiers so durable contracts and
lifecycle-tracked work never get confused with each other.

> **Ground rule:** trust code reality over stale docs. When a spec and the
> running system disagree, the system is the source of truth and the spec is the
> bug — fix it.

## The three tiers

| Tier | Directory | What it holds | Lifecycle |
|------|-----------|---------------|-----------|
| **Core** | `core/` | The durable architectural foundation: constitution, product overview, repo shape, access/infra, the Orun golden path, and the frozen `contracts/`. | Normative; never archived for being "implemented". |
| **Components** | `components/` | One reference spec per bounded context. The durable contract each service and chart must honor. | Stays valid after implementation. |
| **Epics** | [`epics/`](./epics/) | Orun-style work programs. Each carries a README status table, an `implementation-plan.md` of milestones, and an `IMPLEMENTATION-STATUS.md` as-built record. | Draft → Ready → In progress → Shipped → Closed. |

Plus [`roadmap.md`](./roadmap.md) — the cross-epic program register.

## Status legend (used in every epic README + component header)

| Marker | Meaning |
|--------|---------|
| `Draft` | Being authored; not ready to build. |
| `Ready for implementation` | Design locked; safe to assign. |
| `In progress` | Some milestones shipped, others open. |
| ✅ `Shipped` | Milestone live on `main` and verified. |
| 🗓️ `Planned` | Scheduled, not started. |
| ⛔ `Blocked` | Needs human input (credentials/decision) or an upstream slice. |
| `Closed` / `Archived` | Program complete or superseded. |
