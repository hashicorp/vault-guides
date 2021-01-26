#  Vault Sentinel policy
This guide shows how to enable two Sentinel policies in Vault:
- A checks to only allow access to a secret endpoint if the request comes from a certain IP CIDR, which would allow whitelisting a network range or specific IP address.
- A check to only allow access to a secret endpoint if the request is made during workdays (Mon-Fri) and work hours (7am-6pm)

Sentinel policies can be bound to any path within Vault using the *egp* endpoint, or to any Identity entities and groups or to tokens using the *rgp* endpoint. Additional information can be found [here][sentinel-docs].

Many other types of Sentinel checks besides the ones shown here are available, such as request time, token attributes, path attributes and more. A complete list can be found [here][sentinel-properties]

This guide uses jq to parse json output. More information on jq can be found [here][jq]

## Enterprise only
Please note that Sentinel is only available in Vault Enterprise Premium

## Estimated Time to Complete
This exercise should only take 5-10 minutes to complete for a user familiar with Linux.

## Sentinel Testing
You can test your Sentinel policy prior to deployment to validate syntax and to document expected behavior. Sentinel tests are found in the "test" folder, once you have downloaded the [Sentinel simulator][sentinel-binary] you can execute the command
```
cd vault-guides/governance/sentinel
sentinel test
```

## Steps to deploy and test Sentinel policy

## Files in this repository

File | Description | Application
--- | --- | ---
aws-no-keys.sentinel | Sentinel policy that prevents explicit use of AWS keys when creating an instance of the AWS secrets engine or the AWS auth method | Needs to be converted to base64 prior to being added with the Vault HTTP API
businesshours-policy.sentinel | Sentinel policy that checks request's time | Needs to be converted to base64 prior to be added to *egp-time-payload.json*
cidr-policy.sentinel | Sentinel policy that checks request's IP | Needs to be converted to base64 prior to be added to *egp-cidr-payload.json*
egp-businesshours-payload.json | Contains base64 enconded Sentinel policy, to be applied to the "accounting" secrets | Used to register the Sentinel policy within Vault
egp-cidr-payload.json | Contains base64 enconded Sentinel policy, to be applied to all secrets | Used to register the Sentinel policy within Vault
egp-okta-user-whitelist.sentinel | Sentinel policy that gives whitelist of approved users that can authenticate with the Okta auth method | Needs to be converted to base64 prior to being added with the Vault HTTP API
inline-iam-actions.sentinel | Sentinel policy that restricts inline AWS IAM policies to only designate ec2 actions | Needs to be converted to base64 prior to being added with the Vault HTTP API
inline-iam-resources.sentinel | Sentinel policy that restricts inline AWS IAM policies from using a wildcard in resources | Needs to be converted to base64 prior to being added with the Vault HTTP API
max-kv-value-size.sentinel | Sentinel policy that restricts the size of keys written to KVv2 secrets | Needs to be converted to base64 prior to being added with the Vault HTTP API
my-acl-policy.json | ACL policy to be associated to an user | This policy will allow access to the secret path that will be protected by Sentinel
prevent-kv-v1-engines.sentinel | Sentinel policy that prevents KVv1 secrets engines from being created in any namespace | This should be deployed in the root namespace and needs to be converted to base64 prior to being added with the Vault HTTP API
restrict-ttls-of-auth-methods.sentinel | Sentinel policy that imposes maximum limit on `max_lease_ttl` set when enabling Vault auth methods | This should be deployed in the root namespace and needs to be converted to base64 prior to being added with the Vault HTTP API
secret-example.json | Value representing sensitive information to be stored in Vault | Used to test if user can read/write a secret when Sentinel policy is in place
user-password.json | Contains user password | Used to create a new user with the permissive ACL policy
user-payload | Information to create an user | This user will test the Sentinel check
userpass-auth-payload.json | userpass auth method payload | Used to enable userpass authentication method for our tests
userpass-password-check.sentinel | Sentinel policy that requires strong passwords for the Userpass auth method | Needs to be converted to base64 prior to being added with the Vault HTTP API
validate-transit-keys-by-customer.sentinel | Sentinel policy that ensures that each customer logged into an app can only access their own Transit key | The app authenticates against Vault with the same credentials regardless of which customer has logged into it

### Base64
The Sentinel policy needs to be encoded as a base64 string prior to submitting to Vault with the Vault HTTP API. In this repository the Sentinel policy "cidr-policy.sentinel" and a few others are already encoded, however if you would like to change or use your own you can run the following command:
```
cat cidr-policy.sentinel | base64
cat businesshours-policy.sentinel | base64
```
Or you can use a free online service such as https://www.base64decode.org/ to encode/decode a string.

You do not need to encode policies if you add them in the Vault UI.

## Steps

- Register Sentinel policy with the name "cidr" and "businesshours". Any other name could have been used.
```
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @egp-cidr-payload.json \
    $VAULT_ADDR/v1/sys/policies/egp/cidr

curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @egp-businesshours-payload.json \
    $VAULT_ADDR/v1/sys/policies/egp/businesshours
```
- Validate Sentinel policy registered correctly
```
curl  \
     --header "X-Vault-Token: $VAULT_TOKEN" \
     $VAULT_ADDR/v1/sys/policies/egp/cidr

curl  \
     --header "X-Vault-Token: $VAULT_TOKEN" \
     $VAULT_ADDR/v1/sys/policies/egp/businesshours
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
- Ensures userpass auth method is enabled for our tests
```
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @userpass-auth-payload.json \
    $VAULT_ADDR/v1/sys/auth/userpass
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
- Save your Vault admin token
```
VAULT_TOKEN_ADMIN=$(echo $VAULT_TOKEN)
```
- Log as user *test* to get the authentication token associated with that user
```
VAULT_TOKEN=$(curl \
            --silent \
            --request POST \
            --data @user-password.json \
            $VAULT_ADDR/v1/auth/userpass/login/test | jq .auth.client_token -r)
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
- Restore your Vault admin token
```
VAULT_TOKEN=$(echo $VAULT_TOKEN_ADMIN)
```
- Delete Sentinel policies
```
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request DELETE \
    --data @egp-cidr-payload.json \
    $VAULT_ADDR/v1/sys/policies/egp/cidr

curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request DELETE \
    --data @egp-businesshours-payload.json \
    $VAULT_ADDR/v1/sys/policies/egp/businesshours

```
- Repeat above steps:

```
VAULT_TOKEN_ADMIN=$(echo $VAULT_TOKEN)

VAULT_TOKEN=$(curl \
            --silent \
            --request POST \
            --data @user-password.json \
            $VAULT_ADDR/v1/auth/userpass/login/test | jq .auth.client_token -r)

curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    $VAULT_ADDR/v1/secret/app1
```
- Expected result
```
{"request_id":"28e3c5f1-3426-bd7a-8010-e85a909002a3","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"foo":"bar","zip":"zap"},"wrap_info":null,"warnings":null,"auth":null}
```

Testing the "businesshours" policy is left as an exercise to the reader.

[sentinel-docs]: https://www.vaultproject.io/docs/enterprise/sentinel/index.html
[sentinel-properties]: https://www.vaultproject.io/docs/enterprise/sentinel/properties.html
[jq]: https://stedolan.github.io/jq/download/
[sentinel-binary]: https://docs.hashicorp.com/sentinel/downloads.html
