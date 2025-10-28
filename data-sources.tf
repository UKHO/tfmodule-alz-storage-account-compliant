# ==============================================================================
# Data Sources for Azure Storage Module
# ==============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Target resource group for the storage account
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Key Vault for Customer-Managed Keys (CMK)
data "azurerm_key_vault" "cmk" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

# Subnet for private endpoints
data "azurerm_subnet" "main" {
  name                 = var.subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.vnet_resource_group_name
}

# ==============================================================================
# Private DNS Zones for Primary (oldhub) subscription
# ==============================================================================

data "azurerm_private_dns_zone" "storage_blob" {
  count               = var.enable_primary_private_endpoints ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.oldhub_dns_zone_resource_group
  provider            = azurerm.oldhub
}

data "azurerm_private_dns_zone" "storage_file" {
  count               = var.enable_primary_private_endpoints ? 1 : 0
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.oldhub_dns_zone_resource_group
  provider            = azurerm.oldhub
}

# ==============================================================================
# Private DNS Zones for Secondary (hub) subscription  
# ==============================================================================

data "azurerm_private_dns_zone" "storage_blob_hub" {
  count               = var.enable_secondary_private_endpoints ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.hub_dns_zone_resource_group
  provider            = azurerm.hub
}

data "azurerm_private_dns_zone" "storage_file_hub" {
  count               = var.enable_secondary_private_endpoints ? 1 : 0
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.hub_dns_zone_resource_group
  provider            = azurerm.hub
}