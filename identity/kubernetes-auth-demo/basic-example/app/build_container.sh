#!/bin/bash

./build.sh
docker build -t kawsark/vault-example-init:0.0.8 .
rm vault-init
