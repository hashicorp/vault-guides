# Auto-unseal using Azure Key Vault

These assets are provided to perform the tasks described in the [Auto-unseal with Azure Key Vault](https://learn.hashicorp.com/vault/operations/autounseal-azure-keyvault) guide.

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

> **IMPORTANT:** Ensure that your Service Principal has appropriate permissions to provision virtual machines, networks, as well as **Azure Key Vault**. Refer to the [Azure documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal).

## Auto-unseal Steps

1. Set this location as your working directory

1. Provide Azure credentials in the `terraform.tfvars.example` and save it as `terraform.tfvars`

    > NOTE: Overwrite the Azure `location` or `environment` name in the `terraform.tfvars` as desired.

1. Run the Terraform commands:

    ```shell
    # Pull necessary plugins
    $ terraform init

    $ terraform plan -out tfplan
    ...
    Outputs:

    ip = 13.82.62.56
    key_vault_name = Test-vault-1e5a88de
    ssh-addr =
        Connect to your virtual machine via SSH:

        $ ssh azureuser@13.82.62.562
    ```

1. SSH into the virtual machine:

    ```plaintext
    $ ssh azureuser@13.82.62.562
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
    Version                  1.5.0
    Cluster Name             vault-cluster-092ba5de
    Cluster ID               8b173565-7d74-fe5b-a199-a2b56b7019ee
    HA Enabled               false
    ```

1. Explore the Vault configuration file

    ```plaintext
    $ sudo cat /etc/vault.d/vault.hcl

    ui = true
    disable_mlock = true

    api_addr = "http://VAULT-IP-ADDRESS:8200"
    cluster_addr = "http://VAULT-IP-ADDRESS:8201"

    storage "file" {
      path = "/opt/vault/data"
    }

    listener "tcp" {
      address         = "0.0.0.0:8200"
      cluster_address = "0.0.0.0:8201"
      tls_disable     = 1
      telemetry {
        unauthenticated_metrics_access = true
      }
    }

    # enable the telemetry endpoint.
    # access it at http://<VAULT-IP-ADDRESS>:8200/v1/sys/metrics?format=prometheus
    # see https://www.vaultproject.io/docs/configuration/telemetry
    # see https://www.vaultproject.io/docs/configuration/listener/tcp#telemetry-parameters
    telemetry {
      disable_hostname = true
      prometheus_retention_time = "24h"
    }

    # enable auto-unseal using the azure key vault.
    seal "azurekeyvault" {
      client_id      = "YOUR-AZURE-APP-ID"
      client_secret  = "YOUR-AZURE-APP-PASSWORD"
      tenant_id      = "YOUR-AZURE-TENANT-ID"
      vault_name     = "Test-vault-xxxx"
      key_name       = "generated-key"
    }
    ```

## Azure Auth Method Steps

The `azure` auth method allows authentication against Vault using Azure Active Directory credentials.

1. First, log into Vault using the generated initial root token:

    ```plaintext
    $ vault login s.bRyEk2vIPrKfeldFZD5xFvUL
    ```

1. Explore the `/tmp/azure_auth.sh` file

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
    $ /tmp/azure_auth.sh
    ...
    Key                               Value
    ---                               -----
    token                             s.xYqTKUSivsKiwNwXv6wz9LUJ
    token_accessor                    0dua5lTuYkAyQakJiy0oKJW5
    token_duration                    768h
    token_renewable                   true
    token_policies                    ["default"]
    identity_policies                 []
    policies                          ["default"]
    token_meta_resource_group_name    learn-vault-rg
    token_meta_role                   dev-role
    token_meta_subscription_id        YOUR-AZURE-SUBSCRIPTION-ID
    token_meta_vm_name                azure-auth-demo-vm
    ```

    A valid service token is generated.

    ```plaintext
    $ vault token lookup s.xYqTKUSivsKiwNwXv6wz9LUJ

    Key                 Value
    ---                 -----
    accessor            0dua5lTuYkAyQakJiy0oKJW5
    creation_time       1548279674
    creation_ttl        768h
    display_name        azure-cc47203d-6c51-4498-9c3d-5e2874eca6fb
    entity_id           7009136d-2eee-0414-61f9-e705a9f299ef
    expire_time         2019-02-24T21:41:14.231599224Z
    explicit_max_ttl    0s
    id                  s.xYqTKUSivsKiwNwXv6wz9LUJ
    issue_time          2019-01-23T21:41:14.231598924Z
    meta                map[resource_group_name:learn-vault-rg role:dev-role subscription_id:YOUR-AZURE-SUBSCRIPTION-ID vm_name:azure-auth-demo-vm]
    num_uses            0
    orphan              true
    path                auth/azure/login
    policies            [default]
    renewable           true
    ttl                 767h59m48s
    type                service
    ```

## Clean up

Run `terraform destroy` when you are done exploring:

```plaintext
$ terraform destroy -auto-approve

$ rm -rf .terraform terraform.tfstate*
```
