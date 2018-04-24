# spring-vault-demo-pcf

This folder will help you deploy the sample app to Pivotal Cloud Foundry PCF.

## Requirements
- A PCF environment with Vault PCF Service Broker deployed and configured. More information about the service broker can be found [here](https://www.hashicorp.com/blog/cloud-foundry-vault-service-broker)
- A properly configured Vault. Make sure you run this [script](../scripts/vault.sh)
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
```
- Login to PCF by issuing the command
```
cf login -a https://api.sys.YOUR_PCF_URL -u YOUR_USER_NAME --skip-ssl-validation
```
- Execute
```
./deploy.sh
```