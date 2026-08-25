# cumulus

**The Kubernetes baseline — multi-tenant SaaS on AWS EKS.**

A repo that knows how to become a product. TypeScript services in bounded
contexts behind a single public ALB ingress, Helm charts per service, Terraform
for the whole AWS estate (VPC, EKS, ElastiCache, S3, RDS, ECR, IRSA), and CI
that converges the fleet on merge — all driven by
[Orun](https://github.com/sourceplane/orun) desired-state components, with zero
direct `terraform`, `helm`, `docker`, or `pnpm` invocations in GitHub Actions.

Sibling of [`lumen`](https://github.com/sourceplane/lumen) and
[`cirrus`](https://github.com/sourceplane/cirrus) (TypeScript on Cloudflare) and
[`stratus`](https://github.com/sourceplane/stratus) (.NET on Azure Container
Apps). This is the first baseline on Kubernetes.

## Status

**Phase 1 in progress.** See [`specs/epics/eks-baseline/`](specs/epics/eks-baseline/)
for the work program and [`specs/roadmap.md`](specs/roadmap.md) for the register.

## Composition stack

Execution contracts are not vendored here. They are consumed from the published
catalog at `oci://ghcr.io/sourceplane/stack-granite`, pinned to an explicit
version in `intent.yaml`. Composition changes are made in
[sourceplane/stack-granite](https://github.com/sourceplane/stack-granite),
released there, and adopted here by bumping the pinned tag.

## Layout

```
apps/api-gateway         Public HTTP entry point — the only ALB-exposed service
apps/documents-service   Document storage: S3 system of record, Redis cache-aside
apps/identity-service    Users, organizations, API keys (Postgres)

packages/contracts       Shared API, tenancy, and error types + validators
packages/shared          Generic helpers (IDs, errors, logging) — no domain logic
packages/testing         Test fixtures and utilities

deploy/helm/<service>    One chart per service (Deployment/Service/Ingress/HPA/SA)
deploy/values/           Per-environment value overlays

infra/terraform/vpc               Networking primitives
infra/terraform/eks               Control plane + node groups + IRSA
infra/terraform/platform-addons   ALB controller, external-dns, metrics-server
infra/terraform/<service>-deps    Per-service AWS dependencies

specs/                   The spec pack: core contracts, component specs, epics
```
