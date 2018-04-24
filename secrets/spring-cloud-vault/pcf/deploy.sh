#!/bin/bash

#Build
mvn package -f ../pom.xml
#Package
cp ../target/spring-vault-demo-1.0.jar .
#Push
docker build --build-arg JAR_FILE=spring-vault-demo-1.0.jar -t lanceplarsen/spring-vault-cf .
docker push lanceplarsen/spring-vault-cf
#Cloud Foundry
cf enable-feature-flag diego_docker
cf push --no-start cf-spring-vault-demo-ll --docker-image lanceplarsen/spring-vault-cf
cf bind-service  cf-spring-vault-demo-ll ll-vault
cf start cf-spring-vault-demo-ll
#Clean Up
rm -f spring-vault-demo-1.0.jar
