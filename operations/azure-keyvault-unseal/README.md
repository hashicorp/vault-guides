# Vault Auto-unseal using Azure Key Vault

These assets are provided to perform the tasks described in the Auto-unseal with Azure Key Vault guide which is being developed.

---

## Prerequisites

- Microsoft Azure account
- [Terraform installed](https://www.terraform.io/downloads.html) and ready to use

<br>

**Terraform Azure Provider Prerequisites**

A ***service principal*** is an application within Azure Active Directory which
can be used to authenticate. Service principals are preferable to running an app
using your own credentials. Follow the instruction in the [Terraform
documentation](https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_certificate.html)
to create a service principal and then configure in Terraform.

Tips:

- **Subscription ID**: Navigate to the [Subscriptions blade within the Azure
 Portal](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade)
 and copy the **Subscription ID**  

    > **NOTE**: Be sure to set the ARM_SUBSCRIPTION_ID environment variable

    ```text
    $ export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
    ```

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
    ...
    Outputs:

    key_vault_name = Test-vault-cc6092c7
    ```

    Notice that the generated Azure Key Vault name is displayed (e.g. `Test-vault-cc6092c7`).

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
      client_id      = "AZURE_CLIENT_ID"
      client_secret  = "AZURE_CLIENT_SECRET"
      tenant_id      = "AZURE_TENANT_IDc"
      vault_name     = "Test-vault-xxxxx"
      key_name       = "generated-key"
    }

    disable_mlock = true
    ```
