#!/bin/bash

./build.sh
docker build -t kawsark/vault-example-init:0.0.9 .
rm vault-init
