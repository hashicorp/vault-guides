output "zREADME" {
  value = <<README

Your "${var.name}" AWS Vault dev cluster has been
successfully provisioned!

${module.network_aws.zREADME}To force the generation of a new key, the private key instance can be
"tainted" using the below command.

  $ terraform taint -module=ssh_keypair_aws.tls_private_key \
      tls_private_key.key

# ------------------------------------------------------------------------------
# Local HTTP API Requests
# ------------------------------------------------------------------------------

If you're making HTTP API requests outside the Bastion (locally), set
the below env vars.

The `vault_public` variable must be set to true for requests to work.

`vault_public`: ${var.vault_public}

  ${format("$ export VAULT_ADDR=http://%s:8200", module.vault_aws.vault_lb_dns)}${var.consul_install ? format("\n  $ export CONSUL_ADDR=http://%s:8500", module.consul_lb_aws.consul_lb_dns) : ""}

# ------------------------------------------------------------------------------
# Vault Dev
# ------------------------------------------------------------------------------

${join("\n", compact(
  list(
    (__builtin_StringToFloat(replace(var.vault_version, ".", "")) >= 0100 || var.vault_url != "") ? format("Vault UI: http://%s %s", module.vault_aws.vault_lb_dns, var.vault_public ? "(Public)" : "(Internal)") : "",
    var.consul_install ? format("Consul UI: http://%s %s", module.consul_lb_aws.consul_lb_dns, var.vault_public ? "(Public)" : "(Internal)") : "",
  ),
))}

You can SSH into the Vault node by updating the "PUBLIC_IP" and running the
below command.

  $ ${format("ssh -A -i %s %s@%s", module.ssh_keypair_aws.private_key_filename, module.vault_aws.vault_username, "PUBLIC_IP")}

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

output "private_key_name" {
  value = "${module.ssh_keypair_aws.private_key_name}"
}

output "private_key_filename" {
  value = "${module.ssh_keypair_aws.private_key_filename}"
}

output "private_key_pem" {
  value = "${module.ssh_keypair_aws.private_key_pem}"
}

output "public_key_pem" {
  value = "${module.ssh_keypair_aws.public_key_pem}"
}

output "public_key_openssh" {
  value = "${module.ssh_keypair_aws.public_key_openssh}"
}

output "ssh_key_name" {
  value = "${module.ssh_keypair_aws.name}"
}

output "consul_lb_sg_id" {
  value = "${module.consul_lb_aws.consul_lb_sg_id}"
}

output "consul_tg_http_8500_arn" {
  value = "${module.consul_lb_aws.consul_tg_http_8500_arn}"
}

output "consul_lb_dns" {
  value = "${module.consul_lb_aws.consul_lb_dns}"
}

output "vault_asg_id" {
  value = "${module.vault_aws.vault_asg_id}"
}

output "vault_sg_id" {
  value = "${module.vault_aws.vault_sg_id}"
}

output "vault_lb_sg_id" {
  value = "${module.vault_aws.vault_lb_sg_id}"
}

output "vault_tg_http_8200_arn" {
  value = "${module.vault_aws.vault_tg_http_8200_arn}"
}

output "vault_lb_dns" {
  value = "${module.vault_aws.vault_lb_dns}"
}
