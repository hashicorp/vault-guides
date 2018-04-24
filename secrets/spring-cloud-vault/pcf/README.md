# spring-vault-demo-pcf

This folder will help you deploy the sample app to Pivotal Cloud Foundry PCF.

## Requirements
- A PCF environment with Vault PCF Service Broker deployed and configured. More information about the service broker can be found [here](https://www.hashicorp.com/blog/cloud-foundry-vault-service-broker)
- A properly configured Vault. Make sure you run this [script](../scripts/vault.sh). You will need to update the DB connection string.
- A properly configured Postgres DB with the "order" table. Make sure you run this [script](../scripts/postgres.sql)
- Docker properly configured in your machine, with access to Docker Hub to push the image. More information [here](https://docs.docker.com/docker-hub/)
- Maven installed in your machine, to generate the jar file. More information [here](https://maven.apache.org/install.html)
- cf client installed in your machine. More information [here](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)

## Deployment
- Enter the following environment variables in (deploy.sh)[deploy.sh]:
```
PCF_ORG: Name of the PCF org where you want your app deployed
PCF_SPACE: Name of the PCF space where you want your app deployed
DOCKER_IMAGE: Name of your docker hub repository and an image name. Example: lanceplarsen/spring-vault-cf
PCF_VAULT_SERVICE_BROKER_NAME: Name of your Vault service broker. Example: vault
PCF_APP_NAME: A name for your app. This name must ber unique across all organizations of the PCF where the app is being deployed.
POSTGRES_DB_URL: URL for the database that Vault is configured to work with , per [vault.sh](../scripts/vault.sh). Example: MYDB.us-east-1.rds.amazonaws.com:5432
POSTGRES_DB_NAME: Name of the database that Vault is configured to work with, per [vault.sh](../scripts/vault.sh). Example: postgres
```
- Login to docker hub by issuing the command
```
docker login -u YOUR_USERNAME -p YOUR_PASSWORD
```
- Login to PCF by issuing the command
```
cf login -a https://api.sys.YOUR_PCF_URL -u YOUR_USER_NAME --skip-ssl-validation
```
- Execute
```
./deploy.sh
```

Note: when creating the static secret in Vault to use as described in the [README](../README.md), make sure $PCF_APP_NAME matches tone of the values found in [bootstrap.yaml](bootstrap.yaml.template) *application-name*
```
$ curl -s \
   --header "X-Vault-Token: ${VAULT_TOKEN}" \
   --request POST \
   --data '{"secret":"hello-new"}' \
   --write-out "%{http_code}" ${VAULT_ADDR}/v1/secret/$PCF_APP_NAME | jq
204
```