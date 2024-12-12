# DevOps Pokemon Todo List

A Pokemon-themed DevOps task management application deployed using AWS, Jenkins, and Kubernetes. This project combines a fun, interactive todo list with modern DevOps practices and infrastructure management.

## 🌟 Features

- Pokemon-themed user interface
- Task management with CRUD operations
- Interactive animations and tooltips
- Persistent storage using SQLite
- Automated CI/CD pipeline
- Kubernetes deployment on AWS EKS

## 🚀 Technology Stack

- **Frontend**: HTML, CSS, JavaScript
- **Backend**: Flask (Python)
- **Database**: SQLite
- **Infrastructure**: AWS (EKS, EC2)
- **CI/CD**: Jenkins
- **Container Orchestration**: Kubernetes
- **IaC**: Terraform

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform](https://www.terraform.io/downloads.html)
- [Python](https://www.python.org/downloads/)
- SSH key pair (`devops-key.pem` in `devops-flask-project/cloud-infra/jenkins-terraform/keys/`)

## 🛠️ Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd devops-flask-project
```

### 2. Infrastructure Management

Navigate to the scripts directory:
```bash
cd cloud-infra/scripts
```

Available management scripts:
- `startup-all.sh`: Provisions and starts all infrastructure
- `shutdown-all.sh`: Terminates all infrastructure

To run a script:
```bash
./startup-all.sh
# or
./shutdown-all.sh
```

⚠️ **Important**: Use Git Bash terminal on Windows, not PowerShell.

### 3. Jenkins Setup

After running `startup-all.sh`:

1. Get Jenkins EC2 public IP from AWS Console
2. Access Jenkins at `http://<jenkins-ip>:8080`
3. Retrieve initial admin password:
   ```bash
   ssh -i "devops-key.pem" ubuntu@<jenkins-ip>
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

### 4. Application Deployment

1. Navigate to Jenkins URL (provided in terminal after infrastructure setup)
2. Trigger the `flask-app-pipeline`
3. Once pipeline completes successfully, it will output the application URL

## 🌐 Accessing the Application

After successful deployment, access the application at the URL provided by the Jenkins pipeline. The application will be available at:
```
http://<load-balancer-url>:5053
```

## 🏗️ Infrastructure Details

The project sets up:
- Jenkins server on EC2
- EKS cluster for Kubernetes deployment
- ECR repository for Docker images
- Load Balancer for application access

## 📦 Repository Structure

```
devops-flask-project/
├── cloud-infra/
│   ├── jenkins-terraform/
│   │   └── keys/
│   │       └── devops-key.pem
│   ├── eks-terraform/
│   └── scripts/
│       ├── startup-all.sh
│       └── shutdown-all.sh
└── flask-app/
    ├── static/
    ├── templates/
    └── app.py
```

## 🔄 CI/CD Pipeline

The Jenkins pipeline:
1. Builds the Flask application
2. Creates a Docker image
3. Pushes to ECR
4. Deploys to EKS cluster
5. Provides application URL

## 🧹 Cleanup

To tear down all infrastructure:
```bash
cd cloud-infra/scripts
./shutdown-all.sh
```

## 📝 License

[Add your license information here]

## 🤝 Contributing

Darya Atiya 🤝