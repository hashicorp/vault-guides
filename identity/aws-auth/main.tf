terraform {
  required_version = ">= 0.11.0"
}

provider "aws" {}

module "security-base-vault" {
  source      = "./modules/security"
  name_prefix = "vault-server"
  owner_tag   = "${var.owner_tag}"
  ttl_tag     = "${var.ttl_tag}"
}

module "vault_config" {
  source                           = "./modules/templates/vault"
  aws_account_id                   = "${var.aws_account_id}"
  vault_instance_security_group_id = "${module.security-base-vault.security_group_id}"
}

module "vault" {
  source      = "./modules/ec2"
  name_prefix = "vault-server"

  #id_rsa_pub    = "${var.id_rsa_pub}"
  vpc_security_group_ids = ["${module.security-base-vault.security_group_id}"]
  owner_tag              = "${var.owner_tag}"
  ttl_tag                = "${var.ttl_tag}"
  ami_id                 = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  user_data              = "${module.vault_config.vault_user_data}"
}

module "security-base-consumer" {
  source      = "./modules/security"
  name_prefix = "vault-consumer"
  owner_tag   = "${var.owner_tag}"
  ttl_tag     = "${var.ttl_tag}"
}

module "consumer_config" {
  source     = "./modules/templates/consumer"
  vault_addr = "${module.vault.ip}"
}

module "consumer-ec2" {
  source      = "./modules/ec2"
  name_prefix = "vault-consumer"

  #id_rsa_pub    = "${var.id_rsa_pub}"
  vpc_security_group_ids = ["${module.security-base-consumer.security_group_id}"]
  owner_tag              = "${var.owner_tag}"
  ttl_tag                = "${var.ttl_tag}"
  ami_id                 = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  user_data              = "${module.consumer_config.user_data}"
}
