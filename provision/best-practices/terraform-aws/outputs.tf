output "zREADME" {
  value = <<README
Your AWS Consul cluster has been successfully provisioned!

A private RSA key named "${module.ssh_keypair_aws_override.private_key_filename}" has been generated and downloaded locally. The file permissions have been changed to 0600 so the key can be used immediately for SSH or scp.

Run the below command to add this private key to the list maintained by ssh-agent so you're not prompted for it when using SSH or scp to connect to hosts with your public key.

  ssh-add ${module.ssh_keypair_aws_override.private_key_filename}

The public part of the key loaded into the agent ("public_key_openssh" output) has been placed on the target system in ~/.ssh/authorized_keys.

To SSH into a Bastion host using this private key, run one of the below commands.

  ${join("\n  ", formatlist("ssh -A -i %s %s@%s", module.ssh_keypair_aws_override.private_key_filename, module.network_aws.bastion_username, module.network_aws.bastion_ips_public))}

Once on the Bastion host, you can use Consul's DNS functionality to seemlessly SSH into other Consul nodes.

  ssh -A ${module.consul_aws.consul_username}@consul.service.consul

You'll have to SSH into one of the Vault nodes for the first time using the static IP found in `consul members` as Vault is not initialized and won't be considered a healthy service within Consul. However, once initialized, you can SSH into Vault using Consul's DNS functionality as well.

  ssh -A ${module.vault_aws.vault_username}@vault.service.consul # Vault must be initialized for this to work

To force the generation of a new key, the private key instance can be "tainted" using the below command.

  terraform taint -module=ssh_keypair_aws_override.tls_private_key tls_private_key.main
README
}

output "vpc_cidr_block" {
  value = "${module.network_aws.vpc_cidr_block}"
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

output "vault_asg_id" {
  value = "${module.vault_aws.vault_asg_id}"
}

output "vault_sg_id" {
  value = "${module.vault_aws.vault_sg_id}"
}
