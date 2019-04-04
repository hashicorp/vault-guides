provider "vault" {
  version = ">= 1.3.1"
}

resource "vault_policy" "reader" {
  name = "reader"

  policy = <<EOT
path "secret/demo" {

  capabilities = ["read"]
}
EOT
}

resource "vault_generic_secret" "demo_secret" {
  path = "secret/demo"

  data_json = <<EOT
{

  "location": "London"
}
EOT
}

data "terraform_remote_state" "gcp_project_state" {
  backend = "local"
  config {
    path = "${path.module}/../terraform.tfstate"
  }
}

resource "vault_gcp_auth_backend_role" "gcp" {
  role                   = "web"
  type                   = "gce"
  backend                = "gcp"
  project_id             = "${data.terraform_remote_state.gcp_project_state.project_id}"
  bound_regions          = ["europe-west2"]
  policies               = ["reader"]
}
