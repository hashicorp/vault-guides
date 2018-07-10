# The following are required but for security should be set as environment vars:
# AWS_ACCESS_KEY_ID
# AWS_DEFAULT_REGION
# AWS_SECRET_ACCESS_KEY
variable "aws_region" {
  default = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account id required for Vault IAM policy"
}

variable "ssh_key_name" {
  description = "Existing aws key to be associated with Vault and consumer instances"
}

variable "owner_tag" {
  description = "Tag identifying instance owner"
  default     = "Vault-aws-test"
}

variable "ttl_tag" {
  description = "TTL tracking tag for custom management"
  default     = "24"
}

variable "ami_id" {
  description = "ID of the AMI to provision. Default is Ubuntu 14.04 Base Image"
  default     = "ami-2e1ef954"
}

variable "instance_type" {
  description = "type of EC2 instance to provision."
  default     = "t2.micro"
}

/**
Provided as an example if key creation is needed (check README.md)
variable "id_rsa_pub" {
  description = "Public key contents"
  default     = "ssh-rsa AAAA...RFi9wrf+M7Q== abc@mylaptop.local"
}
*/

