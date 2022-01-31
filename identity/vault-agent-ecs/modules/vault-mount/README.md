# Terraform module for Vault agent volume mount

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
| [aws_efs_file_system.mount](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.mount](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecs_security_group"></a> [ecs\_security\_group](#input\_ecs\_security\_group) | Security group for ECS cluster | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name for task that runs with Vault agent | `string` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of private subnets for EFS mount | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to add to EFS resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_file_system_arn"></a> [file\_system\_arn](#output\_file\_system\_arn) | ARN of EFS file system ID for ECS tasks with Vault agents |
| <a name="output_file_system_id"></a> [file\_system\_id](#output\_file\_system\_id) | ID of EFS file system for ECS tasks with Vault agents |
