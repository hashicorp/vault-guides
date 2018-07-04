data "template_file" "vault_aws_auth_policy_template" {
  template = "${file("${path.module}/vault_iam_policy.json.tpl")}"

  vars {
    aws_account_id = "${var.aws_account_id}"

    # in order to avoid circular dependencies
    vault_iam_role = "vault_role"
  }
}

#resource "aws_iam_role_policy" "vault_aws_auth_policy" {
#  role   = "${aws_iam_role.vault_role.id}"
#  policy = "${data.template_file.vault_aws_auth_policy_template.rendered}"
#}
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

resource "aws_security_group_rule" "allow_vault_inbound_from_cidr_blocks" {
  count       = "${length(var.allowed_vault_cidr_blocks) >= 1 ? 1 : 0}"
  type        = "ingress"
  from_port   = "${var.vault_listening_port}"
  to_port     = "${var.vault_listening_port}"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_vault_cidr_blocks}"]

  security_group_id = "${var.vault_instance_security_group_id}"
}

#resource "aws_security_group_rule" "allow_vault_inbound_from_sg_id" {
#  count                    = "${length(var.vault_listening_port) >= 1 ? 1 : 0}"
#  type                     = "ingress"
#  from_port                = "${var.vault_listening_port}"
#  to_port                  = "${var.vault_listening_port}"
#  protocol                 = "tcp"
#  source_security_group_id = "${element(var.allowed_ssh_security_group_ids, count.index)}"


#  security_group_id = "${aws_security_group.lc_security_group.id}"
#}
/**resource "aws_iam_role" "vault_role" {
  name = "vault_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "vault_profile" {
  role       = "${aws_iam_role.vault_role.name}"
  depends_on = ["aws_iam_role.vault_role"]
}
*/

