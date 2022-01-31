module "efs" {
  source             = "../modules/vault-mount"
  name               = var.name
  private_subnets    = module.vpc.private_subnets
  ecs_security_group = aws_security_group.ecs.id
}

resource "aws_efs_access_point" "product_api" {
  file_system_id = module.efs.file_system_id
}