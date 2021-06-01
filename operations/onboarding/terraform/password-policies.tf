resource "vault_password_policy" "database-example" {
  name = "database-example"

  policy = <<EOT
length = 20

rule "charset" {
  charset = "abcdefghijklmnopqrstuvwxyz"
  min-chars = 1
}

rule "charset" {
  charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  min-chars = 1
}

rule "charset" {
  charset = "0123456789"
  min-chars = 1
}

rule "charset" {
  charset = "!@#$%^&*"
  min-chars = 1
}
EOT
}

resource "vault_password_policy" "database-short-example" {
  name = "database-short-example"

  policy = <<EOT
length = 5

rule "charset" {
  charset = "abcde"
  min-chars = 1
}

rule "charset" {
  charset = "ABCDE"
  min-chars = 1
}

rule "charset" {
  charset = "01234"
  min-chars = 1
}
EOT
}
