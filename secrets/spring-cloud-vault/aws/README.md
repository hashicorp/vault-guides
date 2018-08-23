# spring-vault-demo-aws

This folder will help you deploy the sample app to AWS.

## Demo Instruction
We will leverage Packer and Terraform to deploy immutable instances of our application. Spring Cloud Vault supports Vault [EC2](http://cloud.spring.io/spring-cloud-static/spring-cloud-vault/2.0.0.M4/single/spring-cloud-vault.html#vault.config.authentication.awsec2) and [IAM](http://cloud.spring.io/spring-cloud-static/spring-cloud-vault/2.0.0.M4/single/spring-cloud-vault.html#vault.config.authentication.awsiam) auth natively, which we will use to authenticate our app.

### Setup
You will need a Vault instance and a Postgres instance to get started. The top-level folder has instructions on provisioning these.

1. Update the [EC2](bootstrap-ec2.yaml) and [IAM](bootstrap-iam.yaml) files for your environment.
2. [Run the Packer builds](packer/build.sh) and retrieve the AMI IDs.

```
==> amazon-ebs: Creating the AMI: llarsen-vault-aws-ec2-auth-springboot
    amazon-ebs: AMI: ami-05cf898f367c78842
==> amazon-ebs: Creating the AMI: llarsen-vault-aws-iam-auth-springboot
    amazon-ebs: AMI: ami-0c50a7e97627c1719
```

3. Update your [variables](terraform/terraform.tfvars) and run Terraform. Terraform will output your instances.

```
Outputs:

springboot-ec2 = [
    ec2-54-82-180-149.compute-1.amazonaws.com
]
springboot-iam = [
    ec2-34-229-196-83.compute-1.amazonaws.com
]
```

### Testing
You can ssh into your new instances with your springboot.pem key and check the systemd logs for the application.

```
ssh -i springboot.pem ubuntu@ec2-54-82-180-149.compute-1.amazonaws.com
journalctl -u springboot -f
```

The API will serve on port 8080. Instructions for API use can be found in the top-level folder.
You can can increase the count of the VMs using Terraform and verify the additional Vault leases and DB users.
