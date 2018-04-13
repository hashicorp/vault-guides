# spring-vault-demo

Java example for [dynamic secrets](https://www.vaultproject.io/intro/getting-started/dynamic-secrets.html) and [transit encryption](https://www.vaultproject.io/docs/secrets/transit/) using [Spring Cloud Vault](https://cloud.spring.io/spring-cloud-vault)

Check out our HashiCorp Webinar: https://www.youtube.com/watch?v=NxL2-XuZ3kc

## Overview

You can run the sample as a standalone Java application.

1. Run the [Postgres script](scripts/postgres.sql) at your Postgres instance.
2. Run the [vault script](scripts/vault.sh) at your Vault instance.
3. Update the [bootstrap](bootstrap.yaml) file for your enviornment.

## Deployment Platforms

The [Nomad](nomad) and [Kubernetes](kubernetes) folders provide sample container platform deployments. Any additional config for those platforms is located in the folder.

## API USE

- Get Orders
```
$ curl -X GET \
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
$ curl -X POST \
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
$ curl -i -X DELETE http://localhost:8080/api/orders
    HTTP/1.1 200
    Content-Length: 0
    Date: Fri, 13 Apr 2018 21:50:43 GMT
```
