data "http" "workstation_external_ip" {
  url = "http://icanhazip.com"
}

locals {
  workstation_external_cidr = "${chomp(data.http.workstation_external_ip.body)}/32"
}

module "ssh_keypair_aws_override" {
  source = "github.com/hashicorp-modules/ssh-keypair-aws"

  create = "${var.create}"
  name   = "${var.name}-override"
}

module "consul_auto_join_instance_role" {
  source = "github.com/hashicorp-modules/consul-auto-join-instance-role-aws"

  create = "${var.create}"
  name   = "${var.name}"
}

resource "random_id" "consul_encrypt" {
  count = "${var.create ? 1 : 0}"

  byte_length = 16
}

resource "random_id" "vault_encrypt" {
  count = "${var.create ? 1 : 0}"

  byte_length = 16
}

module "root_tls_self_signed_ca" {
  source = "github.com/hashicorp-modules/tls-self-signed-cert"

  create            = "${var.create}"
  name              = "${var.name}-root"
  ca_common_name    = "${var.common_name}"
  organization_name = "${var.organization_name}"
  common_name       = "${var.common_name}"
  download_certs    = "${var.download_certs}"

  validity_period_hours = "8760"

  ca_allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

module "leaf_tls_self_signed_cert" {
  source = "github.com/hashicorp-modules/tls-self-signed-cert"

  create            = "${var.create}"
  name              = "${var.name}-leaf"
  organization_name = "${var.organization_name}"
  common_name       = "${var.common_name}"
  ca_override       = true
  ca_key_override   = "${module.root_tls_self_signed_ca.ca_private_key_pem}"
  ca_cert_override  = "${module.root_tls_self_signed_ca.ca_cert_pem}"
  download_certs    = "${var.download_certs}"

  validity_period_hours = "8760"

  dns_names = [
    "localhost",
    "*.node.consul",
    "*.service.consul",
    "server.dc1.consul",
    "*.dc1.consul",
    "server.${var.name}.consul",
    "*.${var.name}.consul",
  ]

  ip_addresses = [
    "0.0.0.0",
    "127.0.0.1",
  ]

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "random_string" "wetty_password" {
  count = "${var.create ? 1 : 0}"

  length           = 32
  special          = true
  override_special = "${var.override}"
}

data "template_file" "wetty_install" {
  template = "${file("${path.module}/../../templates/install-wetty.sh.tpl")}"

  vars = {
    wetty_user = "wetty-${var.name}"
    wetty_pass = "${element(concat(random_string.wetty_password.*.result, list("")), 0)}" # TODO: Workaround for issue #11210
  }
}

data "template_file" "bastion_best_practices" {
  template = "${file("${path.module}/../../templates/best-practices-bastion-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    ca_crt          = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt        = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key        = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt  = "${element(concat(random_id.consul_encrypt.*.b64_std, list("")), 0)}" # TODO: Workaround for issue #11210
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
  }
}

module "network_aws" {
  # source = "github.com/hashicorp-modules/network-aws"
  source = "../../../../../../hashicorp-modules/network-aws"

  create            = "${var.create}"
  name              = "${var.name}"
  vpc_cidr          = "${var.vpc_cidr}"
  vpc_cidrs_public  = "${var.vpc_cidrs_public}"
  nat_count         = "${var.nat_count}"
  vpc_cidrs_private = "${var.vpc_cidrs_private}"
  cidr_blocks       = "${split(",", var.consul_public ? join(",", compact(concat(list(local.workstation_external_cidr), var.public_cidrs, list(module.network_aws.vpc_cidr)))) : module.network_aws.vpc_cidr)}" # If there's a public IP, open Consul ports for public access - DO NOT DO THIS IN PROD
  release_version   = "${var.bastion_release}"
  consul_version    = "${var.bastion_consul_version}"
  vault_version     = "${var.bastion_vault_version}"
  os                = "${var.bastion_os}"
  os_version        = "${var.bastion_os_version}"
  bastion_count     = "${var.bastion_servers}"
  instance_profile  = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type     = "${var.bastion_instance}"
  image_id          = "${var.bastion_image_id}"
  ssh_key_name      = "${module.ssh_keypair_aws_override.name}"
  ssh_key_override  = true
  private_key_file  = "${module.ssh_keypair_aws_override.private_key_filename}"
  tags              = "${var.network_tags}"
  user_data         = <<EOF
${data.template_file.wetty_install.rendered} # Runtime install Wetty on Bastion
${data.template_file.bastion_best_practices.rendered} # Configure Bastion best practices
EOF
}

data "template_file" "consul_best_practices" {
  template = "${file("${path.module}/../../templates/best-practices-consul-systemd.sh.tpl")}"

  vars = {
    name             = "${var.name}"
    provider         = "${var.provider}"
    local_ip_url     = "${var.local_ip_url}"
    ca_crt           = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt         = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key         = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_bootstrap = "${length(module.network_aws.subnet_private_ids)}"
    consul_encrypt   = "${element(concat(random_id.consul_encrypt.*.b64_std, list("")), 0)}" # TODO: Workaround for issue #11210
    consul_override  = "${var.consul_client_config_override != "" ? true : false}"
    consul_config    = "${var.consul_client_config_override}"
  }
}

module "consul_aws" {
  # source = "github.com/hashicorp-modules/consul-aws"
  source = "../../../../../../hashicorp-modules/consul-aws"

