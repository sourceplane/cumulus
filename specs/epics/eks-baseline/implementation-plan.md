# eks-baseline — Implementation Plan

Status: Normative for the E cluster. Architecture and decisions in `design.md`;
as-built record in `IMPLEMENTATION-STATUS.md`; credential gates in
`risks-and-open-questions.md`.

**One milestone, one PR.** Each PR body names the milestone's "done when"
clauses and how each was verified. A milestone is marked ✅ here only after its
PR is merged and CI is green on `main`.

---

## E0 — `stack-granite`: the composition catalog

**Repo:** [`sourceplane/stack-granite`](https://github.com/sourceplane/stack-granite)
**Depends on:** nothing.

**Scope**

- `stack.yaml` — catalog identity, version `0.1.0`, registry
  `ghcr.io/sourceplane/stack-granite`, public.
- `compositions/terraform-aws/` — `composition.yaml`, `schema.yaml`, the
  `terraform-aws-validate` job template, and profiles `validate`, `plan-only`,
  `apply`, `local`. Capabilities: `setup`, `aws.oidc`, `env`, `context`, `fmt`,
  `init`, `validate`, `plan`, `apply`. Required parameters: `stackName`,
  `terraformDir`, `terraformVersion`; optional `awsRegion`, `awsRoleArn`,
  `secretOutputs`, `lane`, `namespacePrefix`.
- `compositions/container-image/` — profiles `verify` (build + scan, no push)
  and `publish` (build + scan + push to ECR by digest). Capabilities:
  `docker.setup`, `aws.oidc`, `ecr.login`, `image.build`, `image.scan`,
  `image.push`, `image.output`. Emits `IMAGE_DIGEST` and `IMAGE_TAG` as job
  outputs.
- `compositions/helm-release/` — profiles `lint` (lint + template +
  `kubeconform`), and `deploy` (adds `eks.kubeconfig`, `helm.upgrade` with
  `--atomic --wait --timeout`, and `rollout.check`). Required parameters:
  `chartDir`, `releaseName`, `namespace`, `helmVersion`; optional `valuesFiles`,
  `imageRepository`, `imageDigest`, `clusterName`, `awsRegion`.
- `compositions/node-service-turbo/` — profiles `verify` (install → typecheck →
  lint → test → build) and `quick-check`. Modeled on tectonic's
  `cloudflare-worker-turbo` with the wrangler capabilities removed.
- `compositions/turbo-package/` and `compositions/publish-stack/` — ported from
  `stack-tectonic` unchanged.
- `docs/` — `getting-started.md`, `authoring.md`, `concepts.md`,
  `verification.md`; `scripts/verify.sh`; `.github/workflows/{verify,release}.yml`.
- `README.md` naming the sibling relationship to `stack-tectonic` and
  `stack-basalt`, and why the AWS lanes live apart.

**Done when** `stack-granite` is published at
`oci://ghcr.io/sourceplane/stack-granite:0.1.0`, the release workflow is green,
and `orun compositions lock` in a scratch intent resolves all six exports.

---

## E1 — Repo foundation

**Depends on:** E0.

**Scope**

- pnpm workspace + Turborepo: `package.json`, `pnpm-workspace.yaml`,
  `turbo.json`, `tooling/tsconfig/`, `tooling/eslint/` — ported from lumen and
  stripped of Cloudflare/wrangler assumptions.
- `packages/contracts` — API envelope, error taxonomy, tenancy types, and Zod
  validators. Ported from lumen's `packages/contracts`, reduced to what phase 1
  actually uses (documents + identity + gateway).
- `packages/shared` — IDs, structured logging, error helpers. Ported.
- `packages/testing` — fixtures and helpers. Ported.
- `intent.yaml` — pins `oci://ghcr.io/sourceplane/stack-granite:0.1.0`;
  declares the `dev`/`stage`/`prod` environments with `stage → prod` promotion;
  the three trigger bindings (`github-pull-request`, `github-push-main`,
  `local-development`); discovery roots `apps/`, `infra/`, `packages/`,
  `tests/`, `deploy/`; the Orun Cloud state backend and workspace claim.
- `.github/workflows/ci.yml` — the two-job plan/run shape. No direct tool
  invocations.
- `component.yaml` for each of the three packages (`turbo-package`).
- `specs/core/` — `constitution.md`, `repo.md`, `orun-golden-path.md`,
  `access-and-infra.md` adapted to AWS/EKS.

**Done when** `orun validate --intent intent.yaml` passes, `orun plan --changed`
produces a non-empty job matrix for a package edit, and CI is green on the PR
with the three package verify lanes running.

---

## E2 — Terraform AWS estate

**Depends on:** E1.

**Scope**

Four Terraform roots under `infra/terraform/`, each with a `component.yaml` of
type `terraform-aws`, wired by `dependsOn`:

- `vpc/` — 2 AZs (the EKS minimum), public + private subnets, IGW, one NAT per
  AZ, flow logs. Outputs: `vpc_id`, `private_subnet_ids`, `public_subnet_ids`.
- `eks/` — control plane (public endpoint restricted to declared CIDRs),
  managed node groups with a Spot-capable variant, the OIDC provider for IRSA,
  cluster security group, `aws-auth` mapping. Outputs: `cluster_name`,
  `cluster_endpoint`, `oidc_provider_arn`.
- `platform-addons/` — AWS Load Balancer Controller IAM policy + IRSA role,
  `external-dns` role, `metrics-server`, EBS CSI driver role. Outputs: the role
  ARNs the charts annotate their ServiceAccounts with.
- `documents-deps/` — S3 bucket (versioned, SSE, public access blocked,
  lifecycle), ElastiCache Redis replication group (TLS in transit, subnet group,
  security group scoped to the node SG), ECR repository (scan-on-push, lifecycle
  policy), the service's IRSA role, CloudWatch log group + alarms.
- `identity-deps/` — RDS Postgres (private subnets, encrypted, no public
  access), its security group, Secrets Manager entry for the credentials, ECR
  repository, IRSA role.
- `gateway-deps/` — ECR repository, IRSA role, WAF web ACL association point.

Each root declares `secretOutputs` for the values downstream components consume
(bucket name, Redis endpoint, role ARNs, ECR repository URIs, DB connection).

**Done when** every root passes `terraform fmt -check`, `terraform init
-backend=false`, and `terraform validate` in the `dev` verify lane on the PR;
`orun plan --view dag` shows `vpc → eks → platform-addons → *-deps`; and the
`stage`/`prod` components resolve to `plan-only` on PRs and `apply` on
`github-push-main` without an AWS account being present.

---

## E3 — `documents-service`

**Depends on:** E1, E2.

**Scope**

- `apps/documents-service/` — Fastify + TypeScript. `PUT /documents/:id`
  (validate ≤100 KB → write S3 → invalidate cache), `GET /documents/:id`
  (cache-aside), `DELETE /documents/:id`. AWS SDK v3 S3 client with capped
  timeouts and retries; `ioredis` with a short connect timeout and a
  circuit-broken fallback to S3.
- Health server on a second port: `/health/live` (process) and `/health/ready`
  (S3 required, Redis optional), never routed publicly.
- Multi-stage `Dockerfile` — distroless-style runtime, non-root UID, no build
  toolchain in the final layer.
- `deploy/helm/documents-service/` — Deployment (probes wired to the health
  port, `topologySpreadConstraints`, PDB), Service (ClusterIP), ServiceAccount
  (IRSA annotation from a value), HPA, NetworkPolicy allowing ingress only from
  the gateway. **No Ingress template.**
- `deploy/values/documents-service-{dev,stage,prod}.yaml`.
- `docker-compose.yml` with LocalStack + Redis for the smoke lane; unit tests
  (Vitest) and a compose-based smoke test asserting the PUT/GET roundtrip and
  the cache-invalidation path.
- Three `component.yaml`s: `node-service-turbo` (code), `container-image`
  (image), `helm-release` (chart), chained by `dependsOn`.

**Done when** unit + smoke tests pass in CI, `helm lint` and `helm template`
render cleanly for all three environments, `kubeconform` validates the rendered
manifests, the image builds and Trivy-scans clean, and no rendered manifest
contains an `Ingress` or the tag `latest`.

---

## E4 — `identity-service`

**Depends on:** E1, E2.

**Scope**

- `apps/identity-service/` — Fastify + TypeScript. Users, organizations,
  memberships, API keys. `POST /orgs`, `GET /orgs/:id`, `POST /api-keys`,
  `POST /verify` (the gateway's authN call). Postgres via `pg` with a bounded
  pool; credentials from the lease-published `identity-deps` output.
- `packages/db` — migration harness (plain SQL, forward-only, checksummed
  manifest) and runner, ported from lumen's `packages/db` shape.
- `infra/db-migrate` component — plan on PRs, apply on merge to `main`.
- Health server, Dockerfile, `deploy/helm/identity-service/` and env overlays,
  mirroring E3. NetworkPolicy: ingress from gateway only; egress to RDS only.
- Unit tests + a compose smoke lane against a real Postgres container.
- The same three-component chain as E3, plus the migration component ordered
  ahead of the Helm release.

**Done when** the migration harness applies the initial schema against the
compose Postgres in CI, unit + smoke tests pass, the chart renders and validates
for all three environments, and `orun plan --view dag` shows
`identity-deps → db-migrate → identity-service helm release`.

---

## E5 — `api-gateway`

**Depends on:** E3, E4.

**Scope**

- `apps/api-gateway/` — Fastify + TypeScript. The only service with an Ingress.
  - Tenant resolution and authN by calling `identity-service /verify`.
  - Request routing to `documents-service` and `identity-service` over cluster
    DNS, with per-upstream timeouts, retries and a circuit breaker.
  - Idempotency: `Idempotency-Key` on unsafe methods, replay window backed by
    Redis (the same ElastiCache group, separate key prefix).
  - Rate limiting per API key, sliding window in Redis.
  - Structured access logs carrying request id, org id and upstream latency.
- Health server on the internal port; `/health/*` explicitly excluded from every
  Ingress path rule and asserted so by a rendered-manifest test.
- Dockerfile, `deploy/helm/api-gateway/` **with** an Ingress template, env
  overlays.
- The same three-component chain.

**Done when** the gateway's contract tests pass against stubbed upstreams, the
rendered `Ingress` for each environment carries exactly the intended path rules
(and no `/health` rule), and the compose smoke lane drives a full
gateway → documents → S3 roundtrip.

---

## E6 — Endpoint exposure, verification, and docs

**Depends on:** E5.

**Scope**

- ALB wiring on the gateway Ingress: `alb.ingress.kubernetes.io/scheme:
  internet-facing`, `target-type: ip`, HTTPS listener with an ACM certificate
  ARN from a value, HTTP→HTTPS redirect, health-check path pointed at the
  internal health port, deletion protection in `prod`.
- **Source-range restriction** (the reference's `ip-restrict` intent):
  `inbound-cidrs` driven by a per-environment `allowedCidrs` value, defaulting
  closed in `stage`/`prod`; WAF web ACL association.
- `tests/endpoint-contract/` — a `turbo-package` component that renders every
  chart for every environment and asserts the invariants: exactly one Ingress in
  the fleet; it belongs to `api-gateway`; no `/health` path rule; no `latest`
  tag; every ServiceAccount carries an IRSA annotation; every Deployment sets
  resource requests/limits, `runAsNonRoot`, and a read-only root filesystem.
- `docs/` — `architecture.md` (application + operations, mirroring the
  reference's split), `deployment.md`, `testing-api.md`, `runbook.md`.
- `README.md` updated: real layout, real status, the verification commands.
- `specs/components/` — one durable contract doc per service.

**Done when** the endpoint-contract test suite is green on `main`, the docs
describe the built system rather than the intended one, and a reader can follow
`deployment.md` to the exact point where an AWS account is required and no
further.

---

## Phase 2 (registered, not in this epic)

| ID | What |
|----|------|
| E7 | Live AWS apply: OIDC role in `aws-admin`, `vpc → eks → addons → deps` applied, the ALB endpoint answering, cost guardrails. |
| E8 | Observability: OpenTelemetry traces through the gateway, CloudWatch/AMP metrics, dashboards, SLO alarms. |
| E9 | Progressive delivery: canary or blue/green for the Helm releases. |
| E10 | Port further lumen bounded contexts (events, config, metering) onto the same rails. |
