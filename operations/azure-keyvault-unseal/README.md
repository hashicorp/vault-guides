# Vault Auto-unseal using Azure Key Vault

These assets are provided to perform the tasks described in the Auto-unseal with Azure Key Vault guide which is being developed.

---

## Prerequisites

- Microsoft Azure account
- [Terraform installed](https://www.terraform.io/downloads.html) and ready to use

**Terraform Azure Provider Prerequisites**

A ***service principal*** is an application within Azure Active Directory which
can be used to authenticate. Service principals are preferable to running an app
using your own credentials. Follow the instruction in the [Terraform
documentation](https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_certificate.html)
to create a service principal and then configure in Terraform.

To successfully execute this guide, you would need the following:

- **Tenant ID**: Navigate to the [Azure Active Directory >
 Properties](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Properties)
 in the Azure Portal, and copy the **Directory ID** which is your tenant ID  

- **Client ID**: Same as the [**Application
 ID**](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ApplicationsListBlade)

- **Client secret**: The [password
 (credential)](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ApplicationsListBlade)
 set on your application

## Steps

1. Set this location as your working directory

1. Provide tenant ID in the `terraform.tfvars.example` and save it as `terraform.tfvars`

    > NOTE: Overwrite the Azure `location` or `environment` name in the `terraform.tfvars` as desired.

1. Run the Terraform commands:

    ```shell
    # Pull necessary plugins
    $ terraform init

    $ terraform plan

    # Output provides the SSH instruction
    $ terraform apply -auto-approve
    ```

1. Vault server configuration file (`config.hcl`) should look like:

    ```text
    ui = true

    storage "consul" {
      address = "127.0.0.1:8500"
      path = "vault"
    }

    listener "tcp" {
      address     = "127.0.0.1:8200"
      tls_disable = 1
    }

    seal "azurekeyvault" {
      client_id="AZURE_CLIENT_ID"
      client_secret = "AZURE_CLIENT_SECRET"
      tenant_id="AZURE_TENANT_IDc"
      vault_name     = "Test-vault-xxxxx"
      key_name       = "generated-key"
    }

    disable_mlock = true
    ```
