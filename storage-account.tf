# ==============================================================================
# Azure Storage Account - azapi_resource Implementation
# Required to set queue/table keyType at creation time (read-only property)
# ==============================================================================

resource "azapi_resource" "storage_account" {
  type      = "Microsoft.Storage/storageAccounts@2023-01-01"
  name      = var.storage_account_name
  location  = data.azurerm_resource_group.main.location
  parent_id = data.azurerm_resource_group.main.id

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.storage_cmk.id]
  }

  body = {
    sku = {
      name = "${var.account_tier}_${var.account_replication_type}"
    }
    kind = "StorageV2"
    properties = {
      # Basic Configuration
      accessTier = var.access_tier
      
      # ========================================================================
      # ALZ COMPLIANCE SETTINGS
      # ========================================================================
      
      # 1. Security - Require HTTPS traffic only
      supportsHttpsTrafficOnly = true
      
      # 2. Security - Minimum TLS version
      minimumTlsVersion = "TLS1_2"
      
      # 3. Security - Public network access control
      publicNetworkAccess = var.public_network_access_enabled ? "Enabled" : "Disabled"
      
      # 4. Security - Disable shared key access
      allowSharedKeyAccess = false
      
      # 5. Security - Default to OAuth authentication
      defaultToOAuthAuthentication = true
      
      # 6. Security - Disable blob public access
      allowBlobPublicAccess = false
      
      # 7. Security - Disable cross-tenant replication
      allowCrossTenantReplication = false
      
      # 8. Compliance - Restrict copy scope to AAD
      allowedCopyScope = "AAD"
      
      # 9. Compliance - Disable local users (SFTP)
      isLocalUserEnabled = false
      
      # 10. Compliance - Disable SFTP
      isSftpEnabled = false
      
      # 11. Security - Disable large file shares
      largeFileSharesState = "Disabled"
      
      # ========================================================================
      # Customer-Managed Key Encryption - ALL SERVICES
      # ========================================================================
      
      encryption = {
        services = {
          blob = {
            enabled = true
            keyType = "Account"  # Uses customer-managed key
          }
          file = {
            enabled = true
            keyType = "Account"  # Uses customer-managed key
          }
          queue = {
            enabled = true
            keyType = "Account"  # Uses customer-managed key - THIS IS THE KEY FIX
          }
          table = {
            enabled = true
            keyType = "Account"  # Uses customer-managed key - THIS IS THE KEY FIX
          }
        }
        keySource = "Microsoft.Keyvault"
        requireInfrastructureEncryption = true  # Infrastructure encryption
        keyvaultproperties = {
          keyname     = azurerm_key_vault_key.storage_encryption.name
          keyvaulturi = data.azurerm_key_vault.cmk.vault_uri
        }
        identity = {
          userAssignedIdentity = azurerm_user_assigned_identity.storage_cmk.id
        }
      }
      
      # ========================================================================
      # Network Rules - Configurable Access Control
      # ========================================================================
      
      networkAcls = {
        defaultAction = var.network_rules_default_action
        bypass        = join(",", var.network_rules_bypass)
        ipRules       = [for ip in var.allowed_ip_addresses : { value = ip }]
        virtualNetworkRules = [for subnet in var.allowed_subnet_ids : { id = subnet }]
      }
    }
  }

  tags = merge(
    var.tags,
    {
      "Compliance"       = "ALZ-Required"
      "CreatedBy"        = "Terraform"
      "Implementation"   = "Full-azapi"
      "QueueTableCMK"    = "Enabled"
    }
  )

  depends_on = [
    azurerm_user_assigned_identity.storage_cmk,
    azurerm_role_assignment.storage_cmk_access,
    azurerm_key_vault_key.storage_encryption
  ]

  response_export_values = ["*"]
}