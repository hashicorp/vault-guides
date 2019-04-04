data "aws_ami" "spring-ec2" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["${var.ec2_ami_id}"]
  }

  owners = ["${var.ami_owner}"]
}

data "aws_ami" "spring-iam" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["${var.iam_ami_id}"]
  }

  owners = ["${var.ami_owner}"]
}

resource "aws_key_pair" "springboot" {
  key_name   = "${var.env}"
  public_key = "${tls_private_key.springboot.public_key_openssh}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "spring-ec2" {
  count = 1
  ami           = "${data.aws_ami.spring-ec2.id}"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = "${aws_key_pair.springboot.key_name}"
  security_groups = ["${aws_security_group.allow_all.name}"]
  tags {
    env = "${var.env}"
  }
}

resource "aws_instance" "spring-iam" {
  count = 1
  ami           = "${data.aws_ami.spring-iam.id}"
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.springboot.name}"
  associate_public_ip_address = true
  key_name = "${aws_key_pair.springboot.key_name}"
  security_groups = ["${aws_security_group.allow_all.name}"]
  tags {
    env = "${var.env}"
  }
}
