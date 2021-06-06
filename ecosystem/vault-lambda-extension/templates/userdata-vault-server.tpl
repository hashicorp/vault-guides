#!/usr/bin/env bash
set -x
exec > >(tee /var/log/tf-user-data.log|logger -t user-data ) 2>&1

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Running"

##--------------------------------------------------------------------
## Variables

# Get Private IP address
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

VAULT_ZIP="${tpl_vault_zip_file}"

AWS_REGION="${tpl_aws_region}"
KMS_KEY="${tpl_kms_key}"

##--------------------------------------------------------------------
## Functions

user_ubuntu() {
  # UBUNTU user setup
  if ! getent group $${USER_GROUP} >/dev/null
  then
    sudo addgroup --system $${USER_GROUP} >/dev/null
  fi

  if ! getent passwd $${USER_NAME} >/dev/null
  then
    sudo adduser \
      --system \
      --disabled-login \
      --ingroup $${USER_GROUP} \
      --home $${USER_HOME} \
      --no-create-home \
      --gecos "$${USER_COMMENT}" \
      --shell /bin/false \
      $${USER_NAME}  >/dev/null
  fi
}

##--------------------------------------------------------------------
## Install Base Prerequisites

logger "Setting timezone to UTC"
sudo timedatectl set-timezone UTC

logger "Performing updates and installing prerequisites"
sudo apt-get -qq -y update
sudo apt-get install -qq -y wget unzip ntp jq
sudo systemctl start ntp.service
sudo systemctl enable ntp.service
logger "Disable reverse dns lookup in SSH"
sudo sh -c 'echo "\nUseDNS no" >> /etc/ssh/sshd_config'
sudo service ssh restart

##--------------------------------------------------------------------
## Configure Vault user

USER_NAME="vault"
USER_COMMENT="HashiCorp Vault user"
USER_GROUP="vault"
USER_HOME="/srv/vault"

logger "Setting up user $${USER_NAME} for Debian/Ubuntu"
user_ubuntu

##--------------------------------------------------------------------
## Install Vault

logger "Downloading Vault"
curl -o /tmp/vault.zip $${VAULT_ZIP}

logger "Installing Vault"
sudo unzip -o /tmp/vault.zip -d /usr/local/bin/
sudo chmod 0755 /usr/local/bin/vault
sudo chown vault:vault /usr/local/bin/vault
sudo mkdir -pm 0755 /etc/vault.d
sudo mkdir -pm 0755 /etc/ssl/vault

logger "/usr/local/bin/vault --version: $(/usr/local/bin/vault --version)"

logger "Configuring Vault"
sudo tee /etc/vault.d/vault.hcl <<EOF
storage "file" {
    path = "/srv/vault/data"
}

listener "tcp" {
  address     = "$${PRIVATE_IP}:8200"
  tls_disable = 1
}

seal "awskms" {
  region = "$${AWS_REGION}"
  kms_key_id = "$${KMS_KEY}"
}

ui=true
EOF

sudo chown -R vault:vault /etc/vault.d /etc/ssl/vault
sudo chmod -R 0644 /etc/vault.d/*

sudo tee -a /etc/environment <<EOF
export VAULT_ADDR=http://$${PRIVATE_IP}:8200
export VAULT_SKIP_VERIFY=true
export DB_HOST=${tpl_rds_address}
export AWS_ACCOUNT_ID=${tpl_account_id}
export AWS_IAM_ROLE_LAMBDA_NAME="${tpl_role_name}"

EOF

source /etc/environment

logger "Granting mlock syscall to vault binary"
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

##--------------------------------------------------------------------
## Install Vault Systemd Service

read -d '' VAULT_SERVICE <<EOF
[Unit]
Description=Vault Agent
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/local/bin/vault
ExecStart=/usr/local/bin/vault server -config /etc/vault.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=vault
Group=vault

[Install]
WantedBy=multi-user.target

EOF

SYSTEMD_DIR="/lib/systemd/system"
logger "Installing systemd services for Debian/Ubuntu"
echo "$${VAULT_SERVICE}" | sudo tee $${SYSTEMD_DIR}/vault.service
sudo chmod 0664 $${SYSTEMD_DIR}/vault*
sudo mkdir -p $${USER_HOME}
sudo chown vault: $${USER_HOME}

sudo systemctl enable vault
sudo systemctl start vault

vault status
# Wait until vault status serves the request and responds that it is sealed
while [[ $? -ne 2 ]]; do sleep 1 && vault status; done

##--------------------------------------------------------------------
## Configure Vault
##--------------------------------------------------------------------

# NOT SUITABLE FOR PRODUCTION USE
export VAULT_TOKEN="$(vault operator init -format json | jq -r '.root_token')"
sudo cat >> /etc/environment <<EOF
export VAULT_TOKEN=$${VAULT_TOKEN}
EOF

# Set up RDS dynamic credentials
vault secrets enable database
vault write database/config/postgres \
  plugin_name="postgresql-database-plugin" \
  allowed_roles="lambda-*" \
  connection_url="postgres://{{username}}:{{password}}@${tpl_rds_endpoint}/lambdadb" \
  username="vaultadmin" \
  password="${tpl_rds_admin_password}"


# WARNING: Creating credentials this way eventually will max out the table
# Instead create a role that has this grant and have the new credentials
# inherit from that role.
# @see https://learn.hashicorp.com/tutorials/vault/database-secrets
vault write database/roles/lambda-function \
  db_name="postgres" \
  default_ttl="1h" max_ttl="24h" \
  creation_statements=- << EOF
CREATE ROLE "{{name}}" WITH LOGIN ENCRYPTED PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
EOF

# Install the database CLI
sudo apt install postgresql-client -y

logger "Complete"

# There is a remote-exec provisioner in terraform watching for this file
touch /tmp/user-data-completed
