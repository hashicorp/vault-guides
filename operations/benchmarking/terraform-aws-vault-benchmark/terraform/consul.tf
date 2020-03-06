data "aws_ami" "consul" {
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.consul_ami]
  }

  owners = ["self"]
}

resource "aws_instance" "consul" {
  count                       = var.consul_cluster_size
  ami                         = data.aws_ami.consul.id
  instance_type               = var.consul_instance_type
  subnet_id                   = element(module.vpc.private_subnets, count.index)
  key_name                    = aws_key_pair.aws.key_name
  associate_public_ip_address = false
  ebs_optimized               = "true"
  iam_instance_profile        = aws_iam_instance_profile.benchmark.id

  vpc_security_group_ids = [
    aws_security_group.consul.id,
  ]

  tags = {
    env   = var.env
    role  = "consul"
    owner = var.owner
    TTL   = var.ttl
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "50"
  }

  /*
  root_block_device {
    volume_type = "io1"
    volume_size = "50"
    iops        = "3000"
  }
  */

  user_data = data.template_file.consul.rendered
}

data "template_file" "consul" {
  template = file("${path.module}/templates/consul.tpl")

  vars = {
    env = var.env
  }
}

