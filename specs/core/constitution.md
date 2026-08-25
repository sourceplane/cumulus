# Constitution

Status: Normative

The rules everything in this repo obeys. A change here is a deliberate act with
its own PR, not a side effect of another change.

## 1. Desired state, not scripts

Every unit of work is a component with a declared type and typed parameters.
`.github/workflows/` may call `orun plan` and `orun run` and nothing else. The
day a `terraform apply`, `helm upgrade`, `docker push` or `pnpm build` appears
in a workflow step, the plan DAG has stopped being the source of truth and the
repo has quietly forked into two delivery systems.

## 2. A component says what, never how

`component.yaml` names a chart directory, a Terraform root, an image. It never
names a command. How those are executed lives in
[`stack-granite`](https://github.com/sourceplane/stack-granite), versioned and
pinned.

## 3. Order is declared, not documented

Deployment order lives in `dependsOn` edges. A README that says "apply the VPC
first" is a comment; a `dependsOn` edge is a plan that fails when violated.

## 4. Nothing account-specific in source

No AWS account id, no ARN, no cluster endpoint, no bucket name in a committed
file. Resource coordinates are published by the component that created them and
consumed through `secretEnv`. This is enforced by lint rules, and it is what
makes the repo instantiable into a second account.

## 5. Safe by default

A component that omits a profile gets the lane that cannot authenticate and
cannot mutate. Reaching production is always an explicit subscription, never an
inherited one.

## 6. Immutable artifacts

Image tags carry the commit sha and images are deployed by digest. `latest`
never appears in a rendered manifest. A rollback must be a coordinate, not a
guess.

## 7. One public door

Exactly one service in the fleet owns an `Ingress`. Everything else is
`ClusterIP`. Health endpoints are served on a separate internal port and are
never routable from outside the cluster — not "not routed today", *not
routable*.

## 8. Degraded beats down

A failed optional dependency costs latency, never availability. The cache is
optional; the system of record is not. `/health/ready` distinguishes them, and
the distinction is tested.

## 9. Trust code reality over docs

When a spec and the running system disagree, the system is the source of truth
and the spec is the bug. As-built lives in each epic's
`IMPLEMENTATION-STATUS.md`, never silently edited into a design doc.

## 10. One milestone, one PR

A milestone lands as a single reviewable PR whose body names its "done when"
clauses and how each was verified. A "done when" that was not met is stated as
not met.
