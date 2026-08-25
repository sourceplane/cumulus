# The pod's own permissions. Nothing here is attached to a node role — a pod on
# a shared node must not inherit another service's access.

data "aws_iam_policy_document" "documents_service" {
  statement {
    sid    = "DocumentObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    # Scoped to the key prefix the service actually writes, not to the bucket.
    resources = ["${aws_s3_bucket.documents.arn}/documents/*"]
  }

  statement {
    sid       = "BucketMetadata"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.documents.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["documents/*"]
    }
  }
}

module "documents_service" {
  source = "../../modules/irsa-role"

  role_name         = "${local.name_prefix}-documents-service"
  oidc_provider_arn = var.oidcProviderArn
  oidc_provider_url = var.oidcProviderUrl
  namespace         = var.k8sNamespace
  service_account   = "documents-service"
  policy_json       = data.aws_iam_policy_document.documents_service.json
}

module "ecr" {
  source = "../../modules/ecr-repository"
  name   = "${local.name_prefix}-documents-service"
}
