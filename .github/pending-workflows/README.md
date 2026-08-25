# Pending workflows

These files are finished CI workflows that could not be pushed. GitHub refuses a
push that creates or updates anything under `.github/workflows/` unless the
pushing token carries the `workflow` OAuth scope, and the account this repo was
scaffolded from does not have it.

They live here so they are versioned and reviewable rather than sitting in
someone's scratch directory.

## Activating them

In an interactive terminal:

```bash
gh auth refresh -h github.com -s workflow -s write:packages
```

Then, in this repo:

```bash
mkdir -p .github/workflows
git mv .github/pending-workflows/ci.yml .github/workflows/ci.yml
git rm .github/pending-workflows/README.md
git commit -m "ci: activate the orun plan/run workflow"
git push
```

`write:packages` is requested at the same time because the sibling catalog
[`stack-granite`](https://github.com/sourceplane/stack-granite) has the same
problem and additionally needs to publish its OCI artifact — see that repo's
`.github/pending-workflows/README.md`.

Until then `intent.yaml` pins `oci://ghcr.io/sourceplane/stack-granite:0.1.0`,
which does not resolve, so CI here would fail at the plan step even if the
workflow were live. The catalog must publish first.
