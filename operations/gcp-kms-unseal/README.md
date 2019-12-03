# Vault Auto-unseal using GCP Cloud KMS

These assets are provided to perform the tasks described in the [Auto-unseal with Google Cloud
KMS](https://learn.hashicorp.com/vault/operations/autounseal-gcp-kms) guide.

---

## Steps

1. Set this location as your working directory

1. Provide necessary GCP account information in the `terraform.tfvars.example` and save it as `terraform.tfvars`.

    **Example:**

    ```shell
    gcloud-project = "vault-test"
    account_file_path = "/tmp/GCP/my-service-account.json"
    ```

    > Set the `account_file_path` to where your Cloud IAM service account file is located. This is the service account that the Terraform uses to provision GCP resources. If you do not have one, follow the [GCP documentation](https://cloud.google.com/docs/authentication/getting-started) to create a service account and download the JSON file.

1. This guide expects a Cloud KMS key ring and crypto key to already exists. If you **don't** have one to use for Vault auto-unseal, un-comment the key ring and key creation portion in the `main.tf` file.  **NOTE:** Keep line 93 commented out and use line 92.

    ```shell
    ...

    # Create a KMS key ring
    resource "google_kms_key_ring" "key_ring" {
       project  = "${var.gcloud-project}"
       name     = "${var.key_ring}"
       location = "${var.keyring_location}"
    }

    # Create a crypto key for the key ring
    resource "google_kms_crypto_key" "crypto_key" {
       name            = "${var.crypto-key}"
       key_ring        = "${google_kms_key_ring.key_ring.self_link}"
       rotation_period = "100000s"
    }

    # Add the service account to the Keyring
    resource "google_kms_key_ring_iam_binding" "vault_iam_kms_binding" {
      key_ring_id = "${google_kms_key_ring.key_ring.id}"
      # key_ring_id = "${var.gcloud-project}/${var.keyring_location}/${var.key_ring}"
      role = "roles/owner"

      members = [
        "serviceAccount:${var.service_acct_email}",
      ]
    }
    ```

    NOTE: By default, this will create a Cloud KMS key ring named, "test" in the **global** location, and a key named, "vault-test".

    If you are using your own KMS key ring and its crypto key, be sure to set the correct `key_ring` and `crypto_key` values in the `terraform.tfvars` file.

    **Example: `terraform.tfvars`**

    ```
    gcloud-project = "my-project"
    account_file_path = "/usr/gcp/my-project.json"
    key_ring = "key_ring_name"
    crypto_key = "crypto_key_name"
    keyring_location = "global"
    ```

    In the `main.tf` file, un-comment line 92, and comment out line 92 as shown below:

    ```shell
    ...
    # Add the service account to the Keyring
    resource "google_kms_key_ring_iam_binding" "vault_iam_kms_binding" {
      # key_ring_id = "${google_kms_key_ring.key_ring.id}"
      key_ring_id = "${var.gcloud-project}/${var.keyring_location}/${var.key_ring}"
      role = "roles/owner"

      members = [
        "serviceAccount:${var.service_acct_email}",
      ]
    }
    ```

1. Terraform commands:

    ```shell
    # Pull necessary plugins
    $ terraform init

    $ terraform plan

    # Output provides the SSH instruction
    $ terraform apply
    ```

1. [SSH into the compute instance](https://cloud.google.com/compute/docs/instances/connecting-to-instance)

    ```plaintext
    $ export instance_id=$(terraform output vault_server_instance_id)
    $ export project=$(terraform output project)
    $ gcloud compute ssh ${instance_id} --project ${project}
    ```

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
    $ vault operator init -key-shares=1 -key-threshold=1
    ```

1. Stop and start the Vault server

    ```shell
    $ sudo systemctl restart vault
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
