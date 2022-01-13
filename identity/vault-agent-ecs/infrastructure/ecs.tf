resource "aws_security_group" "ecs" {
  name        = "ecs-container-instances"
  description = "ECS security group"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "egress_ecs" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "https_client" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = aws_security_group.ecs.id
  description              = "Allow all TCP traffic between ECS container instances"
}


resource "aws_kms_key" "ecs" {
  description             = "${var.name}-ecs"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs" {
  name = var.name
}

resource "aws_ecs_cluster" "cluster" {
  name = var.name

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.ecs.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs.name
      }
    }
  }
}

data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}