# Demonstrate AWS IAM and ec2 authentication methods

This guide will demonstrate Vault's AWS ec2 authentication method. It will rely on userdata to explicitly execute a shell script authenticating to Vault and retrieving a secret. 

You can go directly to the authentication code [here](modules/templates/consumer/consumer_install.sh.tpl)

The authentication will be done using the instance ami and the corresponding pkcs7 signature with a fixed nonce. For alternate approaches check the *Reference Material* section below. 

## Reference Material
Complete documentation of the Vault AWS authentication method, including alternative approaches such as using IAM roles and an extensive discussion on nonce strategies can be found here:
https://www.vaultproject.io/docs/auth/aws.html

## Note
The code in this repository is for reference only. It is meant to illustrate a few of the requirements for using the AWS authentication method, however it makes certain decisions such as running Vault in dev mode which are not meant for production use.

## Estimated Time to Complete
10 minutes

## Personas
AWS admin must provide credentials with permissions to execute the Terraform script for this demo.
AWS admin must also provide credentials with specific permissions required by Vault to validate authentication requests.
Vault admin must run this code and configure Vault.

## Challenge
Users of Vault eventually find themselves with a chicken-and-egg problem of where to store the initial secret/password that will allow clients to authenticate and retrieve secrets. 

## Solution
Using AWS as a trusted entity means shifting the trust burden to AWS, where Vault validates authentication requests using AWS-issued signatures available for every ec2 instance or Lambda function. The key to making is work is relying on AWS self-lookup capabilities which allows instances to retrieve and share these signatures.

## Prerequisites
- AWS account with sufficient privileges
- Terraform. Installation isntructions here: https://learn.hashicorp.com/tutorials/terraform/install-cli

## Steps
The bellow steps should be executed in a terminal (or Terraform Enterprise UI) once this repository is cloned

### Step 1: Update environment variables
If not already configured, set your aws environment variables with a user credential that has permissions to create IAM roles and ec2 instances:
```
export AWS_ACCESS_KEY_ID=<Your AWS key id>
export AWS_SECRET_ACCESS_KEY=<Your AWS secret access key>
export AWS_DEFAULT_REGION=<Your default region>
```
### Step 2: Update terraform variables
At a minimum, the following must be updated:
- ssh_key_name
- aws_account_id

### Step 3: Execute terraform plan
```
terraform plan
```

### Step 4: Execute terraform apply
If satisfied with the plan:
```
terraform apply
yes
```

### Step 5: Validate consumer authenticated and retrieved secret
Once instances created, ssh into the consumer instance and validate secret retrieved:
```
ssh -i <Path to your ssh_key file> ubuntu@<Public ip of consumer instance>
cat /tmp/vault_secret.txt

# Output:
#  Secret retrieved from Vault: ThisTestWasSuccessful!
```

### Step 6: Execute terraform destroy
To clear all resources, execute:
```
terraform destroy
yes
```

## Reviewing the Terraform code
The Terraform code in this repository is divided into modules, for reuse:
- modules/ec2 has logic for creating generic ec2 instances
- modules/security has the generic security group rules
- templates/consumer has the information specific to a Vault consumer
- templates/vault has the information specific to a Vault server

## Additional Examples
An alternative example showcasing AWS auth method using Terraform resources can be found [here](https://github.com/hashicorp/terraform-guides/tree/master/infrastructure-as-code/dynamic-aws-creds)

