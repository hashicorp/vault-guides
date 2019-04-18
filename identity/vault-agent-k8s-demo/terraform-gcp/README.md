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

1. Now, you should be able to start working with the GKE cluster:

    ```shell
    # Connect to your GKE cluster
    $ gcloud container clusters get-credentials $(terraform output gcp_cluster_name) \
            --zone $(terraform output gcp_zone) \
            --project $(terraform output gcp_project)

    # Now, you should be able to get the cluster info via kubectl
    $ kubectl cluster-info

    Kubernetes master is running at https://198.51.100.24
    GLBCDefaultBackend is running at https://198.51.100.24/api/v1/namespaces/...
    ...
    ```

**NOTE:** Refer to the [Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/quickstart) documentation for more details.
