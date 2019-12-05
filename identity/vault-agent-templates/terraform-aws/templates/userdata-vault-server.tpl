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
#HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/hostname)
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
#PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

VAULT_ZIP="${tpl_vault_zip_file}"
CONSUL_ZIP="${tpl_consul_zip_file}"

AWS_REGION="${tpl_aws_region}"
KMS_KEY="${tpl_kms_key}"
CONSUL_BOOSTRAP_EXPECT="${tpl_consul_bootstrap_expect}"

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

##--------------------------------------------------------------------
## Functions

user_rhel() {
  # RHEL/CentOS user setup
  sudo /usr/sbin/groupadd --force --system $${USER_GROUP}

  if ! getent passwd $${USER_NAME} >/dev/null ; then
    sudo /usr/sbin/adduser \
      --system \
      --gid $${USER_GROUP} \
      --home $${USER_HOME} \
      --no-create-home \
      --comment "$${USER_COMMENT}" \
      --shell /bin/false \
      $${USER_NAME}  >/dev/null
  fi
}

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

if [[ ! -z $${YUM} ]]; then
  logger "RHEL/CentOS system detected"
  logger "Performing updates and installing prerequisites"
  sudo yum-config-manager --enable rhui-REGION-rhel-server-releases-optional
  sudo yum-config-manager --enable rhui-REGION-rhel-server-supplementary
  sudo yum-config-manager --enable rhui-REGION-rhel-server-extras
  sudo yum -y check-update
  sudo yum install -q -y wget unzip bind-utils ruby rubygems ntp jq
  sudo systemctl start ntpd.service
  sudo systemctl enable ntpd.service
elif [[ ! -z $${APT_GET} ]]; then
  logger "Debian/Ubuntu system detected"
  logger "Performing updates and installing prerequisites"
  sudo apt-get -qq -y update
  sudo apt-get install -qq -y wget unzip dnsutils ruby rubygems ntp jq
  sudo systemctl start ntp.service
  sudo systemctl enable ntp.service
  logger "Disable reverse dns lookup in SSH"
  sudo sh -c 'echo "\nUseDNS no" >> /etc/ssh/sshd_config'
  sudo service ssh restart
else
  logger "Prerequisites not installed due to OS detection failure"
  exit 1;
fi

##--------------------------------------------------------------------
## Install AWS-Specific Prerequisites

if [[ ! -z $${YUM} ]]; then
  logger "RHEL/CentOS system detected"
  logger "Performing updates and installing prerequisites"
  curl --silent -O https://bootstrap.pypa.io/get-pip.py
  sudo python get-pip.py
  sudo pip install awscli
elif [[ ! -z $${APT_GET} ]]; then
  logger "Debian/Ubuntu system detected"
  logger "Performing updates and installing prerequisites"
  sudo apt-get -qq -y update
  sudo apt-get install -qq -y awscli
else
  logger "AWS Prerequisites not installed due to OS detection failure"
  exit 1;
fi

##--------------------------------------------------------------------
## Configure Consul user

USER_NAME="consul"
USER_COMMENT="HashiCorp Consul user"
USER_GROUP="consul"
USER_HOME="/srv/consul"

if [[ ! -z $${YUM} ]]; then
  logger "Setting up user $${USER_NAME} for RHEL/CentOS"
  user_rhel
elif [[ ! -z $${APT_GET} ]]; then
  logger "Setting up user $${USER_NAME} for Debian/Ubuntu"
  user_ubuntu
else
  logger "$${USER_NAME} user not created due to OS detection failure"
  exit 1;
fi

##--------------------------------------------------------------------
## Install Consul

logger "Downloading Consul"
curl -o /tmp/consul.zip $${CONSUL_ZIP}

