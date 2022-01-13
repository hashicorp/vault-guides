resource "aws_efs_file_system" "mount" {
  creation_token = var.name
  encrypted      = true
  tags           = local.tags
}

resource "aws_efs_mount_target" "mount" {
  count           = length(var.private_subnets)
  file_system_id  = aws_efs_file_system.mount.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [var.ecs_security_group]
}