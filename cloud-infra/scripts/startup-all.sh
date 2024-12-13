#!/bin/bash

echo "Starting all AWS resources..."

# 1. Setup jenkins env (if needed)
echo "Setting up Jenkins infrastructure..."
cd ../jenkins-terraform

# Check and delete existing instance profile if it exists
echo "Checking for existing instance profile..."
if aws iam get-instance-profile --instance-profile-name jenkins-profile >/dev/null 2>&1; then
    echo "Deleting existing instance profile..."
    # Remove roles from instance profile first
    aws iam remove-role-from-instance-profile --instance-profile-name jenkins-profile --role-name jenkins-role || true
    # Wait a bit for removal to propagate
    sleep 10
    # Delete the instance profile
    aws iam delete-instance-profile --instance-profile-name jenkins-profile || true
    # Wait for deletion to complete
    sleep 10
fi

# Apply terraform configurations
terraform init                  # Fresh initialization with latest providersg
terraform apply -auto-approve   # Apply the configuration

# Get Jenkins instance public IP
JENKINS_IP=$(terraform output -raw jenkins_public_ip)
JENKINS_PASS_LOCATION=$(terraform output -raw jenkins_initial_password_cmd)

# Apply Jenkins configuration
terraform apply -target=null_resource.jenkins_config -auto-approve
cd ..

echo "Waiting for Jenkins to be ready..."
sleep 10

# 3. Setup EKS env (if needed)
echo "Setting up EKS infrastructure..."
cd ./eks-terraform

# Apply terraform configurations
terraform init                  # Fresh initialization with latest providers
terraform apply -auto-approve   # Apply the configuration
cd ..

echo "Waiting for EKS cluster to be fully operational..."
sleep 30

echo "Startup complete. Please wait a few minutes for all services to be fully operational."

echo JENKINS_IP = $JENKINS_IP
echo JENKINS_PASS_LOCATION = $JENKINS_PASS_LOCATION
echo You can check the configure-jenkins.sh scriptlogs with: cat /tmp/jenkins-setup.log on the Jenkins EC2 instance.