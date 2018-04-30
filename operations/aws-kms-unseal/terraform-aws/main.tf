provider "aws" {
  region = "${var.aws_region}"
}

resource "random_pet" "env" {
  length    = 2
  separator = "_"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "vault-kms-unseal-${random_pet.env.id}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "vault-kms-unseal-${random_pet.env.id}"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.vpc_cidr}"
  availability_zone       = "${var.aws_zone}"
  map_public_ip_on_launch = true

  tags {
    Name = "vault-kms-unseal-${random_pet.env.id}"
  }
}

resource "aws_route_table" "route" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "vault-kms-unseal-${random_pet.env.id}"
  }
}

resource "aws_route_table_association" "route" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.route.id}"
}
