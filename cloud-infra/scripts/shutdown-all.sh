#!/bin/bash

echo "Starting shutdown of all costly AWS resources..."

# 1. Jenkins EC2 Instance
echo "Stopping Jenkins EC2 instance..."
jenkins_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=jenkins-server" --query 'Reservations[].Instances[].InstanceId' --output text)
if [ ! -z "$jenkins_id" ]; then
    aws ec2 stop-instances --instance-ids $jenkins_id
    echo "Jenkins instance stopped"
fi

# 2. EKS Cluster (if exists)
echo "Destroying EKS infrastructure..."
cd ../eks-terraform
terraform destroy -auto-approve
cd ..

# 3. Clean ECR images (optional)
echo "Cleaning up ECR images..."
aws ecr list-images --repository-name flask-app --query 'imageIds[*]' --output text | while read -r imageId; do
    aws ecr batch-delete-images --repository-name flask-app --image-ids imageDigest=$imageId
done

echo "Shutdown complete. All costly resources should be stopped."
