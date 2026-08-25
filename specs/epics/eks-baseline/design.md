# eks-baseline — Design

Status: Normative for the E cluster. Milestone sequencing lives in
`implementation-plan.md`; as-built in `IMPLEMENTATION-STATUS.md`.

## 1. The three layers

Cumulus inherits lumen's layering unchanged. Only the compositions differ.

```
intent.yaml            ← repo-level: environments, triggers, discovery roots,
                          the pinned composition source, state backend
component.yaml         ← per-unit desired state: type, parameters, dependsOn,
   (many, discovered)    which environments it subscribes to, with what profile
oci://ghcr.io/…/       ← execution contracts: how a `terraform` unit is actually
   stack-granite         planned/applied, how a container is built, how a Helm
                          release is rolled — versioned, published, pinned
```

The rule that makes this work: **a component says *what*, never *how*.** A
service's `component.yaml` names its chart directory and its image; it never
names `helm upgrade`. Changing how every Helm release in the fleet is rolled is
one release of `stack-granite` and one tag bump here.

## 2. Composition catalog — `stack-granite`

Six compositions, each a `composition.yaml` + `schema.yaml` + job templates +
execution profiles, published as an OCI artifact to
`ghcr.io/sourceplane/stack-granite`.

| Composition | `spec.type` | What it contracts |
|-------------|-------------|-------------------|
| `terraform-aws` | `terraform-aws` | fmt → init → validate → plan → apply against a Terraform root, with AWS credentials assumed via OIDC and state on the Orun HTTP backend. Publishes declared outputs as lease-bound secrets (the SEC-JOB pattern). |
| `container-image` | `container-image` | Docker build (BuildKit, multi-stage, cached), Trivy scan, and push to ECR with an immutable digest+semver tag. Verify lanes build and scan without pushing. |
| `helm-release` | `helm-release` | `helm lint` → `helm template` (rendered manifests asserted, and `kubeconform`-validated) → `helm upgrade --install --atomic --wait` → post-release rollout check. Verify lanes stop after template. |
| `node-service-turbo` | `node-service-turbo` | install → typecheck → lint → test → build for one Fastify service in the pnpm/turbo workspace. The pure-code lane, upstream of the image. |
| `turbo-package` | `turbo-package` | The same for a non-deployable workspace package. Ported from `stack-tectonic` unchanged. |
| `publish-stack` | `publish-stack` | The catalog's own release lane. Ported from `stack-tectonic` unchanged. |

`terraform-aws` is a distinct type rather than a reuse of tectonic's
`terraform`: tectonic's contract has no OIDC role-assumption capability and no
`kubectl`/`aws eks update-kubeconfig` step, and adding AWS-shaped capabilities
to a composition that Cloudflare products pin is exactly the cross-stack
coupling `stack-basalt` was split out to avoid.

### Why a separate catalog at all

Same reason `stack-basalt` exists for .NET/Azure: a Helm-lane change here must
not be able to destabilize `lumen` or `cirrus`, which pin `stack-tectonic`. The
two catalogs share a shape, not a release train.

## 3. Runtime architecture

```
                 Internet
                    │
              ┌─────▼──────┐   AWS Load Balancer Controller
              │    ALB     │   (IngressClass alb, IRSA)
              │ 443 + WAF  │   source-range restricted
              └─────┬──────┘
                    │  the ONLY public Ingress in the cluster
            ┌───────▼────────┐
            │  api-gateway   │  authN, tenant resolution, idempotency,
            │   (Fastify)    │  rate limit, request routing
            └───┬────────┬───┘
       ClusterIP│        │ClusterIP
        ┌───────▼──┐  ┌──▼─────────────┐
        │ identity │  │   documents    │
        │ service  │  │    service     │
        └────┬─────┘  └──┬──────────┬──┘
             │           │          │
        ┌────▼────┐  ┌───▼───┐  ┌───▼──────────┐
        │   RDS   │  │  S3   │  │ ElastiCache  │
        │Postgres │  │bucket │  │    Redis     │
        └─────────┘  └───────┘  └──────────────┘
```

### Decisions

**The gateway owns the only public ingress.** `documents-service` and
`identity-service` are `ClusterIP` with no `Ingress` object at all. The
reference exposes its service directly and then notes, in its TODO list, that
`/health/*` should not be public. Here that is structural: health endpoints bind
a second, non-routed port (`8081`) that only the kubelet and the ALB target
group's health check reach. There is no ALB rule that can reach them.

**Cache-aside, cache-optional.** Carried over from the reference verbatim
because it is right: `GET` tries Redis, falls back to S3 on miss *or error*, and
repopulates with a TTL; `PUT` writes S3 then deletes the key. A Redis outage
degrades latency, never correctness. `/health/ready` reports storage as required
and cache as optional.

**Modular Terraform states.** Four roots, four states, ordered by `dependsOn`:
`vpc` → `eks` → `platform-addons` → `<service>-deps`. Small blast radius, and
ordered destroys work. Identical rationale to the reference; the difference is
that the order is executable.

**Outputs flow as lease-published secrets, not as `terraform_remote_state`.**
Each Terraform component declares `secretOutputs` (`KEY=output`). The runner
publishes them onto the project/environment rung after a successful apply;
consuming components read the same keys through `secretEnv`. No cross-state data
sources, no `remote_state` IAM grants, no bootstrap ordering puzzle.

**IRSA everywhere; no node-level AWS permissions.** Each service's Terraform
root owns its IAM role and trust policy; the chart's ServiceAccount carries the
`eks.amazonaws.com/role-arn` annotation. The role ARN reaches the chart as a
lease-published output, not a committed string.

**Immutable image tags.** `container-image` tags `<semver>-<git-sha>` and pushes
by digest. `helm-release` receives the digest. `latest` never appears in a
rendered manifest — the reference names this as an open TODO.

## 4. Environments and promotion

Three environments, matching lumen's shape:

| Env | Purpose | Terraform lane | Helm lane |
|-----|---------|----------------|-----------|
| `dev` | Verify-only. No cluster, no AWS. Every PR. | `validate` | `lint` + `template` |
| `stage` | The first environment that *would* apply. | `plan-only` on PRs, `apply` on merge to `main` | `template` on PRs, `deploy` on merge |
| `prod` | Promotes after `stage`. | same, gated on `stage` | same, gated on `stage` |

Through phase 1 no AWS account is wired, so `stage` and `prod` resolve to their
plan-only/template profiles in practice. The profile rules are authored now so
that E7 is a credentials change, not a CI rewrite.

## 5. CI

One workflow, two jobs, exactly as in lumen: `plan` produces `plan.json` and a
job matrix; `run` fans out one runner per job and calls `orun run --job`. No
`terraform`, `helm`, `docker`, `pnpm` or `kubectl` command appears in
`.github/workflows/`. `GITHUB_TOKEN` is the only credential the workflow holds.

## 6. What phase 1 deliberately does not do

- **No live cluster.** See `risks-and-open-questions.md` § AWS account.
- **No GitOps controller.** Argo/Flux would put a second reconciler beside the
  Orun plan DAG with no owner boundary between them. If it earns its place it
  arrives as a phase-2 decision, not a default.
- **No service mesh.** Three services with ClusterIP DNS and mTLS terminated at
  the ALB do not need one.
- **No console.** Cumulus is the runtime baseline; a console is lumen's job and
  arrives, if at all, by porting.
