# apps

One directory per deployable service. Each carries three components — the code
lane (`node-service-turbo`), the image (`container-image`), and the release
(`helm-release`) — plus a `Dockerfile` and a `docker-compose.yml` for the smoke
lane.

| Service | Milestone | What |
|---------|-----------|------|
| `documents-service` | E3 | S3 system of record, Redis cache-aside |
| `identity-service` | E4 | Users, organizations, API keys (Postgres) |
| `api-gateway` | E5 | The only public ingress: authN, idempotency, rate limit, routing |

See [`specs/epics/eks-baseline/implementation-plan.md`](../specs/epics/eks-baseline/implementation-plan.md).
