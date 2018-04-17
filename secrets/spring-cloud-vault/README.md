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

## Refreshing Static Secrets
Spring has an actuator we can use to facilitate the rotation of static credentials. Example below.

1. Create the old secret.
```
$ curl -i  \
    --header "X-Vault-Token: root" \
    --request POST \
    --data '{"secret":"hello-old"}' \
    http://localhost:8200/v1/secret/spring-vault-demo
  HTTP/1.1 204 No Content
  Cache-Control: no-store
  Content-Type: application/json
  Date: Tue, 17 Apr 2018 00:47:55 GMT
```

2. Read the old secret.
```
$ curl http://localhost:8080/api/secret | jq
{
  "key": "secret",
  "value": "hello-old"
}
```

3.Create the new secret.
```
$ curl -i  \
    --header "X-Vault-Token: root" \
    --request POST \
    --data '{"secret":"hello-new"}' \
    http://localhost:8200/v1/secret/spring-vault-demo
  HTTP/1.1 204 No Content
  Cache-Control: no-store
  Content-Type: application/json
  Date: Tue, 17 Apr 2018 00:47:55 GMT
```

4. Rotate the secret.
```
$ curl -X POST http://localhost:8080/actuator/refresh | jq
[
  "secret"
]
```

5.Read the new secret.
```
$ curl http://localhost:8080/api/secret | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    36    0    36    0     0   3600      0 --:--:-- --:--:-- --:--:--  3600
{
  "key": "secret",
  "value": "hello-new"
}
```
