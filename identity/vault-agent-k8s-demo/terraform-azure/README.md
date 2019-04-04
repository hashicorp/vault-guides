# Azure Kubernetes Service cluster

If you wish to test the Kubernetes auth method against an Azure Kubernetes Service (AKS) cluster instead of Minikube, you can run Terraform to provision an AKS cluster.

## Steps

1. Modify `terraform.tfvars.example` and provide Azure credentials: `client_id` and `client_secret`, and save it as `terraform.tfvars`.

1. Execute the following Terraform commands:

    ```shell
    # Pull necessary plugins
    $ terraform init

    # Create an execution plan
    $ terraform plan

    # Apply to create a new AKS cluster
    $ terraform apply -auto-approve
    ```

1. Now, you should be able to start working with the AKS cluster:

    ```plaintext
    $ kubectl cluster-info
    ```

**NOTE:** Refer to the [Azure Kubernetes Service Cluster](https://deploy-preview-391--hashicorp-learn.netlify.com/vault/identity-access-management/vault-agent-k8s#azure-kubernetes-service-cluster) section in the guide.
