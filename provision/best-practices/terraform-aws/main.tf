module "ssh_keypair_aws_override" {
  source = "git@github.com:hashicorp-modules/ssh-keypair-aws.git?ref=f-refactor"

  name = "${var.name}-override"
}

module "consul_auto_join_instance_role" {
  source = "git@github.com:hashicorp-modules/consul-auto-join-instance-role-aws?ref=f-refactor"

  name = "${var.name}"
}

resource "random_id" "serf_encrypt" {
  byte_length = 16
}

module "consul_tls_self_signed_cert" {
  source = "git@github.com:hashicorp-modules/tls-self-signed-cert.git?ref=f-refactor"

  name                  = "${var.name}-consul"
  validity_period_hours = "24"
  ca_common_name        = "hashicorp.com"
  organization_name     = "HashiCorp Inc."
  common_name           = "hashicorp.com"
  dns_names             = ["*.node.consul", "*.service.consul"]
  ip_addresses          = ["0.0.0.0", "127.0.0.1"]
}

module "vault_tls_self_signed_cert" {
  source = "git@github.com:hashicorp-modules/tls-self-signed-cert.git?ref=f-refactor"

  name                  = "${var.name}-vault"
  validity_period_hours = "24"
  ca_common_name        = "hashicorp.com"
  organization_name     = "HashiCorp Inc."
  common_name           = "hashicorp.com"
  dns_names             = ["*.node.consul", "*.service.consul"]
  ip_addresses          = ["0.0.0.0", "127.0.0.1"]
}

data "template_file" "bastion_user_data" {
  template = "${file("${path.module}/../../templates/best-practices-bastion-systemd.sh.tpl")}"

  vars = {
    name           = "${var.name}"
    provider       = "${var.provider}"
    local_ip_url   = "${var.local_ip_url}"
    serf_encrypt   = "${random_id.serf_encrypt.b64_std}"
    consul_crt_pem = "${module.consul_tls_self_signed_cert.leaf_pem}"
    consul_key_pem = "${module.consul_tls_private_key.private_key_pem}"
    vault_crt_pem  = "${module.vault_tls_self_signed_cert.leaf_pem}"
  }
}

module "network_aws" {
  source = "git@github.com:hashicorp-modules/network-aws.git?ref=f-refactor"

  name              = "${var.name}"
  vpc_cidr          = "${var.vpc_cidr}"
  vpc_cidrs_public  = "${var.vpc_cidrs_public}"
  nat_count         = "${var.nat_count}"
  vpc_cidrs_private = "${var.vpc_cidrs_private}"
  release_version   = "${var.bastion_release_version}"
  consul_version    = "${var.bastion_consul_version}"
  vault_version     = "${var.bastion_vault_version}"
  nomad_version     = "${var.bastion_nomad_version}"
  os                = "${var.bastion_os}"
  os_version        = "${var.bastion_os_version}"
  bastion_count     = "${var.bastion_count}"
  instance_profile  = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type     = "${var.bastion_instance_type}"
  user_data         = "${data.template_file.bastion_user_data.rendered}" # Override user_data
  ssh_key_name      = "${module.ssh_keypair_aws_override.name}"
}

data "template_file" "consul_user_data" {
  template = "${file("${path.module}/../../templates/best-practices-consul-systemd.sh.tpl")}"

  vars = {
    name             = "${var.name}"
    provider         = "${var.provider}"
    local_ip_url     = "${var.local_ip_url}"
    bootstrap_expect = "${length(module.network_aws.subnet_private_ids)}"
    serf_encrypt     = "${random_id.serf_encrypt.b64_std}"
    consul_crt_pem   = "${module.consul_tls_self_signed_cert.leaf_pem}"
    consul_key_pem   = "${module.consul_tls_private_key.private_key_pem}"
  }
}

module "consul_aws" {
  source = "git@github.com:hashicorp-modules/consul-aws.git?ref=f-refactor"

  name             = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id           = "${module.network_aws.vpc_id}"
  vpc_cidr         = "${module.network_aws.vpc_cidr_block}"
  subnet_ids       = "${module.network_aws.subnet_private_ids}"
  release_version  = "${var.consul_release_version}"
  consul_version   = "${var.consul_version}"
  os               = "${var.consul_os}"
  os_version       = "${var.consul_os_version}"
  count            = "${var.consul_count}"
  instance_profile = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type    = "${var.consul_instance_type}"
  user_data        = "${data.template_file.consul_user_data.rendered}" # Custom user_data
  ssh_key_name     = "${module.network_aws.ssh_key_name}"
}

data "template_file" "vault_user_data" {
  template = "${file("${path.module}/../../templates/best-practices-vault-systemd.sh.tpl")}"

  vars = {
    name           = "${var.name}"
    provider       = "${var.provider}"
    local_ip_url   = "${var.local_ip_url}"
    consul_crt_pem = "${module.consul_tls_self_signed_cert.leaf_pem}"
    consul_key_pem = "${module.consul_tls_private_key.private_key_pem}"
    serf_encrypt   = "${random_id.serf_encrypt.b64_std}"
    vault_crt_pem  = "${module.vault_tls_self_signed_cert.leaf_pem}"
    vault_key_pem  = "${module.vault_tls_private_key.private_key_pem}"
  }
}

module "vault_aws" {
  source = "git@github.com:hashicorp-modules/vault-aws.git?ref=f-refactor"

  name             = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id           = "${module.network_aws.vpc_id}"
  vpc_cidr         = "${module.network_aws.vpc_cidr_block}"
  subnet_ids       = "${module.network_aws.subnet_private_ids}"
  release_version  = "${var.vault_release_version}"
  vault_version    = "${var.vault_version}"
  os               = "${var.vault_os}"
  os_version       = "${var.vault_os_version}"
  count            = "${var.vault_count}"
  instance_profile = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type    = "${var.vault_instance_type}"
  user_data        = "${data.template_file.vault_user_data.rendered}" # Custom user_data
  ssh_key_name     = "${module.network_aws.ssh_key_name}"
}
