# Spring example with Spring Cloud Vault and Cloud Foundry.

## Description
App that shows the following functions:
- PCF integration with Vault using service broker
- Reading Vault static secrets on appId generic path
- Reading Vault static secrets on orgId generic path
- Vault dynamic credentials
- Vault transit backend

This app will upload a Docker image to your Docker hub repository, with a sample java Spring applciation that uses Vault. Then it will deploy this image as a PCF app.

## Requirements:
- A Vault server configured with transit backend.  See [vault config](external/vault_config.sh)
- A Postgres DB secret engine with configured Vault roles. See [vault config](external/vault_config.sh)
- A Postgres DB with the "order" table. See [sql query](external/postgres.sql)
- A PCF env with Vault Service Broker

Reference: https://github.com/hashicorp/vault-service-broker

![picture alt](https://github.com/stenio123/spring-vault-demo-cf/blob/master/VaultServiceBrokerPCF.jpg "Reference PCF Vault Service Broker ")

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

## Vault Policy
By default, the PCF Vault Service Broker only mounts the static secrets backend. In order to enable the dynamic db secrets, after you have bound the service broker follow the steps [here](https://github.com/hashicorp/vault-service-broker#granting-access-to-other-paths) to grant the app access to central DB and Transit policies. Below is an example policy.
```
path "cf/63e3e3a0-31f5-4b28-b38b-6708339df836" {
  capabilities = ["list"]
}

path "cf/63e3e3a0-31f5-4b28-b38b-6708339df836/*" {
	capabilities = ["create", "read", "update", "delete", "list"]
}

path "cf/a3abff6c-a00a-49d3-bca5-8384a9ec2299" {
  capabilities = ["list"]
}

path "cf/a3abff6c-a00a-49d3-bca5-8384a9ec2299/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "cf/32ff778e-0db4-4d24-8629-b316ba71fda4" {
  capabilities = ["list"]
}

path "cf/32ff778e-0db4-4d24-8629-b316ba71fda4/*" {
  capabilities = ["read", "list"]
}

path "transit/decrypt/order" {
  capabilities = ["update"]
}

path "transit/encrypt/order" {
  capabilities = ["update"]
}

path "database/creds/order" {
  capabilities = ["read"]
}
```
If instead you want the service broker to handle these additional backends, you can fork the repository and add paths [here](https://github.com/hashicorp/vault-service-broker/blob/dfe5aaca53aa805e6cd2dd7f703603670594787b/broker.go#L338)

## Seeding Static Secrets:
This application uses Spring Boot Vault to interact with Vault. For complete documentation follow this [link](http://cloud.spring.io/spring-cloud-static/spring-cloud-vault/2.0.0.M4/)

To seed secrets:
```
export VAULT_ADDR=ADDRESS_TO_YOUR_VAULT_SERVER
export VAULT_TOKEN=YOUR_APP_TOKEN
export PCF_ORG_ID=YOUR_PCF_ORG_ID
export PCF_APP_ID=YOUR_PCF_APP_ID

curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @external/appId.json \
    $VAULT_ADDR/v1/cf/$PCF_APP_ID/secret/cf-spring-vault

curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @external/orgId.json \
    $VAULT_ADDR/v1/cf/$PCF_ORG_ID/secret/shared
```    

To read the secrets:
```
http://cf-spring-vault-busy-roan.apps.pcf-environment.spacelyspacesprockets.info/api/orders/app_secret

http://cf-spring-vault-busy-roan.apps.pcf-environment.spacelyspacesprockets.info/api/orders/org_secret
```

## Dynamic DB Credentials and Transit Backend:
Once deployed, the following API endpoints will be available:

POST:
* The post function will create an order with customer and product info
* The application is securely introduced to Vault via the broker
* The application uses dynamic DB credentials retrieved by Spring Cloud Vault
* The application uses the Vault transit backend to encrypt customer name
* The encrypted order is persisted to the DB.

Example call:
```
curl -k -X POST https://cf-spring-vault.apps.ll.pcf.com/api/orders -H 'content-type: application/json' -d '{"customerName": "lance", "productName": "vault-ent"}' | jq
```
Example response:
```
{
  "id": 59,
  "customerName": "lance",
  "productName": "vault-ent",
  "orderDate": 1520878732443
}
```

* The get function will return all customer order info
* The application is securely introduced to Vault via the broker
* The application uses dynamic DB credentials retrieved by Spring Cloud Vault
* The application decrypts all customer records
* The decrypted orders are returned in the API.

Example call:
```
curl -k https://cf-spring-vault.apps.ll.pcf.com/api/orders | jq
```

Example response:
```
[
  {
    "id": 58,
    "customerName": "lance",
    "productName": "vault-ent",
    "orderDate": 1520878677996
  }
]
```