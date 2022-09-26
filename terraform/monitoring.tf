resource "azurerm_monitor_action_group" "group-monitor" {
 resource_group_name = azurerm_resource_group.rg.name
 name                = "group-monitor"
 short_name          = "gm"
}

resource "azurerm_monitor_metric_alert" "alert-vm-cpu" {
 name                = "alert-vm-cpu"
 resource_group_name = azurerm_resource_group.rg.name
 scopes              = [azurerm_linux_virtual_machine_scale_set.sanlab02-sclset.id] # modifié de la vm_app.id pour la ressource scale_set
 description         = "VM App cpu alert"
 target_resource_type = "Microsoft.Compute/virtualMachineScaleSets" 

 criteria {
 
   metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
   metric_name      = "Percentage CPU"
   aggregation      = "Total"
   operator         = "GreaterThan"
   threshold        = 40
 }

 action {
   action_group_id = azurerm_monitor_action_group.group-monitor.id
 }
}
