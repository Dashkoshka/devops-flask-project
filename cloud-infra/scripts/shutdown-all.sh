#!/bin/bash

echo "Starting shutdown of all costly AWS resources..."

# 2. Destroy Jenkins assets (if defined in Terraform)
echo "Destroying Jenkins infrastructure using Terraform..."
cd ../jenkins-terraform
terraform init  # Ensure the Terraform workspace is initialized
terraform destroy -auto-approve  # Automatically approve the destruction
cd ..

# 2. Destroy EKS Cluster (if defined in Terraform)
echo "Destroying EKS infrastructure using Terraform..."

cd ./eks-terraform
terraform init  # Ensure the Terraform workspace is initialized
terraform destroy -auto-approve  # Automatically approve the destruction
cd ..

echo "Shutdown complete. All resources should be destroyed."
