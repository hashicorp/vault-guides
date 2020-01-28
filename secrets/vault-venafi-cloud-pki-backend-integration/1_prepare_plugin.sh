#!/bin/bash

# Download the current vault-pki-backend-venafi release package for your operating system and unzip the plugin to the /etc/vault/plugins directory (or a custom directory of our choosing):
wget https://github.com/Venafi/vault-pki-backend-venafi/releases/download/0.5.2/venafi-pki-backend_0.5.2+586_linux.zip

# Unzip the plugin binary
unzip venafi-pki-backend_0.5.2+586_linux.zip

# Move the plugin binary to the /etc/vault/vault_plugins directory (or a custom directory of your choosing)
sudo mv venafi-pki-backend /etc/vault/plugins
