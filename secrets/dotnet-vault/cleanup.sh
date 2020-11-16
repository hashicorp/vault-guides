#!/bin/bash

docker-compose -f docker-compose-agent.yml down
docker-compose -f docker-compose-agent.yml rm
docker-compose down
docker-compose rm