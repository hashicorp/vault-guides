#!/usr/bin/env bash

# Create ssh key pair
ssh-keygen -f /home/vagrant/.ssh/id_rsa -t rsa -N ''

# Trust CA certificate in known_hosts
cat /vagrant/CA_certificate >> /home/vagrant/.ssh/known_hosts
rm -f /vagrant/CA_certificate

# Authenticate to Vault
vault login -method=userpass username=johnsmith password=test

cat /home/vagrant/.ssh/id_rsa.pub | \
  vault write -format=json ssh-client-signer/sign/clientrole public_key=- \
  | jq -r '.data.signed_key' > /home/vagrant/.ssh/id_rsa-cert.pub

chmod 0400 /home/vagrant/.ssh/id_rsa-cert.pub

echo "To use the new cert you can use the following command"
echo "ssh vault"
