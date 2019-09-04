#  Azure Secrets Engine
This guide shows how to configure Vault's Azure Secrets Engine, both on the Vault and on the Azure side.

## Estimated Time to Complete
This exercise should only take 15 minutes to complete for a user familiar with Azure.

## Azure Configuration
TODO: Convert to Terraform code

### Create App Registration for Vault
Login to Azure Web

Open the cli and execute on bash:

```
# This will create an app registration that will be used by Vault, and make it one of the owners of the subscription
az ad sp create-for-rbac -n vault-admin --role Owner --scope /subscriptions/YOUR-SUBSCRIPTION-ID

## Output:
{
  "appId": "xxxx",
  "displayName": "vault-admin",
  "name": "http://vault-admin",
  "password": "xxxx",
  "tenant": "xxxx"
}

Validate user created:
az ad sp list --query "[?contains(appId, 'AppId created')]"

```

Click on search at the top right and search for "App Registrations"

Change the filter to "All apps"

Search for the app name (vault-admin in the above example), and click on it

Click on "API permissions" > Add a Permission > scroll to the bottom of the page and click "Azure Active Directory Graph"

Click "Application permissions" and check the permissions:
Application - Application.ReadWrite.All
Directory - Directory.ReadWrite.All

Click Add Permissions

Click Grant admin consent for azure (Default Directory)

### Create Custom Role (Optional)
This is an optional step, for tests you can use the default role "Contributor".

```
# List existing roles
az role definition list --custom-role-only true --output json | jq '.[] | {"roleName":.roleName, "roleType":.roleType}'

# Create custom_role.json:
{
  "Name": "YOUR-ROLE-NAME",
  "IsCustom": true,
  "Description": "Testing Vault 0.11 Azure Secret Engine",
  "Actions": [
    "Microsoft.Storage/*/read",
    "Microsoft.Network/*/read",
    "Microsoft.Compute/*/read",
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/restart/action",
    "Microsoft.Authorization/*/read",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Insights/alertRules/*",
    "Microsoft.Support/*"
  ],
  "NotActions": [

  ],
  "AssignableScopes": [
    "/subscriptions/YOUR-SUBSCRIPTION-ID"
  ]
}

# Create custom role
az role definition create --role-definition custom_role.json
```

### Configure Azure Secret Engine
```
# Create config file
{
  "subscription_id": "94ca80...",
  "tenant_id": "d0ac7e...",
  "client_id": "e607c4...",
  "client_secret": "9a6346...",
  "environment": "AzurePublicCloud"
}

curl     --header "X-Vault-Token: $VAULT_TOKEN"     --request POST     --data @payload.json     $VAULT_ADDR/v1/azure/config
```

### Register Role in Vault:
Now on Vault:
```
# payload.json
{
    "name": "test", 
    "azure_roles": "[{ \"role_name\": \"Contributor\" ,\"scope\": \"/subscriptions/YOUR-SUBSCRIPTION-ID\"}]" 
}

# Configure Azure user with this role
 curl     --header "X-Vault-Token: $VAULT_TOKEN"      --request POST     --data @payload.json     $VAULT_ADDR/v1/azure/roles/test-role

# Create user and retrieve creds
curl     --header "X-Vault-Token: $VAULT_TOKEN"      --request GET    $VAULT_ADDR/v1/azure/creds/test-role 

# Output
{
  "request_id": "2f9d37b4-502d-b80f-8242-e455fa3cd1c1",
  "lease_id": "azure/creds/test-role/2orH1EXH2k6fA8xoWVjy0Jml",
  "renewable": true,
  "lease_duration": 2764800,
  "data": {
    "client_id": "xxx",
    "client_secret": "xxx"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}

# User will have the "vault-" prefix. 
# You can see this user on Azure by issuing the command:
az ad sp list --query "[?contains(appId, 'GENERATED-CLIENT-ID')]"
```
