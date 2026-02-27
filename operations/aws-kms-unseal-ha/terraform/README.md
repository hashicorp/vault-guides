# Vault Autounseal using AWS KMS

In this guide, we'll show an example of how to use Terraform to provision a cluster that can utilize an encryption key from AWS Key Management Services to unseal Vault.

## Overview
Vault unseal operation either requires either a number of people who each possess a shard of a key, split by Shamir's Secret sharing algorithm, or protection of the master key via an HSM or cloud key management services (Google CKMS or AWS KMS).

This guide has a guide on how to implement and use this feature in AWS. Included is a Terraform configuration that has the following features:
* Ubuntu 16.04 LTS with Vault
* An instance profile granting the AWS EC2 instance to a KMS key.
* Vault configured with access to a KMS key.


## Prerequisites

This guide assumes the following:

1. AWS account for provisioning cloud resources.
1. Terraform installed, and basic understanding of its usage


## Usage
Instructions assume this location as a working directory, as well as AWS credentials exposed as environment variables

1. Set Vault Enterprise URL in a file named terraform.tfvars (see terraform.tfvars.example)
1. Perform the following to provision the environment

```bash
# Pull necessary plugins
$ terraform init

$ terraform plan

# Output provides the SSH instruction
$ terraform apply
```

Outputs will contain instructions to connect to the server via SSH

```bash
Apply complete! Resources: 17 added, 0 changed, 0 destroyed.

Outputs:

connections = Connect to Node1 via SSH   ssh ubuntu@52.3.231.19 -i private.key
Vault Enterprise web interface  http://52.3.231.19:8200/ui

Connect to Node2 via SSH   ssh ubuntu@35.170.54.27 -i private.key
Vault Enterprise web interface  http://35.170.54.27:8200/ui

Connect to Node3 via SSH   ssh ubuntu@34.200.221.65 -i private.key
Vault Enterprise web interface  http://34.200.221.65:8200/ui```
```

Login to one of the instances

```bash
$ vault status

# Initialize Vault
$ vault operator init -recovery-shares=1 -recovery-threshold=1

# The current machine is the Active node
$ vault status

# Restart the Vault server
$ sudo systemctl restart vault

# Check to verify that the Vault is auto-unsealed
# and that another node is now Active
$ vault status

$ vault login <INITIAL_ROOT_TOKEN>


# cat /etc/vault.d/vault.hcl
storage "consul" {
 address = "127.0.0.1:8500"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
seal "awskms" {
  kms_key_id = "d7c1ffd9-8cce-45e7-be4a-bb38dd205966"
}
ui=true
```

Login to a different node and check the status of Vault (One of them should now be active)

```bash
$ vault status
Key                      Value
---                      -----
Recovery Seal Type       shamir
Sealed                   false
Total Recovery Shares    1
Threshold                1
Version                  0.9.4+ent
Cluster Name             vault-cluster-17200d37
Cluster ID               81c09b45-0ff3-a1c6-65c6-4df2964b261e
HA Enabled               true
HA Cluster               https://192.168.100.166:8201
HA Mode                  active
```

Once complete perform the following to clean up

```
terraform destroy -force
rm -rf .terraform terraform.tfstate* private.key
```




