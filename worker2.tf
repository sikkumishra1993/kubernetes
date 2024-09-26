resource "azurerm_network_interface" "worker2" {
  name                = "worker2-nic"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker2.id
  }
}

resource "azurerm_public_ip" "worker2" {
  name                = "worker2-pip"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface_security_group_association" "worker2" {
  network_interface_id      = azurerm_network_interface.worker2.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_virtual_machine" "worker2" {
  name                  = "worker2-vm"
  location              = data.azurerm_resource_group.example.location
  resource_group_name   = data.azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.worker2.id]
  vm_size               = "Standard_DS2_v2"

  storage_os_disk {
    name              = "worker2-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "worker2-vm"
    admin_username = "bigboss"
    admin_password = "Maersk@12345"
    custom_data    = base64encode(file("k8_worker.sh"))
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

output "worker2_ip" {
  value = azurerm_public_ip.worker2.ip_address
}
