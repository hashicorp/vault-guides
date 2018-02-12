output "zREADME" {
  value = <<README
Your "${var.name}" Vault cluster has been successfully provisioned!

A private RSA key has been generated and downloaded locally. The file permissions have been changed to 0600 so the key can be used immediately for SSH or scp.

Run the below command to add this private key to the list maintained by ssh-agent so you're not prompted for it when using SSH or scp to connect to hosts with your public key.

  ${join("\n  ", formatlist("ssh-add %s", module.ssh_keypair_aws.private_key_filename))}

The public part of the key loaded into the agent ("public_key_openssh" output) has been placed on the target system in ~/.ssh/authorized_keys.

To SSH into a Vault host using this private key, run the below command after replacing "HOST" with the public IP of one of the provisioned Vault hosts.

  ${join("\n  ", formatlist("ssh -A -i %s %s@HOST", module.ssh_keypair_aws.private_key_filename, module.vault_aws.vault_username))}

You can now interact with Vault using any of the CLI (https://www.vaultproject.io/docs/commands/index.html) or API (https://www.vaultproject.io/api/index.html) commands.

  # The Root token for your Vault -dev instance is set to `root` and the `VAULT_TOKEN` environment variable has already been set for you
  $ echo $VAULT_TOKEN

  # Use the CLI to write and read a generic secret
  $ vault write secret/cli bar=baz
  $ vault read secret/cli

  # Use the API to write and read a generic secret
  $ curl \
      -H "X-Vault-Token: $VAULT_TOKEN" \
      -X POST \
      -d '{"bar":"baz"}' \
      http://127.0.0.1:8200/v1/secret/api | jq '.'
  $ curl \
      -H "X-Vault-Token: $VAULT_TOKEN" \
      http://127.0.0.1:8200/v1/secret/api | jq '.'

Because this is a development environment, the Vault nodes are in a public subnet with SSH access open from the outside. WARNING - DO NOT DO THIS IN PRODUCTION!

Below are output variables that are currently commented out to reduce clutter. If you need the value of a certain output variable, such as "private_key_pem", just uncomment in outputs.tf.

 - "vpc_cidr_block"
 - "vpc_id"
 - "subnet_public_ids"
 - "subnet_private_ids"
 - "private_key_name"
 - "private_key_filename"
 - "private_key_pem"
 - "public_key_pem"
 - "public_key_openssh"
 - "ssh_key_name"
 - "vault_asg_id"
 - "vault_sg_id"
README
}

/*
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

output "vault_asg_id" {
  value = "${module.vault_aws.vault_asg_id}"
}

output "vault_sg_id" {
  value = "${module.vault_aws.vault_sg_id}"
}
*/
