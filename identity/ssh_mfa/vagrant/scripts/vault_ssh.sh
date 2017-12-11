#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}


vault auth password

logger "Configuring Vault SSH CA backend"
# Mount a backend's instance for signing host keys
vault mount -path ssh-host-signer ssh

# Mount a backend's instance for signing client keys
vault mount -path ssh-client-signer ssh

# Configure the host CA certificate
vault write -f -format=json ssh-host-signer/config/ca | jq -r '.data.public_key' > /home/vagrant/host_CA_certificate_raw
echo "@cert-authority *.example.com $(cat /home/vagrant/host_CA_certificate_raw)" > /vagrant/CA_certificate

# Configure the client CA certificate
vault write -f -format=json ssh-client-signer/config/ca | jq -r '.data.public_key' > /home/vagrant/trusted-user-ca-keys.pem
cp /home/vagrant/trusted-user-ca-keys.pem /vagrant/trusted-user-ca-keys.pem

# Allow host certificate to have longer TTLs
vault mount-tune -max-lease-ttl=87600h ssh-host-signer

# Create a role to sign host keys
vault write ssh-host-signer/roles/hostrole ttl=87600h \
  allow_host_certificates=true \
  key_type=ca \
  allowed_domains="localdomain,example.com" \
  allow_subdomains=true

  echo '
  {
    "allow_user_certificates": true,
    "allowed_users": "*",
    "default_extensions": [
      {
        "permit-pty": ""
      }
    ],
    "key_type": "ca",
    "key_id_format": "vault-{{role_name}}-{{token_display_name}}-{{public_key_hash}}",
    "default_user": "vagrant",
    "ttl": "30m0s"
  }' > /home/vagrant/clientrole.json

# Create a role to sign client keys
vault write ssh-client-signer/roles/clientrole @/home/vagrant/clientrole.json


logger "Configuring Vault SSH OTP backend"
vault mount ssh
vault write ssh/roles/otp_key_role \
  key_type=otp \
  default_user=vagrant \
  cidr_list=192.168.50.102/32

sudo systemctl restart sshd
