# infra

Terraform roots, one per state, ordered by `dependsOn` rather than by a
documented apply order. Landed in E2.

```
terraform/vpc               networking primitives
terraform/eks               control plane, node groups, IRSA provider
terraform/platform-addons   ALB controller, external-dns, metrics-server, EBS CSI
terraform/documents-deps    S3, ElastiCache, ECR, IRSA role, CloudWatch
terraform/identity-deps     RDS Postgres, ECR, IRSA role
terraform/gateway-deps      ECR, IRSA role, WAF association point
```

Each root declares `secretOutputs`; the runner lease-publishes them onto the
environment rung and downstream components read the same keys through
`secretEnv`. There are no `terraform_remote_state` data sources.
