resource "vault_auth_backend" "aws" {
  type = "aws"
}

resource "vault_aws_auth_backend_role" "ecs" {
  backend                  = vault_auth_backend.aws.path
  role                     = "${var.name}-product-api"
  auth_type                = "iam"
  resolve_aws_unique_ids   = false
  bound_iam_principal_arns = [module.task_role.arn]
  token_policies           = [vault_policy.product.name]
}