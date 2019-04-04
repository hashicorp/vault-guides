resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10

  tags {
    Name = "vault-kms-unseal-${random_pet.env.id}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = "true"
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "vault" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  count         = 3
  subnet_id     = "${aws_subnet.public_subnet.id}"
  key_name      = "vault-kms-unseal-${random_pet.env.id}"

  security_groups = [
    "${aws_security_group.vault.id}",
  ]

  associate_public_ip_address = true
  ebs_optimized               = false
  iam_instance_profile        = "${aws_iam_instance_profile.vault-kms-unseal.id}"

  tags {
    Name = "Vault_KMS_unseal_cluster"
    environment_name = "vault-kms-unseal-${random_pet.env.id}"
  }

  user_data = "${data.template_file.vault.rendered}"
}

data "template_file" "vault" {
  template = "${file("userdata.tpl")}"

  vars = {
    kms_key    = "${aws_kms_key.vault.id}"
    vault_url  = "${var.vault_url}"
    aws_region = "${var.aws_region}"
    cluster_size = "3"
    environment_name = "vault-kms-unseal-${random_pet.env.id}"
  }
}

data "template_file" "format_ssh" {
  template = "connect to host with following command: ssh ubuntu@$${admin} -i private.key"

  vars {
    admin = "${aws_instance.vault.0.public_ip}"
  }
}

output "connections" {
  value = <<VAULT
Connect to Node1 via SSH   ssh ubuntu@${aws_instance.vault.0.public_ip} -i private.key
Vault Enterprise web interface  http://${aws_instance.vault.0.public_ip}:8200/ui

Connect to Node2 via SSH   ssh ubuntu@${aws_instance.vault.1.public_ip} -i private.key
Vault Enterprise web interface  http://${aws_instance.vault.1.public_ip}:8200/ui

Connect to Node3 via SSH   ssh ubuntu@${aws_instance.vault.2.public_ip} -i private.key
Vault Enterprise web interface  http://${aws_instance.vault.2.public_ip}:8200/ui
VAULT
}

resource "aws_security_group" "vault" {
  name        = "vault-kms-unseal-${random_pet.env.id}"
  description = "vault access"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name = "vault-kms-unseal-${random_pet.env.id}"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault Client Traffic
  ingress {
    from_port   = 8200
    to_port     = 8201
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    # DNS (TCP)
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS (UDP)
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Consul
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Serf LAN (TCP)
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Serf LAN (UDP)
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    # Serf WAN (TCP)
  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Serf WAN (UDP)
  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul Server RPC
  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RPC Consul
  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
