GOARCH = amd64

UNAME = $(shell uname -s)

ifndef OS
	ifeq ($(UNAME), Linux)
		OS = linux
	else ifeq ($(UNAME), Darwin)
		OS = darwin
	endif
endif

.DEFAULT_GOAL := all

all: fmt build start

build:
	GOOS=$(OS) GOARCH="$(GOARCH)" go build -o vault/plugins/vault-plugin-database-mock cmd/vault-plugin-database-mock/main.go

start:
	vault server -dev -dev-root-token-id=root -dev-plugin-dir=./vault/plugins

enable:
	vault secrets enable database

	vault write database/config/mock \
    plugin_name=vault-plugin-database-mock \
		allowed_roles="mock-role" \
    username="vault" \
    password="vault" \
    connection_url="mock.local:1234"

	vault write database/roles/mock-role \
    db_name=mock \
    default_ttl="5m" \
    max_ttl="24h"
clean:
	rm -f ./vault/plugins/vault-plugin-database-mock

fmt:
	go fmt $$(go list ./...)

.PHONY: build clean fmt start enable
