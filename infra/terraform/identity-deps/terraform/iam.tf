# identity-service reaches Postgres with a password, not an IAM token, so its
# role grants almost nothing today. It exists anyway: a ServiceAccount with no
# role cannot later be given one without a pod restart, and the chart's IRSA
# annotation is asserted by the E6 invariant suite for every service.

data "aws_iam_policy_document" "identity_service" {
  statement {
    sid       = "Logs"
    effect    = "Allow"
    actions   = ["logs:PutLogEvents", "logs:CreateLogStream"]
    resources = ["${aws_cloudwatch_log_group.identity_service.arn}:*"]
  }
}

module "identity_service" {
  source = "../../modules/irsa-role"

  role_name         = "${local.name_prefix}-identity-service"
  oidc_provider_arn = var.oidcProviderArn
  oidc_provider_url = var.oidcProviderUrl
  namespace         = var.k8sNamespace
  service_account   = "identity-service"
  policy_json       = data.aws_iam_policy_document.identity_service.json
}

module "ecr" {
  source = "../../modules/ecr-repository"
  name   = "${local.name_prefix}-identity-service"
}

resource "aws_cloudwatch_log_group" "identity_service" {
  name              = "/cumulus/${var.environment}/identity-service"
  retention_in_days = 30
}
