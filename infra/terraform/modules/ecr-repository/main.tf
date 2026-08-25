# One ECR repository per service.

terraform {
  required_version = "~> 1.15.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
  }
}

variable "name" {
  type = string
}

variable "untagged_expiry_days" {
  type    = number
  default = 7
}

variable "keep_last" {
  type    = number
  default = 30
}

resource "aws_ecr_repository" "this" {
  name = var.name

  # IMMUTABLE is the setting that makes a digest-addressed deploy meaningful. If
  # a tag can be moved, "we deployed v1.2.3" stops being a statement about which
  # bytes are running.
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expiry_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep a bounded history of tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_last
        }
        action = { type = "expire" }
      },
    ]
  })
}

output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "registry_id" {
  value = aws_ecr_repository.this.registry_id
}
