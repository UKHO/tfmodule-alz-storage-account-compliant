# Quick Reference: Using the Non-Legacy Module

## Module Call Example

```hcl
# Configure providers in your root module
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  subscription_id            = "your-target-subscription-id"
  storage_use_azuread        = true
  skip_provider_registration = true
}

provider "azurerm" {
  alias                      = "oldhub"
  features {}
  subscription_id            = "your-oldhub-subscription-id"
  skip_provider_registration = true
}

provider "azurerm" {
  alias                      = "hub"
  features {}
  subscription_id            = "your-hub-subscription-id"
  skip_provider_registration = true
}

# Call the module
module "storage_account" {
  source = "git::https://github.com/UKHO/tfmodule-alz-storage-account-compliant.git?ref=main"
  
  # REQUIRED: Pass provider configurations
  providers = {
    azurerm        = azurerm
    azurerm.oldhub = azurerm.oldhub
    azurerm.hub    = azurerm.hub
  }
  
  # Required variables
  resource_group_name            = "rg-storage-prod"
  storage_account_name           = "stprodunique123"
  key_vault_name                 = "kv-storage-prod"
  virtual_network_name           = "vnet-prod"
  subnet_name                    = "snet-privateendpoints"
  vnet_resource_group_name       = "rg-network-prod"
  oldhub_dns_zone_resource_group = "rg-dns-oldhub"
  hub_dns_zone_resource_group    = "rg-dns-hub"
  
  # Optional variables
  enable_primary_private_endpoints   = true
  enable_secondary_private_endpoints = false
  account_replication_type           = "ZRS"
  
  # NOW SUPPORTED: Use count, for_each, or depends_on
  count = var.create_storage ? 1 : 0
  
  depends_on = [
    azurerm_resource_group.main_rg,
    azurerm_key_vault.main
  ]
}
```

## Using for_each

```hcl
variable "storage_accounts" {
  type = map(object({
    resource_group   = string
    key_vault        = string
    replication_type = string
  }))
  
  default = {
    "stdev001" = {
      resource_group   = "rg-storage-dev"
      key_vault        = "kv-dev"
      replication_type = "LRS"
    }
    "stprod001" = {
      resource_group   = "rg-storage-prod"
      key_vault        = "kv-prod"
      replication_type = "ZRS"
    }
  }
}

module "storage_account" {
  source   = "git::https://github.com/UKHO/tfmodule-alz-storage-account-compliant.git?ref=main"
  for_each = var.storage_accounts
  
  providers = {
    azurerm        = azurerm
    azurerm.oldhub = azurerm.oldhub
    azurerm.hub    = azurerm.hub
  }
  
  storage_account_name         = each.key
  resource_group_name          = each.value.resource_group
  key_vault_name               = each.value.key_vault
  account_replication_type     = each.value.replication_type
  virtual_network_name         = "vnet-shared"
  subnet_name                  = "snet-privateendpoints"
  vnet_resource_group_name     = "rg-network"
  oldhub_dns_zone_resource_group = "rg-dns-oldhub"
  hub_dns_zone_resource_group    = "rg-dns-hub"
}
```

## Key Changes from Legacy Version

### ❌ NO LONGER NEEDED
```hcl
# These variables have been REMOVED:
subscription_id            = "..."
hub_subscription_id        = "..."
oldhub_subscription_id     = "..."
```

### ✅ NOW REQUIRED
```hcl
# Provider block must be passed:
providers = {
  azurerm        = azurerm
  azurerm.oldhub = azurerm.oldhub
  azurerm.hub    = azurerm.hub
}
```

### ✅ NOW SUPPORTED
```hcl
# These meta-arguments now work:
count      = 1
for_each   = var.items
depends_on = [resource.example]
```

## Accessing Outputs with count/for_each

### With count:
```hcl
output "storage_account_id" {
  value = var.create_storage ? module.storage_account[0].storage_account_id : null
}
```

### With for_each:
```hcl
output "storage_account_ids" {
  value = {
    for k, v in module.storage_account : k => v.storage_account_id
  }
}
```

## Troubleshooting

| Error | Solution |
|-------|----------|
| "Module is incompatible with count..." | Update to latest module version |
| "No configuration files" | Run `terraform init -upgrade` |
| "provider ... is required" | Add all three providers to `providers` block |
| "Unsupported attribute: subscription_id" | Remove subscription_id variables from module call |

## More Information

See `MIGRATION-GUIDE.md` for detailed migration steps and examples.
