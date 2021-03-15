#!/bin/bash
#
# This script demonstrates a Vault HA cluster with 5 nodes
#

# Create the server configuration files
./cluster.sh create config

# Setup the Vault server which provides unseal key
./cluster.sh setup vault_1

# Setup vault_2 server
./cluster.sh setup vault_2

# Setup vault_3 server
./cluster.sh setup vault_3

# Setup vault_4 server
./cluster.sh setup vault_4

# Setup vault_5 server
./cluster.sh setup vault_5

# Setup vault_6 server
./cluster.sh setup vault_6
