resource "null_resource" "jenkins_config" {
  depends_on = [aws_instance.jenkins]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/keys/devops-key.pem")
      host        = aws_instance.jenkins.public_ip
    }

    inline = [
      # Wait for Jenkins to start
      "echo 'Waiting for Jenkins to start...'",
      "while ! curl -s http://localhost:8080 > /dev/null; do sleep 10; done",
      "sleep 10",

      # Create Groovy scripts directory
      "sudo mkdir -p /var/lib/jenkins/init.groovy.d",

      "echo 'Configure Jenkins cradential...'",
      # Apply basic security configuration
      "sudo tee /var/lib/jenkins/init.groovy.d/01-basic-security.groovy <<'EOF'\n${file("${path.module}/scripts/basic-security.groovy")}\nEOF",

      "echo 'Install Jenkins plugins...'",
      # Install plugins configuration script
      "sudo tee /var/lib/jenkins/init.groovy.d/02-plugins.groovy <<'EOF'\n${file("${path.module}/scripts/basic-plugins.groovy")}\nEOF",
      "echo 'Finish install Jenkins plugins'",

      # Restart Jenkins to apply changes
      "sudo systemctl restart jenkins",
      "sleep 10",
      "echo 'Waiting for Jenkins to start after plugin installation...'",
      "while ! curl -s http://localhost:8080 > /dev/null; do sleep 10; done",
      "sleep 10",

      "echo 'Configure Jenkins flask-app pipeline...'",
      # Create pipeline configuration script
      "sudo tee /var/lib/jenkins/init.groovy.d/03-pipeline.groovy <<'EOF'\n${file("${path.module}/scripts/flask-app-pipeline-config.groovy")}\nEOF",
      "echo 'Finish Configure Jenkins flask-app pipeline'",

      # Set permissions
      "sudo chown -R jenkins:jenkins /var/lib/jenkins/",

      # Restart Jenkins to apply changes
      "sudo systemctl restart jenkins",
      "echo 'Jenkins configuration complete. Wait 2-3 minutes for changes to take effect.'"
    ]
  }
}