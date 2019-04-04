#!/bin/bash
set -e
set -v
set -x

export ROOT_TOKEN=$1
vault login $ROOT_TOKEN

vault secrets enable -path EU_GDPR_data kv
vault write EU_GDPR_data/UK foo=bar
vault write secret/foo bar=baz

vault auth enable userpass
USERPASS_ACCESSOR=$(curl -H "X-Vault-Token: ${ROOT_TOKEN}" \
  --request GET http://127.0.0.1:8200/v1/sys/auth | jq -r '.data."userpass/".accessor') 



##################
#SETUP PROCESS0RS
##################
echo '
path "EU_GDPR_data/*" {
    capabilities = ["read"]
    control_group = {
        factor "Dual Controllers" {
            identity {
                group_names = ["controllers"]
                approvals = 2
            }
        }
    }
}
path "secret/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}'| vault policy write gdpr -

#Create Andrew K entity
echo '
{
  "name": "andrewkHcorp",
  "metadata": {
    "team": "processors"
  },
  "policies": ["gdpr"]
}' > andrewk-entity.json

ANDREWK_ENTITY_ID=$(curl -H "X-Vault-Token: ${ROOT_TOKEN}" \
   --request POST \
   --data @andrewk-entity.json  http://127.0.0.1:8200/v1/identity/entity | jq -r '.data.id')

#Create entity alias for Andrew to the userpass backend
echo "{
  \"name\": \"andrew\",
  \"canonical_id\": \"$ANDREWK_ENTITY_ID\",
  \"mount_accessor\": \"$USERPASS_ACCESSOR\"
}" > andrewk-userpass-entity-alias.json

ANDREWK_ENTITY_ALIAS_ID=$(curl -H "X-Vault-Token: ${ROOT_TOKEN}" \
   --request POST \
   --data @andrewk-userpass-entity-alias.json  http://127.0.0.1:8200/v1/identity/entity-alias | jq -r '.data.id')

echo "{
  \"name\": \"processors\",
  \"member_entity_ids\": [ \"${ANDREWK_ENTITY_ID}\" ],
  \"policies\": [\"gdpr\"]
}" > processors.json

vault write identity/group @processors.json




##################
#SETUP CONTROLLERS
##################
echo '
#For authorization
path "/sys/control-group/authorize" {
    capabilities = ["create", "update"]
}
#admin test
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}'| vault policy write controllers -

#Create Brian G entity
echo '
{
  "name": "briangHcorp",
  "metadata": {
    "team": "controllers"
  },
  "policies": ["controllers"]
}' > briang-entity.json

BRIANG_ENTITY_ID=$(curl -H "X-Vault-Token: ${ROOT_TOKEN}" \
  --request POST \
  --data @briang-entity.json  http://127.0.0.1:8200/v1/identity/entity | jq -r '.data.id')

#Create entity alias for Brian to the userpass backend
echo "{
  \"name\": \"brian\",
  \"canonical_id\": \"$BRIANG_ENTITY_ID\",
  \"mount_accessor\": \"$USERPASS_ACCESSOR\"
}" > briang-userpass-entity-alias.json

BRIANG_ENTITY_ALIAS_ID=$(curl -H "X-Vault-Token: ${ROOT_TOKEN}" \
  --request POST \
  --data @briang-userpass-entity-alias.json  http://127.0.0.1:8200/v1/identity/entity-alias | jq -r '.data.id')

#Create Nico entity
echo '
{
  "name": "nicoHcorp",
  "metadata": {
    "team": "controllers"
  },
  "policies": ["controllers"]
}' > nico-entity.json

NICO_ENTITY_ID=$(curl -H "X-Vault-Token: ${ROOT_TOKEN}" \
  --request POST \
  --data @nico-entity.json  http://127.0.0.1:8200/v1/identity/entity | jq -r '.data.id')

#Create entity alias for Nico to the userpass backend
echo "{
  \"name\": \"nico\",
  \"canonical_id\": \"$NICO_ENTITY_ID\",
  \"mount_accessor\": \"$USERPASS_ACCESSOR\"
}" > nico-userpass-entity-alias.json

NICO_ENTITY_ALIAS_ID=$(curl -H "X-Vault-Token: ${ROOT_TOKEN}" \
  --request POST \
  --data @nico-userpass-entity-alias.json  http://127.0.0.1:8200/v1/identity/entity-alias | jq -r '.data.id')

echo "{
  \"name\": \"controllers\",
  \"member_entity_ids\": [ \"${BRIANG_ENTITY_ID}\", \"${NICO_ENTITY_ID}\" ],
  \"policies\": [\"controllers\"]
}" > controllers.json

vault write identity/group @controllers.json

vault write auth/userpass/users/andrew password=vault
vault write auth/userpass/users/brian password=vault
vault write auth/userpass/users/nico password=vault



#USAGE
#Login as Andrew
#$ vault login -method=userpass username=andrew
#
#Read the secret
#$ vault read EU_GDPR_data/UK
#Key                              Value
#---                              -----
#wrapping_token:                  a8ca9e0e-c086-85ae-40da-1b5bd500a873
#wrapping_accessor:               e1a58a15-31cd-ca1d-0c10-7613b24e38f3
#wrapping_token_ttl:              24h
#wrapping_token_creation_time:    2018-03-10 16:08:03 -0600 CST

# Now Login as Brian
#$ vault login -method=userpass username=brian
#$ vault write sys/control-group/authorize accessor=e1a58a15-31cd-ca1d-0c10-7613b24e38f3

# Now Login as Nico
#$ vault login -method=userpass username=nico
#$ vault write sys/control-group/authorize accessor=e1a58a15-31cd-ca1d-0c10-7613b24e38f3

# Switch back to Andrew and try to unwrap the token
#$ vault login -method=userpass username=andrew
#vault unwrap a8ca9e0e-c086-85ae-40da-1b5bd500a873
#Key                 Value
#---                 -----
#refresh_interval    768h
#foo                 bar

