# Auto-unseal using Azure Key Vault

These assets are provided to perform the tasks described in the [Auto-unseal with Azure Key Vault](https://deploy-preview-346--hashicorp-learn.netlify.com/vault/operations/autounseal-azure-keyvault) guide.

In addition, a script is provided so that you can enable and test `azure` auth method. (_Optional_)
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

- **Tenant ID**: Navigate to the [Azure Active Directory >
 Properties](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Properties)
 in the Azure Portal, and copy the **Directory ID** which is your tenant ID  

- **Client ID**: Same as the [**Application
 ID**](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ApplicationsListBlade)

- **Client secret**: The [password
 (credential)](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ApplicationsListBlade)
 set on your application

## Auto-unseal Steps

1. Set this location as your working directory

1. Provide Azure credentials in the `terraform.tfvars.example` and save it as `terraform.tfvars`

    > NOTE: Overwrite the Azure `location` or `environment` name in the `terraform.tfvars` as desired.

1. Run the Terraform commands:

    ```shell
    # Pull necessary plugins
    $ terraform init

    $ terraform plan

    # Output provides the SSH instruction
    $ terraform apply -auto-approve

    # Refresh to fetch the IP address
    $ terraform refresh
    ...
    Outputs:

    ip = 52.168.108.142
    key_vault_name = Test-vault-a414d041
    ssh_link = ssh azureuser@52.168.108.142
    ```

1. SSH into the virtual machine:

    ```text
    $ ssh azureuser@52.168.108.142
    ```

1. Check the current Vault status:

    ```text
    $ vault status
    Key                      Value
    ---                      -----
    Recovery Seal Type       azurekeyvault
    Initialized              false
    Sealed                   true
    Total Recovery Shares    0
    Threshold                0
    Unseal Progress          0/0
    Unseal Nonce             n/a
    Version                  n/a
    HA Enabled               false
    ```
    Vault hasn't been initialized, yet.

1. Initialize Vault

    ```plaintext
    $ vault operator init

    Recovery Key 1: PfPiNcKeZRVigLJxqyCPHezqLbLLz8q4PAzeSAueFnvK
    Recovery Key 2: MLLZQL1hsT9Pjp5KYw5f22/q5ia3/A9lf+XpEoEKjiMR
    Recovery Key 3: GLVGur9KTUdOEGSxB8byOZTreRZnHX9fl+F32sxhLsav
    Recovery Key 4: n3I5h2yNOx9sEJ2vej9n4GacYi9Si4RGE8zcssahFlQ+
    Recovery Key 5: 9qG+L8Z5uoyKJMbBPtcXyYw00XJMxLry6h5U5wjl356f

    Initial Root Token: s.bRyEk2vIPrKfeldFZD5xFvUL

    Success! Vault is initialized

    Recovery key initialized with 5 key shares and a key threshold of 3. Please
    securely distribute the key shares printed above.
    ```

1. Stop and start the Vault server

    ```shell
    $ sudo systemctl restart vault
    ```

1. Check to verify that the Vault is auto-unsealed

    ```text
    $ vault status
    Key                      Value
    ---                      -----
    Recovery Seal Type       shamir
    Initialized              true
    Sealed                   false
    Total Recovery Shares    5
    Threshold                3
    Version                  1.0.2
    Cluster Name             vault-cluster-092ba5de
    Cluster ID               8b173565-7d74-fe5b-a199-a2b56b7019ee
    HA Enabled               false
    ```

1. Explorer the Vault configuration file

    ```plaintext
    $ cat /etc/vault.d/config.hcl

    storage "file" {
      path = "/opt/vault"
    }
    listener "tcp" {
      address     = "0.0.0.0:8200"
      tls_disable = 1
    }
    seal "azurekeyvault" {
      client_id      = "YOUR-AZURE-APP-ID"
      client_secret  = "YOUR-AZURE-APP-PASSWORD"
      tenant_id      = "YOUR-AZURE-TENANT-ID"
      vault_name     = "Test-vault-xxxx"
      key_name       = "generated-key"
    }
    ui=true
    disable_mlock = true
    ```

## Azure Auth Method Steps

The `azure` auth method allows authentication against Vault using Azure Active Directory credentials.

1. First, log into Vault using the generated initial root token:

    ```plaintext
    $ vault login s.bRyEk2vIPrKfeldFZD5xFvUL
    ```

1. Explorer the `/tmp/azure_auth.sh` file

    ```plaintext
    $ cat /tmp/azure_auth.sh
    ```

    This script performs the following:

    - Enable the Azure auth method at `azure`
    - Configure the Azure auth method
    - Create a role named `dev-role` with `default` policy
    - Finally, log into Vault using as `dev-role` to obtain a Vault client token

1. Execute the script

    ```plaintext
    $ ./azure_auth.sh

     ...

    Key                  Value
    ---                  -----
    token                s.kjS8K4VrrpejH1kuYKdqpdEG
    token_accessor       iawFjCWPnVEowHIu9VRZ0yU0
    token_duration       768h
    token_renewable      true
    token_policies       ["default"]
    identity_policies    []
    policies             ["default"]
    token_meta_role      dev-role
    ```

    A valid service token is generated.

## Clean up

```plaintext
$ terraform destroy -auto-approve

$ rm -rf .terraform terraform.tfstate*
```
