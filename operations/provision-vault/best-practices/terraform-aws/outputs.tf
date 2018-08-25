output "zREADME" {
  value = <<README

Your "${var.name}" AWS Vault Best Practices cluster has been
successfully provisioned!

${module.network_aws.zREADME}
To force the generation of a new key, the private key instance can be "tainted"
using the below command.

  $ terraform taint -module=ssh_keypair_aws_override.tls_private_key \
      tls_private_key.key
${var.download_certs ?
"\n${module.root_tls_self_signed_ca.zREADME}
${module.leaf_tls_self_signed_cert.zREADME}" : ""}
# ------------------------------------------------------------------------------
# External Cluster Access
# ------------------------------------------------------------------------------

If you'd like to interact with your cluster externally, use one of the below
options.

The `vault_public` and `consul_public` variables must be set to true to
access the cluster(s) outside of the bastion host.

`vault_public`: ${var.vault_public}
`consul_public`: ${var.consul_public}

Below are the list of CIDRs that are whitelisted to have external access. This
list is populated from the 'public_cidrs' variable merged with the external cidr
of the local workstation running Terraform for ease of use. If your CIDR does not
appear in the list, you can find it by googling "What is my ip" and add it to the
'public_cidrs' Terraform variable.

`public_cidrs`:
  ${join("\n  ", compact(concat(list(local.workstation_external_cidr), var.public_cidrs)))}

1.) Use Wetty (Web + tty), a web terminal for the Bastion over HTTP and HTTPS

  ${join("\n  ", formatlist("%s Wetty Url: https://%s:3030/wetty", list("Bastion", "Vault"), list(element(concat(module.network_aws.bastion_ips_public, list("")), 0), module.vault_aws.vault_app_lb_dns)))}
  Wetty Username: wetty-${var.name}
  Wetty Password: ${element(concat(random_string.wetty_password.*.result, list("")), 0)}

2.) Set the below env var(s) and use Vault & Consul's CLI or HTTPS API

Ensure you have the certs locally by setting 'download_certs' (${var.download_certs}) to true.

  ${format("export VAULT_ADDR=https://%s:8200", module.vault_aws.vault_lb_dns)}
  ${format("export VAULT_CACERT=./", module.leaf_tls_self_signed_cert.ca_cert_filename)}
  ${format("export VAULT_CLIENT_CERT=./%s", module.leaf_tls_self_signed_cert.leaf_cert_filename)}
  ${format("export VAULT_CLIENT_KEY=./%s", module.leaf_tls_self_signed_cert.leaf_private_key_filename)}

  ${format("export CONSUL_ADDR=http://%s:8500", module.consul_aws.consul_lb_dns)}
  ${format("export CONSUL_HTTP_ADDR=http://%s:8500", module.consul_aws.consul_app_lb_dns)}
  ${format("export CONSUL_CACERT=./%s", module.leaf_tls_self_signed_cert.ca_cert_filename)}
  ${format("export CONSUL_CLIENT_CERT=./%s", module.leaf_tls_self_signed_cert.leaf_cert_filename)}
  ${format("export CONSUL_CLIENT_KEY=./%s", module.leaf_tls_self_signed_cert.leaf_private_key_filename)}

# ------------------------------------------------------------------------------
# Vault Best Practices
# ------------------------------------------------------------------------------

Once on the Bastion host, you can use Consul's DNS functionality to seamlessly
SSH into other Vault & Consul nodes if they exist.

  $ ssh -A ${module.consul_aws.consul_username}@consul.service.consul

  # Vault must be initialized & unsealed for this command to work
  $ ssh -A ${module.vault_aws.vault_username}@vault.service.consul

If public, you can SSH into the Vault & Consul nodes directly through the LB.

  $ ${format("ssh -A -i %s %s@%s", module.ssh_keypair_aws_override.private_key_filename, module.vault_aws.vault_username, module.vault_aws.vault_lb_dns)}
  $ ${format("ssh -A -i %s %s@%s", module.ssh_keypair_aws_override.private_key_filename, module.consul_aws.consul_username, module.consul_aws.consul_lb_dns)}

${module.vault_aws.zREADME}
${module.consul_aws.zREADME}
README
}

