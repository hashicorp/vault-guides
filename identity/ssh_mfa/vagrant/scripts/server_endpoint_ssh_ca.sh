#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}


#Auth
vault auth password

sudo rm -f /etc/ssh/ssh_host*
sudo dpkg-reconfigure openssh-server

# Sign the host key
sudo cat /etc/ssh/ssh_host_rsa_key.pub | vault write -format=json \
  ssh-host-signer/sign/hostrole public_key=- \
  cert_type=host | jq -r ".data.signed_key" | sudo tee /etc/ssh/ssh_host_rsa_key-cert.pub

#SSHD config
sudo chmod 600 /etc/ssh/ssh_host_*

sudo cp /vagrant/trusted-user-ca-keys.pem /etc/ssh/trusted-user-ca-keys.pem
sudo echo "TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem" | sudo tee --append /etc/ssh/sshd_config
echo "HostKey /etc/ssh/ssh_host_rsa_key.pub " | sudo tee --append /etc/ssh/sshd_config
echo "HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub" | sudo tee --append /etc/ssh/sshd_config

sudo systemctl restart sshd
