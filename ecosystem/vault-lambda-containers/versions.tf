
terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source = "aws"
      version = "~> 3.6.0"
    }
  }
}
