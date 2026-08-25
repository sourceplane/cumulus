# eks-baseline — Implementation Status

Status: **As-built record.** What actually shipped, PR by PR. Intent and design
live in `README.md` / `design.md` / `implementation-plan.md` and are never
edited to match reality here — this file is where reality is recorded.

## Milestone ledger

| ID | Milestone | Status | PR | Verified by |
|----|-----------|--------|----|-------------|
| E0 | `stack-granite` catalog | ⛔ Blocked (publish) | [stack-granite@7af81da](https://github.com/sourceplane/stack-granite/commit/7af81da) | Catalog gate green (6/6 compositions pack and export); a scratch consumer plans all four new types and the rendered steps confirm capability filtering. **Not published** — see Deviations. |
| E1 | Repo foundation | 🚧 In review | #2 | `pnpm typecheck` / `lint` / `test` green (17 tests); `orun validate` passes; `orun plan` produces 9 jobs across 3 environments. CI workflow **not landed** — see Deviations. |
| E2 | Terraform AWS estate | 🗓️ Planned | — | — |
| E3 | `documents-service` | 🗓️ Planned | — | — |
| E4 | `identity-service` | 🗓️ Planned | — | — |
| E5 | `api-gateway` | 🗓️ Planned | — | — |
| E6 | Endpoint exposure + docs | 🗓️ Planned | — | — |

## Deviations from plan

### E0 — the catalog is authored and verified but not published

`implementation-plan.md` says E0 is done when the catalog is published at
`oci://ghcr.io/sourceplane/stack-granite:0.1.0`. It is not. Everything else in
E0 shipped and is verified; publication is blocked on a GitHub token scope.

The `gh` account this work ran under holds `admin:public_key, gist, read:org,
repo`. Publishing needs `write:packages`, and pushing
`.github/workflows/release.yml` — the workflow that would publish from CI —
needs `workflow`. Both pushes were rejected by GitHub, so the two workflow files
are authored but held out of the commit.

**Unblock:** in an interactive terminal,

    gh auth refresh -h github.com -s workflow -s write:packages

then re-add `.github/workflows/{verify,release}.yml` to `stack-granite` and push
tag `v0.1.0`. The release workflow does the rest.

### E1 — the CI workflow is authored but not landed

Same cause. `.github/workflows/ci.yml` is written and correct but cannot be
pushed without `workflow` scope, so E1's "done when" clause *"CI is green on the
PR"* is **not met**. The three verify lanes were instead exercised locally
through `orun plan` against a locally-packed copy of the catalog, which proves
the components resolve and the job templates render but does not prove the lanes
run green on a runner.

E1 is therefore reviewable but not complete. It completes when the scope above
is granted, the catalog publishes, and CI runs.

## Live state

No environment is deployed. Phase 1 is verify-only by design — see
`risks-and-open-questions.md` § AWS account.
