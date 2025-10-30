# ==============================================================================
# User-Assigned Managed Identity and RBAC for Storage Account CMK
# ==============================================================================

# User-Assigned Managed Identity for Storage Account CMK
resource "azurerm_user_assigned_identity" "storage_cmk" {
  name                = "${var.storage_account_name}-identity"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

# RBAC - Key Vault Crypto Service Encryption User Role for Storage Account Identity
resource "azurerm_role_assignment" "storage_cmk_access" {
  scope                = data.azurerm_key_vault.cmk.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.storage_cmk.principal_id

  depends_on = [
    azurerm_user_assigned_identity.storage_cmk
  ]
}