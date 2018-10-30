# Vault Auto-unseal using GCP Cloud KMS

These assets are provided to perform the tasks described in the [Auto-unseal with Google Cloud
KMS](https://www.vaultproject.io/guides/operations/autounseal-gcp-kms.html) guide.

---

## Steps

1. Set this location as your working directory

1. Provide necessary GCP account information in the `terraform.tfvars.example` and save it as `terraform.tfvars`.

1. This guide expects a Cloud KMS key ring and crypto key to already exists. If you **don't** have one to use for Vault auto-unseal, un-comment the key ring and key creation portion in the `main.tf` file:

    ```plaintext
    ...

    // Create a KMS key ring
    resource "google_kms_key_ring" "key_ring" {
       project  = "${var.gcloud-project}"
       name     = "${var.key_ring}"
       location = "${var.keyring_location}"
    }

    // Create a crypto key for the key ring
    resource "google_kms_crypto_key" "crypto_key" {
       name            = "${var.crypto-key}"
       key_ring        = "${google_kms_key_ring.key_ring.self_link}"
       rotation_period = "100000s"
    }
    ```

    NOTE: By default, this will create a Cloud KMS key ring named, "test" in the global location, and a key named, "vault-test".

1. Update the `init.sh` script with correct parameter values in the `seal` stanza (starting at line 39):

    ```plaintext
    ...

    sudo cat << EOF > /test/vault/config.hcl
    storage "file" {
      path = "/opt/vault"
    }
    listener "tcp" {
      address     = "127.0.0.1:8200"
      tls_disable = 1
    }
    seal "gcpckms" {
      project     = "<PROJECT_ID>"
      region      = "global"
      key_ring    = "test"
      crypto_key  = "vault-test"
    }
    disable_mlock = true
    EOF

    ...
    ```

1. Terraform commands:

    ```shell
    # Pull necessary plugins
    $ terraform init

    $ terraform plan

    # Output provides the SSH instruction
    $ terraform apply
    ```

1. SSH into the EC2 machine

1. Check the Vault server status

    ```plaintext
    $ vault status
    Key                      Value
    ---                      -----
    Recovery Seal Type       gcpckms
    Initialized              false
    Sealed                   true
    Total Recovery Shares    0
    Threshold                0
    Unseal Progress          0/0
    Unseal Nonce             n/a
    Version                  n/a
    HA Enabled               false
    ```

1. Initialize Vault

    ```plaintext
    $ vault operator init -stored-shares=1 -recovery-shares=1 \
           -recovery-threshold=1 -key-shares=1 -key-threshold=1
    ```

1. Stop and start the Vault server

    ```shell
    $ sudo systemctl stop vault

    # Restart the Vault server
    $ sudo systemctl start vault
    ```

1. Check to verify that the Vault is auto-unsealed

    ```plaintext
    $ vault status
    Key                      Value
    ---                      -----
    Recovery Seal Type       shamir
    Initialized              true
    Sealed                   false
    Total Recovery Shares    1
    Threshold                1
    Version                  1.0.0-beta1
    Cluster Name             vault-cluster-a78acfcd
    Cluster ID               fdfcaf84-6333-8689-a99a-e57d60bf347f
    HA Enabled               false
    ```

1. Explorer the Vault configuration file

    ```plaintext
    $ cat /test/vault/config.hcl
    ```

1. Clean up

    ```plaintext
    $ terraform destroy -force
    $ rm -rf .terraform terraform.tfstate* private.key
    ```
