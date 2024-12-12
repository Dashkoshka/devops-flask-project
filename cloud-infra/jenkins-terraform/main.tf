# Provider Configuration
provider "aws" {
  region = "us-east-1"
}

# VPC Configuration
resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "jenkins-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "jenkins_public_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "jenkins-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = "jenkins-igw"
  }
}

# Route Table          
resource "aws_route_table" "jenkins_public_rt" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }

  tags = {
    Name = "jenkins-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "jenkins_public_rta" {
  subnet_id      = aws_subnet.jenkins_public_subnet.id
  route_table_id = aws_route_table.jenkins_public_rt.id
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.jenkins_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins web interface"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-security-group"
  }
}

# IAM Role for Jenkins
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Attach policies to Jenkins role
resource "aws_iam_role_policy_attachment" "jenkins_eks_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.jenkins_role.name
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# Custom policy for Jenkins EKS access
resource "aws_iam_policy" "jenkins_eks_access" {
  name        = "jenkins-eks-access"
  description = "Policy allowing Jenkins to interact with EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi",
          "eks:ListNodegroups",
          "eks:ListUpdates",
          "eks:ListFargateProfiles"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the new policy to Jenkins role
resource "aws_iam_role_policy_attachment" "jenkins_eks_access" {
  policy_arn = aws_iam_policy.jenkins_eks_access.arn
  role       = aws_iam_role.jenkins_role.name
}


resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-profile"
  role = aws_iam_role.jenkins_role.name

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Instance for Jenkins
resource "aws_instance" "jenkins" {
  ami           = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS in us-east-1
  instance_type = "t2.medium"
  key_name        = "devops-key"
  subnet_id     = aws_subnet.jenkins_public_subnet.id
  
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name
  
  root_block_device {
    volume_size = 30    # GB
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y openjdk-17-jdk

              # Install Jenkins
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
                /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
              apt-get update
              apt-get install -y jenkins

              # Install Docker
              apt-get remove -y docker docker-engine docker.io containerd runc || true
              apt-get update
              apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              add-apt-repository \
                "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io
              sudo usermod -aG docker jenkins
              sudo systemctl restart docker
              sudo systemctl restart jenkins

              # Install AWS CLI
              apt-get install -y unzip
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              chmod +x kubectl
              mv kubectl /usr/local/bin/

              # Install eksctl
              curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
              mv /tmp/eksctl /usr/local/bin
              EOF

  tags = {
    Name = "jenkins-server"
  }
}

# Output the public IP and initial password command
output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_initial_password_cmd" {
  value = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
  description = "Command to retrieve the initial Jenkins admin password (run this on the EC2 instance)"
}

output "jenkins_role_arn" {
  description = "ARN of the Jenkins IAM role"
  value       = aws_iam_role.jenkins_role.arn
}
