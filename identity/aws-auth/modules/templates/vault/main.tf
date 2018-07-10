data "template_file" "vault_aws_auth_policy_template" {
  template = "${file("${path.module}/vault_iam_policy.json.tpl")}"

  vars {
    aws_account_id = "${var.aws_account_id}"

    # in order to avoid circular dependencies
    vault_iam_role = "vault_role"
  }
}

resource "aws_iam_user" "vault_demo_user" {
  name = "vault_demo_user"
}

resource "aws_iam_access_key" "vault_demo_user_key" {
  user = "${aws_iam_user.vault_demo_user.name}"
}

resource "aws_iam_user_policy" "vault_demo_user_policy" {
  user = "${aws_iam_user.vault_demo_user.name}"

  policy = "${data.template_file.vault_aws_auth_policy_template.rendered}"
}

data "template_file" "vault_init_config" {
  template = "${file("${path.module}/vault_init_config.sh.tpl")}"

  vars {
    aws_access_key_id     = "${aws_iam_access_key.vault_demo_user_key.id}"
    aws_secret_access_key = "${aws_iam_access_key.vault_demo_user_key.secret}"
    aws_account_id        = "${var.aws_account_id}"
    aws_auth_iam_role     = "${var.aws_auth_iam_role}"
  }
}
