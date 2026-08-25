# eks-baseline — Risks and Open Questions

Status: Living. Each entry is either a **gate** (needs a human decision or a
credential) or a **risk** (needs mitigation or acceptance).

## Gates

### AWS account — ⛔ blocks E7, not E0–E6

Phase 1 ships no live infrastructure. There is no AWS account wired to this
repo, and standing up the designed estate costs roughly **$150–250/month**
(EKS control plane ~$73, one NAT gateway per AZ, an internet-facing ALB,
ElastiCache, RDS, CloudWatch ingestion).

The decision to stop at verify lanes is deliberate and reversible: every
Terraform root, every chart and every profile rule for `stage`/`prod` is
authored now, so E7 is *supplying an account and an OIDC role*, not writing
infrastructure.

**Needed to open E7:** an AWS account id, a region, and a per-repo IAM role
created through [`sourceplane/aws-admin`](https://github.com/sourceplane/aws-admin)
(`components/github-repos/sourceplane-cumulus/`) trusting
`repo:sourceplane/cumulus:*` via the shared GitHub OIDC provider.

### ACM certificate and DNS — ⛔ blocks the TLS half of E6

The gateway's HTTPS listener needs a certificate ARN and a hostname. Until a
domain is chosen, `deploy/values/api-gateway-{stage,prod}.yaml` carry empty
`ingress.certificateArn` / `ingress.host` and the rendered Ingress is
HTTP-only in `dev`. The endpoint-contract test asserts that `stage`/`prod`
values must not be empty *once E7 opens* — it is skipped until then, and the
skip is explicit rather than silent.

### Allowed source ranges — needs a decision before E7

`ingress.allowedCidrs` defaults to `[]` in `stage`/`prod`, which the chart
renders as "deny all". Someone must decide the real allow-list (office egress?
a VPN CIDR? fully public?) before the endpoint is reachable. Defaulting closed
means the decision cannot be skipped by accident.

## Risks

### R1 — Catalog drift between `stack-granite` and `stack-tectonic`

Two catalogs with a shared shape will drift: a fix to the `turbo-package`
contract lands in one and not the other.

*Mitigation:* `turbo-package` and `publish-stack` are ported **byte-identical**
from `stack-tectonic` in E0, and a note in `stack-granite`'s `docs/authoring.md`
names `stack-tectonic` as their upstream. Divergence must be a deliberate edit.

*Accepted:* the alternative — one shared catalog — is the coupling that
`stack-basalt` was split out to avoid.

### R2 — Verify-only lanes can pass while the real apply would fail

`terraform validate` with `-backend=false` does not catch provider-side errors,
IAM policy mistakes, or quota limits. A green phase-1 CI is not a promise that
E7 applies cleanly on the first try.

*Mitigation:* say so plainly in `docs/deployment.md` rather than implying
otherwise, and budget E7 for iteration. `terraform plan` against a real account
is the first E7 task, ahead of any apply.

### R3 — LocalStack fidelity

The compose smoke lane runs against LocalStack S3, not S3. SSE-KMS, bucket
policies and IAM denials behave differently or not at all.

*Mitigation:* keep the smoke lane's assertions to the application contract
(roundtrip, cache invalidation, degraded-cache behaviour) and leave
storage-policy assertions to Terraform-level checks and, later, E7.

### R4 — Helm chart sprawl

Three near-identical charts invite copy-paste divergence.

*Mitigation:* the endpoint-contract suite in E6 asserts the cross-cutting
invariants (security context, resource limits, IRSA annotation, no `latest`, no
unexpected Ingress) over *every* rendered chart, so divergence fails CI rather
than review. A shared library chart is a phase-2 option if the duplication
actually hurts.

### R5 — Cost surprise if E7 is opened casually

An EKS estate left running is a recurring bill with no natural stopping point.

*Mitigation:* E7's scope includes a destroy lane and a documented teardown
order before it includes an apply. The reference solution's "deploy and destroy
via CI, cost-free idle time" property is worth keeping.

## Resolved

_None yet._
