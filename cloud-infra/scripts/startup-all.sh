#!/bin/bash

echo "Starting all AWS resources..."

# 1. Setup jenkins env (if needed)
echo "Setting up Jenkins infrastructure..."
cd ../jenkins-terraform

terraform import aws_iam_role.jenkins_role jenkins-role
terraform import aws_iam_instance_profile.jenkins_profile jenkins-profile

# Apply terraform configurations
terraform init
terraform apply -auto-approve

# Get Jenkins instance public IP
JENKINS_IP=$(terraform output -raw jenkins_public_ip)
JENKINS_PASS_LOCATION=$(terraform output -raw jenkins_initial_password_cmd)

# Apply Jenkins configuration
terraform apply -target=null_resource.jenkins_config -auto-approve
cd ..

sleep 30

# 3. Setup EKS env (if needed)
echo "Setting up EKS infrastructure..."
cd ./eks-terraform
terraform init
terraform apply -auto-approve
cd ..

echo "Startup complete. Please wait a few minutes for all services to be fully operational."

echo JENKINS_IP = $JENKINS_IP
echo JENKINS_PASS_LOCATION = $JENKINS_PASS_LOCATION
echo You can check the configure-jenkins.sh scriptlogs with: cat /tmp/jenkins-setup.log on the Jenkins EC2 instance.