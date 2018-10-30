#!/usr/bin/env bash

sudo apt-get install -y unzip libtool libltdl-dev

curl -s -L -o ~/vault.zip https://releases.hashicorp.com/vault/1.0.0-beta1/vault_1.0.0-beta1_linux_amd64.zip
sudo unzip ~/vault.zip
sudo install -c -m 0755 vault /usr/bin

sudo mkdir -p /test/vault

sudo cat << EOF > /lib/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/vault server -config=/test/vault/config.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


sudo cat << EOF > /test/vault/config.hcl
storage "file" {
  path = "/opt/vault"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = 1
}

seal "gcpckms" {
  project     = "<PROJECT_ID>"
  region      = "global"
  key_ring    = "test"
  crypto_key  = "vault-test"
}

disable_mlock = true
EOF


sudo chmod 0664 /lib/systemd/system/vault.service

sudo tee /etc/profile.d/vault.sh > /dev/null <<"EOF"
alias v="vault"
alias vualt="vault"
export VAULT_ADDR="http://127.0.0.1:8200"
EOF
source /etc/profile.d/vault.sh

sudo systemctl enable vault
sudo systemctl start vault
