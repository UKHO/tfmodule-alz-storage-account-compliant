# ==============================================================================
# Storage Account Outputs
# ==============================================================================

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azapi_resource.storage_account.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azapi_resource.storage_account.name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint"
  value       = azapi_resource.storage_account.output.properties.primaryEndpoints.blob
}

output "storage_account_primary_file_endpoint" {
  description = "The primary file endpoint"
  value       = azapi_resource.storage_account.output.properties.primaryEndpoints.file
}

# ==============================================================================
# Private Endpoint Outputs - Primary
# ==============================================================================

output "blob_primary_private_endpoint_id" {
  description = "The ID of the primary blob private endpoint"
  value       = var.enable_primary_private_endpoints ? azurerm_private_endpoint.blob_primary[0].id : null
}

output "file_primary_private_endpoint_id" {
  description = "The ID of the primary file private endpoint"
  value       = var.enable_primary_private_endpoints ? azurerm_private_endpoint.file_primary[0].id : null
}

# ==============================================================================
# Private Endpoint Outputs - Secondary
# ==============================================================================

output "blob_secondary_private_endpoint_id" {
  description = "The ID of the secondary blob private endpoint"
  value       = var.enable_secondary_private_endpoints ? azurerm_private_endpoint.blob_secondary[0].id : null
}

output "file_secondary_private_endpoint_id" {
  description = "The ID of the secondary file private endpoint"
  value       = var.enable_secondary_private_endpoints ? azurerm_private_endpoint.file_secondary[0].id : null
}

# ==============================================================================
# Private DNS Zone VNet Link Outputs
# ==============================================================================

output "blob_primary_dns_vnet_link_id" {
  description = "The ID of the primary blob private DNS zone virtual network link"
  value       = var.create_primary_dns_vnet_links && var.enable_primary_private_endpoints ? azurerm_private_dns_zone_virtual_network_link.blob_primary[0].id : null
}

output "file_primary_dns_vnet_link_id" {
  description = "The ID of the primary file private DNS zone virtual network link"
  value       = var.create_primary_dns_vnet_links && var.enable_primary_private_endpoints ? azurerm_private_dns_zone_virtual_network_link.file_primary[0].id : null
}

# ==============================================================================
# Encryption Configuration Outputs
# ==============================================================================

output "customer_managed_key_enabled" {
  description = "Whether customer-managed key encryption is enabled"
  value       = true
}

output "key_vault_key_id" {
  description = "The ID of the Key Vault key used for encryption"
  value       = azurerm_key_vault_key.storage_encryption.id
}

output "user_assigned_identity_id" {
  description = "The ID of the user-assigned identity used for CMK"
  value       = azurerm_user_assigned_identity.storage_cmk.id
}

# ==============================================================================
# ALZ Compliance Features
# ==============================================================================

output "alz_compliance_features" {
  description = "Map of ALZ compliance features enabled"
  value = {
    https_traffic_only                = true
    min_tls_version                   = "TLS1_2"
    infrastructure_encryption         = true
    public_network_access_disabled    = true
    shared_access_key_disabled        = true
    default_oauth_authentication      = true
    blob_public_access_disabled       = true
    cross_tenant_replication_disabled = true
    allowed_copy_scope                = "AAD"
    local_users_disabled              = true
    sftp_disabled                     = true
    network_bypass_restricted         = true
    blob_versioning_enabled           = true
    blob_change_feed_enabled          = true
    blob_soft_delete_enabled          = true
    container_soft_delete_enabled     = true
    point_in_time_restore_enabled     = true
    customer_managed_key_enabled      = true
    queue_encryption_cmk              = true # NEW - Queue encrypted with CMK
    table_encryption_cmk              = true # NEW - Table encrypted with CMK
  }
}
