data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  subnets = cidrsubnets(var.vpc_cidr_block, 8, 8, 8, 8, 8, 8)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name            = var.name
  cidr            = var.vpc_cidr_block
  azs             = data.aws_availability_zones.available.names
  private_subnets = slice(local.subnets, 0, 2)
  public_subnets  = slice(local.subnets, 2, 4)

  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  enable_nat_gateway = true
  single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    key = "AmazonECSManaged"
  }

  private_subnet_tags = {
    key = "AmazonECSManaged"
  }
}