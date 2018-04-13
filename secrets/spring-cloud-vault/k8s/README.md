# spring-vault-demo-k8s

This folder will help you deploy the sample app to K8s.

Run the [vault script](vault.sh) to configure the K8s trust relationship with Vault.

An example configmap is included for you to deploy to an existing K8s cluster. The workload is modeled as code in the [spring.tf](terraform/spring.tf) Terraform file.

If you prefer to manage K8s with Terraform you can use the Terraform code included in the folder. Here are two projects to help you get a K8s cluster with Terraform:

Azure: https://github.com/hashicorp/terraform-guides/tree/master/infrastructure-as-code/k8s-cluster-acs
GKE: https://github.com/hashicorp/terraform-guides/tree/master/infrastructure-as-code/k8s-cluster-gke
