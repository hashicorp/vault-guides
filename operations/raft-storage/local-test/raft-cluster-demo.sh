set -x
set -e

vault_1() {
    VAULT_ADDR=http://127.0.0.1:8200 vault $@
}

vault_2() {
    VAULT_ADDR=http://127.0.0.2:8200 vault $@
}

vault_3() {
    VAULT_ADDR=http://127.0.0.3:8200 vault $@
}

vault_4() {
    VAULT_ADDR=http://127.0.0.4:8200 vault $@
}

TEST_HOME=$HOME/raft-test

tee $TEST_HOME/config-vault1.hcl <<EOF
storage "inmem" {}
listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = true
}
EOF

 VAULT_API_ADDR=http://127.0.0.1:8200 vault server -log-level=trace -config $TEST_HOME/config-vault1.hcl > $TEST_HOME/vault1.log 2>&1 &

sleep 5s

INIT_RESPONSE=$(vault_1 operator init -format=json -key-shares 1 -key-threshold 1)

UNSEAL_KEY=$(echo $INIT_RESPONSE | jq -r .unseal_keys_b64[0])
ROOT_TOKEN=$(echo $INIT_RESPONSE | jq -r .root_token)

echo $UNSEAL_KEY
echo $ROOT_TOKEN

vault_1 operator unseal $UNSEAL_KEY
vault_1 login $ROOT_TOKEN

vault_1 secrets enable transit
vault_1 write -f transit/keys/unseal_key

tee $TEST_HOME/config-vault2.hcl <<EOF
storage "raft" {
  path    = "$TEST_HOME/vault-raft/"
  node_id = "node2"
}
listener "tcp" {
  address = "127.0.0.2:8200"
  cluster_address = "127.0.0.2:8201"
  tls_disable = true
}
seal "transit" {
  address            = "http://127.0.0.1:8200"
  token              = "$ROOT_TOKEN"
  disable_renewal    = "false"

  // Key configuration
  key_name           = "unseal_key"
  mount_path         = "transit/"
}
disable_mlock = true
cluster_addr = "http://127.0.0.2:8201"
EOF

tee $TEST_HOME/config-vault3.hcl <<EOF
storage "raft" {
  path    = "$TEST_HOME/vault-raft2/"
  node_id = "node3"
}
listener "tcp" {
  address = "127.0.0.3:8200"
  cluster_address = "127.0.0.3:8201"
  tls_disable = true
}
seal "transit" {
  address            = "http://127.0.0.1:8200"
  token              = "$ROOT_TOKEN"
  disable_renewal    = "false"

  // Key configuration
  key_name           = "unseal_key"
  mount_path         = "transit/"
}
disable_mlock = true
cluster_addr = "http://127.0.0.3:8201"
EOF

tee $TEST_HOME/config-vault4.hcl <<EOF
storage "raft" {
  path    = "$TEST_HOME/vault-raft3/"
  node_id = "node4"
}
listener "tcp" {
  address = "127.0.0.4:8200"
  cluster_address = "127.0.0.4:8201"
  tls_disable = true
}
seal "transit" {
  address            = "http://127.0.0.1:8200"
  token              = "$ROOT_TOKEN"
  disable_renewal    = "false"

  // Key configuration
  key_name           = "unseal_key"
  mount_path         = "transit/"
}
disable_mlock = true
cluster_addr = "http://127.0.0.4:8201"
EOF

rm -rf $TEST_HOME/vault-raft/ $TEST_HOME/vault-raft2/ $TEST_HOME/vault-raft3/
mkdir -pm 0755 $TEST_HOME/vault-raft $TEST_HOME/vault-raft2 $TEST_HOME/vault-raft3

VAULT_API_ADDR=http://127.0.0.2:8200 vault server -log-level=trace -config $TEST_HOME/config-vault2.hcl > $TEST_HOME/vault2.log 2>&1 &
VAULT_API_ADDR=http://127.0.0.3:8200 vault server -log-level=trace -config $TEST_HOME/config-vault3.hcl > $TEST_HOME/vault3.log 2>&1 &
VAULT_API_ADDR=http://127.0.0.4:8200 vault server -log-level=trace -config $TEST_HOME/config-vault4.hcl > $TEST_HOME/vault4.log 2>&1 &

sleep 5s
INIT_RESPONSE2=$(vault_2 operator init -format=json -key-shares 1 -key-threshold 1)

UNSEAL_KEY2=$(echo $INIT_RESPONSE2 | jq -r .unseal_keys_b64[0])
ROOT_TOKEN2=$(echo $INIT_RESPONSE2 | jq -r .root_token)

echo $UNSEAL_KEY2
echo $ROOT_TOKEN2

sleep 15s
vault_2 login $ROOT_TOKEN2

vault_2 secrets enable -path=kv kv-v2

sleep 2s
vault_2 kv put kv/apikey webapp=ABB39KKPTWOR832JGNLS02
vault_2 kv get kv/apikey
