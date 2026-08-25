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

variable "vpcId" {
  type        = string
  description = "Lease-published by the vpc component."
  default     = ""
}

variable "vpcCidr" {
  type        = string
  description = "Lease-published by the vpc component."
  default     = "10.0.0.0/16"
}

variable "privateSubnetIds" {
  type        = string
  description = "Comma-separated, lease-published by the vpc component."
  default     = ""
}

variable "oidcProviderArn" {
  type        = string
  description = "Lease-published by the eks component."
  default     = ""
}

variable "oidcProviderUrl" {
  type        = string
  description = "Lease-published by the eks component."
  default     = ""
}

variable "nodeSecurityGroupId" {
  type        = string
  description = "Cluster security group, lease-published by the eks component. Data-store ingress is scoped to it."
  default     = ""
}

variable "k8sNamespace" {
  type        = string
  description = "Kubernetes namespace the service's ServiceAccount lives in."
  default     = "cumulus"
}

variable "documentsBucketArn" {
  type        = string
  description = "Unused today; declared so the gateway can be granted direct object reads if a future milestone streams downloads."
  default     = ""
}