output "vpc_cidr" {
  value = "${module.network_aws.vpc_cidr}"
}

output "vpc_id" {
  value = "${module.network_aws.vpc_id}"
}

output "subnet_public_ids" {
  value = "${module.network_aws.subnet_public_ids}"
}

output "subnet_private_ids" {
  value = "${module.network_aws.subnet_private_ids}"
}

output "bastion_security_group" {
  value = "${module.network_aws.bastion_security_group}"
}

output "bastion_ips_public" {
  value = "${module.network_aws.bastion_ips_public}"
}

output "bastion_username" {
  value = "${module.network_aws.bastion_username}"
}

output "private_key_name" {
  value = "${module.ssh_keypair_aws_override.private_key_name}"
}

output "private_key_filename" {
  value = "${module.ssh_keypair_aws_override.private_key_filename}"
}

output "private_key_pem" {
  value = "${module.ssh_keypair_aws_override.private_key_pem}"
}

output "public_key_pem" {
  value = "${module.ssh_keypair_aws_override.public_key_pem}"
}

output "public_key_openssh" {
  value = "${module.ssh_keypair_aws_override.public_key_openssh}"
}

output "ssh_key_name" {
  value = "${module.ssh_keypair_aws_override.name}"
}

output "consul_asg_id" {
  value = "${module.consul_aws.consul_asg_id}"
}

output "consul_sg_id" {
  value = "${module.consul_aws.consul_sg_id}"
}

output "consul_app_lb_sg_id" {
  value = "${module.consul_aws.consul_app_lb_sg_id}"
}

output "consul_lb_arn" {
  value = "${module.consul_aws.consul_lb_arn}"
}

output "consul_app_lb_dns" {
  value = "${module.consul_aws.consul_app_lb_dns}"
}

output "consul_network_lb_dns" {
  value = "${module.consul_aws.consul_network_lb_dns}"
}

output "consul_tg_tcp_22_arn" {
  value = "${module.consul_aws.consul_tg_tcp_22_arn}"
}

output "consul_tg_tcp_8500_arn" {
  value = "${module.consul_aws.consul_tg_tcp_8500_arn}"
}

output "consul_tg_http_8500_arn" {
  value = "${module.consul_aws.consul_tg_http_8500_arn}"
}

output "consul_tg_tcp_8080_arn" {
  value = "${module.consul_aws.consul_tg_tcp_8080_arn}"
}

output "consul_tg_https_8080_arn" {
  value = "${module.consul_aws.consul_tg_https_8080_arn}"
}

output "consul_tg_http_3030_arn" {
  value = "${module.consul_aws.consul_tg_http_3030_arn}"
}

output "consul_tg_https_3030_arn" {
  value = "${module.consul_aws.consul_tg_https_3030_arn}"
}

output "vault_asg_id" {
  value = "${module.vault_aws.vault_asg_id}"
}

output "vault_sg_id" {
  value = "${module.vault_aws.vault_sg_id}"
}

output "vault_app_lb_sg_id" {
  value = "${module.vault_aws.vault_app_lb_sg_id}"
}

output "vault_lb_arn" {
  value = "${module.vault_aws.vault_lb_arn}"
}

output "vault_app_lb_dns" {
  value = "${module.vault_aws.vault_app_lb_dns}"
}

output "vault_network_lb_dns" {
  value = "${module.vault_aws.vault_network_lb_dns}"
}

output "vault_tg_tcp_22_arn" {
  value = "${module.vault_aws.vault_tg_tcp_22_arn}"
}

output "vault_tg_tcp_8200_arn" {
  value = "${module.vault_aws.vault_tg_tcp_8200_arn}"
}

output "vault_tg_http_8200_arn" {
  value = "${module.vault_aws.vault_tg_http_8200_arn}"
}

output "vault_tg_https_8200_arn" {
  value = "${module.vault_aws.vault_tg_https_8200_arn}"
}

output "vault_tg_http_3030_arn" {
  value = "${module.vault_aws.vault_tg_http_3030_arn}"
}

output "vault_tg_https_3030_arn" {
  value = "${module.vault_aws.vault_tg_https_3030_arn}"
}
