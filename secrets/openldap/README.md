# Docker OpenLDAP Secrets Engine with SSH Demonstration

You can use the information in this guide to build a demonstration for testing authentication of SSH connections using LDAP and PAM in a Docker environment with OpenLDAP credentials managed by Vault.

The infrastructure in this demonstration consists of the following:

- 1 Vault container
- 1 OpenLDAP container
- 1 Secure Shell Daemon (sshd) container

Once you have established the initial SSH authentication through OpenLDAP, we can demonstrate use of Vault to manage our LDAP user credential with the [OpenLDAP Secrets Engine](https://www.vaultproject.io/docs/secrets/openldap/) introduced in Vault version 1.4.0).

## Prerequisites

You need the following to successfully try this demonstration.

1. [Docker Desktop](https://www.docker.com/products/docker-desktop)
1. A clone of the [HashiCorp vault-guides repository](https://github.com/hashicorp/vault-guides)
1. LDAP utilities (these are provided by default on some operating systems, such as macOS, but must be installed via package on others).
  - `ldapadd`
  - `ldappasswd`

## Setup the Infrastructure

Once you meet all prerequisites, proceed with the setup to establish a dedicated Docker network and the necessary containers for our demonstration infrastructure.

### Docker Network

Let's begin the setup by creating a Docker network for our containers to keep them isolated from any existing containers.

Use the `docker network create` command to create a bridged network (the default driver) named _learn-vault_.

```shell
$ docker network create learn-vault
```

**Successful output**:

```plaintext
cab57becef85420f00cb78a41eecd21a196e102a52f7843a3ddff5f529ff4527
```

### OpenLDAP Container

Use `docker run` to run the OpenLDAP container using settings as shown in this example.

```shell
$ docker run \
  --name=learn-ldap \
  --hostname=learn-ldap \
  --network=learn-vault \
  --hostname=ldap \
  -p 389:389 \
  -p 636:636 \
  -e LDAP_ORGANISATION="Example" \
  -e LDAP_DOMAIN="example.com" \
  -e LDAP_ADMIN_PASSWORD="admin" \
  --detach \
  --rm \
  osixia/openldap:1.3.0
```

**Successful output**:

```
FIXME
```

You can use `docker ps` to validate that the container is up and ready.

```
$ docker ps -f name=learn-ldap --format "table {{.Names}}\t{{.Status}}"
NAMES               STATUS
learn-ldap          Up 5 seconds
```

Now that the OpenLDAP server is ready, let's move on to configuring it.

#### OpenLDAP Configuration

The OpenLDAP server needs a bit of additional configuration to define some initial groups and a POSIX user account named _learner_. We'll use this account to authenticate to the sshd container later on. You can find this configuration in the files `configs/base.ldif` and `configs/learn.ldif`.

Use the `ldapadd` command to add configuration from `configs.base.ldif` to your OpenLDAP server.

```shell
$ ldapadd \
  -x \
  -w admin \
  -D "cn=admin,dc=example,dc=com" \
  -f ./configs/base.ldif
```

**Successful output**:

```plaintext
adding new entry "ou=users,dc=example,dc=com"

adding new entry "ou=groups,dc=example,dc=com"
```

Next, add the POSIX user _learner_ with the `ldapadd` command and  configuration from the file `configs/learner.ldif`.

```shell
$ ldapadd \
  -x \
  -w admin \
  -D "cn=admin,dc=example,dc=com" \
  -f ./configs/learner.ldif
```

**Successful output**:

```plaintext
adding new entry "uid=learner,ou=users,dc=example,dc=com"

adding new entry "cn=learners,ou=groups,dc=example,dc=com"
```

Finally, use `ldappasswd` to set _learner_'s password value to the literal string _password_.

```shell
$ ldappasswd \
  -s password \
  -w admin \
  -D "cn=admin,dc=example,dc=com" \
  -x "uid=learner,ou=users,dc=example,dc=com"
```

**Successful output**:

Successful results of this command should produce no output.

With the OpenLDAP container fully configured, let's move on to building and running the SSH Container.

### Secure Shell Daemon (sshd) Container

The sshd container used in this demonstration is customized to configure PAM for OpenLDAP based logins, so you must build the container image from the included `Dockerfile.centos7` file before running it.

Use `docker build` with the flags shown to build the container.

```shell
$ docker build . -f Dockerfile.centos7 -t sshtest:1.0.0
```

**Successful output**:

This process will take up to a minute or so the first time depending on your Docker host system, but the final result should conclude with successful built and tagged messages as in this example.

```plaintext
...
Successfully built a3400498ff9e
Successfully tagged sshtest:1.0.0
```

Use `docker run` to run the container image.

```shell
$ docker run \
  --name=learn-sshd \
  --hostname=learn-sshd \
  --network=learn-vault \
  --hostname=sshd \
  -e SSH_PASSWORD_AUTHENTICATION='true' \
  -p 2022:22 \
  --detach \
  --rm \
  sshtest:1.0.0
```

**Successful output**:

```
FIXME
```

You can use `docker ps` go validate that the container is up and ready.

```
$ docker ps -f name=learn-sshd --format "table {{.Names}}\t{{.Status}}"
NAMES               STATUS
learn-sshd          Up 6 seconds (healthy)
```

Now that the sshd server is ready, let's move on to testing it.

## Test SSH Authentication

Let's try to authenticate to the sshd container with our LDAP user and its password.

```shell
$ ssh -l learner 0.0.0.0 -p 2022
```

Since this is the first connection to the sshd container, you will be prompted with some information about the host and asked whether you want to continue connecting.

```
The authenticity of host '[0.0.0.0]:2022 ([0.0.0.0]:2022)' can't be established.
ECDSA key fingerprint is SHA256:jiMaT0yey0MUFs7qKg+OTMGPBILuBaUKkATVjB02s4o.
Are you sure you want to continue connecting (yes/no)? yes
```

Enter `yes` then press ENTER, then enter `password` when prompted for password. If all goes well, you should be authenticated with the _learn-sshd_ container and in a shell session.

```plaintext
Warning: your password will expire in 0 days
Creating directory '/home/learner'.
[learner@sshd ~]$
```

Now that we have successfully authenticated with the sshd server, let's configure Vault to manage the LDAP credential for our _learner_ and then rotate it.

### Vault Container

We will use a simple Vault development server container for the purpose of this demonstration.

Use `docker run`, to run the Vault container with flags as shown in this example.

```shell
$ docker run \
  --name=learn-vault \
  --hostname=learn-vault \
  --network=learn-vault \
  --hostname=vault \
  --cap-add=IPC_LOCK \
  -e 'VAULT_DEV_ROOT_TOKEN_ID=c0ffee0ca7' \
  -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' \
  -p 8200:8200 \
  --detach \
  --rm \
  vault:1.4.0
```

> **NOTE**: We have started the Vault server in [development mode](https://www.vaultproject.io/docs/commands/server/#inlinecode--dev-1); this means Vault initializes, unseals itself, and sets the initial root token to _c0ffee0ca7_ for us. Any 1.4.0+ version of the container can be used.

Beware that in dev mode all Vault data are persisted only to memory, so if the container is stopped you will lose any progress from this point onward.

You can use `docker ps` go validate that the container is up and ready.

```
$ docker ps -f name=learn-vault --format "table {{.Names}}\t{{.Status}}"
NAMES               STATUS
learn-sshd          Up 14 seconds
```

From this point on, we will execute a shell in the Vault server container and carry out commands to configure the Vault OpenLDAP secrets engine from within the container itself.

Use `docker exec` to open a shell in the Vault server container.

```
$ docker exec -it learn-vault sh
```

Next, export a `VAULT_ADDR` environment variable that instructs the `vault` binary client on the specific host and port in use by our Vault server.

```shell
# export VAULT_ADDR=http://127.0.0.1:8200
```

Now that the Vault server is ready and we have instructed our `vault` client binary to communicate with it, let's do a quick check of Vault's current status.

```shell
# vault status
```

**Successful output**:

```plaintext
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.4.0
Cluster Name    vault-cluster-831f0112
Cluster ID      6ea9421f-13b7-7eda-10ad-dea8e6e4a3a5
HA Enabled      false
```

Great, Vault is ready to go and we are now ready to configure the OpenLDAP secrets engine.

First, use `vault login` authenticate with the root _c0ffee0ca7_ token.

```
# vault login c0ffee0ca7
```

**Successful output**:

```
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                c0ffee0ca7
token_accessor       pIHND1DJdDFZHJ1yrDfPmm37
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"
```

Now that we are authenticated with the root token, continue with the secrets engine configuration.

#### Enable and Configure OpenLDAP Secrets Engine

First, use `vault secrets enable` to enable the secrets engine.

```shell
$ vault secrets enable openldap
```

**Successful output**:

```plaintext
Success! Enabled the openldap secrets engine at: openldap/
```

Next, use `vault write` to configure the secrets engine.

```shell
$ vault write openldap/config \
    binddn=cn=admin,dc=example,dc=com \
    bindpass=admin \
    url=ldap://learn-ldap
```

**Successful output**:

```plaintext
Success! Data written to: openldap/config
```

Then rotate the root credential.

```shell
$ vault write -f openldap/rotate-root
```

**Successful output**:

```plaintext
Success! Data written to: openldap/rotate-root
```

Now let's create a static role to manage the _learner_ user's credentials and while we are at it, let's define an automatic rotation period of 24 hours for example as well.


```shell
$ vault write openldap/static-role/learner \
    dn='uid=learner,ou=users,dc=example,dc=com' \
    username='learner' \
    rotation_period="24h"
```

**Successful output**:

```
Success! Data written to: openldap/static-role/learner
```

Finally, rotate the _learner_ password

```shell
$ vault write -f /openldap/rotate-role/learner
```

**Successful output**:

```plaintext
Success! Data written to: openldap/rotate-role/learner
```
## Test SSH Authentication Again

Now if we attempt authenticate with the sshd server container, it should no longer be possible to use the old value of _password_ for the _learner_ user password.

```shell
$ ssh -l learner 0.0.0.0 -p 2022
learner@0.0.0.0's password:
Permission denied, please try again.
```

Indeed this is the case, but now that we have rotated the credential what is the new password value?

## Back to Vault

From within the Vault server container, we can ask Vault by reading from the _/openldap/static-cred/learner_ using `vault read`; if we further use the `-field` flag, we can ask for _only the raw password string_, which offers precision for use in automation use cases and so on.

```
# vault read -field=password /openldap/static-cred/learner
```

> NOTE: This operation is expected to produce sensitive output.

**Successful output**:

```plaintext
ZdSuDuHEUeeLlNijYXF527RzYdiF34h2YmgAv0EhNhpLRhCUmmpkGzenTQHyTs1H
```

If you'd prefer to see all the metadata associated with the secret, just omit the `-field=password`.

```plaintext
# vault read /openldap/static-cred/learner
```

**Successful output**:

```plaintext
Key                    Value
---                    -----
dn                     uid=learner,ou=users,dc=example,dc=com
last_vault_rotation    2020-03-10T17:42:07.6574783Z
password               ZdSuDuHEUeeLlNijYXF527RzYdiF34h2YmgAv0EhNhpLRhCUmmpkGzenTQHyTs1H
rotation_period        72h
ttl                    71h59m40s
username               learner
```

So now that we know the credential value that Vault has generated during the previous rotate operation, let's try to use it with the sshd server container.

## Test SSH Authentication One Last Time

If we attempt authenticate with the sshd server container using our updated password as read from Vault we should observe success.

```shell
$ ssh -l learner 0.0.0.0 -p 2022
learner@0.0.0.0's password:
```

**Successful output**:

```
Warning: your password will expire in 0 days
Last login: Tue Mar 10 17:12:56 2020 from 172.22.0.1
[learner@sshd ~]$ logout
```

## Cleanup

You can quickly clean up the environment with `docker rm` and `docker network rm` commands:

```
$ docker rm learn-vault --force ; \
  docker rm learn-ldap --force ; \
  docker rm learn-sshd --force ; \
  docker network rm learn-vault
```

**Successful output**:

```plaintext
learn-vault
learn-ldap
learn-sshd
learn-vault
```

## Help and Reference

1. [Docker Desktop](https://www.docker.com/products/docker-desktop)
1. [vault-guides repository](https://github.com/hashicorp/vault-guides)
1. [hashicorp/vault](https://hub.docker.com/_/vault)
1. [hashicorp/vault GitHub repository](https://github.com/hashicorp/docker-vault)
1. [Vault server development mode](https://www.vaultproject.io/docs/commands/server/#inlinecode--dev-1)
1. [OpenLDAP Secrets Engine](https://www.vaultproject.io/docs/secrets/openldap/)
1. [OpenLDAP Secrets Engine API](https://www.vaultproject.io/api-docs/secret/openldap/)
1. [OpenLDAP](https://www.openldap.org/)
1. [osixia/openldap](https://hub.docker.com/r/osixia/openldap)
1. [osixia/openldap  GitHub repository](https://github.com/osixia/docker-openldap)
1. [jdeathe/centos-ssh](https://hub.docker.com/r/jdeathe/centos-ssh/)
1. [jdeathe/centos-ssh GitHub repository](https://github.com/jdeathe/centos-ssh)
