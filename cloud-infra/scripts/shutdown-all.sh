#!/bin/bash

echo "Starting shutdown of all costly AWS resources..."

# 1. Removing Kubernetes resources
echo "Removing Kubernetes resources..."
# Check if kubectl can access the cluster
if kubectl get nodes &>/dev/null; then
    # Delete resources in parallel with wait
    kubectl delete all --all --all-namespaces --wait=true
    
    # Delete persistent volumes and claims
    kubectl delete pvc --all --all-namespaces
    kubectl delete pv --all --all-namespaces
    
    # Delete config maps and secrets
    kubectl delete configmap --all --all-namespaces
    kubectl delete secret --all --all-namespaces --field-selector type!=kubernetes.io/service-account-token
    
    echo "Waiting for resources to be removed..."
    sleep 30
else
    echo "Cannot access Kubernetes cluster, skipping resource deletion"
fi

echo "Waiting for resources to be removed..."
sleep 30

# 2. Destroy EKS Cluster (if defined in Terraform)
echo "Destroying EKS infrastructure using Terraform..."

cd ../eks-terraform
terraform destroy -auto-approve  # Automatically approve the destruction
# Cleanup terraform state files to prevent version mismatch or corruption next time we start up the infrastructure
rm -f .terraform.lock.hcl
rm -f terraform.tfstate*
rm -rf .terraform/
cd ..

# 3. Destroy Jenkins assets (if defined in Terraform)
echo "Destroying Jenkins infrastructure using Terraform..."
cd ./jenkins-terraform
terraform destroy -auto-approve  # Automatically approve the destruction

# Additional cleanup for Jenkins IAM resources if terraform destroy failed
echo "Cleaning up any remaining IAM resources..."
aws iam remove-role-from-instance-profile --instance-profile-name jenkins-profile --role-name jenkins-role || true
aws iam delete-instance-profile --instance-profile-name jenkins-profile || true

# Cleanup terraform state files to prevent version mismatch or corruption next time we start up the infrastructure
rm -f .terraform.lock.hcl
rm -f terraform.tfstate*
rm -rf .terraform/
cd ..


echo "Shutdown complete. All resources should be destroyed."
