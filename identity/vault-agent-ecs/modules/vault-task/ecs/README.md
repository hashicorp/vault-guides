# Terraform module for ECS task definition with Vault agent sidecar

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.72 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecs_task_definition.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | Application [container definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions). | `any` | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Number of cpu units used by the task. | `number` | `256` | no |
| <a name="input_efs_access_point_id"></a> [efs\_access\_point\_id](#input\_efs\_access\_point\_id) | EFS access point ID for Vault agent in the ECS task definition | `string` | n/a | yes |
| <a name="input_efs_file_system_id"></a> [efs\_file\_system\_id](#input\_efs\_file\_system\_id) | EFS file system ID for Vault agent in the ECS task definition | `string` | n/a | yes |
| <a name="input_execution_role"></a> [execution\_role](#input\_execution\_role) | ECS execution role to include in the task definition. If not provided, a role is created. | <pre>object({<br>    id  = string<br>    arn = string<br>  })</pre> | n/a | yes |
| <a name="input_family"></a> [family](#input\_family) | Task definition [family](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#family). This is used by default as the Consul service name if `consul_service_name` is not provided. | `string` | n/a | yes |
| <a name="input_log_configuration"></a> [log\_configuration](#input\_log\_configuration) | Task definition [log configuration object](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html). | `any` | `null` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Amount (in MiB) of memory used by the task. | `number` | `512` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the service. Defaults to the Task family name. | `string` | `""` | no |
| <a name="input_requires_compatibilities"></a> [requires\_compatibilities](#input\_requires\_compatibilities) | Set of launch types required by the task. | `list(string)` | <pre>[<br>  "EC2",<br>  "FARGATE"<br>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to add to ECS task resources. | `map(string)` | `{}` | no |
| <a name="input_task_role"></a> [task\_role](#input\_task\_role) | ECS task role to include in the task definition. If not provided, a role is created. | <pre>object({<br>    id  = string<br>    arn = string<br>  })</pre> | n/a | yes |
| <a name="input_vault_address"></a> [vault\_address](#input\_vault\_address) | The Vault address for the cluster. | `string` | n/a | yes |
| <a name="input_vault_agent_template"></a> [vault\_agent\_template](#input\_vault\_agent\_template) | The base64-encoded Vault agent template to render secrets. | `string` | n/a | yes |
| <a name="input_vault_agent_template_file_name"></a> [vault\_agent\_template\_file\_name](#input\_vault\_agent\_template\_file\_name) | File name of Vault agent template to render secrets. Default is `secrets`. | `string` | `"secrets"` | no |
| <a name="input_vault_ecs_image"></a> [vault\_ecs\_image](#input\_vault\_ecs\_image) | Vault agent ECS Docker image. | `string` | `"joatmon08/vault-agent-ecs:1.9.2"` | no |
| <a name="input_vault_namespace"></a> [vault\_namespace](#input\_vault\_namespace) | The Vault namespace for the cluster. | `string` | `null` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | List of volumes to include in the aws\_ecs\_task\_definition resource. | `any` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | n/a |
