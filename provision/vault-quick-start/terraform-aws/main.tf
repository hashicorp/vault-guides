data "template_file" "bastion_user_data" {
  template = "${file("${path.module}/../templates/bastion-init-systemd.sh.tpl")}"

  vars = {
    name         = "${var.name}"
    vault_config = <<SCRIPT
echo "Configure Vault CLI to point to remote Vault cluster"
sudo sed -i '1s/$/ -address="http:\/\/vault.service.consul:8200"/' /etc/vault.d/vault.conf

echo "Configure VAULT_ADDR environment variable to point Vault server to remote Vault cluster"
echo 'export VAULT_ADDR="http://vault.service.consul:8200"' | sudo tee /etc/profile.d/vault.sh

echo "Stop Vault now that the CLI is pointing to a live Vault cluster"
systemctl stop vault
SCRIPT
  }
}

module "network_aws" {
  source = "../../../network-aws"
  # source = "git@github.com:hashicorp-modules/network-aws.git?ref=f-refactor"

  name          = "${var.name}"
  nat_count     = "1"
  bastion_count = "1"
  user_data     = "${data.template_file.bastion_user_data.rendered}" # Override user_data
}

data "template_file" "consul_user_data" {
  template = "${file("${path.module}/../templates/consul-init-systemd.sh.tpl")}"

  vars = {
    name             = "${var.name}"
    bootstrap_expect = "${length(module.network_aws.subnet_private_ids)}"
  }
}

module "consul_aws" {
  source = "../../../consul-aws"
  # source = "git@github.com:hashicorp-modules/network-aws.git?ref=f-refactor"

  name         = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id       = "${module.network_aws.vpc_id}"
  vpc_cidr     = "${module.network_aws.vpc_cidr_block}"
  subnet_ids   = "${module.network_aws.subnet_private_ids}"
  user_data    = "${data.template_file.consul_user_data.rendered}" # Custom user_data
  ssh_key_name = "${module.network_aws.ssh_key_name}"
}

data "template_file" "vault_user_data" {
  template = "${file("${path.module}/../templates/vault-init-systemd.sh.tpl")}"

  vars = {
    name         = "${var.name}"
    vault_config = <<SCRIPT
echo "Configure Vault server"
cat <<EOF >/etc/vault.d/vault-server.hcl
# Configure Vault server with TLS disabled and the Consul storage backend: https://www.vaultproject.io/docs/configuration/storage/consul.html
backend "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
EOF

echo "Update Vault configuration file permissions"
chown -R vault:vault /etc/vault.d
chmod -R 0644 /etc/vault.d/*

echo "Don't start Vault in -dev mode"
echo '' | sudo tee /etc/vault.d/vault.conf

echo "Restart Vault"
systemctl restart vault
SCRIPT
  }
}

module "vault_aws" {
  source = "../../../vault-aws"
  # source = "git@github.com:hashicorp-modules/network-aws.git?ref=f-refactor"

  name         = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id       = "${module.network_aws.vpc_id}"
  vpc_cidr     = "${module.network_aws.vpc_cidr_block}"
  subnet_ids   = "${module.network_aws.subnet_private_ids}"
  user_data    = "${data.template_file.vault_user_data.rendered}" # Custom user_data
  ssh_key_name = "${module.network_aws.ssh_key_name}"
}
