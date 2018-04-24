#!/bin/bash

PCF_ORG=
: ${PCF_ORG:?"Need to set PCF_ORG non-empty"}
PCF_SPACE=
: ${PCF_SPACE:?"Need to set PCF_SPACE non-empty"}
DOCKER_IMAGE=
: ${DOCKER_IMAGE:?"Need to set DOCKER_IMAGE non-empty"}
PCF_VAULT_SERVICE_BROKER_NAME=
: ${PCF_VAULT_SERVICE_BROKER_NAME:?"Need to set PCF_VAULT_SERVICE_BROKER_NAME non-empty"}
PCF_APP_NAME=
: ${PCF_APP_NAME:?"Need to set PCF_APP_NAME non-empty"}
POSTGRES_DB_URL=
: ${POSTGRES_DB_URL:?"Need to set POSTGRES_DB_URL non-empty"}
POSTGRES_DB_NAME=postgres
: ${POSTGRES_DB_NAME:?"Need to set POSTGRES_DB_NAME non-empty"}

# Dynamically creates bootstrap.yaml based on env vars
echo "Creating bootstrap.yaml based on env vars ..."
echo $PCF_VAULT_SERVICE_BROKER_NAME
sed -e "s#PCF_VAULT_SERVICE_BROKER_NAME#$PCF_VAULT_SERVICE_BROKER_NAME#g" \
    -e "s#PCF_APP_NAME#$PCF_APP_NAME#g" \
    -e "s#POSTGRES_DB_URL#$POSTGRES_DB_URL#g" \
    -e "s#POSTGRES_DB_NAME#$POSTGRES_DB_NAME#g" \
    bootstrap.yaml.template > bootstrap.yaml


#Build
mvn package -f ../pom.xml
#Package
cp ../target/spring-vault-demo-1.0.jar .
#Push
docker build --build-arg JAR_FILE=spring-vault-demo-1.0.jar -t $DOCKER_IMAGE .
docker push $DOCKER_IMAGE
#Cloud Foundry
cf target -o $PCF_ORG -s $PCF_SPACE
cf enable-feature-flag diego_docker
cf push --no-start $PCF_APP_NAME --docker-image $DOCKER_IMAGE
cf bind-service  $PCF_APP_NAME $PCF_VAULT_SERVICE_BROKER_NAME
cf start $PCF_APP_NAME
#Clean Up
rm -f spring-vault-demo-1.0.jar
