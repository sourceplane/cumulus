# IAM for the in-cluster platform controllers.
#
# This root creates ROLES only. The controllers themselves are Helm releases —
# an IAM change and a chart upgrade have different blast radii and different
# rollback stories, and coupling them means neither can move alone.

locals {
  addon_namespace = "kube-system"
}

# ---------------------------------------------------------------------------
# AWS Load Balancer Controller — provisions the ALB that fronts the gateway.
#
# The policy is vendored verbatim from the controller's own release
# (kubernetes-sigs/aws-load-balancer-controller v2.13.0,
# docs/install/iam_policy.json). Vendored rather than hand-written because a
# hand-trimmed version fails at Ingress-reconcile time with an AccessDenied
# naming an action nobody expected to need. Refresh it in the same PR that
# bumps the controller version.
# ---------------------------------------------------------------------------

module "alb_controller" {
  source = "../../modules/irsa-role"

  role_name         = "${local.name_prefix}-alb-controller"
  oidc_provider_arn = var.oidcProviderArn
  oidc_provider_url = var.oidcProviderUrl
  namespace         = local.addon_namespace
  service_account   = "aws-load-balancer-controller"
  policy_json       = file("${path.module}/aws-load-balancer-controller-policy.json")
}

# ---------------------------------------------------------------------------
# external-dns — writes the Route 53 records the gateway Ingress asks for.
# Scoped to change records, never to create or delete a hosted zone.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "external_dns" {
  statement {
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

module "external_dns" {
  source = "../../modules/irsa-role"

  role_name         = "${local.name_prefix}-external-dns"
  oidc_provider_arn = var.oidcProviderArn
  oidc_provider_url = var.oidcProviderUrl
  namespace         = local.addon_namespace
  service_account   = "external-dns"
  policy_json       = data.aws_iam_policy_document.external_dns.json
}

# ---------------------------------------------------------------------------
# EBS CSI driver — needed by any StatefulSet that claims a volume. Nothing in
# phase 1 does, but the driver is cluster infrastructure and adding it later
# means adding it during the incident where something needs a volume.
# ---------------------------------------------------------------------------

module "ebs_csi" {
  source = "../../modules/irsa-role"

  role_name         = "${local.name_prefix}-ebs-csi"
  oidc_provider_arn = var.oidcProviderArn
  oidc_provider_url = var.oidcProviderUrl
  namespace         = local.addon_namespace
  service_account   = "ebs-csi-controller-sa"
  policy_json       = data.aws_iam_policy_document.ebs_csi.json
}

data "aws_iam_policy_document" "ebs_csi" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*:*:volume/*", "arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateVolume", "CreateSnapshot"]
    }
  }

  # Create and delete are restricted to volumes this driver made. Without the
  # tag condition the driver can delete any EBS volume in the account.
  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateVolume", "ec2:DeleteVolume", "ec2:DeleteSnapshot"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}
