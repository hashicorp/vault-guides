# vault-plugin-secrets-hashicups

This tutorial guides you through creating your own Vault secrets engine
with an API that rotates API tokens.

## Prerequisites

1. Target API with CRUD capabilities for secrets.
1. Golang
1. Docker &  Docker Compose

## Getting Started

1. Set your target to the API you want to rotate the secrets. In this
   case, we set it to `hashicups`.
   ```shell
   export TARGET=hashicups
   ```

1. Clone this repository.
   ```shell
   git clone https://github.com/joatmon08/vault-plugin-secrets-${HASHICUPS}.git
   ```

1. Run `go mod init`.

## Start the HashiCorp Demo Application

The [HashiCorp Demo Application](https://github.com/hashicorp-demoapp)
includes a set of services that run
an online coffee store. In this demo, we use two of these services:

- A products database, which stores information about coffee and
  user logins.
- A products API, which returns information about coffee, ingredients,
  and handles user logins.

1. Go to the `hashicups-api` directory. It includes configuration files
   to create a local instance of the demo application and database.
   ```shell
   cd hashicups-api
   ```

1. Start the HashiCorp Demo Application.
   ```shell
   docker-compose up -d
   ```

1. You should have started two containers.
   ```shell
   $ docker ps -n 2

   CONTAINER ID   IMAGE                                     COMMAND                  CREATED         STATUS         PORTS                                         NAMES
   a03b2fa558fe   hashicorpdemoapp/product-api:v0.0.17      "/app/product-api"       8 minutes ago   Up 8 minutes   0.0.0.0:19090->9090/tcp, :::19090->9090/tcp   hashicups-api_api_1
   b6232a812a94   hashicorpdemoapp/product-api-db:v0.0.17   "docker-entrypoint.s…"   9 minutes ago   Up 8 minutes   0.0.0.0:15432->5432/tcp, :::15432->5432/tcp   hashicups-api_db_1
   ```

You can access the products API on your local machine on `localhost:19090`.

We'll be using specific API endpoints related to user
logins in the [products API](https://github.com/hashicorp-demoapp/product-api-go).

| PATH | METHOD | DESCRIPTION | HEADER | REQUEST | RESPONSE |
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| /signup | POST | Create a new user with a password. | | `{"username": "user", "password": "pass"}` | `{"UserID":1,"Username":"user","token":"<JWT>"}` |
| /signin | POST | Sign in an existing user and return an API token in the form of a JWT | | `{"username": "user", "password": "pass"}` | `{"UserID":1,"Username":"user","token":"<JWT>"}` |
| /signout | POST | Sign out a user based on their API token | `Authorization:<JWT>` | | `Signed out user` |

## Create plugin CLI

1. Create a directory named `cmd` and a subdirectory
   named after your plugin.
   ```shell
   mkdir -p cmd/vault-plugin-secrets-$TARGET
   ```

1. Create a `main.go` file. This file references the plugin and sets
   up the interfaces for Vault to communicate over GRPC. It also contains
   the `main` function.
   ```shell
   touch cmd/vault-plugin-secrets-<target>/main.go
   ```

1. Add the dependencies to the Vault Plugin SDK and API.
   ```shell
   go get github.com/hashicorp/vault/api
   go get github.com/hashicorp/vault/sdk/plugin
   ```

1. Add the dependency to HashiCorp's logging library. This makes
   it easier to log any events within your plugin.
   ```shell
   go get github.com/hashicorp/go-hclog
   ```

1. In your `main.go` file, update the example code to use your
   target API.

## Create the Vault backend

A Vault backend stores the secrets managed by the secrets engine.

Define this in `backend.go`. However, the backend needs to
create the client to access HashiCups!

## Create HashiCups client

The client will instantiate a new client for HashiCups based on
the configuration object.

Define this in `client.go`. However, the client needs the configuration
object with a username, password, and HashiCups endpoint!

## Create configuration for Vault backend

You need to create a configuration for the username, password, and URL for
HashiCups.

Define this in `path_config.go`. This will define the backend configuration
at `/config`.

Besides defining a `struct` for `hashiCupsConfig`, you'll also need to define
the schema for the `pathConfig` of the HashiCups backend.

Every time you add a new API path, you need to add it to `backend.go` under
the `backend` function (under `Paths`). Make sure you add the `pathConfig`.

```go
func backend() *hashiCupsBackend {
	var b = hashiCupsBackend{}

	b.Backend = &framework.Backend{
		Help: strings.TrimSpace(backendHelp),
		PathsSpecial: &logical.Paths{
			LocalStorage: []string{
				// WAL stands for Write-Ahead-Log, which is used for Vault replication
				framework.WALPrefix,
			},
			SealWrapStorage: []string{
				"config",
				"role/*",
			},
		},
		Paths: framework.PathAppend(
			[]*framework.Path{
				pathConfig(&b),
			},
		),
		Secrets: []*framework.Secret{},
		BackendType: logical.TypeLogical,
		Invalidate:  b.invalidate,
	}
	return &b
}
```

If you don't add `pathConfig` to the paths, you'll get the following error
when you run your plugin:

```shell
unsupported path
```

## Create the Vault role endpoint for the backend

A Vault role attaches permissions, groups, and policies to a user. HashiCups does
not have permissions or policies per user. A HashiCups user can only rotate, revoke,
and issue a token to their username. As a result, the role configuration maps
the user to the role.

In more complex secrets engines, you might have role definitions for identity access
and management policies or different kinds of secrets.

Define this in `path_roles.go`.

Every time you add a new API path, you need to add it to `backend.go` under
the `backend` function (under `Paths`). Make sure you add the `pathRole`.

```go
func backend() *hashiCupsBackend {
	var b = hashiCupsBackend{}

	b.Backend = &framework.Backend{
		Help: strings.TrimSpace(backendHelp),
		PathsSpecial: &logical.Paths{
			LocalStorage: []string{
				// WAL stands for Write-Ahead-Log, which is used for Vault replication
				framework.WALPrefix,
			},
			SealWrapStorage: []string{
				"config",
				"role/*",
			},
		},
		Paths: framework.PathAppend(
         pathRole(&b),
			[]*framework.Path{
				pathConfig(&b),
			},
		),
		Secrets: []*framework.Secret{},
		BackendType: logical.TypeLogical,
		Invalidate:  b.invalidate,
	}
	return &b
}
```

If you don't add `pathRole` to the paths, you'll get the following error
when you run your plugin:

```shell
unsupported path
```

## Create the Vault credentials endpoint for the backend

### Create the type of secret

Define this in `hashicups_token.go`. You will create a token
that includes the user ID, username, token ID, and token.

It helps to separate this into a different file, especially
since you might want to change how you create and delete
the secret in your target API.

Define a schema for the token using `framework.Secret`.
You'll also need to implement
a `tokenRevoke` and `tokenRenew` function.

Every time you add a new secret, you need to add it to `backend.go` under
the `backend` function (under `Secrets`). Make sure you add `b.hashiCupsToken()`.

```go
func backend() *hashiCupsBackend {
	var b = hashiCupsBackend{}

	b.Backend = &framework.Backend{
		Help: strings.TrimSpace(backendHelp),
		PathsSpecial: &logical.Paths{
			LocalStorage: []string{
				// WAL stands for Write-Ahead-Log, which is used for Vault replication
				framework.WALPrefix,
			},
			SealWrapStorage: []string{
				"config",
				"role/*",
			},
		},
		Paths: framework.PathAppend(
         pathRole(&b),
			[]*framework.Path{
				pathConfig(&b),
			},
		),
		Secrets: []*framework.Secret{
         b.hashiCupsToken(),
		},
		BackendType: logical.TypeLogical,
		Invalidate:  b.invalidate,
	}
	return &b
}
```

If you don't add `b.hashiCupsToken()` to the secrets, your
list will have no values and your plugin will fail with
a nil memory error!

### Read the credentials endpoint

Define this in `path_credentials.go`.

You'll need to create a function for `pathCredentialsRead`.
In Vault plugins, credentials endpoints should always be
a __read__ endpoint. As a result, you need to add code
in `pathCredentialsRead` to idempotently handle any credential
creation or updates.

Every time you add a new API path, you need to add it to `backend.go` under
the `backend` function (under `Paths`). Make sure you add the `pathCredentials`.

```go
func backend() *hashiCupsBackend {
	var b = hashiCupsBackend{}

	b.Backend = &framework.Backend{
		Help: strings.TrimSpace(backendHelp),
		PathsSpecial: &logical.Paths{
			LocalStorage: []string{
				// WAL stands for Write-Ahead-Log, which is used for Vault replication
				framework.WALPrefix,
			},
			SealWrapStorage: []string{
				"config",
				"role/*",
			},
		},
		Paths: framework.PathAppend(
         pathRole(&b),
			[]*framework.Path{
				pathConfig(&b),
				pathCredentials(&b),
			},
		),
		Secrets: []*framework.Secret{},
		BackendType: logical.TypeLogical,
		Invalidate:  b.invalidate,
	}
	return &b
}
```

If you don't add `pathCredentials` to the paths, you'll get the following error
when you run your plugin:

```shell
unsupported path
```

## Build the plugin

You'll need to build the plugin from `cmd/vault-plugin-secrets-hashicups/main.go`.

```shell
make build
```

The command builds the plugin and saves it to `vault/plugins`, which you can configure
Vault to load from.

## Start Vault server with the custom plugin

You must load the custom plugin to __each__ node of the Vault cluster
and start up Vault with the `-plugin-dir` configuration. For this
demonstration, we're using `dev` mode to automatically register the plugin.

```shell
$ make vault_server

## omitted for clarity

The following dev plugins are registered in the catalog:
    - vault-plugin-secrets-hashicups

## omitted for clarity
```

In a Vault cluster, you'll need to register the new plugin and reload any time
you update.

## Try it out!

You can run a set of commands to enable the secrets engine at `/hashicups` in
Vault.

Then, you can write a configuration and a `test` role based on a HashiCups username.

Finally, you can read the credentials for the `test` role.

```shell
$ make vault_plugin

vault secrets enable -path=hashicups vault-plugin-secrets-hashicups
Success! Enabled the vault-plugin-secrets-hashicups secrets engine at: hashicups/
vault write hashicups/config username="vault-plugin-testing" password='Testing!123' url="${TEST_HASHICUPS_URL}"
Success! Data written to: hashicups/config
vault write hashicups/role/test username="vault-plugin-testing"
Success! Data written to: hashicups/role/test
vault read hashicups/creds/test
Key                Value
---                -----
lease_id           hashicups/creds/test/tVsj1JusAp8mW2vgD3FqAnxf
lease_duration     768h
lease_renewable    true
token              eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MjY5MDI1MzQsInRva2VuX2lkIjoyNywidXNlcl9pZCI6MSwidXNlcm5hbWUiOiJ2YXVsdC1wbHVnaW4tdGVzdGluZyJ9.ZlH4ysV3860KbqU-rZHeQJ8p_WT6TCNrr_rWB075efY
token_id           5f83a6ee-3b51-44e4-9744-76e467762fde
user_id            1
username           vault-plugin-testing
```

Copy the token and set it to the `TOKEN` environment variable.

```shell
export TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MjY5MDI1MzQsInRva2VuX2lkIjoyNywidXNlcl9pZCI6MSwidXNlcm5hbWUiOiJ2YXVsdC1wbHVnaW4tdGVzdGluZyJ9.ZlH4ysV3860KbqU-rZHeQJ8p_WT6TCNrr_rWB075efY
```

Call the HashiCups API to create a new coffee product. You should successfully create a new Melbourne Magic coffee offering.

```shell
$ curl -i -X POST -H "Authorization:${TOKEN}" ${TEST_HASHICUPS_URL}/coffees -d '{"name":"melbourne magic", "teaser": "delicious custom coffee", "description": "best coffee in the world"}'

HTTP/1.1 200 OK
Date: Tue, 20 Jul 2021 21:25:38 GMT
Content-Length: 87
Content-Type: text/plain; charset=utf-8

{"id":9,"name":"","teaser":"","description":"","price":0,"image":"","ingredients":null}
```

Revoke the lease for the HashiCups token in Vault.

```shell
$ vault lease revoke hashicups/creds/test/tVsj1JusAp8mW2vgD3FqAnxf

All revocation operations queued successfully!
```

If you try to add a new coffee product, tonic espresso, to HashiCups, you'll find that the token is no longer valid.

```shell
$ curl -i -X POST -H "Authorization:${TOKEN}" ${TEST_HASHICUPS_URL}/coffees -d '{"name":"tonic espresso", "teaser": "delicious custom coffee", "description": "best coffee in the world"}'

HTTP/1.1 401 Unauthorized
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Tue, 20 Jul 2021 21:27:47 GMT
Content-Length: 14

Invalid token
```

## Additional references:

- [Upgrading Plugins](https://www.vaultproject.io/docs/upgrading/plugins)
- [List of Vault Plugins](https://www.vaultproject.io/docs/plugin-portal)