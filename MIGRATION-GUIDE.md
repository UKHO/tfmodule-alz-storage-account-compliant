# Migration Guide: Legacy to Non-Legacy Module

## Overview
This module has been updated to be compatible with `count`, `for_each`, and `depends_on` by removing provider configurations from the module itself. The providers must now be configured and passed from the calling module.

## What Changed

### 1. Provider Configuration Moved
**Before** (Legacy - in module):
```hcl
# versions.tf contained provider blocks
provider "azurerm" {
  subscription_id = var.subscription_id
  # ... other config
}

provider "azurerm" {
  alias = "hub"
  subscription_id = var.hub_subscription_id
}

provider "azurerm" {
  alias = "oldhub"
  subscription_id = var.oldhub_subscription_id
}
```

**After** (Non-Legacy - in calling module):
```hcl
# versions.tf only contains required_providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70"
      configuration_aliases = [azurerm.hub, azurerm.oldhub]
    }
  }
}
```

### 2. Variables Removed
The following variables have been **removed** as they're no longer needed:
- `subscription_id`
- `hub_subscription_id`
- `oldhub_subscription_id`

These are now configured in the provider blocks in your calling module.

### 3. Provider Configuration Now Required in Calling Module

You must now configure providers in your root module and pass them to this module.

## Migration Steps

### Step 1: Configure Providers in Your Root Module

Add these provider configurations to your root Terraform configuration:

```hcl
# main.tf or providers.tf in your root module

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  subscription_id            = var.subscription_id  # Your variable
  storage_use_azuread        = true
  skip_provider_registration = true
}

provider "azurerm" {
  alias                      = "oldhub"
  features {}
  subscription_id            = var.oldhub_subscription_id  # Your variable
  skip_provider_registration = true
}

provider "azurerm" {
  alias                      = "hub"
  features {}
  subscription_id            = var.hub_subscription_id  # Your variable
  skip_provider_registration = true
}
```

### Step 2: Update Module Call

Update your module call to pass the providers and remove subscription ID variables:

**Before**:
```hcl
module "storage_account" {
  source = "git::https://github.com/UKHO/tfmodule-alz-storage-account-compliant.git?ref=main"
  
  # These variables no longer exist!
  subscription_id            = var.subscription_id
  hub_subscription_id        = var.hub_subscription_id
  oldhub_subscription_id     = var.oldhub_subscription_id
  
  resource_group_name        = "your-rg"
  # ... other variables
}
```

**After**:
```hcl
module "storage_account" {
  source = "git::https://github.com/UKHO/tfmodule-alz-storage-account-compliant.git?ref=main"
  
  # Pass provider configurations
  providers = {
    azurerm        = azurerm
    azurerm.oldhub = azurerm.oldhub
    azurerm.hub    = azurerm.hub
  }
  
  resource_group_name        = "your-rg"
  storage_account_name       = "yourstorageacct"
  key_vault_name             = "your-keyvault"
  # ... other variables
  
  # Now you can use count, for_each, and depends_on!
  count = var.create_storage ? 1 : 0
  
  depends_on = [
    azurerm_resource_group.main_rg
  ]
}
```

### Step 3: Update Your Variables

Remove these variables from your root module's `variables.tf` if they were only used to pass to this module:
- Any variables specifically for passing subscription IDs to the module

Keep these variables for your provider configuration:
- Variables used in your provider blocks (subscription IDs)

### Step 4: Run Terraform Init

After making these changes, reinitialize Terraform:

```bash
terraform init -upgrade
```

### Step 5: Verify Configuration

Check that your configuration is valid:

```bash
terraform validate
terraform plan
```

## Benefits of Non-Legacy Module

### Now Supported:
✅ **count** - Conditionally create storage accounts
```hcl
module "storage_account" {
  source = "..."
  count  = var.environment == "prod" ? 1 : 0
  # ...
}
```

✅ **for_each** - Create multiple storage accounts
```hcl
module "storage_account" {
  source   = "..."
  for_each = var.storage_accounts
  
  storage_account_name = each.key
  # ...
}
```

✅ **depends_on** - Explicit dependencies
```hcl
module "storage_account" {
  source = "..."
  
  depends_on = [
    azurerm_resource_group.main_rg,
    azurerm_key_vault.main
  ]
  # ...
}
```

## Example: Using count

```hcl
variable "environments" {
  default = ["dev", "test", "prod"]
}

module "storage_account" {
  source   = "git::https://github.com/UKHO/tfmodule-alz-storage-account-compliant.git?ref=main"
  for_each = toset(var.environments)
  
  providers = {
    azurerm        = azurerm
    azurerm.oldhub = azurerm.oldhub
    azurerm.hub    = azurerm.hub
  }
  
  resource_group_name  = "rg-storage-${each.key}"
  storage_account_name = "sa${each.key}unique123"
  # ... other variables
}
```

## Troubleshooting

### Error: "Module is incompatible with count, for_each, and depends_on"
**Cause**: Using an old version of the module with provider blocks  
**Solution**: Update to the latest version and follow this migration guide

### Error: "No configuration files"
**Cause**: Forgot to run `terraform init -upgrade` after updating the module  
**Solution**: Run `terraform init -upgrade`

### Error: "provider ... is required by this module"
**Cause**: Missing provider configuration in the `providers` block  
**Solution**: Ensure all three providers are passed:
```hcl
providers = {
  azurerm        = azurerm
  azurerm.oldhub = azurerm.oldhub
  azurerm.hub    = azurerm.hub
}
```

### Error: "Unsupported attribute" for subscription_id variables
**Cause**: Trying to pass subscription IDs as module variables  
**Solution**: Remove these from your module call - they're now configured in providers

## Questions?

If you encounter issues during migration:
1. Check that all three providers are configured
2. Verify the `providers` block in your module call
3. Ensure you've removed the subscription_id variables from the module call
4. Run `terraform init -upgrade` to refresh the module

## Summary

| Aspect | Before (Legacy) | After (Non-Legacy) |
|--------|----------------|-------------------|
| Provider Config | In module | In calling module |
| Subscription IDs | Module variables | Provider config |
| count support | ❌ Not supported | ✅ Supported |
| for_each support | ❌ Not supported | ✅ Supported |
| depends_on support | ❌ Not supported | ✅ Supported |
| Provider passing | Automatic | Explicit via `providers` block |
