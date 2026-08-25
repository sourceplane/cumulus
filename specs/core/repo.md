# Repo shape

Status: Normative

```
apps/<service>/           one deployable service
  src/                    Fastify app, handlers, clients
  test/                   unit tests (vitest)
  Dockerfile              multi-stage, non-root, no build toolchain in runtime
  docker-compose.yml      the service + local dependency doubles, for the smoke lane
  component.yaml          node-service-turbo — the code lane
  image/component.yaml    container-image — build, scan, push
deploy/
  helm/<service>/         one chart per service
  values/<service>-<env>.yaml   per-environment overlays
  helm/<service>/component.yaml helm-release — render, validate, roll
infra/terraform/<root>/
  terraform/              the Terraform root
  component.yaml          terraform-aws
packages/
  contracts/              shared API, tenancy, health, error, idempotency types
  shared/                 ids, structured logging, config, error taxonomy
  testing/                deterministic fixtures, smoke-lane helpers
tests/<suite>/            cross-cutting suites that are components themselves
tooling/{tsconfig,eslint}/  shared configuration
specs/                    core contracts, component specs, epics
```

## Component discovery

`orun` discovers a component from a file named exactly `component.yaml` under a
declared discovery root. `*.component.yaml` is **not** discovered — a second
component in the same tree needs its own directory.

## Service anatomy

Every service exposes two HTTP listeners:

| Port | Bound to | Serves | Reachable from |
|------|----------|--------|----------------|
| `8080` | `0.0.0.0` | the API | in-cluster; the gateway additionally via ALB |
| `8081` | `0.0.0.0` | `/health/live`, `/health/ready` | kubelet probes and the ALB target-group health check only |

The health listener is a separate port rather than a separate path prefix
because a path is something an Ingress rule can accidentally expose and a port
is not. `/health/live` must never consult a dependency: a liveness probe that
fails when Redis is slow restarts a healthy pod and converts a degradation into
an outage.

## Naming

| Thing | Convention |
|-------|------------|
| workspace package | `@cumulus/<name>` |
| service directory | `apps/<name>-service`, except `api-gateway` |
| component name | matches the directory, or `<service>-image` / `<service>-release` |
| Helm release | the service name |
| Terraform root | `<service>-deps`, or the platform name (`vpc`, `eks`, `platform-addons`) |
| public id | `<prefix>_<24 hex>` — `org_`, `usr_`, `key_` |