  create           = "${var.create}"
  name             = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id           = "${module.network_aws.vpc_id}"
  vpc_cidr         = "${module.network_aws.vpc_cidr}"
  subnet_ids       = "${split(",", var.consul_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  release_version  = "${var.consul_release}"
  consul_version   = "${var.consul_version}"
  os               = "${var.consul_os}"
  os_version       = "${var.consul_os_version}"
  count            = "${var.consul_servers}"
  instance_profile = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type    = "${var.consul_instance}"
  image_id         = "${var.consul_image_id}"
  ssh_key_name     = "${module.ssh_keypair_aws_override.name}"
  lb_cidr_blocks   = "${split(",", var.consul_public ? join(",", compact(concat(list(local.workstation_external_cidr), var.public_cidrs, list(module.network_aws.vpc_cidr)))) : module.network_aws.vpc_cidr)}" # If there's a public IP, open Consul ports for public access - DO NOT DO THIS IN PROD
  lb_internal      = "${!var.consul_public}"
  lb_use_cert      = true
  lb_cert          = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
  lb_private_key   = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
  lb_cert_chain    = "${module.root_tls_self_signed_ca.ca_cert_pem}"
  tags             = "${var.consul_tags}"
  tags_list        = "${var.consul_tags_list}"
  user_data        = <<EOF
${data.template_file.wetty_install.rendered} # Runtime install Wetty
${data.template_file.consul_best_practices.rendered} # Configure Consul best practices
EOF
}

data "template_file" "vault_best_practices" {
  template = "${file("${path.module}/../../templates/best-practices-vault-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    ca_crt          = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt        = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key        = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt  = "${random_id.consul_encrypt.b64_std}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
    vault_encrypt   = "${random_id.vault_encrypt.b64_std}"
    vault_override  = "${var.vault_server_config_override != "" ? true : false}"
    vault_config    = "${var.vault_server_config_override}"
  }
}

module "vault_aws" {
  # source = "github.com/hashicorp-modules/vault-aws"
  source = "../../../../../../hashicorp-modules/vault-aws"

  create           = "${var.create}"
  name             = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id           = "${module.network_aws.vpc_id}"
  vpc_cidr         = "${module.network_aws.vpc_cidr}"
  subnet_ids       = "${split(",", var.vault_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  release_version  = "${var.vault_release}"
  vault_version    = "${var.vault_version}"
  consul_version   = "${var.consul_version}"
  os               = "${var.vault_os}"
  os_version       = "${var.vault_os_version}"
  count            = "${var.vault_servers}"
  instance_profile = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type    = "${var.vault_instance}"
  image_id         = "${var.vault_image_id}"
  ssh_key_name     = "${module.ssh_keypair_aws_override.name}"
  lb_cidr_blocks   = "${split(",", var.vault_public ? join(",", compact(concat(list(local.workstation_external_cidr), var.public_cidrs, list(module.network_aws.vpc_cidr)))) : module.network_aws.vpc_cidr)}" # If there's a public IP, open Vault ports for public access - DO NOT DO THIS IN PROD
  lb_internal      = "${!var.vault_public}"
  lb_use_cert      = true
  lb_cert          = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
  lb_private_key   = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
  lb_cert_chain    = "${module.root_tls_self_signed_ca.ca_cert_pem}"
  tags             = "${var.vault_tags}"
  tags_list        = "${var.vault_tags_list}"
  user_data        = <<EOF
${data.template_file.wetty_install.rendered} # Runtime install Wetty
${data.template_file.vault_best_practices.rendered} # Configure Vault best practices
EOF
}
