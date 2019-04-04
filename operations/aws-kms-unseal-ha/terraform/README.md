# Vault Autounseal using AWS KMS

In this guide, we'll show an example of how to use Terraform to provision a cluster that can utilize an encryption key from AWS Key Management Services to unseal Vault.

## Overview
Vault unseal operation either requires either a number of people who each possess a shard of a key, split by Shamir's Secret sharing algorithm, or protection of the master key via an HSM or cloud key management services (Google CKMS or AWS KMS). 

This guide has a guide on how to implement and use this feature in AWS. Included is a Terraform configuration that has the following features:  
* Ubuntu 16.04 LTS with Vault Enterprise (0.9.0+prem.hsm).   
* An instance profile granting the AWS EC2 instance to a KMS key.   
* Vault configured with access to a KMS key.   


## Prerequisites

This guide assumes the following:   

1. Access to Vault Enterprise > 0.9.0 which supports AWS KMS as an unseal mechanism. 
1. A URL to download Vault Enterprise from (an S3 bucket will suffice). 
1. AWS account for provisioning cloud resources. 
1. Terraform installed, and basic understanding of its usage


## Usage
Instructions assume this location as a working directory, as well as AWS credentials exposed as environment variables

1. Set Vault Enterprise URL in a file named terraform.tfvars (see terraform.tfvars.example)
1. Perform the following to provision the environment

```
terraform init
terraform plan
terraform apply
```

Outputs will contain instructions to connect to the server via SSH

```
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

```
# vault status
Error checking seal status: Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/seal-status
Code: 400. Errors:

* server is not yet initialized

# Active a primary node
# vault init -stored-shares=1 -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1
Recovery Key 1: oOxAQfxcZitjqZfF3984De8rUckPeahQDUvmJ1A4JrQ=
Initial Root Token: 54c4dbe3-d45b-79d9-18d0-602831a6a991

Vault initialized successfully.

Recovery key initialized with 1 keys and a key threshold of 1. Please
securely distribute the above keys.

# systemctl stop vault
root@ip-192-168-100-100:~# vault status
Error checking seal status: Get http://127.0.0.1:8200/v1/sys/seal-status: dial tcp 127.0.0.1:8200: getsockopt: connection refused

# systemctl start vault
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
HA Mode                  standby
Active Node Address:     http://192.168.100.166:82001

High-Availability Enabled: false

# vault auth 54c4dbe3-d45b-79d9-18d0-602831a6a991
Successfully authenticated! You are now logged in.
token: 54c4dbe3-d45b-79d9-18d0-602831a6a991
token_duration: 0
token_policies: [root]


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

```
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




