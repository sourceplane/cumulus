# An IAM role a Kubernetes ServiceAccount can assume via IRSA.
#
# Shared because the trust policy is the part that is easy to get subtly wrong
# and impossible to notice: a `StringLike` where `StringEquals` belongs, or a
# missing `aud` condition, turns a role scoped to one ServiceAccount into a role
# any pod in the cluster can assume.

terraform {
  required_version = "~> 1.15.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
  }
}

variable "role_name" {
  type = string
}

variable "oidc_provider_arn" {
  type        = string
  description = "The cluster's IRSA provider ARN."
}

variable "oidc_provider_url" {
  type        = string
  description = "The issuer URL without its scheme."
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace of the ServiceAccount."
}

variable "service_account" {
  type        = string
  description = "ServiceAccount name."
}

variable "policy_json" {
  type        = string
  description = "The inline policy this role grants."
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # StringEquals, not StringLike: this role is assumable by exactly one
    # ServiceAccount in exactly one namespace.
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account}"]
    }

    # Without the audience condition the trust policy accepts tokens minted for
    # any audience the provider will issue.
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy" "this" {
  name   = "inline"
  role   = aws_iam_role.this.id
  policy = var.policy_json
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "role_name" {
  value = aws_iam_role.this.name
}
