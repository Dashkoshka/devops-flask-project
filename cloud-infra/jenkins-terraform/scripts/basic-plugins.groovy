#!groovy
import jenkins.model.*
import jenkins.install.*
    
def pluginList = ['git','docker','workflow-aggregator','pipeline-aws','docker-workflow','kubernetes','kubernetes-cli','github']
    
def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

pluginList.each { 
    pluginName ->  
    if(!pm.getPlugin(pluginName)) {
        def plugin = uc.getPlugin(pluginName)    
        
        if (plugin) { 
            plugin.deploy() 
        }  
    }
}
    
instance.save()