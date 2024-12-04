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
      # Wait for Jenkins
      "echo 'Waiting for Jenkins...'",
      "while ! curl -s http://localhost:8080 > /dev/null; do sleep 10; done",
      "sleep 60",

      # Create Groovy scripts directory
      "sudo mkdir -p /var/lib/jenkins/init.groovy.d",

      # Create security configuration
      "sudo tee /var/lib/jenkins/init.groovy.d/01-basic-security.groovy <<'EOT'\n#!groovy\nimport jenkins.model.*\nimport hudson.security.*\nimport jenkins.install.*\n\ndef instance = Jenkins.getInstance()\ndef hudsonRealm = new HudsonPrivateSecurityRealm(false)\nhudsonRealm.createAccount(\"admin\", \"admin\")\ninstance.setSecurityRealm(hudsonRealm)\ninstance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)\ninstance.save()\nEOT",

      # Create plugin installation script
      "sudo tee /var/lib/jenkins/init.groovy.d/02-plugins.groovy <<'EOT'\n#!groovy\nimport jenkins.model.*\nimport jenkins.install.*\n\ndef pluginList = [\n  'git',\n 'docker',\n 'workflow-aggregator',\n  'pipeline-aws',\n  'docker-workflow',\n  'kubernetes',\n  'kubernetes-cli',\n  'github'\n]\n\ndef instance = Jenkins.getInstance()\ndef pm = instance.getPluginManager()\ndef uc = instance.getUpdateCenter()\n\npluginList.each { pluginName ->\n  if (!pm.getPlugin(pluginName)) {\n    def plugin = uc.getPlugin(pluginName)\n    if (plugin) {\n      plugin.deploy()\n    }\n  }\n}\n\ninstance.save()\nEOT",

      # Create pipeline configuration script
      "sudo tee /var/lib/jenkins/init.groovy.d/03-pipeline.groovy <<'EOT'\n#!groovy\nimport jenkins.model.*\nimport org.jenkinsci.plugins.workflow.job.*\nimport org.jenkinsci.plugins.workflow.cps.*\nimport hudson.plugins.git.*\n\ndef instance = Jenkins.getInstance()\n\ndef flowDefinition = new WorkflowJob(instance, \"flask-app-pipeline\")\ndef gitRepo = new GitSCM(\"https://github.com/Dashkoshka/devops-flask-project.git\")\ngitRepo.branches = [new BranchSpec(\"*/main\")]\n\ndef cpsScmFlowDefinition = new CpsScmFlowDefinition(gitRepo, \"flask-app/Jenkins/Jenkinsfile\")\nflowDefinition.setDefinition(cpsScmFlowDefinition)\nflowDefinition.save()\n\ninstance.reload()\nEOT",

      # # Create security configuration
      # "sudo tee /var/lib/jenkins/init.groovy.d/01-basic-security.groovy <<'EOT'\n${file("${path.module}/scripts/basic-security.groovy")}\nEOT",

      # # Create plugin installation script
      # "sudo tee /var/lib/jenkins/init.groovy.d/02-plugins.groovy <<'EOT'\n${file("${path.module}/scripts/basic-plugins.groovy")}\nEOT",

      # # Create pipeline configuration script
      # "sudo tee /var/lib/jenkins/init.groovy.d/03-pipeline.groovy <<'EOT'\n${file("${path.module}/scripts/pipeline-config.xml")}\nEOT",

      # Set permissions and restart
      "sudo chown -R jenkins:jenkins /var/lib/jenkins/",
      "sudo systemctl restart jenkins",
      "echo 'Jenkins configuration complete. Wait 2-3 minutes for all changes to take effect.'"
    ]
  }
}