variable "aws_region" {
  description = "AWS region you wish to provision cloud resources"
  default = "us-east-1"
}

variable "environment_name" {
  description = "All resources will be tagged with this"
  default = "vault-chef-approle-demo"
}

variable "vault_zip_url" {
  default = "https://releases.hashicorp.com/vault/1.3.0/vault_1.3.0_linux_amd64.zip"
}

variable "vpc_id" {
  description = "VPC ID in which to create security group(s)"
}

variable "subnet_id" {
  description = "Subnet ID in which to install"
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


//--------------------------------------------------------------------
// Chef Variables

variable "chef_server_package_url" {
  default = "https://packages.chef.io/files/stable/chef-server/12.17.15/ubuntu/16.04/chef-server-core_12.17.15-1_amd64.deb"
}

variable "chef_dk_package_url" {
  default = "https://packages.chef.io/files/stable/chefdk/2.4.17/ubuntu/16.04/chefdk_2.4.17-1_amd64.deb"
}

variable "chef_admin" {
  default = "demo-admin"
}

variable "chef_admin_password" {
  default = "changeme"
}

variable "chef_org" {
  default = "demo-org"
}

variable "chef_app_name" {
  default = "chef-demo-app"
}
