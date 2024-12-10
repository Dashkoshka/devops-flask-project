import jenkins.model.*
import hudson.model.*
import jenkins.install.*

def instance = Jenkins.getInstance()
def pluginManager = instance.getPluginManager()
def updateCenter = instance.getUpdateCenter()

// List of plugins to install
def plugins = [
    'git',                       //Git
    'docker',
    'workflow-aggregator',       // Pipeline
    'pipeline-aws',
    'docker-workflow',
    'kubernetes-cli',
    'github',
    'credentials',               // Credentials
    'matrix-auth',               // Matrix Authorization Strategy
    'configuration-as-code',     // Jenkins Configuration as Code
    'blueocean',                 // Blue Ocean
    'job-dsl',                   // Job DSL
    'docker-plugin',             // Docker
    'kubernetes',                // Kubernetes
    'aws-credentials',           // AWS Credentials
    'pipeline-github-lib',       // GitHub Groovy Libraries
    'pipeline-stage-view',       // Pipeline Graph View
    'ssh-slaves',                // SSH Build Agents
    'timestamper',               // Timestamper
    'email-ext',                 // Email Extension
    'slack',                     // Slack
    'folders',                   // Folders
    'owasp-markup-formatter',    // OWASP Markup Formatter
    'build-timeout',             // Build Timeout
    'credentials-binding',       // Credentials Binding
    'ws-cleanup',                // Workspace Cleanup
    'ant',                       // Ant
    'gradle',                    // Gradle
    'github-branch-source',      // GitHub Branch Source
    'pam-auth',                  // PAM Authentication
    'ldap',                      // LDAP
    'mailer',                    // Mailer
    'dark-theme'                 // Dark Theme
]

// Install missing plugins
plugins.each { pluginName ->
    if (!pluginManager.getPlugin(pluginName)) {
        def plugin = updateCenter.getPlugin(pluginName)
        if (plugin) {
            plugin.deploy()
            println "Installing plugin: ${pluginName}"
        } else {
            println "Plugin not found in Update Center: ${pluginName}"
        }
    } else {
        println "Plugin already installed: ${pluginName}"
    }
}

// Mark Jenkins as fully initialized
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
instance.save()

println "Plugin installation complete. Restart Jenkins to activate new plugins."
