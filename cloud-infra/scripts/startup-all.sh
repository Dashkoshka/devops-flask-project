#!/bin/bash

echo "Starting all AWS resources..."

# 1. Start Jenkins
echo "Starting Jenkins EC2 instance..."
jenkins_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=jenkins-server" --query 'Reservations[].Instances[].InstanceId' --output text)
if [ ! -z "$jenkins_id" ]; then
    aws ec2 start-instances --instance-ids $jenkins_id
    echo "Jenkins instance started"
fi

# 2. Setup EKS (if needed)
echo "Setting up EKS infrastructure..."
cd ../eks-terraform
terraform apply -auto-approve
cd ..

echo "Startup complete. Please wait a few minutes for all services to be fully operational."
