#  Vault Sentinel policy
This guide shows how to enable a Sentinel policy in Vault that will only allow access to a secret enpoint if the request comes from a certain ip address.

Sentinel policies can be bound to any path within Vault using the *egp* endpoint, or to any Identity entities and groups or to tokens using the *rgp* endpoint. Additional information can be found [here][sentinel-docs].

This guide only uses Sentinel for IP whitelisting of a secret endpoint. However there are many other types of checks available for Sentinel, such as request time, token attributes, path attributes and more. A complete list can be found [here][sentinel-properties]

## Enterprise only
Please note that Sentinel is only available in the Enterprise version of Vault

## Estimated Time to Complete
This exercise should only take 5-10 minutes to complete for a user familiar with Linux.

## Steps to deploy and test Sentinel policy

## Files in this repository

File | Description | Application
--- | --- | ---
egp-payload.json | Contains base64 enconded Sentinel policy | Used to register the Sentinel policy within Vault
secret-example.json | Value representing sensitive information to be stored in Vault | Used to test if user can read/write a secret when Sentinel policy is in place
cidr-policy.sentinel | The checks this Sentinel policy will enforce | Needs to be converted to base64 prior to be added to *egp-payload.json*
my-acl-policy.json | ACL policy to be associated to an user | This policy will allow access to the secret path that will be protected by Sentinel
user-password.json | Contains user password | Used to create a new user with the permissive ACL policy
user-payload | Information to create an user | This user will test the Sentinel check

### Optional
The Sentinel policy needs to be encoded as a base64 string prior to submitting to Vault. In this repository the Sentinel policy "cidr-policy.sentinel" is already encoded, however if you would like to change or use your own you can use a service such as https://www.base64decode.org/ to encode/decode a string.

## Steps

- Register Sentinel policy with the name "cidr". Any other name could have been used.
```
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @egp-payload.json \
    $VAULT_ADDR/v1/sys/policies/egp/cidr
```
- Validate Sentinel policy registered correctly
```
curl  \
     --header "X-Vault-Token: $VAULT_TOKEN" \
     $VAULT_ADDR/v1/sys/policies/egp/cidr
```
- List existing Sentinel policies in egp endpoint
```
curl \
     --request LIST \
     --header "X-Vault-Token: $VAULT_TOKEN" \
     $VAULT_ADDR/v1/sys/policies/egp
```
- Register ACL policy. This is the policy that can be used to allow an user the permissions defined in this policy.
```
curl \
  --request POST \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  --data @my-acl-policy.json \
  $VAULT_ADDR/v1/sys/policy/my-acl-policy
```
- Create a user *test* associated with policy my-acl-policy
```
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @user-payload.json \
    $VAULT_ADDR/v1/auth/userpass/users/test
```
- Write a secret in Vault, under the path that is protected by the Sentinel policy and for which user *test* has access to, according to the *my-acl-policy*
```
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @secret-example.json \
    $VAULT_ADDR/v1/secret/app1
```
- Read the secret to confirm it is there
```
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    $VAULT_ADDR/v1/secret/app1
```
- Log as user *test* to get the authentication token associated with that user
```
curl \
    --request POST \
    --data @user-password.json \
    $VAULT_ADDR/v1/auth/userpass/login/test
```
- Update the environment variable with this token
```
export VAULT_TOKEN=CLIENT_TOKEN_HERE
```
- Attempt to read the secret
```
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    $VAULT_ADDR/v1/secret/app1
```
- Expected error
```
{"errors":["1 error occurred:\n\n* egp standard policy \"cidr\" evaluation resulted in denial.\n\nThe specific error was:\n\u003cnil\u003e\n\nA trace of the execution for policy \"cidr\" is available:\n\nResult: false\n\nDescription: \u003cnone\u003e\n\nRule \"main\" (byte offset 202) = false\n  false (offset 125): sockaddr.is_contained\n\nRule \"cidrcheck\" (byte offset 101) = false\n"]}
```

[sentinel-docs]: https://www.vaultproject.io/docs/enterprise/sentinel/index.html
[sentinel-properties]: https://www.vaultproject.io/docs/enterprise/sentinel/properties.html