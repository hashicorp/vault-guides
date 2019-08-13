#!/usr/bin/env bash

# Authenticate to Vault
vault login password

# Mount a backend's instance for signing host keys
vault secrets enable -path ssh-host-signer ssh

# Mount a backend's instance for signing client keys
vault secrets enable -path ssh-client-signer ssh

# Configure the host CA certificate
vault write -f -format=json ssh-host-signer/config/ca | jq -r '.data.public_key' > /home/vagrant/host_CA_certificate_raw

echo "@cert-authority *.example.com $(cat /home/vagrant/host_CA_certificate_raw)" > /vagrant/CA_certificate
cat /vagrant/CA_certificate >> /home/vagrant/.ssh/known_hosts

# Configure the client CA certificate
vault write -f -format=json ssh-client-signer/config/ca | jq -r '.data.public_key' >>  /home/vagrant/trusted-user-ca-keys.pem

sudo mv /home/vagrant/trusted-user-ca-keys.pem /etc/ssh/trusted-user-ca-keys.pem
echo "TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem" | sudo tee --append /etc/ssh/sshd_config
echo "HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub" | sudo tee --append /etc/ssh/sshd_config

# Allow host certificate to have longer TTLs
vault secrets tune -max-lease-ttl=87600h ssh-host-signer

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
  }' >> /home/vagrant/clientrole.json

# Create a role to sign client keys
vault write ssh-client-signer/roles/clientrole @/home/vagrant/clientrole.json

# Sign the host key
cat /etc/ssh/ssh_host_rsa_key.pub | vault write -format=json \
  ssh-host-signer/sign/hostrole public_key=- \
  cert_type=host | jq -r ".data.signed_key" | sudo tee /etc/ssh/ssh_host_rsa_key-cert.pub

# Restart sshd
sudo systemctl restart sshd

echo '
path "sys/mounts" {
  capabilities = ["list","read"]
}
path "ssh-client-signer/sign/clientrole" {
  capabilities = ["create", "update"]
}' | vault policy write user -

vault auth enable userpass
vault write auth/userpass/users/johnsmith password=test policies=user