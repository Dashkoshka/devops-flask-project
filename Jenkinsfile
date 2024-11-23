pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "flask-app:${BUILD_NUMBER}"     
        AWS_DEFAULT_REGION = "us-east-1"               
        ECR_REPO = "890742604545.dkr.ecr.us-east-1.amazonaws.com"
    }

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}", "-f Dockerfile .")
                }
            }
        }
     
        stage('Push to ECR') {                         
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                        docker tag ${DOCKER_IMAGE} ${ECR_REPO}/${DOCKER_IMAGE}
                        docker push ${ECR_REPO}/${DOCKER_IMAGE}
                    """                                
                }
            }
        }

        stage('Deploy to EKS') {                     
            steps {
                script {
                    sh """
                        aws eks update-kubeconfig --name my-eks-cluster --region ${AWS_DEFAULT_REGION}
                        kubectl apply -f k8s/configmap-and-secret/
                        sed 's|\${DOCKER_IMAGE}|${ECR_REPO}/${DOCKER_IMAGE}|g' k8s/deployment-and-services/deployment.yaml | kubectl apply -f -
                        kubectl apply -f k8s/deployment-and-services/service.yaml
                    """                                
                }
            }
        }
    }
}                                                      