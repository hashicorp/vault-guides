provider "aws" {
  region = var.region
}

resource "random_id" "environment_name" {
  byte_length = 4
  prefix      = "${var.env}-"
}