logger "Installing Consul"
sudo unzip -o /tmp/consul.zip -d /usr/local/bin/
sudo chmod 0755 /usr/local/bin/consul
sudo chown consul:consul /usr/local/bin/consul
# Config dir
sudo mkdir -pm 0755 /etc/consul.d
# Storage dir
sudo mkdir -pm 0755 /opt/consul
# SSL dir (optional)
sudo mkdir -pm 0755 /etc/ssl/consul

logger "/usr/local/bin/consul --version: $(/usr/local/bin/consul --version)"

logger "Configuring Consul"

# Consul Client Config
sudo tee /etc/consul.d/consul-default.json <<EOF
{
  "datacenter": "${tpl_consul_dc}",
  "data_dir": "/opt/consul/data",
  "bind_addr": "$${PRIVATE_IP}",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "retry_join": ["provider=aws tag_key=ConsulDC tag_value=${tpl_consul_dc}"]
}
EOF

# Consul Server Config
sudo tee /etc/consul.d/consul-server.json <<EOF
{
  "server": true,
  "bootstrap_expect": $${CONSUL_BOOSTRAP_EXPECT}
}
EOF

sudo chown -R consul:consul /etc/consul.d /opt/consul /etc/ssl/consul
sudo chmod -R 0644 /etc/consul.d/*

##--------------------------------------------------------------------
## Create Consul Systemd Service

# Service Definition
read -d '' CONSUL_SERVICE <<EOF
[Unit]
Description=Consul Agent

[Service]
Restart=on-failure
ExecStart=/usr/local/bin/consul agent -config-dir /etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=consul
Group=consul

[Install]
WantedBy=multi-user.target
EOF

if [[ ! -z $${YUM} ]]; then
  SYSTEMD_DIR="/etc/systemd/system"
  logger "Installing systemd services for RHEL/CentOS"
  echo "$${CONSUL_SERVICE}" | sudo tee $${SYSTEMD_DIR}/consul.service
  sudo chmod 0664 $${SYSTEMD_DIR}/consul*
elif [[ ! -z $${APT_GET} ]]; then
  SYSTEMD_DIR="/lib/systemd/system"
  logger "Installing systemd services for Debian/Ubuntu"
  echo "$${CONSUL_SERVICE}" | sudo tee $${SYSTEMD_DIR}/consul.service
  sudo chmod 0664 $${SYSTEMD_DIR}/consul*
else
  logger "Service not installed due to OS detection failure"
  exit 1;
fi

sudo systemctl enable consul
sudo systemctl start consul

##--------------------------------------------------------------------
## Configure DNS Forwarding for Consul
## (https://www.consul.io/docs/guides/forwarding.html#dnsmasq-setup)

install_dnsmasq_rhel() {
  logger "Installing dnsmasq"
  sudo yum install -q -y dnsmasq

  configure_dnsmasq
}

install_dnsmasq_ubuntu() {
  logger "Installing dnsmasq"
  sudo apt-get -qq update
  sudo apt-get install -qq -y dnsmasq-base dnsmasq

  configure_dnsmasq
}

configure_dnsmasq() {
  logger "Configuring dnsmasq to forward .consul requests to consul port 8600"
  sudo sh -c 'echo "server=/consul/127.0.0.1#8600" >> /etc/dnsmasq.d/consul'

  sudo systemctl restart dnsmasq
}

configure_systemd_resolved() {
  # See: https://www.consul.io/docs/guides/forwarding.html#systemd-resolved-setup
  echo "DNS=127.0.0.1" | sudo tee -a /etc/systemd/resolved.conf
  echo "Domains=~consul" | sudo tee -a /etc/systemd/resolved.conf

  # We need to create and persist iptable rules to map port 53 to 8600
  # since Consul (by default) serves DNS on port 8600 and we're avoiding
  # running Consul as a privileged user
  sudo iptables -t nat -A OUTPUT -d localhost -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
  sudo iptables -t nat -A OUTPUT -d localhost -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600

  # Save these iptables rules and persist them
  # Unattended install of iptables-persistent
  echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
  echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
  sudo apt-get install iptables-persistent

  sudo systemctl restart systemd-resolved
}

# Tested on Ubuntu 16.04 and 18.04 so far
if [[ ! -z $(which yum) ]]; then
  # RHEL
  install_dnsmasq_rhel
elif [[ ! -z $(which apt-get) ]]; then
  # Ubuntu
  if [[ $(lsb_release -rs) == 16.04 ]]; then
    install_dnsmasq_ubuntu
  # Ubuntu 18.04 uses systemd-resolved as the default DNS resolver
  elif [[ $(lsb_release -rs) == 18.04 ]]; then
    configure_systemd_resolved
  else
    logger "ERROR configuring DNS forwarding for Consul: unsupported Ubuntu version found"
    exit 1;
  fi
else
  logger "ERROR configuring DNS forwarding for Consul: OS detection failure"
  exit 1;
fi

##--------------------------------------------------------------------
## Configure Vault user

USER_NAME="vault"
USER_COMMENT="HashiCorp Vault user"
USER_GROUP="vault"
USER_HOME="/srv/vault"

if [[ ! -z $${YUM} ]]; then
  logger "Setting up user $${USER_NAME} for RHEL/CentOS"
  user_rhel
elif [[ ! -z $${APT_GET} ]]; then
  logger "Setting up user $${USER_NAME} for Debian/Ubuntu"
  user_ubuntu
else
  logger "$${USER_NAME} user not created due to OS detection failure"
  exit 1;
fi

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
storage "consul" {
    service = "${tpl_vault_service_name}"
    path = "${tpl_vault_service_name}"
}

listener "tcp" {
  address     = "$${PRIVATE_IP}:8200"
  #address     = "0.0.0.0:8200"
  tls_disable = 1
}

#api_addr = "http://active.${tpl_vault_service_name}.service.${tpl_consul_dc}.consul:8200"
#cluster_addr = "https://active.${tpl_vault_service_name}.service.${tpl_consul_dc}.consul:8201"

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

if [[ ! -z $${YUM} ]]; then
  SYSTEMD_DIR="/etc/systemd/system"
  logger "Installing systemd services for RHEL/CentOS"
  echo "$${VAULT_SERVICE}" | sudo tee $${SYSTEMD_DIR}/vault.service
  sudo chmod 0664 $${SYSTEMD_DIR}/vault*
elif [[ ! -z $${APT_GET} ]]; then
  SYSTEMD_DIR="/lib/systemd/system"
  logger "Installing systemd services for Debian/Ubuntu"
  echo "$${VAULT_SERVICE}" | sudo tee $${SYSTEMD_DIR}/vault.service
  sudo chmod 0664 $${SYSTEMD_DIR}/vault*
else
  logger "Service not installed due to OS detection failure"
  exit 1;
fi

sudo systemctl enable vault
sudo systemctl start vault


##--------------------------------------------------------------------
## Shortcut script
##--------------------------------------------------------------------
cat << EOF > /home/ubuntu/data.json
{
  "organization": "ACME Inc.",
  "customer_id": "ABXX2398YZPIE7391",
  "region": "US-West",
  "zip_code": "94105",
  "type": "premium",
  "contact_email": "james@acme.com",
  "status": "active"
}
EOF


sudo cat << EOF > /home/ubuntu/aws_auth.sh
vault secrets enable -path=secret kv-v2
vault kv put secret/customers/acme @/home/ubuntu/data.json

echo "path \"secret/data/*\" {
    capabilities = [\"read\"]
}
path \"auth/token/*\" {
    capabilities = [\"create\", \"update\"]
}" | vault policy write app-pol -

vault auth enable aws
vault write -force auth/aws/config/client

vault write auth/aws/role/app-role auth_type=iam bound_iam_principal_arn="arn:aws:iam::${account_id}:role/${role_name}" policies=app-pol ttl=24h
EOF

sudo chmod +x /home/ubuntu/aws_auth.sh

logger "Complete"
