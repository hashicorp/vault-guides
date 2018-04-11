# spring-vault-demo-nomad

This folder will help you deploy the sample app to Nomad.

We've included three sample *.nomad projects to help you deploy this application. In this example, we deploy the container image, but you could also run this as a jar with the [java driver](https://www.nomadproject.io/docs/drivers/java.html).

The static and dynamic Nomad examples leverage Nomad's [template feature](https://www.nomadproject.io/docs/job-specification/template.html) to manage the lifecycle of secret and tokens for our application. The inmem Nomad example handles the lifecycle in application memory. Vault is flexible in your integration approach.

You can see the bootstrap config directly in the job file for each of the Nomad samples.

We need to add entries to Consul and Vault for our jobs to run. See example below.

```
vault write secret/order/postgres username=postgres password=postgres
consul kv put postgres/jdbc jdbc:postgresql://localhost:5432/postgres
```
