data "aws_ami" "telemetry" {
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.consul_ami]
  }

  owners = ["self"]
}

resource "aws_instance" "telemetry" {
  ami                         = data.aws_ami.telemetry.id
  instance_type               = var.telemetry_instance_type
  subnet_id                   = module.vpc.private_subnets[0]
  key_name                    = aws_key_pair.aws.key_name
  associate_public_ip_address = false
  ebs_optimized               = "true"

  iam_instance_profile = aws_iam_instance_profile.benchmark.id

  vpc_security_group_ids = [
    aws_security_group.telemetry.id,
  ]

  tags = {
    env   = var.env
    role  = "telemetry"
    owner = var.owner
    ttl   = var.ttl
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "50"
  }

  user_data = data.template_file.telemetry.rendered
}

data "template_file" "telemetry" {
  template = file("${path.module}/templates/telemetry.tpl")

  vars = {
    env = var.env
  }
}

resource "aws_lb_target_group_attachment" "grafana" {
  target_group_arn = aws_lb_target_group.grafana.arn
  target_id        = aws_instance.telemetry.id
  port             = 3000
}

