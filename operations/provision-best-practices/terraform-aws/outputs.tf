output "zREADME" {
  value = <<README
Your "${var.name}" Vault cluster has been successfully provisioned!

A private RSA key has been generated and downloaded locally. The file permissions have been changed to 0600 so the key can be used immediately for SSH or scp.

Run the below command to add this private key to the list maintained by ssh-agent so you're not prompted for it when using SSH or scp to connect to hosts with your public key.

  ${join("\n  ", formatlist("$ ssh-add %s", module.ssh_keypair_aws_override.private_key_filename))}

The public part of the key loaded into the agent ("public_key_openssh" output) has been placed on the target system in ~/.ssh/authorized_keys.

To SSH into a Bastion host using this private key, run one of the below commands.

  ${join("\n  ", formatlist("$ ssh -A -i %s %s@%s", module.ssh_keypair_aws_override.private_key_filename, module.network_aws.bastion_username, module.network_aws.bastion_ips_public))}

You won't be able to start interacting with Vault from the Bastion host yet as the Vault server has not been initialized & unsealed. Follow the below steps to set this up.

1.) SSH into one of the Vault servers registered with Consul, you can use the below command to accomplish this automatically (we'll use Consul DNS moving forward once Vault is unsealed)

  $ ssh -A ${module.vault_aws.vault_username}@$(curl http://127.0.0.1:8500/v1/agent/members | jq -M -r '[.[] | select(.Name | contains ("${var.name}-vault")) | .Addr][0]')

2.) Initialize Vault

  $ vault init

3.) Unseal Vault using the "Unseal Keys" output from the `vault init` command and check the seal status

  $ vault unseal <unsealkey1>
  $ vault unseal <unsealkey2>
  $ vault unseal <unsealkey3>
  $ vault status

Repeat steps 1.) and 3.) to unseal the other "standby" Vault servers as well to achieve high availablity.

4.) Logout of the Vault server (ctrl+d) and check Vault's seal status from the Bastion host to verify you can interact with the Vault cluster from the Bastion host Vault CLI

  $ vault status

5.) You can now interact with Vault using any of the CLI (https://www.vaultproject.io/docs/commands/index.html) or API (https://www.vaultproject.io/api/index.html) commands from your Bastion host

  # Set your Vault token to authenticate requests, to start we can use the "Root Token" that was output from the `vault init` command above
  $ export VAULT_TOKEN=<roottoken>

  # Use Vault's CLI to write and read a generic secret
  $ vault write secret/cli foo=bar
  $ vault read secret/cli

  # Use Vault's API with Consul DNS to write and read a generic secret
  $ curl \
      -H "X-Vault-Token: $VAULT_TOKEN" \
      -X POST \
      -d '{"foo":"bar"}' \
      -k --cacert /opt/vault/tls/ca.crt --cert /opt/vault/tls/vault.crt --key /opt/vault/tls/vault.key \
      https://vault.service.consul:8200/v1/secret/api | jq '.'
  $ curl \
      -H "X-Vault-Token: $VAULT_TOKEN" \
      -k --cacert /opt/vault/tls/ca.crt --cert /opt/vault/tls/vault.crt --key /opt/vault/tls/vault.key \
      https://vault.service.consul:8200/v1/secret/api | jq '.'

Now that Vault is unsealed, you can seemlessly SSH back into unsealed Vault servers using Consul DNS (rather than using the command in Step 1). The nodes returned will be both active and standby Vault servers as long as they're unsealed.

  $ ssh -A ${module.vault_aws.vault_username}@vault.service.consul

To SSH into Consul server nodes, you can also leverage Consul's DNS functionality.

  $ ssh -A ${module.consul_aws.consul_username}@consul.service.consul

To force the generation of a new key, the private key instance can be "tainted" using the below command.

  terraform taint -module=ssh_keypair_aws_override.tls_private_key tls_private_key.key

Below are output variables that are currently commented out to reduce clutter. If you need the value of a certain output variable, such as "private_key_pem", just uncomment in outputs.tf.

 - "vpc_cidr_block"
 - "vpc_id"
 - "subnet_public_ids"
 - "subnet_private_ids"
 - "bastion_security_group"
 - "bastion_ips_public"
 - "bastion_username"
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
*/
