provider "vault" {
  version = ">= 1.3.1"
}

resource "vault_generic_secret" "test_secret" {
  path = "secret/test/mysecret"

  data_json = <<EOT
{
  "key":"London"
}
EOT

}

resource "vault_generic_secret" "prod_secret" {
  path = "secret/prod/mysecret"

  data_json = <<EOT
{
  "key":"Area 51"
}
EOT

}

resource "vault_policy" "reader" {
  name = "reader"

  policy = <<EOT
path "secret/data/test/*" {
  capabilities = ["read"]
}
EOT

}

data "terraform_remote_state" "gcp_project_state" {
  backend = "local"
  config = {
    path = "${path.module}/../terraform.tfstate"
  }
}

resource "vault_gcp_auth_backend" "gcp" {
  credentials  = "${file("../vaultadmin-credentials.json")}"
}

resource "vault_gcp_auth_backend_role" "gcp" {
  role                    = "web"
  type                    = "iam"
  backend                 = "gcp"
  bound_projects          = [data.terraform_remote_state.gcp_project_state.outputs.project_id]
  bound_service_accounts  = [data.terraform_remote_state.gcp_project_state.outputs.alice_account_email]
  policies                = ["reader"]
  depends_on              = [vault_gcp_auth_backend.gcp]
}

