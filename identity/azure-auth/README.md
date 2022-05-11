# Vault Azure Auth
Demo Azure auth method capabilities using Azure VM.

## Documentation
[Vault](https://www.vaultproject.io/docs/auth/azure.html)
[Vault API](https://www.vaultproject.io/api/auth/azure/index.html)
[MSFT Blog](https://open.microsoft.com/2018/04/10/scaling-tips-hashicorp-vault-azure-active-directory/)


## Instructions

### step 0: Config
Fill out the required variables inside terraform.tfvars.example (copy to terraform.tfvars).
```
public_key = ""
client_id=""
client_secret=""
tenant_id=""
subscription_id=""
```

`tenant_id` and `subscription_id` can be found when you use the "az login" command prior to executing Terraform. You can also hover your account name to get the tenant ID or you can select Azure Active Directory > Properties > Directory ID in the Azure portal. Subscription id in portal can be also be found [here](https://blogs.msdn.microsoft.com/mschray/2016/03/18/getting-your-azure-subscription-guid-new-portal/)

```
$ az login
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code ABCEDEF123 to authenticate.

[
  {
    "cloudName": "AzureCloud",
    "id": "SUBSCRIPTION_ID",
    "isDefault": true,
    "name": "",
    "state": "Enabled",
    "tenantId": "TENANT_ID",
    "user": {
      "name": "Bill@gmail.com",
      "type": "user"
    }
  }
]
```

The `client_id` and `client_secret` are used by Vault for authenticating (as an application) against MSI. 

The following instructions explain creating an application (service principal) for terraform executions but the same instructions apply for configuring our Vault azure auth backend:
https://learn.hashicorp.com/tutorials/vault/azure-secrets#create-an-azure-service-principal-and-resource-group

### step 1: Terraform

```
$ terraform apply
$ terraform refresh
Outputs:

ip = 41.77.92.227
```
Run terraform refresh to output the public IP. This is a known [Azure issue](https://github.com/terraform-providers/terraform-provider-azurerm/issues/159)

### step 2: Vault auth
```
$ ssh azureuser@41.77.92.227
$ cd /tmp
$ cat azure_auth.sh
```
You can either use the script or run the commands line by line.
```
azureuser@azure-auth-demo-vm:/tmp$ ./azure_auth.sh
export VAULT_ADDR="http://127.0.0.1:8200"

vault write auth/azure/login role="dev-role"   jwt="cXXZhSQ...."   subscription_id="a7b56ba....."   resource_group_name="vault-demo-azure-auth"   vm_name="azure-auth-demo-vm"
Key                Value
---                -----
token              1a213da9-04b3-2813-20fd-9d863d35627f
token_accessor     7e0732de-2f02-cb41-93a6-13e93e3038a9
token_duration     768h
token_renewable    true
token_policies     [default test]
token_meta_role    dev-role

azureuser@azure-auth-demo-vm:/tmp$ vault login 1a213da9-04b3-2813-20fd-9d863d35627f
Key                Value
---                -----
token              1a213da9-04b3-2813-20fd-9d863d35627f
token_accessor     7e0732de-2f02-cb41-93a6-13e93e3038a9
token_duration     767h59m50s
token_renewable    true
token_policies     [default test]
token_meta_role    dev-role
```
Manually login (Note the curl command for retrieving the JWT token from MSI):
```
vault write auth/azure/login role="dev-role" \
  jwt="$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F'  -H Metadata:true -s | jq -r .access_token)" \
  subscription_id="${subscription_id}" \
  resource_group_name="${resource_group_name}" \
  vm_name="${vm_name}"
```

