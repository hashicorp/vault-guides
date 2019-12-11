#!/usr/bin/env bash
set -x
exec > >(tee /var/log/tf-user-data.log|logger -t user-data ) 2>&1

# Install jq
# sudo curl --silent -Lo /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
# sudo chmod +x /bin/jq
sudo apt-get install jq

# Write AppRole RoleID
echo -e "APPROLE_ROLEID=${tpl_role_id}" >> /etc/environment

# Write Vault address
echo "VAULT_ADDR=${tpl_vault_addr}" >> /etc/environment

# Signal when Terraform user_data is finished
# https://github.com/hashicorp/terraform/issues/4668
touch /tmp/signal
