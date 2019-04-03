# Google Kubernetes Engine cluster

If you wish to test the Kubernetes auth method against an Google Kubernetes Engine (GKE) cluster instead of Minikube, you can run Terraform to provision an GKE cluster.

## Steps

1. Modify `terraform.tfvars.example` and provide GCP credentials: `account_file_path` and `project`, and save it as `terraform.tfvars`.

1. Execute the following Terraform commands:

    ```shell
    # Pull necessary plugins
    $ terraform init

    # Create an execution plan
    $ terraform plan

    # Apply to create a new GKE cluster
    $ terraform apply -auto-approve
    ```

1. Now, you should be able to start working with the AKS cluster:

    ```shell
    # To authenticate for the cluster, run the following command
    $ gcloud container clusters $(terraform output gcp_cluster_name)

    # To get the K8S cluster address
    $ kubectl cluster-info

    Kubernetes master is running at https://192.0.2.19
    ...
    ```

**NOTE:** Refer to the [Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/quickstart) documentation for more details.
