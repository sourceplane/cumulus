# Every parameter on the component is exported as TF_VAR_<name> by the
# terraform-aws composition, alongside TF_VAR_environment and TF_VAR_component.
# Declaring them here is what turns a typo in component.yaml into a failed
# validate rather than a silently ignored value.

variable "environment" {
  type        = string
  description = "Environment name (dev, stage, prod). Injected by the composition."
}

variable "component" {
  type        = string
  description = "Component name. Injected by the composition."
}

variable "awsRegion" {
  type        = string
  description = "AWS region."
  default     = "ap-southeast-1"
}

variable "namespacePrefix" {
  type        = string
  description = "Prefix on every named resource so environments cannot collide in one account."
  default     = "dev-"
}

variable "owner" {
  type        = string
  description = "GitHub owner, for tagging."
  default     = "sourceplane"
}

variable "repo" {
  type        = string
  description = "GitHub repo, for tagging."
  default     = "cumulus"
}

variable "lane" {
  type        = string
  description = "verify or deploy. Surfaced for conditional guards; not otherwise used."
  default     = "verify"
}

variable "namespace" {
  type        = string
  description = "Org namespace label."
  default     = "sourceplane"
}

variable "stackName" {
  type        = string
  description = "Logical root name; passed through by the composition."
  default     = ""
}

variable "terraformDir" {
  type    = string
  default = ""
}

variable "terraformVersion" {
  type    = string
  default = ""
}

variable "secretOutputs" {
  type        = string
  description = "Passed through by the composition; consumed by the runner, not by Terraform."
  default     = ""
}

variable "oidcProviderArn" {
  type        = string
  description = "IRSA provider ARN, lease-published by the eks component."
  default     = ""
}

variable "oidcProviderUrl" {
  type        = string
  description = "IRSA issuer without scheme, lease-published by the eks component."
  default     = ""
}
