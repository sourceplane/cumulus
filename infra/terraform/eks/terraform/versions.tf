terraform {
  # Exact, not a range: a floating version makes a green lane unreproducible.
  required_version = "~> 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # State lives on the Orun Cloud HTTP backend. The runner exports TF_HTTP_*
  # per job (address = .../state/tfstate/{component}/{env}, run token as
  # password), so this block needs no -backend-config and no AWS credential of
  # its own. The environment is IN the address — there are no workspaces, and
  # there is no state bucket to bootstrap before the first apply.
  #
  # The `validate` lane runs `init -backend=false` and never reaches this.
  backend "http" {}
}

provider "aws" {
  region = var.awsRegion

  default_tags {
    tags = {
      "cumulus.io/component"   = var.component
      "cumulus.io/environment" = var.environment
      "cumulus.io/managed-by"  = "orun"
      "cumulus.io/repo"        = "${var.owner}/${var.repo}"
    }
  }
}

# tls is used only to read the OIDC issuer's certificate thumbprint.
provider "tls" {}
