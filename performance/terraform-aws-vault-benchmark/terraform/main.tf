provider "aws" {}

resource "random_id" "environment_name" {
  byte_length = 4
  prefix      = "${var.env}-"
}
