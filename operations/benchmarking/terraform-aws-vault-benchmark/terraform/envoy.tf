data "aws_ami" "envoy" {
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.consul_ami]
  }

  owners = ["self"]
}

resource "aws_instance" "envoy" {
  ami                         = data.aws_ami.envoy.id
  instance_type               = var.envoy_instance_type
  subnet_id                   = module.vpc.private_subnets[0]
  key_name                    = aws_key_pair.aws.key_name
  associate_public_ip_address = false
  ebs_optimized               = "true"
  iam_instance_profile        = aws_iam_instance_profile.benchmark.id
  private_ip                  = "10.0.1.20"

  vpc_security_group_ids = [
    aws_security_group.envoy.id,
  ]

  tags = {
    env   = var.env
    role  = "envoy"
    owner = var.owner
    ttl   = var.ttl
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "50"
  }

  user_data = data.template_file.envoy_tpl.rendered
}

data "template_file" "envoy_config" {
  template = file("${path.module}/../envoy/envoy.yaml")
}

data "template_file" "envoy_tpl" {
  template = file("${path.module}/templates/envoy.tpl")

  vars = {
    env   = var.env
    cert  = tls_locally_signed_cert.envoy.cert_pem
    key   = tls_private_key.envoy.private_key_pem
    ca    = tls_self_signed_cert.root.cert_pem
    envoy = data.template_file.envoy_config.rendered
  }
}

resource "aws_lb_target_group_attachment" "envoy_http" {
  target_group_arn = aws_lb_target_group.envoy_http.arn
  target_id        = aws_instance.envoy.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "envoy_https" {
  target_group_arn = aws_lb_target_group.envoy_https.arn
  target_id        = aws_instance.envoy.id
  port             = 8443
}

