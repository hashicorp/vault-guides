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

**NOTE:** In `setup-k8s-spec.sh` file, be sure to replace _Line 34_ to point to the AKS cluster address rather than
`export K8S_HOST=$(minikube ip)`. 
