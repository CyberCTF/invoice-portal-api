# Lab host on Azure (cloud target): one Debian 12 VM in a resource group of its own, on a
# small VNet, reached only over SSH from allowed_cidr. cloud-init fetches the lab and runs
# deploy/ansible/site.yml (the same bootstrap as the AWS target). Lab services live on the
# Docker network inside the VM, reached from the attack box next to them; only SSH is open.
#
# Credentials: the Azure CLI (`az login`) plus a subscription. azurerm reads the subscription
# from ARM_SUBSCRIPTION_ID (the launcher sets it) or the environment.
#
# Auto-stop note: cloud-init powers the OS off after auto_stop_hours, but Azure keeps billing
# a merely powered-off VM until it is DEALLOCATED. Stop (terraform destroy) removes everything
# and is the reliable way to end billing; a timed deallocate is a follow-up.

terraform {
  required_version = ">= 1.6"
  # The launcher keeps state outside the lab folder: -backend-config=path=...
  backend "local" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# A short random id per deployment, stable across re-applies, so two deployments of the same
# lab in one subscription never collide on names.
resource "terraform_data" "deployment" {
  input = substr(replace(uuid(), "-", ""), 0, 8)
  lifecycle {
    ignore_changes = [input]
  }
}

locals {
  name = "cyberctf-${var.lab_slug}-${terraform_data.deployment.output}"
  # Sizing the lab asks for in .ctf/metadata.json ("resources"), when the lab ships it.
  resources = try(jsondecode(file("${path.module}/../../../.ctf/metadata.json")).resources, {})
  memory_mb = try(local.resources.memory_mb, 4096)
  vm_size = coalesce(
    var.instance_type,
    local.memory_mb <= 4096 ? "Standard_B2s" : local.memory_mb <= 8192 ? "Standard_B2ms" : "Standard_B4ms",
  )
  disk_gb = coalesce(var.disk_gb, try(local.resources.disk_gb, null), 30)
  tags = {
    "cyberctf-lab" = var.lab_slug
    "managed-by"   = "cyberctf"
  }
}

resource "azurerm_resource_group" "lab" {
  name     = local.name
  location = var.region
  tags     = local.tags
}

resource "azurerm_virtual_network" "lab" {
  name                = local.name
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  address_space       = ["10.42.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "lab" {
  name                 = "lab"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.42.1.0/24"]
}

resource "azurerm_network_security_group" "labhost" {
  name                = local.name
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tags                = local.tags

  # Only SSH, only from the player. Everything else is denied by Azure's default rules;
  # outbound to the internet is allowed by default (the lab needs it to fetch images).
  dynamic "security_rule" {
    for_each = var.allowed_cidr == "" ? [] : [var.allowed_cidr]
    content {
      name                       = "ssh-from-player"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "lab" {
  subnet_id                 = azurerm_subnet.lab.id
  network_security_group_id = azurerm_network_security_group.labhost.id
}

resource "azurerm_public_ip" "labhost" {
  name                = local.name
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "labhost" {
  name                = local.name
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.labhost.id
  }
}

resource "azurerm_linux_virtual_machine" "labhost" {
  name                  = local.name
  resource_group_name   = azurerm_resource_group.lab.name
  location              = azurerm_resource_group.lab.location
  size                  = local.vm_size
  admin_username        = "cyberctf"
  network_interface_ids = [azurerm_network_interface.labhost.id]
  tags                  = local.tags

  admin_ssh_key {
    username   = "cyberctf"
    public_key = var.ssh_public_key
  }

  custom_data = base64encode(templatefile("${path.module}/../../cloud-init/user-data.yaml.tftpl", {
    lab_repository    = var.lab_repository
    lab_commit        = var.lab_commit
    ctf_api_url       = var.ctf_api_url
    ctf_launch_token  = var.ctf_launch_token
    attackbox_image   = var.attackbox_image
    ssh_public_key    = var.ssh_public_key
    auto_stop_minutes = var.auto_stop_hours * 60
  }))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = local.disk_gb
  }

  # Debian's official Azure image (gen2).
  source_image_reference {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }
}
