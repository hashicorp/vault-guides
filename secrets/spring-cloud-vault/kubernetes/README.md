# spring-vault-demo-kubernetes

This folder will help you deploy the sample app to Kubernetes.

Run the additional [vault script](vault.sh) in this folder to configure the Kubernetes trust relationship with Vault.

An example configmap is included for you to deploy to an existing Kubernetes cluster. The workload is modeled as code in the [spring.tf](terraform/spring.tf) Terraform file.

If you prefer to manage Kubernetes with Terraform you can use the Terraform code included in the folder. Here are two projects to help you get a Kubernetes cluster with Terraform:

- Azure: https://github.com/hashicorp/terraform-guides/tree/master/infrastructure-as-code/k8s-cluster-acs
- GKE: https://github.com/hashicorp/terraform-guides/tree/master/infrastructure-as-code/k8s-cluster-gke
