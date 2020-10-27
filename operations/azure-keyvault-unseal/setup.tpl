#!/bin/bash
# NB this file will be executed as root by cloud-init.
# NB to troubleshoot the execution of this file, you can:
#      1. access the virtual machine boot diagnostics pane in the azure portal.
#      2. ssh into the virtual machine and execute:
#           * sudo journalctl
#           * sudo journalctl -u cloud-final
set -euxo pipefail

ip_address="$(ip addr show eth0 | perl -n -e'/ inet (\d+(\.\d+)+)/ && print $1')"

# install vault.
# NB execute `apt-cache madison vault` to known the available versions.
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get install -y "vault=${vault_version}" jq
cat >/etc/vault.d/vault.hcl <<EOF
ui = true
disable_mlock = true

api_addr = "http://$ip_address:8200"
cluster_addr = "http://$ip_address:8201"

storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = 1
  telemetry {
    unauthenticated_metrics_access = true
  }
}

# enable the telemetry endpoint.
# access it at http://<VAULT-IP-ADDRESS>:8200/v1/sys/metrics?format=prometheus
# see https://www.vaultproject.io/docs/configuration/telemetry
# see https://www.vaultproject.io/docs/configuration/listener/tcp#telemetry-parameters
telemetry {
   disable_hostname = true
   prometheus_retention_time = "24h"
}

# enable auto-unseal using the azure key vault.
seal "azurekeyvault" {
  client_id      = "${client_id}"
  client_secret  = "${client_secret}"
  tenant_id      = "${tenant_id}"
  vault_name     = "${vault_name}"
  key_name       = "${key_name}"
}
EOF
systemctl enable vault
systemctl restart vault

cat >/etc/profile.d/vault.sh <<'EOF'
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true
EOF

# TODO why isn't this in $HOME?
cat >/tmp/azure_auth.sh <<'EOF'
#!/bin/bash
set -euxo pipefail

# for more information see:
#   * https://www.vaultproject.io/docs/auth/azure
#   * https://www.vaultproject.io/api/auth/azure

vault auth enable azure

vault write auth/azure/config \
  tenant_id="${tenant_id}" \
  resource="https://management.azure.com/" \
  client_id="${client_id}" \
  client_secret="${client_secret}"

vault write auth/azure/role/dev-role \
  policies="default" \
  bound_subscription_ids="${subscription_id}" \
  bound_resource_groups="${resource_group_name}"

# create a vault login token for the current virtual machine identity (as
# returned by the azure instance metadata service).
# NB use the returned token to login into vault using `vault login`.
# see https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-use-vm-token
# see https://docs.microsoft.com/en-us/azure/virtual-machines/linux/instance-metadata-service
vault write auth/azure/login \
  role="dev-role" \
  jwt="$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true -s | jq -r .access_token)" \
  subscription_id="${subscription_id}" \
  resource_group_name="${resource_group_name}" \
  vm_name="${vm_name}"
EOF
chmod +x /tmp/azure_auth.sh
