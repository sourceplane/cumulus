# The gateway's own dependencies. It owns no data store: it holds idempotency
# records and rate-limit counters in the documents cache under a separate key
# prefix, because a second Redis for two key prefixes is a second thing to
# operate for no isolation benefit.

data "aws_iam_policy_document" "api_gateway" {
  statement {
    sid       = "Logs"
    effect    = "Allow"
    actions   = ["logs:PutLogEvents", "logs:CreateLogStream"]
    resources = ["${aws_cloudwatch_log_group.api_gateway.arn}:*"]
  }
}

module "api_gateway" {
  source = "../../modules/irsa-role"

  role_name         = "${local.name_prefix}-api-gateway"
  oidc_provider_arn = var.oidcProviderArn
  oidc_provider_url = var.oidcProviderUrl
  namespace         = var.k8sNamespace
  service_account   = "api-gateway"
  policy_json       = data.aws_iam_policy_document.api_gateway.json
}

module "ecr" {
  source = "../../modules/ecr-repository"
  name   = "${local.name_prefix}-api-gateway"
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/cumulus/${var.environment}/api-gateway"
  retention_in_days = 30
}

# ---------------------------------------------------------------------------
# WAF. Associated with the ALB by the Ingress annotation the chart renders, so
# the ACL is created here and referenced there — the chart never creates it.
# ---------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "gateway" {
  name  = "${local.name_prefix}-gateway"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rule-set"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # A blunt per-IP ceiling underneath the application's per-API-key limiter. The
  # application limiter cannot help with traffic that never gets far enough to
  # be identified.
  rule {
    name     = "RateLimitPerIp"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-per-ip"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "gateway"
    sampled_requests_enabled   = true
  }
}
