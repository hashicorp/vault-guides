# Java Sample App using Spring Cloud Vault

These assets are provided to perform the tasks described in the [Java Application Demo](https://learn.hashicorp.com/vault/developer/eaas-spring-demo) guide.


Originally, this app was demonstrated during the [Manage secrets, access, and encryption in the public cloud
with Vault](https://www.hashicorp.com/resources/solutions-engineering-webinar-series-episode-2-vault)
webinar.


----


## Demo Instruction

To keep it simple and lightweight, the [Java Sample App using Spring Cloud Vault](https://learn.hashicorp.com/vault/developer/eaas-spring-demo) guide used **Vagrant** to demonstrate the app.  This repository also provides example deployments on various platforms:

- [Nomad](nomad)
- [Kubernetes](kubernetes)
- [Pivotal Cloud Foundry](pcf)
- [Vagrant](vagrant-local)
- [AWS](aws)
<br>

### Setup

You can run the sample as a standalone Java application. You will need a Vault instance and a Postgres instance to get started.

1. Run the [Postgres script](scripts/postgres.sql) at your Postgres instance.
2. Run the [Vault script](scripts/vault.sh) at your Vault instance.
3. Update the [bootstrap.yaml](bootstrap.yaml) file for your environment.
4. Run the Java application.
5. Try the API.



### API

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

### Refreshing Static Secrets

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
