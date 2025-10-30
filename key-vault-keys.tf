# ==============================================================================
# Key Vault Keys for Customer-Managed Encryption
# ==============================================================================

# Key Vault Key for Customer-Managed Encryption
resource "azurerm_key_vault_key" "storage_encryption" {
  name         = "${var.storage_account_name}-cmk"
  key_vault_id = data.azurerm_key_vault.cmk.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  # ALZ Policy Compliance - Keys must have expiration within 89 days
  expiration_date = timeadd(timestamp(), "2136h") # 89 days from creation (89 days * 24 hours)

  # Key rotation policy for ongoing compliance
  rotation_policy {
    automatic {
      time_before_expiry = "P30D" # Rotate 30 days before expiry
    }

    expire_after         = "P89D" # Expire after 89 days
    notify_before_expiry = "P29D" # Notify 29 days before expiry
  }

  depends_on = [
    azurerm_role_assignment.storage_cmk_access # Wait for RBAC to be assigned
  ]
}