setup:
	cd hashicups-api/terraform && terraform apply
	gcloud container clusters get-credentials ${CLOUDSDK_CORE_PROJECT} --zone us-central1-c
	kubectl apply -f hashicups-api/kubernetes

local:
	cd hashicups-api/docker-compose && docker-compose up -d

signup:
	curl -X POST -H 'Content-Type:application/json' ${TEST_HASHICUPS_URL}/signup -d '{"username": "vault-plugin-testing", "password": "Testing!123"}'

build:
	go build -o vault/plugins/vault-plugin-secrets-hashicups cmd/vault-plugin-secrets-hashicups/main.go

vault_server:
	vault server -dev -dev-root-token-id=root -dev-plugin-dir=./vault/plugins

vault_plugin:
	vault secrets enable -path=hashicups vault-plugin-secrets-hashicups
	vault write hashicups/config username="vault-plugin-testing" password='Testing!123' url="${TEST_HASHICUPS_URL}"
	vault write hashicups/role/test username="vault-plugin-testing"
	vault read hashicups/creds/test

new_coffee:
	curl -i -X POST -H "Authorization:${TOKEN}" ${TEST_HASHICUPS_URL}/coffees -d '{"name":"melbourne magic", "teaser": "delicious custom coffee", "description": "best coffee in the world"}'

clean:
	cd hashicups-api/docker-compose && docker-compose down
	kubectl delete -f hashicups-api/kubernetes --ignore-not-found
	cd hashicups-api/terraform && terraform destroy