#!/bin/bash

export PCF_ORG=
: ${PCF_ORG:?"Need to set PCF_ORG non-empty"}
export PCF_SPACE=
: ${PCF_SPACE:?"Need to set PCF_SPACE non-empty"}
export DOCKER_IMAGE=lanceplarsen/spring-vault-cf
: ${DOCKER_IMAGE:?"Need to set DOCKER_IMAGE non-empty"}
export PCF_VAULT_SERVICE_BROKER_NAME=
: ${PCF_VAULT_SERVICE_BROKER_NAME:?"Need to set PCF_VAULT_SERVICE_BROKER_NAME non-empty"}
export PCF_APP_NAME=
: ${PCF_APP_NAME:?"Need to set PCF_APP_NAME non-empty"}

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
