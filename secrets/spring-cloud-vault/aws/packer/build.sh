#!/bin/bash

FAIL=0

#Get vars
if [ -z ${PACKER_ENVIRONMENT} ]; then
  read -p $'\033[1;32mPlease enter your PACKER ENVIRONMENT: \033[0m' PACKER_ENVIRONMENT
  export PACKER_ENVIRONMENT="${PACKER_ENVIRONMENT}"
else
  export PACKER_ENVIRONMENT="${PACKER_ENVIRONMENT}"
fi

if [ -z ${AWS_ACCESS_KEY_ID} ]; then
  read -p $'\033[1;32mPlease enter an AWS access key ID for Packer: \033[0m' AWS_ACCESS_KEY_ID
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
else
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
fi

if [ -z ${AWS_SECRET_ACCESS_KEY} ]; then
  read -p $'\033[1;32mPlease enter an AWS secret access key for Packer: \033[0m' AWS_SECRET_ACCESS_KEY
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
else
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
fi

#Start Jobs
echo "Starting Packer builds..."
export AWS_REGION=us-east-1
packer build -force springboot-ec2.json &
packer build -force springboot-iam.json &

#Wait for completion
for job in `jobs -p`; do
  echo $job
  wait $job || let "FAIL+=1"
done

if [ "$FAIL" == "0" ]; then
  echo -e "\033[32m\033[1m[BUILD SUCCESFUL]\033[0m"
else
  echo -e "\033[31m\033[1m[BUILD ERROR]\033[0m"
fi
