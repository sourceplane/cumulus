# deploy

```
helm/<service>/    one chart per service
values/            per-environment overlays, <service>-<env>.yaml
```

Charts carry no environment-specific values. An overlay that belongs in
`values/` but lives in the chart is how `stage` and `prod` quietly diverge.

Only `api-gateway` has an `Ingress` template. The other services are
`ClusterIP` and unreachable from outside the cluster by construction, not by
configuration — see [`specs/epics/eks-baseline/design.md`](../specs/epics/eks-baseline/design.md) § 3.
