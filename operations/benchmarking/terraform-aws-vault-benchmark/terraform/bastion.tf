data "aws_ami" "bastion" {
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.consul_ami]
  }

  owners = ["self"]
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.bastion.id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = aws_key_pair.aws.key_name
  associate_public_ip_address = true
  ebs_optimized               = false
  iam_instance_profile        = aws_iam_instance_profile.benchmark.id

  vpc_security_group_ids = [
    aws_security_group.bastion.id,
  ]

  tags = {
    env   = var.env
    role  = "bastion"
    owner = var.owner
    ttl   = var.ttl
  }

  user_data = data.template_file.bastion.rendered
}

data "template_file" "bastion" {
  template = file("${path.module}/templates/bastion.tpl")

  vars = {
    env = var.env
  }
}

