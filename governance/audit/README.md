# Audit Logs for Incident Response
One of the most important features in Vault is the ‘break glass’ procedure. This can mean several different things in the context of Vault world. In this document we show a few examples of how we can leverage Vault to stop the bleeding of a compromised organization.

The examples here utilize the Vault audit log written to a file. These same processes can be performed when a SIEM tool is used (Splunk, ELK stack etc). It is recommended to leverage these tools to monitor and trigger alerts to detect security threats to provide for efficient notification and handling, perhaps automated remediation.

## Scenarios
- [Host compromised](#host)
- [Credentials exposed](#creds)
- [User access](#user)
- [Authentication failure](#auth)
- [Vault compromised](#vault)

## Setup
For these tests, please ensure you have 
- [A Vault server](../operations/provision-vault)
- [Dynamic DB credentials](../secrets/database-mysql)
- [Username and password setup](https://www.vaultproject.io/api/auth/userpass/index.html)

### <a name="host"></a>Host compromised
An IDS alerts that a certain server host has been rooted by a malicious user. In this scenario a security administrator may want to revoke all leases associated with the given IP address. You can leverage the audit log to revoke all secret leases associated with that IP very quickly.

Create as a script:
```
# revoke.sh
# This script will retrieve and revoke all leases found in the logs created by the compromised IP.
# Examples of leases include access tokens and dynamic secrets. Revoking the lease will revoke these.

for LEASE in $(grep 10.103.9.43  /var/log/vault_audit.log | jq -rj \
.response.secret.lease_id); do
  curl --header "X-Vault-Token: $VAULT_TOKEN"  \
    --request PUT \
    --data "{\"lease_id\": \"$LEASE\" }" \
    https://vault.rocks/v1/sys/leases/revoke
  done

```

### <a name="creds"></a> Credentials Exposed
In this example, assume that a username/password was committed to GitHub. We can leverage Vault’s API to find the hmac’d value of our input (the compromised secret). Using that value we can search Vault’s audit log to find the corresponding secret’s lease id for revoking.

Compromised password:
```
74fba557-528a-61ef-1acc-9e7e5989a277
```

First, make a request to Vault’s API to find the hashed (hmac) value of the secret:
```
curl --header "X-Vault-Token: $VAULT_TOKEN"  \
  --request POST \
  --data "{\"input\": \"74fba557-528a-61ef-1acc-9e7e5989a277\" }"  \
  https://vault.rocks/v1/sys/audit-hash/file | jq -r .data.hash

hmac-sha256:ef6840c79d1be65f328b51141c3f19ca3360a7ed9d972a76f1cd6e7c240436ca
```

Now determine the associated lease_id
```
hmac=hmac-sha256:ef6840c79d1be65f328b51141c3f19ca3360a7ed9d972a76f1cd6e7c240436ca

$ grep -m 1 -r $hmac /var/log/vault_audit.log | jq -r .response.secret.lease_id

mysql/creds/app/f254f9a3-50b0-16b7-7694-0cad2855b779
```

Using lease_id we can now safely revoke this secret (via the REST API, web interface, or command line interface).

```
curl --header "X-Vault-Token: $VAULT_TOKEN"  \
  --request PUT \
  --data "{\"lease_id\": \"$1\" }" \
  https://vault.rocks/v1/sys/leases/revoke
```
Vault will revoke the lease and delete the username/password from the dynamic database backend.

### <a name="user"></a> User Access
In this example, we will show how to audit the logs for the following:
- IP CIDR range
- Secret path
- AppRole role access

Here is an example log output that will be used:

```
{
  "time": "2018-08-28T19:10:16.292180298Z",
  "type": "response",
  "auth": {
    "client_token": "hmac-sha256:883d7702eb6b48067dc6482a32af1e049a301dd0722fe6d95d19d4534a3609bf",
    "accessor": "hmac-sha256:49bdb7bf983f1fc72d3443c58147db1e1ada2b715894e6384a4c0208925ee99c",
    "display_name": "approle",
    "policies": [
      "app1",
      "default"
    ],
    "token_policies": [
      "app1",
      "default"
    ],
    "metadata": {
      "role_name": "app1role"
    },
    "entity_id": "aa709fab-816f-4ec6-b6d0-ace9766b347d"
  },
  "request": {
    "id": "da41f356-f0dd-ac3a-19c3-3f3c210c3f23",
    "operation": "update",
    "client_token": "hmac-sha256:883d7702eb6b48067dc6482a32af1e049a301dd0722fe6d95d19d4534a3609bf",
    "client_token_accessor": "hmac-sha256:49bdb7bf983f1fc72d3443c58147db1e1ada2b715894e6384a4c0208925ee99c",
    "path": "secret/app1",
    "data": {
      "value": "hmac-sha256:68370cdb9216366c2dfc537a5a921ef9e92970a721aeb33996e7827b783b7a92"
    },
    "policy_override": false,
    "remote_address": "205.178.21.228",
    "wrap_ttl": 0,
    "headers": {}
  },
  "response": {},
  "error": ""
}
```
And we will use [jq](https://stedolan.github.io/jq/download/) to parse the json object.

#### IP Access
```
cat vault_audit.log |  jq 'select(.request.remote_address | startswith("205.178"))'
```
#### Secret Path
```
cat vault_audit.log |  jq 'select(.request.path | startswith("secret/app1"))'
```
#### AppRole Role Access
```
cat vault_audit.log |  jq 'select(.auth.metadata.role_name | startswith("app1role"))'
```

### <a name="auth"></a> Authentication failure

This use case is important for secure introduction. Tokens in Vault can be given a one time wrapping token or limited time use token. If we see an error with the use of these tokens we should investigate. In the context of an orchestrator: an attacker may have stolen the wrapped token (being passed from orchestrator to application or container). If the call fails for the container we can revoke the associated authentication tokens to deter malicious use.

First: the application API request would fail to unwrap:
```
curl
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST  \
    --data "{ \"token\": \"$WRAPPED_TOKEN\" }" \            http://127.0.0.1:8200/v1/sys/wrapping/unwrap | jq

#Result:
{
  "errors": [
    "wrapping token is not valid or does not exist"
  ]
}

```
At this point if a lookup or unwrap fails then an immediate investigation should be triggered

```
$ curl --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data "{\"input\": \"$WRAPPED_TOKEN" }" \        
  http://127.0.0.1:8200/v1/sys/audit-hash/file | jq

hmac-sha256:ef6840c79d1be65f328b51141c3f19ca3360a7ed9d972a76f1cd6e7c240436ca

$ grep "hmac-sha256:31178fa19495c966e843b40e2bfa8f7d771be840ec6fb4c7270a01d5f08d5469" /var/log/vault_audit.log | grep unwrap | jq.
```
If an unwrapping action was performed (sys/wrapping/unwrap) then we can take steps to revoke the resulting auth token. 
We need to now revoke the authentication leases associated with the token role.

```
curl --header "X-Vault-Token: $VAULT_TOKEN" \
  --request PUT \ https://vault.rocks/v1/sys/leases/revoke-prefix/auth/token/create/${ROLE}

```

### <a name="vault"></a> Vault compromised 

Solution: With only a short window of time or the existence of a large unknown threat or virus it may be most suitable to seal Vault. Once sealed, Vault will be unable to serve any API/CLI/GUI requests until it is unsealed. There are two methods for sealing and unsealing: Shamir’s secret method (shared keys) and HSM’s

Seal Vault
```
$ curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    https://vault.rocks/v1/sys/seal
```

Once the threat has subsided, Vault can be unsealed using the quorum of unseal keys. this command will need to be repeated separately to reach the quorum of unseal keys (3 of 5, 4 of 7, etc.)

```
$ curl \
    --request PUT \
    --data “{ \”key\”:\”abcd…..\” }”  \
    https://vault.rocks/v1/sys/unseal
```
The alternative to this method is to use a hardware security module, a Vault Enterprise feature, to encrypt the master key. In this setup Vault simply needs to be restarted to unseal a sealed Vault node.