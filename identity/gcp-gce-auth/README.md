# Demonstrate GCP gce authentication method

This guide will demonstrate Vault's GCP gce authentication method:

> 1. The client obtains an instance identity metadata token on a GCE instance.
> 1. The client sends this JWT to Vault along with a role name.
> 1. Vault extracts the kid header value, which contains the ID of the key-pair used to generate the JWT, to find the OAuth2 public cert to verify this JWT.
> 1. Vault authorizes the confirmed instance against the given role, ensuring the instance matches the bound zones, regions, or instance groups. If that is successful, a Vault token with the proper policies is returned.
> https://www.vaultproject.io/docs/auth/gcp.html#gce-login

<img src="https://raw.githubusercontent.com/hashicorp/vault-guides/master/assets/vault_gcp_gce_arch.png" alt="GCP gce authentication" width="400">

## Background

The project will create the following resources in GCP:

* vault-gcp-demo-[abc] - A project with a random generated name to assosiate all the resources to
* Vault-server - A GCE instance running Vault
* Vault-happy - A GCE instance in the bound region - This should be able to get a token from Vault
* Vault-sad - A GCE instance not in the bound region - This should not be able to get a token from Vault
* vault-auth-checker - A Service Account with the Compute Viewer and Security Viewer permissions - Vault will use these credentials for the GCE backend

Note: These resources will be firewall access bound to the IP of the machine running Terraform.

We will then create the following Vault install and configuration using the vault-server:

* An initalized vault instance
* One secret in the K/V store under `secret/demo`
* A policy for access to that one secret called `reader` with permissions to read that secret
* An auth policy tied to that reader policy that uses GCP IAM tied to a `bound_region`

The initial token on the instance is created with a script on the machine stored under `/root/.vault_credentials`:

```shell
function set_vault_credentials {
  VAULT_ADDR=${vault_addr}

  JWT=\$(curl -H "Metadata-Flavor: Google"\
  -G \
  --data-urlencode "audience=$VAULT_ADDR/vault/web"\
  --data-urlencode "format=full" \
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity")

  check_errors=\$(curl \
    --request POST \
    --data "{\"role\": \"web\", \"jwt\": \"\$JWT\"}" \
    "${vault_addr}/v1/auth/gcp/login" | jq -r ".errors")

  if [ "\$check_errors" == "null" ]
  then
    VAULT_TOKEN=\$(curl \
    --request POST \
    --data "{\"role\": \"web\", \"jwt\": \"\$JWT\"}" \
    "${vault_addr}/v1/auth/gcp/login" | jq -r ".auth.client_token")
  else
    echo "Error from vault: \$check_errors"
    exit 1
  fi

  export VAULT_ADDR
  export VAULT_TOKEN
}
```

## Reference Material
https://www.vaultproject.io/docs/auth/gcp.html
https://www.vaultproject.io/api/auth/gcp/index.html

## Note
The code in this repository is for reference only. It is meant to illustrate a few of the requirements for using the GCP gce authentication method.

## Instructions

Install gcloud

With Brew:

```
brew install gcloud
```

Or with the installer:

```
curl https://sdk.cloud.google.com |
exec -l $SHELL
gcloud init
```

Configure authentication:

```
gcloud auth login
gcloud auth application-default login
```

Export your billing and organisation settings:
```
gcloud organizations list
gcloud beta billing accounts list

export TF_VAR_org_id=<Organisation ID>
export TF_VAR_billing_account=<Billing Account ID>
```

Run terraform:

```
terraform init
terraform plan
terraform apply
```

## Configure Vault after installation

Use the Terraform output `vault_addr_export` for the shell code to export Vault configuration:

```
vault_addr_export = Run the following for the Vault configuration: export VAULT_ADDR=http://11.22.33.44:8200
```

Initialize Vault:
```
vault operator init -key-shares=1 -key-threshold=1
```

Unseal Vault (by supplying at least a key from the above output)
```
vault operator unseal
Unseal Key (will be hidden): <Enter key here>
```

Export the Vault token from the info from the initialize
```
export VAULT_TOKEN=s.KkNJYWF5g0pomcCLEmDdOVCW
```

### Configure GCP Backend and secrets

Configure Vault with Terraform code:
```
cd vault/
terraform plan
terraform apply
cd ..
```

## Show Backend and Policies

### SSH into the Vault Happy path instance

```
./scripts/ssh_to_vault_happy.sh
```

## Run the functions to get Vault credentials

```
$ sudo -i
$ source ~/.vault_credentials
$ env | grep VAULT
VAULT_ADDR=http://11.22.33.44:8200
VAULT_TOKEN=9a73bcbd-460f-bca8-39b5-04854799cb96
```

## Get the example data (with JQ for nice output)

```
$ curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    $VAULT_ADDR/v1/secret/demo | jq
{
  "request_id": "a4e5343c-e10f-dc80-19a3-cd107332014f",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "location": "London"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

## Do the same on the Vault Unhappy path to see that there is a region bind to europe-west2:

```
$ ./scripts/ssh_to_vault_sad.sh
$ source ~/.vault_credentials
Error from vault: [
  "instance not in bound regions [\"europe-west2\"]"
]
```
