#!groovy
import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*

def instance = Jenkins.getInstance()

def flowDefinition = new WorkflowJob(instance, "flask-app-pipeline")

def gitRepo = new GitSCM("https://github.com/Dashkoshka/devops-flask-project.git")
gitRepo.branches = [new BranchSpec("*/main")]


def cpsScmFlowDefinition = new CpsScmFlowDefinition(gitRepo, "flask-app/Jenkins/Jenkinsfile")
flowDefinition.setDefinition(cpsScmFlowDefinition)
flowDefinition.save()

instance.reload()