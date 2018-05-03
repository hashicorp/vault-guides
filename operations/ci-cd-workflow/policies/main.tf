#Policies 

resource "vault_policy" "dev" {
  name = "dev"

  policy = <<EOF
path "secret/my_app" {
  policy = "read"
}
EOF
}

resource "vault_policy" "prod" {
  name = "prod"

  policy = <<EOF
path "secret/prod/my_app" {
  policy = "read"
}
EOF
}
