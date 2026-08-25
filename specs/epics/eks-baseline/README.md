# Epic: eks-baseline

**Phase 1 of the Kubernetes baseline** — the composition catalog, the repo
foundation, the Terraform AWS estate, three services with Helm charts, and one
public endpoint, all verified in CI.

## Status

| Field | Value |
|-------|-------|
| Status | **In progress** (E0–E2 landed; E3–E6 open) |
| Cluster | **E** (E0–E6) |
| Owner(s) | `stack-granite`, `infra/terraform/*`, `apps/*`, `deploy/helm/*`, `packages/*` |
| Target branch | `main` (one milestone, one PR) |
| Builds on | [`sourceplane/lumen`](https://github.com/sourceplane/lumen) machinery; the AWS EKS reference at [`ruehowl/sample-microservice-on-eks@ip-restrict`](https://github.com/ruehowl/sample-microservice-on-eks/tree/ip-restrict/my-solution) |
| Decisions locked | TypeScript/Fastify services; Orun-native CI (no direct `terraform`/`helm`/`docker`/`pnpm` in Actions); modular Terraform states; one chart per service; gateway owns the only public ingress; **phase 1 is verify-only — no live AWS apply** |

## Thesis

`lumen` proved that a baseline repo can *know how to become a product*: desired
state in `component.yaml`, execution contracts in a versioned OCI catalog, and a
CI that converges the fleet on merge without a single hand-written deploy
script. Every bit of that machinery is runtime-agnostic — but every composition
`lumen` consumes is Cloudflare-shaped.

This epic re-lays those rails on Kubernetes. The reference EKS solution supplies
the domain content (S3 as system of record, Redis cache-aside, ALB ingress,
IRSA, modular Terraform); `lumen` supplies the shape (intent/component/
composition layering, environment subscription, profile rules, spec pack, epic
lifecycle). What the reference does with two hand-maintained GitHub Actions
workflows and a `workflow_dispatch` apply-order comment, this repo does with a
plan DAG that orders itself.

Phase 1 stops deliberately short of a live cluster. Everything is authored,
type-checked, linted, `terraform validate`d, `helm template`d, container-built
and smoke-tested against LocalStack + Redis in CI. The single remaining step —
pointing it at a real AWS account — is a credential gate, not an engineering
one, and it is E7 in a later phase.

## Read order

1. `README.md` (this file) — status + milestone-at-a-glance.
2. [`design.md`](./design.md) — the architecture and the decisions behind it.
3. [`implementation-plan.md`](./implementation-plan.md) — E0–E6, each with
   scope, dependencies, and "done when".
4. [`IMPLEMENTATION-STATUS.md`](./IMPLEMENTATION-STATUS.md) — what actually
   shipped (PR-level).
5. [`risks-and-open-questions.md`](./risks-and-open-questions.md) — the
   credential gates and deferred decisions.

## Milestones at a glance

| ID | Milestone | Status |
|----|-----------|--------|
| E0 | `stack-granite` — the composition catalog | ⛔ Blocked (publish only; authored + verified) |
| E1 | Repo foundation — workspace, contracts, intent, CI | ✅ Shipped (#2) — CI workflow parked, see status |
| E2 | Terraform AWS estate — VPC, EKS, platform addons | ✅ Shipped (#3) |
| E3 | `documents-service` — S3 + Redis cache-aside, chart | 🗓️ Planned |
| E4 | `identity-service` — Postgres, migrations lane, chart | 🗓️ Planned |
| E5 | `api-gateway` — the only public ingress | 🗓️ Planned |
| E6 | Endpoint exposure + verification + docs | 🗓️ Planned |

Phase 2 candidates (explicitly **out** of this epic) are registered in
[`../../roadmap.md`](../../roadmap.md).

## Scope boundary

| In scope | Out of scope |
|----------|--------------|
| The `stack-granite` catalog; pnpm/turbo workspace; shared contracts/testing packages; Terraform for VPC, EKS, platform addons and per-service AWS dependencies; three services with Dockerfiles, Helm charts and env overlays; ALB ingress with source-range restriction; CI verify lanes green on PR and main | A live AWS apply (E7, phase 2); the console/UI; billing, metering, webhooks and the rest of lumen's bounded contexts; service mesh; multi-region; GitOps (Argo/Flux) — the Orun plan DAG *is* the delivery mechanism here |

## Relationship to the reference solution

| Reference | Cumulus | Why |
|-----------|---------|-----|
| `workflow_dispatch` with a documented apply order `github-cicd → vpc → eks → document-service` | `dependsOn` edges in `component.yaml`; the plan DAG orders applies | A comment is not a dependency. The DAG fails a plan that would apply out of order. |
| Long-lived `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` in GitHub Secrets | GitHub OIDC → per-repo IAM role (owned by [`sourceplane/aws-admin`](https://github.com/sourceplane/aws-admin)); `GITHUB_TOKEN` is the only credential CI holds | The reference's own TODO list names this. |
| `helm upgrade --install --set image.tag=…` in a workflow step | `helm-release` composition; image tag flows from the `container-image` component's output | Deploy-time wiring, not string interpolation in YAML. |
| Health endpoints reachable through the public ALB | Gateway owns the only public ingress; `/health/*` is served on a separate internal-only port and never routed | The reference's security-guideline adaptation, implemented rather than described. |
| Terraform state in S3 with a hand-written `backend.tf` per module | Orun Cloud HTTP state backend; address derived per component/environment | No bootstrap chicken-and-egg, no per-module backend blocks to drift. |
| Single `document-service` | `api-gateway` + `documents-service` + `identity-service` | Establishes the multi-tenant seam and the service-to-service call path that phase 2 grows into. |
