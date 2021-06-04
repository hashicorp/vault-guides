.DEFAULT_GOAL := info

all: clean up-detach init terraform approle token

.PHONY: clean up up-detach init terraform approle info admin ip

info:
	$(info Targets are: all, up, up-detach, init, terraform, clean. Run all to execute them in order.)
	$(info up will block and docker compose in foreground, up-detach will run docker compose in background.)

admin:
	$(info this target will create an admin policy. Note: the root token needs to be set with the VAULT_TOKEN environment variable)
	export VAULT_ADDR=http://localhost:8200 \
	  && vault policy write learn-admin admin-policy.hcl \
	  && vault token create -policy=learn-admin
	$(info **please export the above token as part as the VAULT_TOKEN environment variable**)

up:
	cd docker-compose \
	  && docker compose up

up-detach:
	cd docker-compose \
	  && docker compose up --detach

ip:
	cd docker-compose/scripts \
	  && ./api_addr.sh

init:
	cd docker-compose/scripts \
	  && ./00-init.sh

terraform:
	rm -rf terraform/terraform.tfstate*
	cd docker-compose/scripts \
	  && ./run_terraform.sh

destroy:
	cd terraform && terraform destroy --auto-approve

clean:
	cd docker-compose \
	  && docker compose down
	rm -rf terraform/terraform.tfstate*
	rm -rf terraform/.terraform
	rm -f docker-compose/vault-agent/*role_id
	rm -f docker-compose/vault-agent/*secret_id
	rm -f docker-compose/vault-agent/login.json
	rm -f docker-compose/vault-agent/token
	rm -f docker-compose/scripts/vault.txt
	rm -f docker-compose/nginx/index.html
	rm -f docker-compose/nginx/kv.html

token:
	cat docker-compose/scripts/vault.txt | jq -r .root_token

license:
	./apply_license.sh

agent:
	helm install consul-k8s -f consul-k8s.values.yaml .

upgrade:
	helm upgrade consul-k8s -f consul-k8s.values.yaml .
