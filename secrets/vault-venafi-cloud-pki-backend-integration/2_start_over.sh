#!/bin/bash

# Kill Vault if it is alreay running and remove secrets directory used for storage

ps aux | grep "[v]ault server" | awk '{print $2}' | xargs kill 2> /dev/null

pushd $(dirname $0) > /dev/null
DIR=$(pwd)

if [ -d ./secrets ]; then
   rm -Rf ./secrets
fi

mkdir ./secrets

# Configure the plugin directory for your Vault by specifying it in the startup configuration file
# In this example plugin_directory = "/etc/vault/plugins" is used
# File storage backend is used. In production, use a supported backend like consul

cat >vault.hcl <<EOF
disable_mlock = true
listener "tcp" {
 address = "0.0.0.0:8200"
 tls_disable = 1
}

backend "file" {
 path = "$DIR/secrets"
}
plugin_directory = "/etc/vault/plugins"
api_addr = "http://127.0.0.1:8200" 
EOF

# Start Vault in the background. In a production deployment, use systemd as discussed in deployment guide.
nohup vault server -config=vault.hcl >vault.log 2>&1 &
