# ==============================================================================
# Private Endpoints for Storage Account Services
# ==============================================================================

# ==============================================================================
# Private Endpoints - Primary (Clean Names - oldhub subscription)
# ==============================================================================

resource "azurerm_private_endpoint" "blob_primary" {
  count               = var.enable_primary_private_endpoints ? 1 : 0
  name                = "${local.storage_account_name}-blob-pe"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = data.azurerm_subnet.main.id

  private_service_connection {
    name                           = "pse-${local.storage_account_name}-blob"
    private_connection_resource_id = local.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_blob[0].id]
  }

  tags = var.tags

  depends_on = [azapi_resource.storage_account]
}

resource "azurerm_private_endpoint" "file_primary" {
  count               = var.enable_primary_private_endpoints ? 1 : 0
  name                = "${local.storage_account_name}-file-pe"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = data.azurerm_subnet.main.id

  private_service_connection {
    name                           = "pse-${local.storage_account_name}-file"
    private_connection_resource_id = local.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_file[0].id]
  }

  tags = var.tags

  depends_on = [azapi_resource.storage_account]
}

# ==============================================================================
# Secondary DNS Records (hub subscription)
# ==============================================================================

resource "azurerm_private_dns_a_record" "blob_secondary" {
  count               = var.enable_secondary_private_endpoints ? 1 : 0
  name                = local.storage_account_name
  resource_group_name = var.primary_dns_zone_resource_group
  zone_name           = data.azurerm_private_dns_zone.storage_blob_primary[0].name
  ttl                 = 10
  records = var.enable_primary_private_endpoints ? [
    azurerm_private_endpoint.blob_primary[0].private_service_connection[0].private_ip_address
  ] : []

  lifecycle {
    precondition {
      condition     = var.enable_primary_private_endpoints
      error_message = "enable_primary_private_endpoints must be true when enable_secondary_private_endpoints is true, because the hub DNS record uses the primary endpoint IP."
    }
  }

  tags     = var.tags
  provider = azurerm.primary
}

resource "azurerm_private_dns_a_record" "file_secondary" {
  count               = var.enable_secondary_private_endpoints ? 1 : 0
  name                = local.storage_account_name
  resource_group_name = var.primary_dns_zone_resource_group
  zone_name           = data.azurerm_private_dns_zone.storage_file_primary[0].name
  ttl                 = 10
  records = var.enable_primary_private_endpoints ? [
    azurerm_private_endpoint.file_primary[0].private_service_connection[0].private_ip_address
  ] : []

  lifecycle {
    precondition {
      condition     = var.enable_primary_private_endpoints
      error_message = "enable_primary_private_endpoints must be true when enable_secondary_private_endpoints is true, because the hub DNS record uses the primary endpoint IP."
    }
  }

  tags     = var.tags
  provider = azurerm.primary
}

# ==============================================================================
# Private DNS Zone Virtual Network Links - Primary (oldhub subscription)
# ==============================================================================

resource "azurerm_private_dns_zone_virtual_network_link" "blob_primary" {
  count                 = var.create_secondary_dns_vnet_links && var.enable_primary_private_endpoints ? 1 : 0
  name                  = "${var.virtual_network_name}-blob-link"
  resource_group_name   = var.secondary_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.storage_blob[0].name
  virtual_network_id    = data.azurerm_virtual_network.main[0].id
  registration_enabled  = false

  tags = merge(var.tags, {
    "Purpose" = "Storage-Private-Endpoint-DNS"
  })

  provider = azurerm.secondary
}

resource "azurerm_private_dns_zone_virtual_network_link" "file_primary" {
  count                 = var.create_secondary_dns_vnet_links && var.enable_primary_private_endpoints ? 1 : 0
  name                  = "${var.virtual_network_name}-file-link"
  resource_group_name   = var.secondary_dns_zone_resource_group
  private_dns_zone_name = data.azurerm_private_dns_zone.storage_file[0].name
  virtual_network_id    = data.azurerm_virtual_network.main[0].id
  registration_enabled  = false

  tags = merge(var.tags, {
    "Purpose" = "Storage-Private-Endpoint-DNS"
  })

  provider = azurerm.secondary
}