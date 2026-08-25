# Access and infrastructure

Status: Normative. Phase 1 provisions nothing — this document describes the
model the components are authored against, and names precisely what a human
must supply before E7 can apply any of it.

## What CI holds

`GITHUB_TOKEN`, and nothing else. It is GitHub-issued, ephemeral, and scoped to
the run.

Through phase 1 that is not merely a policy but a structural fact: every
component subscribes to a profile whose capability set excludes the OIDC step,
so no lane in this repo has a path to AWS. There is no long-lived access key to
rotate because there is no long-lived access key.

## The intended AWS access model

```
GitHub Actions (id-token: write)
        │  OIDC assertion: repo:sourceplane/cumulus:<ref>
        ▼
Shared GitHub OIDC provider          ← one per AWS account, owned by aws-admin
        │
        ▼
Per-repo IAM roles                   ← owned by aws-admin, split by lane
   cumulus-plan     read-only, for plan-only lanes
   cumulus-deploy   mutating, for apply and helm deploy lanes
```

Roles are **never** created by this repo. They live in
[`sourceplane/aws-admin`](https://github.com/sourceplane/aws-admin) under
`components/github-repos/sourceplane-cumulus/`. A repo that can grant itself
permissions is a repo whose permissions mean nothing.

## Terraform state

State lives on the Orun Cloud HTTP backend, not in S3. The runner exports
`TF_HTTP_*` per job (address `…/state/tfstate/{component}/{env}`, run token as
password), so:

- `backend "http"` needs no `-backend-config` block to drift,
- state needs no AWS credential of its own,
- the environment is *in* the address, so there are no Terraform workspaces,
- and there is no state bucket to bootstrap before the first apply — the
  chicken-and-egg the reference solution solves with a separate `tf-state`
  module simply does not arise.

## What E7 requires from a human

| # | Item | Why it cannot be automated here |
|---|------|---------------------------------|
| 1 | An AWS account id and region | Nothing in the repo may name an account (constitution §4). |
| 2 | `components/github-repos/sourceplane-cumulus/` in `aws-admin`, applied | Role creation is the other repo's job by design. |
| 3 | A decision on `ingress.allowedCidrs` for `stage` and `prod` | Defaults closed, so the decision cannot be skipped silently. |
| 4 | An ACM certificate ARN and a hostname | Requires a domain someone owns. |
| 5 | Acceptance of roughly $150–250/month | EKS control plane, NAT per AZ, ALB, ElastiCache, RDS, CloudWatch. |

Items 3–5 are tracked in
[`../epics/eks-baseline/risks-and-open-questions.md`](../epics/eks-baseline/risks-and-open-questions.md).

## Secrets

There is no AWS Secrets Manager in this design and no `kubectl create secret`
step. Values produced by infrastructure are lease-published by the component
that produced them and resolved into consuming components as `secretEnv` at run
time, redacted from logs. A secret that exists in two places has two rotation
schedules and one of them is wrong.
