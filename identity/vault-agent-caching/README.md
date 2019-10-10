# [Vault 1.1 Beta] Vault Agent Caching

These assets are provided to provision AWS resources to perform the steps described in the [Vault Agent Caching](https://learn.hashicorp.com/vault/identity-access-management/agent-caching).

**NOTE:** Currently, Vault 1.1 is in _beta_.

---


## Demo Steps

>**NOTE:** The example Terraform in this repository is created for the demo purpose, and not suitable for production use.


1. Set this location as your working directory

1. Set your AWS credentials as environment variables: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

1. Set the Terraform variable values in a file named `terraform.tfvars` (use `terraform.tfvars.example` as a base)

    **Example:**

    ```shell
    # SSH key name to access EC2 instances (should already exist) in the region you are using
    key_name = "vault-test"

    # All resources will be tagged with this
    environment_name = "va-demo"
    ```

1. Run Terraform:

    ```shell
    # Pull necessary plugins
    $ terraform init

    $ terraform plan

    # Output provides the SSH instruction
    $ terraform apply -auto-approve
    ```

### Vault Server

1. SSH into the Vault **server** instance: `ssh -i <path_to_key> ubuntu@<public_ip_of_server>`

1. On the **server** instance, run the following commands:

    ```shell
    # Initialize Vault
    $ vault operator init > key.txt

    # Check the Vault server status
    $ vault status

    # Log in with initial root token
    $ vault login $(grep 'Initial Root Token:' key.txt | awk '{print $NF}')    
    ```

1. Run `aws_auth.sh` script to create `myapp` policy, enable and configure AWS auth method, and create a `student` user in `userpass` auth method

    ```plaintext
    $ ./aws_auth.sh
    ```

1. Also, run `auth_secret.sh` script to enable and configure AWS secrets engine

    ```plaintext
    $ ./aws_secrets.sh
    ```

### Vault Client

1. SSH into the Vault **client** instance: `ssh -i <path_to_key> ubuntu@<public_ip_of_client>`

1. On the **client** instance, examine the Vault Agent file, `vault-agent.hcl`:

    ```shell
    $ cat vault-agent.hcl

    exit_after_auth = false
    pid_file = "./pidfile"

    auto_auth {
       method "aws" {
           mount_path = "auth/aws"
           config = {
               type = "iam"
               role = "app-role"
           }
       }

       sink "file" {
           config = {
               path = "/home/ubuntu/vault-token-via-agent"
           }
       }
    }

    cache {
       use_auto_auth_token = true       
    }

    listener "tcp" {
       address = "127.0.0.1:8200"
       tls_disable = true
    }

    vault {
       address = "http://<vault-server-host>:8200"
    }
    ```

    **NOTE:** Notice the `cache` block. The TCP listener is configured to listen to port 8200 on the client host.

1. Run Vault Agent

    ```plaintext
    $ vault agent -config=/home/ubuntu/vault-agent.hcl -log-level=debug
    ```

1. Open **another terminal** and SSH into the client host. The `auto_auth` token should be written in the `/home/ubuntu/vault-token-via-agent` file

    ```plaintext
    $ more vault-token-via-agent
    ```

1. Also, verify that `VAULT_AGENT_ADDR` has been set correctly:

    ```plaintext
    $ echo $VAULT_AGENT_ADDR
    ```

1. Verify that you can get an AWS credentials

    ```shell
    # CLI command
    $ vault read aws/creds/readonly

    # API call using cURL
    $ curl -s $VAULT_AGENT_ADDR/v1/aws/creds/readonly | jq
    ```

    Since the `use_auto_auth_token` was set to **true** in the Vault Agent's configuration, you can send the request straight through the proxy (http://127.0.0.1:8200).

    Examine the agent log in the other terminal:

    ```plaintext
    ...
    [INFO]  cache: received request: path=/v1/aws/creds/readonly method=GET
    [DEBUG] cache: using auto auth token: path=/v1/aws/creds/readonly method=GET
    [DEBUG] cache.leasecache: forwarding request: path=/v1/aws/creds/readonly method=GET
    [INFO]  cache.apiproxy: forwarding request: path=/v1/aws/creds/readonly method=GET
    [DEBUG] cache.leasecache: processing lease response: path=/v1/aws/creds/readonly method=GET
    [DEBUG] cache.leasecache: storing response into the cache: path=/v1/aws/creds/readonly method=GET
    [DEBUG] cache.leasecache: initiating renewal: path=/v1/aws/creds/readonly method=GET
    [DEBUG] cache.leasecache: secret renewed: path=/v1/aws/creds/readonly
    ```

1. Log in as `student` user:

    ```shell
    # Login with username 'student' and password is "pAssw0rd" via CLI
    $ vault login -method=userpass username="student" password="pAssw0rd"


    # Or, login via API
    $ curl --request POST --data '{"password": "pAssw0rd"}' \
           $VAULT_AGENT_ADDR/v1/auth/userpass/login/student | jq
    {
      ...
      "auth": {
        "client_token": "s.3vfZXvNcgiIGdJM5gqdSkOlo",        
        ...
    }

    # Store the acquired token in VAULT_TOKEN environment variable
    $ export VAULT_TOKEN="s.3vfZXvNcgiIGdJM5gqdSkOlo"
    ```

    >**NOTE:** You send the API request via agent proxy (`$VAULT_AGENT_ADDR`) rather than `VAULT_ADDR`.

    Examine the agent log in the other terminal:

    ```plaintext
    ...
    [INFO]  cache: received request: path=/v1/auth/userpass/login/student method=POST
    [DEBUG] cache: using auto auth token: path=/v1/auth/userpass/login/student method=POST
    [DEBUG] cache.leasecache: forwarding request: path=/v1/auth/userpass/login/student method=POST
    [INFO]  cache.apiproxy: forwarding request: path=/v1/auth/userpass/login/student method=POST
    [DEBUG] cache.leasecache: processing auth response: path=/v1/auth/userpass/login/student method=POST
    [DEBUG] cache.leasecache: storing response into the cache: path=/v1/auth/userpass/login/student method=POST
    ...
    ```

1. Create a token to see the agent behavior:

    ```shell
    # CLI command
    $ vault token create

    # API call using cURL
    $ curl --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_AGENT_ADDR/v1/auth/token/create | jq
    ```

## Cache Eviction

Cache eviction can be forced via `/agent/v1/cache-clear` endpoint, or via lease/token **revocation**.

1. Revoke a cached token

    ```shell
    # CLI command
    $ vault token revoke s.AvjnUWFQ3RNa6IzkM9WProxS

    # API call using cURL
    $ curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST \
           --data '{"token": "s.AvjnUWFQ3RNa6IzkM9WProxS"}' \
           $VAULT_AGENT_ADDR/v1/auth/token/revoke
    ```    

    Examine the agent log:

    ```plaintext
    ...
    [INFO]  cache: received request: path=/v1/auth/token/revoke method=POST
    [DEBUG] cache.leasecache: forwarding request: path=/v1/auth/token/revoke method=POST
    [INFO]  cache.apiproxy: forwarding request: path=/v1/auth/token/revoke method=POST
    [DEBUG] cache.leasecache: cancelling context of index attached to token
    [DEBUG] cache.leasecache: successfully cleared matching cache entries
    [DEBUG] cache.leasecache: triggered caching eviction from revocation request
    [DEBUG] cache.leasecache: context cancelled; stopping renewer: path=/v1/auth/token/create
    [DEBUG] cache.leasecache: evicting index from cache: id=b5715bdca771174... path=/v1/auth/token/create method=POST
    ```

1. Clear AWS secret lease

    ```plaintext
    curl --request POST --data '{ "type": "lease", "value": "aws/creds/readonly" }' \
         $VAULT_AGENT_ADDR/agent/v1/cache-clear
    ```
    The agent log should show:

    ```plaintext
    [DEBUG] cache.leasecache: received cache-clear request: type=lease namespace= value=aws/creds/readonly
    ```

## Clean up

1. Revoke all AWS leases from the **server** host:

    ```plaintext
    $ vault lease revoke -prefix aws/creds
    ```

1. Clean up the cloud resources

    ```plaintext
    $ terraform destroy -auto-approve
    $ rm -rf .terraform terraform.tfstate* private.key
    ```
