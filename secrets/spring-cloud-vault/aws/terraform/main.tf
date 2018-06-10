variable ec2_ami_id {}
variable iam_ami_id {}
variable ami_owner {}
variable env {}

provider "aws" {
  region = "us-east-1"
}

provider "vault" {}

output "springboot-ec2" {
  value = "${aws_instance.spring-ec2.*.public_dns}"
}

output "springboot-iam" {
  value = "${aws_instance.spring-iam.*.public_dns}"
}
