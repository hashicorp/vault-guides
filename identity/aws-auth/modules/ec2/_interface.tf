variable "aws_region" {}

variable "owner_tag" {}

variable "ttl_tag" {}

variable "ami_id" {}

variable "instance_type" {}
variable "ssh_key_name" {}

/**
Provided as an example if key creation is needed (check README.md)
variable "id_rsa_pub" {}
*/
variable "name_prefix" {}

variable "user_data" {}

variable "iam_instance_profile_name" {
  default = ""
}

output "ip" {
  value = "${aws_instance.ubuntu.public_ip}"
}
