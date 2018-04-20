# Spring example with Spring Cloud Vault and Cloud Foundry.

## Description
App that shows the following functions:
- PCF integration with Vault using service broker
- Reading Vault static secrets on appId generic path
- Vault dynamic credentials
- Vault transit backend

## Requirements:
- A Vault server configured with transit backend.  See [vault config](scripts/vault.sh)
- A Postgres DB secret engine with configured Vault roles. See [vault config](scripts/vault.sh)
- A Postgres DB with the "order" table. See [sql query](scripts/postgres.sql)
- A PCF env with Vault Service Broker

Reference: https://github.com/hashicorp/vault-service-broker

![picture alt](https://github.com/stenio123/spring-vault-demo-cf/blob/master/VaultServiceBrokerPCF.jpg "Reference PCF Vault Service Broker ")

## Vault Policy
After you have bound the service broker follow the steps [here](https://github.com/hashicorp/vault-service-broker#granting-access-to-other-paths) to grant the app access to central DB and Transit policies. Below is an example policy.
```
path "cf/63e3e3a0-31f5-4b28-b38b-6708339df836" {
  capabilities = ["list"]
}

path "cf/63e3e3a0-31f5-4b28-b38b-6708339df836/*" {
	capabilities = ["create", "read", "update", "delete", "list"]
}

path "cf/a3abff6c-a00a-49d3-bca5-8384a9ec2299" {
  capabilities = ["list"]
}

path "cf/a3abff6c-a00a-49d3-bca5-8384a9ec2299/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "cf/32ff778e-0db4-4d24-8629-b316ba71fda4" {
  capabilities = ["list"]
}

path "cf/32ff778e-0db4-4d24-8629-b316ba71fda4/*" {
  capabilities = ["read", "list"]
}

path "transit/decrypt/order" {
  capabilities = ["update"]
}

path "transit/encrypt/order" {
  capabilities = ["update"]
}

path "database/creds/order" {
  capabilities = ["read"]
}
```
If instead you want the service broker to handle these additional backends, you can fork the repository and add paths [here](https://github.com/hashicorp/vault-service-broker/blob/dfe5aaca53aa805e6cd2dd7f703603670594787b/broker.go#L338)


## Deployment Platforms
1. Execute
```
mvn package
cf push
```
2. Follow the instructions on https://github.com/hashicorp/vault-service-broker to bind the app

3. Restart the app


## API USE

- Get Orders
```
$ curl -s -X GET \
   http://localhost:8080/api/orders | jq
[
  {
    "id": 204,
    "customerName": "Lance",
    "productName": "Vault-Ent",
    "orderDate": 1523656082215
  }
]
```
- Create Order
```
$ curl -s -X POST \
   http://localhost:8080/api/orders \
   -H 'content-type: application/json' \
   -d '{"customerName": "Lance", "productName": "Vault-Ent"}' | jq
{
  "id": 204,
  "customerName": "Lance",
  "productName": "Vault-Ent",
  "orderDate": 1523656082215
}
```
- Delete Orders
```
$ curl -s -X DELETE -w "%{http_code}" http://localhost:8080/api/orders | jq
200
```

## Refreshing Static Secrets
Spring has an actuator we can use to facilitate the rotation of static credentials. Example below.
1. Export your env vars
```
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root
```

2. Create the old secret.
```
$ curl -s \
   --header "X-Vault-Token: ${VAULT_TOKEN}" \
   --request POST \
   --data '{"secret":"hello-old"}' \
   --write-out "%{http_code}" ${VAULT_ADDR}/v1/secret/spring-vault-demo | jq
204
```

3. Read the old secret.
```
$ curl -s http://localhost:8080/api/secret | jq
{
  "key": "secret",
  "value": "hello-old"
}
```

4. Create the new secret.
```
$ curl -s \
   --header "X-Vault-Token: ${VAULT_TOKEN}" \
   --request POST \
   --data '{"secret":"hello-new"}' \
   --write-out "%{http_code}" ${VAULT_ADDR}/v1/secret/spring-vault-demo | jq
204
```

5. Rotate the secret.
```
$ curl -s -X POST http://localhost:8080/actuator/refresh | jq
[
  "secret"
]
```

6. Read the new secret.
```
$ curl -s http://localhost:8080/api/secret | jq
{
  "key": "secret",
  "value": "hello-new"
}
```
