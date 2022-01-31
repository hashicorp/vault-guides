export VAULT_ADDR=$(cd infrastructure && terraform output -raw hcp_vault_public_endpoint)
export VAULT_TOKEN=$(cd infrastructure && terraform output -raw hcp_vault_admin_token)
export VAULT_NAMESPACE=admin

# Go get Private IP from task
export TF_VAR_product_db_hostname=$(cd infrastructure && terraform output -raw product_database_hostname)
export TF_VAR_product_db_username=$(cd infrastructure && terraform output -raw product_database_username)
export TF_VAR_product_db_password=$(cd infrastructure && terraform output -raw product_database_password)
export TF_VAR_product_api_efs_access_point_arn=$(cd infrastructure && terraform output -raw product_api_efs_access_point_arn)


export TF_VAR_vault_address=$(cd infrastructure && terraform output -raw hcp_vault_private_endpoint)
export TF_VAR_vault_namespace=admin

export TF_VAR_efs_file_system_id=$(cd infrastructure && terraform output -raw efs_file_system_id)
export TF_VAR_product_api_efs_access_point_id=$(cd infrastructure && terraform output -raw product_api_efs_access_point_id)
export TF_VAR_product_api_role=$(cd vault && terraform output -raw product_api_role)
export TF_VAR_product_api_role_arn=$(cd vault && terraform output -raw product_api_role_arn)
export TF_VAR_product_db_vault_path=$(cd vault && terraform output -raw product_db_vault_path)

export TF_VAR_private_subnets=$(cd infrastructure && terraform output -json private_subnets)
export TF_VAR_ecs_security_group=$(cd infrastructure && terraform output -raw ecs_security_group)
export TF_VAR_database_security_group=$(cd infrastructure && terraform output -raw database_security_group)
export TF_VAR_target_group_arn=$(cd infrastructure && terraform output -raw target_group_arn)

export PRODUCT_API_ENDPOINT=http://$(cd infrastructure && terraform output -raw product_api_endpoint)