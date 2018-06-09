resource "vault_auth_backend" "aws-ec2" {
  type = "aws"
  path = "aws-ec2"
}

resource "vault_auth_backend" "aws-iam" {
  type = "aws"
  path = "aws-iam"
}

resource "vault_aws_auth_backend_client" "ec2" {
  backend = "${vault_auth_backend.aws-ec2.path}"
  access_key = "${aws_iam_access_key.vault.id}"
  secret_key = "${aws_iam_access_key.vault.secret}"
}

resource "vault_aws_auth_backend_client" "iam" {
  backend = "${vault_auth_backend.aws-iam.path}"
  access_key = "${aws_iam_access_key.vault.id}"
  secret_key = "${aws_iam_access_key.vault.secret}"
}

resource "vault_aws_auth_backend_role" "aws-ec2" {
  backend                        = "${vault_auth_backend.aws-ec2.path}"
  role                           = "order"
  auth_type                      = "ec2"
  bound_ami_id                   = "${var.ec2_ami_id}"
  policies                       = ["order"]
}

resource "vault_aws_auth_backend_role" "aws-iam" {
  backend                        = "${vault_auth_backend.aws-iam.path}"
  role                           = "order"
  auth_type                      = "iam"
  bound_iam_principal_arn        = "${aws_iam_role.springboot.arn}"
  policies                       = ["order"]
}
