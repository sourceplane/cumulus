# Consumed downstream through secretEnv, not through terraform_remote_state.
# The component declares which of these are published; see component.yaml's
# secretOutputs.

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC id."
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "VPC CIDR, for security-group rules in dependent roots."
}

output "private_subnet_ids" {
  value       = join(",", aws_subnet.private[*].id)
  description = "Comma-separated private subnet ids. Joined because outputs cross the wire as strings."
}

output "public_subnet_ids" {
  value       = join(",", aws_subnet.public[*].id)
  description = "Comma-separated public subnet ids."
}

output "availability_zones" {
  value       = join(",", local.azs)
  description = "Comma-separated AZs the VPC spans."
}
