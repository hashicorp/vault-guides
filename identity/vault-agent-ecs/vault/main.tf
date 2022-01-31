terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.72"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = local.tags
  }
}

provider "vault" {}