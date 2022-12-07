# Vault Auto-unseal using AWS KMS

These assets are provided to perform the tasks described in the [Vault Auto-unseal with AWS KMS](https://developer.hashicorp.com/vault/tutorials/auto-unseal/autounseal-aws-kms) guide.

---

## Hands on Lab Steps

### Setup

1. Set this location as your working directory.

1. Export your AWS credentials as environment variables: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

1. Override default AWS region and zone in a `terraform.tfvars` file as needed (see `terraform.tfvars.example`).

### Commands Cheat Sheet

These are the commands which are shown in the tutorial content.

#### Terraform

Initialize Terraform.

```shell
terraform init
```

Plan resource changes.

```shell
terraform plan -out learn-vault-aws-kms.plan
```

Apply the plan.

```shell
terraform apply "learn-vault-aws-kms.plan"
```

#### Vault in EC2 instance

SSH into the EC2 machine; use the example command from the
Terraform apply output, as it contains the correct IP address.

```shell
ssh ubuntu@<IP_ADDRESS> -i private.key
```

Once in the EC2 instance, export a `VAULT_ADDR` environment variable.

```shell
export VAULT_ADDR=http://127.0.0.1:8200
```

Get Vault server status.

```shell
vault status
```


Initialize Vault

```shell
vault operator init -key-shares=1 -key-threshold=1
```

Restart the Vault server process.

```shell
sudo systemctl restart vault
```

Check to verify that the Vault is auto-unsealed

```shell
vault status
```

Login with Initial Root Token value from the Vault
initialization output.

```shell
vault login <INITIAL_ROOT_TOKEN_VALUE>
```

Explore the Vault server configuration file.

```
cat /etc/vault.d/vault.hcl
```

Log out.

```
exit
```

Clean up.

```
terraform destroy -auto-approve
```

```shell
rm -rf .terraform terraform.tfstate* private.key
```
