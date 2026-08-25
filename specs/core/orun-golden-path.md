# The Orun golden path

Status: Normative. Read this before changing CI, `intent.yaml`, or anything
under `infra/`.

## The three layers

| Layer | File | Owns |
|-------|------|------|
| Intent | `intent.yaml` | environments, trigger bindings, discovery roots, the pinned composition source, the state backend, per-environment parameter defaults |
| Component | `component.yaml` | one unit's type, typed parameters, `dependsOn`, `secretEnv`, and which environments it subscribes to with which profile |
| Composition | [`stack-granite`](https://github.com/sourceplane/stack-granite) | how a unit of that type is actually executed |

## Where a change belongs

| You want to… | Change |
|--------------|--------|
| add a service, chart or Terraform root | a new `component.yaml` — discovery finds it on the next plan |
| change what a lane *does* for every component of a type | `stack-granite`, release it, bump the pin here |
| change which lane a component gets in an environment | that component's `subscribe.environments[].profile` / `profileRules` |
| change a value for every component in an environment | `intent.yaml` → `environments.<env>.parameterDefaults.<type>` |
| add a credential | the composition profile's `secretBindings`, or the component's `secretEnv` — never a GitHub secret |
| change CI | almost certainly none of the above; `.github/workflows/ci.yml` is not where behaviour lives |

## Profile rules are the delivery policy

```yaml
subscribe:
  environments:
    - name: stage
      profile: plan-only
      profileRules:
        - profile: apply
          when: { triggerRef: github-push-main }
```

Read-only on pull requests, applied on merge. This is the entire promotion
policy for that component, and it lives beside the thing it governs.

## Outputs flow as lease-published values

A component that creates a resource declares `secretOutputs`; the runner
publishes them onto the project/environment rung after a successful run. A
component that consumes one declares `secretEnv` reading the same key. There are
no `terraform_remote_state` data sources and no manual copying of ARNs between
files.

## Verifying locally

```bash
orun compositions lock --intent intent.yaml
orun validate --intent intent.yaml
orun plan --changed --intent intent.yaml --output plan.json
orun plan --intent intent.yaml --view dag
```

Use `--changed` for PR-scoped checks; use a full plan when validating promotion
or cross-component ordering.
