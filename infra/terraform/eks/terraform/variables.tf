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
  description = "VPC id, lease-published by the vpc component."
  default     = ""
}

variable "privateSubnetIds" {
  type        = string
  description = "Comma-separated private subnet ids, lease-published by the vpc component."
  default     = ""
}

variable "publicSubnetIds" {
  type        = string
  description = "Comma-separated public subnet ids, lease-published by the vpc component."
  default     = ""
}

variable "kubernetesVersion" {
  type        = string
  description = "EKS control-plane version."
  default     = "1.31"
}

variable "publicEndpointCidrs" {
  type        = string
  description = <<-EOT
    Comma-separated CIDRs allowed to reach the public API endpoint. Defaults to
    the empty string, which this root renders as "no public access" — a control
    plane open to 0.0.0.0/0 must be a decision someone typed, never a default
    they inherited.
  EOT
  default     = ""
}

variable "nodeInstanceTypes" {
  type        = string
  description = "Comma-separated instance types for the managed node group."
  default     = "t3.large,t3a.large"
}

variable "nodeCapacityType" {
  type        = string
  description = "ON_DEMAND or SPOT."
  default     = "ON_DEMAND"
}

variable "nodeDesiredSize" {
  type    = number
  default = 2
}

variable "nodeMinSize" {
  type    = number
  default = 2
}

variable "nodeMaxSize" {
  type    = number
  default = 6
}
