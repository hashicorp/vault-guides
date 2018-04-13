# spring-vault-demo

Java example for dynamic secrets and transit (encryption) using Spring and [Spring Cloud Vault](https://cloud.spring.io/spring-cloud-vault)

Check out our HashiCorp Webinar: https://www.youtube.com/watch?v=NxL2-XuZ3kc

You will need a Postgres instance for this application. See the [Postgres script](scripts/postgres.sql) for the sample table.

The [vault script](scripts/vault.sh) has a sample config for your Vault.

You can run the sample as standalone Java application. See the [bootstrap](bootstrap.yaml) for a sample config. Alternatively the [Nomad](nomad) and [Kubernetes](kubernetes) folders provide sample container platform deployments. Any additional config for those platforms is located in the folder.

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
