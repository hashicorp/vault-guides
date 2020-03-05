module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  name               = random_id.environment_name.hex
  cidr               = "10.0.0.0/16"
  azs                = var.azs
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = true
  enable_vpn_gateway = false
  tags = {
    owner = var.owner
    TTL   = var.ttl
  }
}

