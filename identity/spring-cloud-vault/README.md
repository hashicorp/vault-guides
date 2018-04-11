# spring-vault-demo

Java example for dynamic secrets and transit (encryption) using Spring and [Spring Cloud Vault](https://cloud.spring.io/spring-cloud-vault)

Check out our HashiCorp Webinar: https://www.youtube.com/watch?v=NxL2-XuZ3kc

You will need a Postgres instance for this application. See the [Postgres script](scripts/postgres.sql) for the sample table.

The [vault script](scripts/vault.sh) has a sample config for your Vault.

You can run the sample as standalone Java application. See the [boostrap file](bootstrap.yaml) for a sample config. Alternatively the [Nomad](nomad) and [K8s](k8s) folders provide sample container platform deployments. Any additional config for those platforms is located in the folder.
