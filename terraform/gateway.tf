resource "azurerm_subnet" "subnet_gateway" {
  name                 = "subnet_gateway"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Creation d'un NIC pour le scale set 

resource "azurerm_network_interface" "sanlab02-nic-sclset" {
  name                = "${var.rg}-nic-sclset"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "scale-set-nic-configuration"
    subnet_id                     = azurerm_subnet.subnet_vmss.id
    private_ip_address_allocation = "Dynamic"
  }
}

# CREATION D'UN NSG POUR VMSS
resource "azurerm_network_security_group" "nsg_vmss" {
  name                = "${var.rg}-nsg_vmss"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "HTTP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#ASSOCIATION NSG - INTERFACE
resource "azurerm_network_interface_security_group_association" "assoc-nic-nsg-vmss" {
  network_interface_id      = azurerm_network_interface.sanlab02-nic-sclset.id
  network_security_group_id = azurerm_network_security_group.nsg_vmss.id
}

#-----------------------------------------------------------------------------------


resource "azurerm_public_ip" "public_ip_gateway" {
  name                = "public_ip_gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${lower(var.subdomain-prefix)}-${lower(var.rg)}"
}

resource "azurerm_application_gateway" "gateway" {
 name                = "gateway"
 resource_group_name = azurerm_resource_group.rg.name
 location            = azurerm_resource_group.rg.location


 sku {
   name     = "Standard_v2"
   tier     = "Standard_v2"
   capacity = 2
 }

 gateway_ip_configuration {
   name      = "ip-configuration"
   subnet_id = azurerm_subnet.subnet_gateway.id
 }

 frontend_port {
   name = "http"
   port = 80
 }

 frontend_ip_configuration {
   name                 = "front-ip"
   public_ip_address_id = azurerm_public_ip.public_ip_gateway.id
 }

 backend_address_pool {
   name = "backend_pool"
   #vmss_list = ["${azurerm_virtual_machine_scale_set.sanlab02-sclset.name}"] #ajout d'une liste scale set pour backendpool
 }

 backend_http_settings {
   name                  = "http-settings"
   cookie_based_affinity = "Disabled"
   path                  = "/"
   port                  = 80
   protocol              = "Http"
   request_timeout       = 10
 }

 http_listener {
   name                           = "listener"
   frontend_ip_configuration_name = "front-ip"
   frontend_port_name             = "http"
   protocol                       = "Http"
 }

 request_routing_rule {
   name                       = "rule-1"
   rule_type                  = "Basic"
   http_listener_name         = "listener"
   backend_address_pool_name  = "backend_pool"
   backend_http_settings_name = "http-settings"
   priority                   = 100
 }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "poolbackend" {
 network_interface_id    = azurerm_network_interface.sanlab02-nic-sclset.id
 ip_configuration_name   = "scale-set-nic-configuration" # même nom que dans le network interface !!!! 
 backend_address_pool_id = tolist(azurerm_application_gateway.gateway.backend_address_pool).0.id
}

output "application-address" {
  value = "http://${azurerm_public_ip.public_ip_gateway.fqdn}"
}





#------------------- SCALE SET DE REMPLACEMENT DE LA VM-----------------------------

resource "azurerm_subnet" "subnet_vmss" {
  name                 = "${var.rg}-vmss"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_linux_virtual_machine_scale_set" "sanlab02-sclset" {
  name                = "${var.rg}set"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  upgrade_mode        = "Manual"
  sku                 = "Standard_F2"
  instances           = 1
  admin_username      = "admin${var.rg}"
  custom_data                     = data.cloudinit_config.cloud-init.rendered
  disable_password_authentication = true
  #admin_password = "blabla$123!"


  admin_ssh_key {
    username   = "admin${var.rg}"
    public_key = file("C:/Users/utilisateur/.ssh/id_rsa.pub")
  }

 

  network_interface {
    name    = "NetworkForScale"
    primary = true

    ip_configuration {
      name      = "IPForScale"
      primary   = true
      subnet_id                              = azurerm_subnet.subnet_vmss.id
      application_gateway_backend_address_pool_ids = tolist(azurerm_application_gateway.gateway.backend_address_pool).*.id
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    # publisher = "Credativ"
    # offer     = "Debian"
    # sku       = "11"
    # version   = "latest"
        publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
    
  }

  lifecycle {
    ignore_changes = ["instances"]
  }
}


# ---------------- AUTOSCALE PROGRAMMATION ------------------------------

resource "azurerm_monitor_autoscale_setting" "sanlab02-autosclset" {
  name                = "${var.rg}myAutoscaleSetting"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.sanlab02-sclset.id

  profile {
    name = "${var.rg}profil"

    capacity {
      default = 1
      minimum = 1
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.sanlab02-sclset.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 40
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppNameSanlab"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.sanlab02-sclset.id
        time_grain         = "PT1M" # Time grain + time window = fenetre glissante sur 5 minutes, point de métrique toute les 1 minutes. 
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["ryanmagento@gmail.com"]
    }
  }
}