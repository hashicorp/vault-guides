data "http" "workstation_external_ip" {
  url = "http://icanhazip.com"
}

locals {
  workstation_external_cidr = "${chomp(data.http.workstation_external_ip.body)}/32"
}

data "aws_ami" "base" {
  most_recent = true
  owners      = ["${var.ami_owner}"]

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "base_install" {
  template = "${file("${path.module}/../../templates/install-base.sh.tpl")}"
}

data "template_file" "consul_install" {
  template = "${file("${path.module}/../../templates/install-consul-systemd.sh.tpl")}"

  vars = {
    consul_version  = "${var.consul_version}"
    consul_url      = "${var.consul_url}"
    name            = "${var.name}"
    local_ip_url    = "${var.local_ip_url}"
    consul_override = false
    consul_config   = ""
  }
}

data "template_file" "vault_install" {
  template = "${file("${path.module}/../../templates/install-vault-systemd.sh.tpl")}"

  vars = {
    vault_version  = "${var.vault_version}"
    vault_url      = "${var.vault_url}"
    name           = "${var.name}"
    local_ip_url   = "${var.local_ip_url}"
    vault_override = false
    vault_config   = ""
  }
}

data "template_file" "bastion_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-bastion-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
  }
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
  bastion_count     = "${var.bastion_servers}"
  instance_type     = "${var.bastion_instance}"
  os                = "${replace(lower(var.ami_name), "ubuntu", "") != lower(var.ami_name) ? "Ubuntu" : replace(lower(var.ami_name), "rhel", "") != lower(var.ami_name) ? "RHEL" : "unknown"}"
  image_id          = "${var.bastion_image_id != "" ? var.bastion_image_id : data.aws_ami.base.id}"
  tags              = "${var.network_tags}"
  user_data         = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.vault_install.rendered} # Runtime install Vault in -dev mode
${data.template_file.bastion_quick_start.rendered} # Configure Bastion quick start
${data.template_file.wetty_install.rendered} # Runtime install Wetty on Bastion
EOF
}

data "template_file" "consul_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-consul-systemd.sh.tpl")}"

  vars = {
    name             = "${var.name}"
    provider         = "${var.provider}"
    local_ip_url     = "${var.local_ip_url}"
    consul_bootstrap = "${var.consul_servers != -1 ? var.consul_servers : length(module.network_aws.subnet_private_ids)}"
    consul_override  = "${var.consul_server_config_override != "" ? true : false}"
    consul_config    = "${var.consul_server_config_override}"
  }
}

module "consul_aws" {
  # source = "github.com/hashicorp-modules/consul-aws"
  source = "../../../../../../hashicorp-modules/consul-aws"

  create         = "${var.create}"
  name           = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id         = "${module.network_aws.vpc_id}"
  vpc_cidr       = "${module.network_aws.vpc_cidr}"
  subnet_ids     = "${split(",", var.consul_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  count          = "${var.consul_servers}"
  instance_type  = "${var.consul_instance}"
  os             = "${replace(lower(var.ami_name), "ubuntu", "") != lower(var.ami_name) ? "Ubuntu" : replace(lower(var.ami_name), "rhel", "") != lower(var.ami_name) ? "RHEL" : "unknown"}"
  image_id       = "${var.consul_image_id != "" ? var.consul_image_id : data.aws_ami.base.id}"
  ssh_key_name   = "${module.network_aws.ssh_key_name}"
  lb_cidr_blocks = "${split(",", var.consul_public ? join(",", compact(concat(list(local.workstation_external_cidr), var.public_cidrs, list(module.network_aws.vpc_cidr)))) : module.network_aws.vpc_cidr)}" # If there's a public IP, open Consul ports for public access - DO NOT DO THIS IN PROD
  lb_internal    = "${!var.consul_public}"
  tags           = "${var.consul_tags}"
  tags_list      = "${var.consul_tags_list}"
  user_data      = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.consul_quick_start.rendered} # Configure Consul quick start
${data.template_file.wetty_install.rendered} # Runtime install Wetty
EOF
}

data "template_file" "vault_quick_start" {
  template = "${file("${path.module}/../../templates/quick-start-vault-systemd.sh.tpl")}"

  vars = {
    name            = "${var.name}"
    provider        = "${var.provider}"
    local_ip_url    = "${var.local_ip_url}"
    consul_override = "${var.consul_client_config_override != "" ? true : false}"
    consul_config   = "${var.consul_client_config_override}"
    vault_override  = "${var.vault_server_config_override != "" ? true : false}"
    vault_config    = "${var.vault_server_config_override}"
  }
}

module "vault_aws" {
  # source = "github.com/hashicorp-modules/vault-aws"
  source = "../../../../../../hashicorp-modules/vault-aws"

  create         = "${var.create}"
  name           = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id         = "${module.network_aws.vpc_id}"
  vpc_cidr       = "${module.network_aws.vpc_cidr}"
  subnet_ids     = "${split(",", var.vault_public ? join(",", module.network_aws.subnet_public_ids) : join(",", module.network_aws.subnet_private_ids))}"
  count          = "${var.vault_servers}"
  instance_type  = "${var.vault_instance}"
  os             = "${replace(lower(var.ami_name), "ubuntu", "") != lower(var.ami_name) ? "Ubuntu" : replace(lower(var.ami_name), "rhel", "") != lower(var.ami_name) ? "RHEL" : "unknown"}"
  image_id       = "${var.vault_image_id != "" ? var.vault_image_id : data.aws_ami.base.id}"
  ssh_key_name   = "${module.network_aws.ssh_key_name}"
  lb_cidr_blocks = "${split(",", var.vault_public ? join(",", compact(concat(list(local.workstation_external_cidr), var.public_cidrs, list(module.network_aws.vpc_cidr)))) : module.network_aws.vpc_cidr)}" # If there's a public IP, open Vault ports for public access - DO NOT DO THIS IN PROD
  lb_internal    = "${!var.vault_public}"
  tags           = "${var.vault_tags}"
  tags_list      = "${var.vault_tags_list}"
  user_data      = <<EOF
${data.template_file.base_install.rendered} # Runtime install base tools
${data.template_file.consul_install.rendered} # Runtime install Consul in -dev mode
${data.template_file.vault_install.rendered} # Runtime install Vault in -dev mode
${data.template_file.vault_quick_start.rendered} # Configure Vault quick start
${data.template_file.wetty_install.rendered} # Runtime install Wetty
EOF
}
