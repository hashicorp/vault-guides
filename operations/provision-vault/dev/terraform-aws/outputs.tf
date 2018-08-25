output "zREADME" {
  value = <<README

Your "${var.name}" AWS Vault dev cluster has been
successfully provisioned!

${module.network_aws.zREADME}
To force the generation of a new key, the private key instance can be
"tainted" using the below command.

  $ terraform taint -module=ssh_keypair_aws_override.tls_private_key \
      tls_private_key.key

# ------------------------------------------------------------------------------
# External Cluster Access
# ------------------------------------------------------------------------------

If you'd like to interact with your cluster externally, use one of the below
options.

The `vault_public` variable must be set to true for any of these options to work.

`vault_public`: ${var.vault_public}

Below are the list of CIDRs that are whitelisted to have external access. This
list is populated from the "public_cidrs" variable merged with the external cidr
of the local workstation running Terraform for ease of use. If your CIDR does not
appear in the list, you can find it by googling "What is my ip" and add it to the
"public_cidrs" Terraform variable.

`public_cidrs`:
  ${join("\n  ", compact(concat(list(local.workstation_external_cidr), var.public_cidrs)))}

1.) Use Wetty (Web + tty), a web terminal for the cluster over HTTP and HTTPS

  Wetty Url: ${format("http://%s:3030/wetty", module.vault_aws.vault_lb_dns)}
  Wetty Username: wetty-${var.name}
  Wetty Password: ${element(concat(random_string.wetty_password.*.result, list("")), 0)}

2.) Set the below env var(s) and use Vault & Consul's CLI or HTTP API

  ${format("export VAULT_ADDR=https://%s:8200", module.vault_aws.vault_lb_dns)}
  ${format("export CONSUL_ADDR=http://%s:8500", module.vault_aws.vault_lb_dns)}
  ${format("export CONSUL_HTTP_ADDR=http://%s:8500", module.vault_aws.vault_lb_dns)}

# ------------------------------------------------------------------------------
# Vault Dev
# ------------------------------------------------------------------------------

${join("\n", compact(
  list(
    (__builtin_StringToFloat(replace(var.vault_version, ".", "")) >= 0100 || var.vault_url != "") ? format("Vault UI: http://%s %s", module.vault_aws.vault_lb_dns, var.vault_public ? "(Public)" : "(Internal)") : "",
    var.consul_install ? format("Consul UI: http://%s %s", module.vault_lb_aws.vault_lb_dns, var.vault_public ? "(Public)" : "(Internal)") : "",
  ),
))}

If public, you can SSH into the Vault node(s) directly through the LB.

  $ ${format("ssh -A -i %s %s@%s", module.ssh_keypair_aws_override.private_key_filename, module.vault_aws.vault_username, module.vault_aws.vault_lb_dns)}

${module.vault_aws.zREADME}
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

output "bastion_sg_id" {
  value = "${module.network_aws.bastion_sg_id}"
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
