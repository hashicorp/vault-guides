variable "aws_region" {
  description = "AWS region you wish to provision cloud resources"
  default = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID in which to create security group(s)"
}

variable "subnet_id" {
  description = "Subnet ID in which to install"
}

variable "environment_name" {
  description = "All resources will be tagged with this"
  default = "vault-chef-approle-demo"
}

variable "instance_type" {
  description = "Amazon EC2 instance size to use"
  default = "t2.micro"
}

variable "key_name" {
  description = "EC2 SSH key-pair name to attach to instance"
}

variable "ec2_pem" {
  description = "File path to EC2 SSH key .pem file for Chef provisioner connection"
}

variable "s3_bucket_name" {
  description = "S3 bucket for demo - must exists"
}

variable "vault_address" {
  description = "Vault Server IP address (public if you want to access from outside your VPC)"
}

variable "vault_token" {
  description = "Token that Terraform will use to retrieve AppRole RoleID from Vault"
}

variable "chef_server_address" {
  description = "Chef Server IP address (public if you want to access from outside your VPC)"
}
