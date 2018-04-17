# spring-vault-demo

Java example for [dynamic secrets](https://www.vaultproject.io/intro/getting-started/dynamic-secrets.html) and [transit encryption](https://www.vaultproject.io/docs/secrets/transit/) using [Spring Cloud Vault](https://cloud.spring.io/spring-cloud-vault)

Check out our HashiCorp Webinar: https://www.hashicorp.com/resources/solutions-engineering-webinar-series-episode-2-vault

## Overview

You can run the sample as a standalone Java application. You will need a Vault instance and a Postgres instance to get started.

1. Run the [Postgres script](scripts/postgres.sql) at your Postgres instance.
2. Run the [Vault script](scripts/vault.sh) at your Vault instance.
3. Update the [bootstrap.yaml](bootstrap.yaml) file for your enviornment.
4. Run the Java application.
5. Try the API.

## Deployment Platforms
The following provides example deployments on various platforms.
- [Vagrant](vagrant-local)
- [Nomad](nomad)
- [Kubernetes](kubernetes)

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
