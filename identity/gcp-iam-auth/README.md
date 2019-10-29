# Demonstrate GCP IAM authentication method

This guide will demonstrate Vault's GCP IAM authentication method:

> 1. The client generates a signed JWT using the IAM projects.serviceAccounts.signJwt method. For examples of how to do this, see the Obtaining JWT Tokens section.
> 1. The client sends this signed JWT to Vault along with a role name.
> 1. Vault extracts the kid header value, which contains the ID of the key-pair used to generate the JWT, and the sub ID/email to find the service account key. If the service account does not exist or the key is not linked to the service account, Vault denies authentication.
> 1. Vault authorizes the confirmed service account against the given role. If that is successful, a Vault token with the proper policies is returned.
> https://www.vaultproject.io/docs/auth/gcp.html#iam-login

<img src="https://raw.githubusercontent.com/hashicorp/vault-guides/master/assets/vault_gcp_iam_arch.png" alt="GCP IAM authentication" width="400">

## Background

The project will create the following resources in GCP:

* vault-gcp-iam-demo-[abc] - A project with a random generated name to assosiate all the resources to
* vaultadmin - A Service Account with the iam.serviceAccountKeyAdmin - Vault will use this to check other service account credentials
* alice-account - A Service Account bound to the backend
* bob-account - A Service Account not bound to the backend

It will also create two credential JSON files used for the login step.

We will then create the following Vault install and configuration using the vault-server:

* An initalized vault instance
* One secret in the K/V store under `secret/test/mysecret`
* One secret in the K/V store under `secret/prod/mysecret`
* A policy for access to that one secret called `reader` with permissions to read that secret
* An auth policy tied to that reader policy that uses GCP IAM tied to the alice service account eg. `alice-account@vaultguides-gcpiam-ee.iam.gserviceaccount.com`

## Reference Material
https://www.vaultproject.io/docs/auth/gcp.html
https://www.vaultproject.io/api/auth/gcp/index.html

## Note
The code in this repository is for reference only. It is meant to illustrate a few of the requirements for using the GCP IAM authentication method.

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

Run a local Vault instance in a new terminal in dev mode:

```
$ vault server -dev &
```

Export the root token and address
```
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='s.F7G0fS7FqlCgkKHe0JWPfD6u'
```

### Configure Vault GCP Backend and secrets

Configure Vault with Terraform code:
```
cd vault/
terraform plan
terraform apply
cd ..
```

### Auth with Alice service account

```
$ unset VAULT_TOKEN
$ vault login -method=gcp \
  role="web" \
  credentials=@alice-credentials.json \
  project="$(terraform output project_id)" \
  service_account="$(terraform output alice_account_email)"
```

Then try and lookup the demo secret:

```
$ vault kv get secret/test/mysecret
====== Metadata ======
Key              Value
---              -----
created_time     2019-07-26T17:37:18.325839Z
deletion_time    n/a
destroyed        false
version          2

=== Data ===
Key    Value
---    -----
key    London
```

Then try and lookup the forbidden prod secret:

```
$ vault kv get secret/prod/mysecret
Error reading secret/data/prod/mysecret: Error making API request.

URL: GET http://127.0.0.1:8200/v1/secret/data/prod/mysecret
Code: 403. Errors:

* 1 error occurred:
  * permission denied
```

### Auth with Bob service account

Since we bound the auth endpoint to just Bob's account, this will fail:

```
$ unset VAULT_TOKEN
$ vault login -method=gcp \
    role="web" \
    credentials=@bob-credentials.json \
    project="$(terraform output project_id)" \
    service_account="$(terraform output bob_account_email)"
Error authenticating: Error making API request.

URL: PUT http://127.0.0.1:8200/v1/auth/gcp/login
Code: 400. Errors:

* service account bob-acount@vaultguides-gcpiam-ee.iam.gserviceaccount.com (id: 103413538402565467997) is not authorized for role
```

If we were to change the `bound_service_accounts` to `*` or all, or a comma seperated list including Bob, they would also be able to login.
