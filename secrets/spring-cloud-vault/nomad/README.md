# spring-vault-demo-nomad

This folder will help you deploy the sample app to Nomad.

We've included three sample *.nomad projects to help you deploy this application. In this example, we deploy the container image, but you could also run this as a jar with the [java driver](https://www.nomadproject.io/docs/drivers/java.html).

The static and dynamic Nomad examples leverage Nomad's [template feature](https://www.nomadproject.io/docs/job-specification/template.html) to manage the lifecycle of secret and tokens for our application. The inmem Nomad example handles the lifecycle in application memory. Vault is flexible in your integration approach.

You can see the bootstrap config directly in the job file for each of the Nomad samples.

We need to add entries to Consul and Vault for our jobs to run.

```
vault write secret/order/postgres username=postgres password=postgres
consul kv put postgres/jdbc jdbc:postgresql://localhost:5432/postgres
```

These job templates also assume Nomad client nodes are Consul DNS aware. Alternatively you can supply the Vault address and JDBC directly in the job files are strings.  See example below.


```
spring.application.name: spring-vault-demo
spring.cloud.vault:
    authentication: TOKEN
    token: ${VAULT_TOKEN}
    host: localhost
    port: 8200
    scheme: http
    fail-fast: true
    config.lifecycle.enabled: true
    database:
        enabled: true
        role: order
        backend: database
spring.datasource:
  url: jdbc:postgresql://localhost:5432/postgres
```
