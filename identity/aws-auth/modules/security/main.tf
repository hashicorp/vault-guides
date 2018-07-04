terraform {
  required_version = ">= 0.11.0"
}

provider "aws" {
  region = "${var.aws_region}"
}

# Security group to manage ingress and egress access
resource "aws_security_group" "lc_security_group" {
  name_prefix = "vault-demo-sg-${var.name_prefix}"
  description = "Security group for the Vault demo launch configuration"

  tags {
    Name  = "vault-demo-sg-${var.name_prefix}"
    Owner = "${var.owner_tag}"
    TTL   = "${var.ttl_tag}"
  }
}

resource "aws_security_group_rule" "allow_ssh_inbound_from_cidr_blocks" {
  count       = "${length(var.allowed_ssh_cidr_blocks) >= 1 ? 1 : 0}"
  type        = "ingress"
  from_port   = "${var.ssh_port}"
  to_port     = "${var.ssh_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_ssh_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

# This rule is only needed for the Vault Server
# TODO: place as separate logic
resource "aws_security_group_rule" "allow_vault_inbound_from_cidr_blocks" {
  count       = "${length(var.allowed_vault_cidr_blocks) >= 1 ? 1 : 0}"
  type        = "ingress"
  from_port   = "${var.vault_listening_port}"
  to_port     = "${var.vault_listening_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_vault_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

# TODO: to allow access per security group id
#resource "aws_security_group_rule" "allow_vault_inbound_from_sg_id" {
#  count                    = "${length(var.vault_listening_port) >= 1 ? 1 : 0}"
#  type                     = "ingress"
#  from_port                = "${var.vault_listening_port}"
#  to_port                  = "${var.vault_listening_port}"
#  protocol                 = "tcp"
#  source_security_group_id = "${element(var.allowed_ssh_security_group_ids, count.index)}"


#  security_group_id = "${aws_security_group.lc_security_group.id}"
#}

