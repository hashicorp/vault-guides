# Vault Agent with Amazon ECS

This directory contains example code for retrieving secrets for an Amazon ECS task from Vault using Vault Agent. Refer to the [Vault Agent with Amazon Elastic Container Service](https://learn.hashicorp.com/tutorials/vault/agent-aws-ecs) tutorial for step-by-step instruction.

## Prerequistes

- Terraform 1.0+
- Vault 1.9+
- Hashicorp Cloud Platform (service principal credentials)

## Modules

YYou can reuse some of the local modules in the `modules/` directory for your own ECS task definition.

- `vault-mount`: sets up the EFS file system and mount targets
- `vault-task/iam`: sets up the task IAM role that Vault will use in its AWS IAM auth method
- `vault-task/ecs`: sets up the task definition with a Vault agent sidecar

## Usage

1. Set up [HCP service principal credentials](https://registry.terraform.io/providers/hashicorp/hcp/latest/docs/guides/auth) as environment variables.
   ```shell
   export HCP_CLIENT_ID=$HCP_CLIENT_ID
   export HCP_CLIENT_SECRET=$HCP_CLIENT_SECRET
   ```

1. Set up AWS environment variables.

### Create demo infrastructure

This step creates an application load balancer, ECS cluster, HCP Vault cluster,
networks, and an ECS task definition for the database.

1. In your terminal, navigate to the `infrastructure/` directory.
   ```shell
   cd infrastructure/
   ```

1. Initialize Terraform.
   ```shell
   terraform init
   ```

1. Apply Terraform. This step will take some time!
   ```shell
   terraform apply
   ```

1. Return to the top-level directory.
   ```shell
   cd ../
   ```

1. Set up input variables for the next Terraform configuration.
   ```shell
   source set.sh
   ```

### Configure Vault

This step configures Vault with the database secrets engine and AWS IAM auth method.

1. In your terminal, navigate to the `vault/` directory.
   ```shell
   cd vault/
   ```

1. Initialize Terraform.
   ```shell
   terraform init
   ```

1. Apply Terraform. This configures Vault with the database secrets engine and
   AWS IAM auth method.
   ```shell
   terraform apply
   ```

1. Return to the top-level directory.
   ```shell
   cd ../
   ```

1. Set up input variables for the next Terraform configuration.
   ```shell
   source set.sh
   ```

### Deploy example application

This step deploys an example ECS task definition. The task definition includes
an application (`product-api`) and uses a local module to inject the Vault sidecar.

1. In your terminal, navigate to the `vault/` directory.
   ```shell
   cd application/
   ```

1. Initialize Terraform.
   ```shell
   terraform init
   ```

1. Apply Terraform. This deploys an AWS ECS task for the `product-api`.
   ```shell
   terraform apply
   ```

1. You can test if the endpoint works by access the `product-api` over its application
   load balancer endpoint.
   ```shell
   $ curl $PRODUCT_API_ENDPOINT/coffees

   [{"id":1,"name":"HashiCup","teaser":"Automation in a cup","description":"","price":200,"image":"/hashicorp.png","ingredients":[{"ingredient_id":6}]},{"id":2,"name":"Packer Spiced Latte","teaser":"Packed with goodness to spice up your images","description":"","price":350,"image":"/packer.png","ingredients":[{"ingredient_id":1},{"ingredient_id":2},{"ingredient_id":4}]},{"id":3,"name":"Vaulatte","teaser":"Nothing gives you a safe and secure feeling like a Vaulatte","description":"","price":200,"image":"/vault.png","ingredients":[{"ingredient_id":1},{"ingredient_id":2}]},{"id":4,"name":"Nomadicano","teaser":"Drink one today and you will want to schedule another","description":"","price":150,"image":"/nomad.png","ingredients":[{"ingredient_id":1},{"ingredient_id":3}]},{"id":5,"name":"Terraspresso","teaser":"Nothing kickstarts your day like a provision of Terraspresso","description":"","price":150,"image":"/terraform.png","ingredients":[{"ingredient_id":1}]},{"id":6,"name":"Vagrante espresso","teaser":"Stdin is not a tty","description":"","price":200,"image":"/vagrant.png","ingredients":[{"ingredient_id":1}]},{"id":7,"name":"Connectaccino","teaser":"Discover the wonders of our meshy service","description":"","price":250,"image":"/consul.png","ingredients":[{"ingredient_id":1},{"ingredient_id":5}]},{"id":8,"name":"Boundary Red Eye","teaser":"Perk up and watch out for your access management","description":"","price":200,"image":"/boundary.png","ingredients":[{"ingredient_id":1},{"ingredient_id":6}]},{"id":9,"name":"Waypointiato","teaser":"Deploy with a little foam","description":"","price":250,"image":"/waypoint.png","ingredients":[{"ingredient_id":1},{"ingredient_id":2}]}]
   ```

## Clean Up

```shell
bash clean.sh
```