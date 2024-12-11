provider "aws" {
  region = "us-east-1"
}

# VPC Configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"
  azs = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = "dev"
    Project = "DevOps-Project"
  }
}

# KMS Key for EKS
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = "dev"
    Project     = "DevOps-Project"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/eks/my-eks-cluster"
  target_key_id = aws_kms_key.eks.key_id
}

# EKS Cluster Configuration
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.27"
  
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets
  
  cluster_endpoint_public_access = true

  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  create_cloudwatch_log_group = false

  eks_managed_node_groups = {
    general = {
      desired_size    = 1
      min_size       = 1
      max_size       = 1
      instance_types = ["t3.micro"]
      capacity_type  = "SPOT"
      disk_size      = 20
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  tags = {
    Environment = "dev"
    Project     = "DevOps-Project"
  }
}

# ECR Repository
resource "aws_ecr_repository" "flask_app" {
  name                 = "flask-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "dev"
    Project     = "DevOps-Project"
  }
}

# IAM Role Policy for EKS
resource "aws_iam_role_policy" "eks_cluster_policy" {
  name = "eks-cluster-policy"
  role = module.eks.cluster_iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Outputs
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1"
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value = aws_ecr_repository.flask_app.repository_url
}