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
# Private Endpoints - Secondary (Cross-subscription DNS - hub subscription)
# ==============================================================================

resource "azurerm_private_endpoint" "blob_secondary" {
  count               = var.enable_secondary_private_endpoints ? 1 : 0
  name                = "${local.storage_account_name}-blob-pe-hub"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = data.azurerm_subnet.main.id

  private_service_connection {
    name                           = "pse-${local.storage_account_name}-blob-hub"
    private_connection_resource_id = local.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_blob_hub[0].id]
  }

  tags = merge(var.tags, {
    "Purpose" = "Cross-Subscription-DNS"
  })

  depends_on = [azapi_resource.storage_account]
}

resource "azurerm_private_endpoint" "file_secondary" {
  count               = var.enable_secondary_private_endpoints ? 1 : 0
  name                = "${local.storage_account_name}-file-pe-hub"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = data.azurerm_subnet.main.id

  private_service_connection {
    name                           = "pse-${local.storage_account_name}-file-hub"
    private_connection_resource_id = local.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_file_hub[0].id]
  }

  tags = merge(var.tags, {
    "Purpose" = "Cross-Subscription-DNS"
  })

  depends_on = [azapi_resource.storage_account]
}