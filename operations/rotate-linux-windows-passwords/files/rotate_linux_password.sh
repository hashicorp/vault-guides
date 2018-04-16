#!/bin/sh
# Script for rotating passwords on the local machine.
# Make sure and store VAULT_TOKEN as an environment variable before running this.
# OPTIONAL - Clone the bashpass repository and use it to generate passphrases
# Bashpass is located here: https://github.com/joshuar/bashpass
# Requires the `hunspell` package to work.

USERNAME=$1
PASSLENGTH=$2
VAULTURL=$3
# NEWPASS=$(openssl rand -base64 $PASSLENGTH)
NEWPASS=$(bashpass -n 4)
JSON="{ \"options\": { \"max_versions\": 3 }, \"data\": { \"root\": \"$NEWPASS\" } }"

# Check for usage
if [[ $# -ne 3 ]]; then
  echo "You must include the username, password length, and Vault URL.  Example:"
  echo "$0 root 12 http://ec2-35-170-57-156.compute-1.amazonaws.com:8200"
fi

# Renew our token before we do anything else.
curl -sS --fail -X POST -H "X-Vault-Token: $VAULT_TOKEN" ${VAULTURL}/v1/auth/token/renew-self | grep -q 'lease_duration'
retval=$?
if [[ $retval -ne 0 ]]; then
  echo "Error renewing Vault token lease."
fi

# First commit the new password to vault, then capture the exit status
curl -sS --fail -X POST -H "X-Vault-Token: $VAULT_TOKEN" --data "$JSON" ${VAULTURL}/v1/secret/data/linux/$(hostname)/${USERNAME}_creds | grep -q 'request_id'
retval=$?
if [[ $retval -eq 0 ]]; then
  # After we save the password to vault, update it on the instance
  echo $NEWPASS | passwd root --stdin
  retval=$?
    if [[ $retval -eq 0 ]]; then
      echo -e "${USERNAME}'s password was stored in Vault and updated locally."
    else
      echo "Error: ${USERNAME}'s password was stored in Vault but *not* updated locally."
    fi
else
  echo "Error saving new password to Vault. Local password will remain unchanged."
  exit 1
fi