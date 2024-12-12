#!/bin/bash

echo "Starting shutdown of all costly AWS resources..."

# 1. Removing Kubernetes resources
echo "Removing Kubernetes resources..."
kubectl delete services --all
kubectl delete deployments --all
kubectl delete pods --all

echo "Waiting for resources to be removed..."
sleep 30

# 2. Destroy EKS Cluster (if defined in Terraform)
echo "Destroying EKS infrastructure using Terraform..."

cd ../eks-terraform
terraform destroy -auto-approve  # Automatically approve the destruction
cd ..

# 3. Destroy Jenkins assets (if defined in Terraform)
echo "Destroying Jenkins infrastructure using Terraform..."
cd ./jenkins-terraform
terraform destroy -auto-approve  # Automatically approve the destruction
cd ..


echo "Shutdown complete. All resources should be destroyed."
