# ==============================================================================
# Local Values for Storage Account Module
# ==============================================================================

locals {
  # Storage account resource references
  storage_account_id   = azapi_resource.storage_account.id
  storage_account_name = azapi_resource.storage_account.name
}