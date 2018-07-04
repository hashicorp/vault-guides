terraform {
  required_version = ">= 0.11.0"
}

provider "aws" {}

/**
Provided as an example if key creation is needed (check README.md)
 resource "aws_key_pair" "vault-demo-ssh" {
   key_name   = "vault-demo-ssh"
   public_key = "${var.id_rsa_pub}"
}
*/

resource "aws_instance" "ubuntu" {
  ami                    = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  key_name               = "stenio-aws"
  vpc_security_group_ids = "${var.vpc_security_group_ids}"
  user_data              = "${var.user_data}"
  iam_instance_profile   = "${var.iam_instance_profile_name}"

  tags {
    Name  = "vault-demo-${var.name_prefix}"
    Owner = "${var.owner_tag}"
    TTL   = "${var.ttl_tag}"
  }
}
