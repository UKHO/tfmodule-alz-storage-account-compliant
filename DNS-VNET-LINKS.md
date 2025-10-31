# Private DNS Zone Virtual Network Links - Feature Documentation

## Overview
Added optional support for creating private DNS zone virtual network links for primary (oldhub) private DNS zones to the spoke VNet. This ensures DNS resolution works for storage account private endpoints when the spoke VNet is not already linked to the DNS zones.

## Feature Details

### New Variable
```hcl
variable "create_primary_dns_vnet_links" {
  description = "Create virtual network links for primary (oldhub) private DNS zones to the spoke VNet. Set to false if VNet is already linked to the DNS zones."
  type        = bool
  default     = false
}
```

### Resources Created
When `create_primary_dns_vnet_links = true` and `enable_primary_private_endpoints = true`:

1. **Blob DNS Zone VNet Link**
   - Name: `{vnet-name}-blob-link`
   - Links spoke VNet to `privatelink.blob.core.windows.net` in oldhub
   - Provider: `azurerm.oldhub`

2. **File DNS Zone VNet Link**
   - Name: `{vnet-name}-file-link`
   - Links spoke VNet to `privatelink.file.core.windows.net` in oldhub
   - Provider: `azurerm.oldhub`

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ Spoke Subscription                                              │
│                                                                 │
│  ┌──────────────┐         ┌─────────────────────┐             │
│  │ Storage      │◄────────┤ Private Endpoint    │             │
│  │ Account      │         │ (in spoke VNet)     │             │
│  └──────────────┘         └─────────────────────┘             │
│                                     │                           │
│                                     │ DNS Resolution            │
│                                     ▼                           │
└─────────────────────────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │ VNet Link (if not exists)         │
                    └─────────────────┬─────────────────┘
                                      │
┌─────────────────────────────────────────────────────────────────┐
│ Oldhub Subscription                                             │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐   │
│  │ Private DNS Zones                                       │   │
│  │  • privatelink.blob.core.windows.net                   │   │
│  │  • privatelink.file.core.windows.net                   │   │
│  │                                                         │   │
│  │  Contains A records created by private endpoint        │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## When to Use This Feature

### ✅ Use `create_primary_dns_vnet_links = true` When:

1. **First-time deployment** in a spoke VNet that has never had private endpoints
2. **New spoke VNet** that hasn't been linked to the oldhub DNS zones
3. **Isolated spoke** where DNS zones are not centrally managed
4. **Testing scenarios** where you want the module to handle all DNS configuration

### ❌ Use `create_primary_dns_vnet_links = false` (default) When:

1. **VNet already linked** to oldhub DNS zones (most common in hub-spoke architectures)
2. **Central networking team** manages all DNS zone links
3. **Multiple storage accounts** in the same VNet (link only needs to be created once)
4. **Avoid conflicts** with existing VNet link resources managed elsewhere

## Usage Examples

### Example 1: First Storage Account in New Spoke VNet
```hcl
module "storage_account" {
  source = "git::https://github.com/UKHO/tfmodule-alz-storage-account-compliant.git?ref=main"
  
  providers = {
    azurerm        = azurerm
    azurerm.oldhub = azurerm.oldhub
    azurerm.hub    = azurerm.hub
  }
  
  resource_group_name            = "rg-spoke-app"
  storage_account_name           = "stspoke001"
  key_vault_name                 = "kv-spoke"
  virtual_network_name           = "vnet-spoke-001"
  subnet_name                    = "snet-pe"
  vnet_resource_group_name       = "rg-spoke-network"
  oldhub_dns_zone_resource_group = "rg-dns-oldhub"
  hub_dns_zone_resource_group    = "rg-dns-hub"
  
  # Create VNet links for first storage account
  enable_primary_private_endpoints = true
  create_primary_dns_vnet_links    = true  # ✅ VNet not yet linked
}
```

### Example 2: Additional Storage Account in Same VNet
```hcl
module "storage_account_2" {
  source = "git::https://github.com/UKHO/tfmodule-alz-storage-account-compliant.git?ref=main"
  
  providers = {
    azurerm        = azurerm
    azurerm.oldhub = azurerm.oldhub
    azurerm.hub    = azurerm.hub
  }
  
  resource_group_name            = "rg-spoke-app"
  storage_account_name           = "stspoke002"
  key_vault_name                 = "kv-spoke"
  virtual_network_name           = "vnet-spoke-001"  # Same VNet
  subnet_name                    = "snet-pe"
  vnet_resource_group_name       = "rg-spoke-network"
  oldhub_dns_zone_resource_group = "rg-dns-oldhub"
  hub_dns_zone_resource_group    = "rg-dns-hub"
  
  # Don't create VNet links again
  enable_primary_private_endpoints = true
  create_primary_dns_vnet_links    = false  # ✅ VNet already linked by first storage account
}
```

### Example 3: Hub-Spoke Architecture with Central DNS Management
```hcl
# Networking team already linked VNet to DNS zones
module "storage_account" {
  source = "git::https://github.com/UKHO/tfmodule-alz-storage-account-compliant.git?ref=main"
  
  providers = {
    azurerm        = azurerm
    azurerm.oldhub = azurerm.oldhub
    azurerm.hub    = azurerm.hub
  }
  
  resource_group_name            = "rg-spoke-app"
  storage_account_name           = "stspoke001"
  key_vault_name                 = "kv-spoke"
  virtual_network_name           = "vnet-spoke-managed"
  subnet_name                    = "snet-pe"
  vnet_resource_group_name       = "rg-spoke-network"
  oldhub_dns_zone_resource_group = "rg-dns-oldhub"
  hub_dns_zone_resource_group    = "rg-dns-hub"
  
  # Use existing VNet links managed by networking team
  enable_primary_private_endpoints = true
  create_primary_dns_vnet_links    = false  # ✅ Default - VNet already linked centrally
}
```

### Example 4: Using for_each with Conditional VNet Links
```hcl
variable "storage_accounts" {
  type = map(object({
    vnet_name              = string
    create_vnet_links      = bool  # Set true for first in each VNet
  }))
  
  default = {
    "stapp001" = {
      vnet_name         = "vnet-spoke-001"
      create_vnet_links = true   # First in this VNet
    }
    "stapp002" = {
      vnet_name         = "vnet-spoke-001"
      create_vnet_links = false  # Same VNet, don't recreate
    }
    "stapp003" = {
      vnet_name         = "vnet-spoke-002"
      create_vnet_links = true   # First in different VNet
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
  
  storage_account_name            = each.key
  virtual_network_name            = each.value.vnet_name
  create_primary_dns_vnet_links   = each.value.create_vnet_links
  
  # ... other variables
}
```

## Outputs

New outputs available when VNet links are created:

```hcl
output "blob_primary_dns_vnet_link_id" {
  description = "The ID of the primary blob private DNS zone virtual network link"
  value       = module.storage_account.blob_primary_dns_vnet_link_id
  # Returns ID if created, null otherwise
}

output "file_primary_dns_vnet_link_id" {
  description = "The ID of the primary file private DNS zone virtual network link"
  value       = module.storage_account.file_primary_dns_vnet_link_id
  # Returns ID if created, null otherwise
}
```

## Important Notes

### 1. Secondary DNS Zones Don't Need Links
The `create_primary_dns_vnet_links` variable **only affects primary (oldhub) DNS zones**. Secondary (hub) DNS zones are assumed to already have VNet links configured, as they are typically used for cross-subscription testing and are centrally managed.

### 2. VNet Link Names
VNet links are named: `{vnet-name}-{service}-link`
- Example: `vnet-spoke-001-blob-link`
- Example: `vnet-spoke-001-file-link`

This naming ensures:
- ✅ Descriptive and easy to identify
- ✅ Unique per VNet
- ✅ Won't conflict with existing links

### 3. Provider Context
VNet links are created in the **oldhub subscription** using the `azurerm.oldhub` provider, as that's where the primary private DNS zones are located. The VNet itself remains in the spoke subscription.

### 4. Registration Disabled
Virtual network links are created with `registration_enabled = false`, meaning:
- ✅ DNS records from VMs in the VNet won't auto-register in the DNS zone
- ✅ Follows best practices for private endpoint DNS zones
- ✅ Private endpoint DNS records are managed by Azure automatically

## Troubleshooting

### Error: "A Virtual Network Link with name 'xxx' already exists"

**Cause**: VNet is already linked to the DNS zone (possibly by another process or module)

**Solution**: Set `create_primary_dns_vnet_links = false`

### Private Endpoint DNS Not Resolving

**Symptoms**: Cannot reach storage account via private endpoint, DNS returns public IP

**Solutions**:
1. Check if VNet is linked to DNS zone: Set `create_primary_dns_vnet_links = true`
2. Verify private endpoint is created: Check `enable_primary_private_endpoints = true`
3. Ensure DNS zone contains A record for the storage account
4. Test with `nslookup {storage-account}.blob.core.windows.net` from VM in spoke VNet

### Need to Check Existing VNet Links

```bash
# List existing VNet links for blob DNS zone
az network private-dns link vnet list \
  --resource-group rg-dns-oldhub \
  --zone-name privatelink.blob.core.windows.net \
  --query "[].{Name:name, VNet:virtualNetwork.id}" \
  --output table

# List existing VNet links for file DNS zone
az network private-dns link vnet list \
  --resource-group rg-dns-oldhub \
  --zone-name privatelink.file.core.windows.net \
  --query "[].{Name:name, VNet:virtualNetwork.id}" \
  --output table
```

If your VNet is already in the list, set `create_primary_dns_vnet_links = false`.

## Best Practices

1. **Default to false**: Leave `create_primary_dns_vnet_links = false` unless you know the VNet needs linking
2. **One link per VNet**: Only create VNet links once per VNet (first storage account)
3. **Central management**: Prefer having networking team manage VNet links centrally
4. **Document decision**: Tag storage accounts to indicate whether they created VNet links
5. **Test DNS resolution**: Always test DNS resolution after creating private endpoints

## Migration from Manual VNet Links

If you previously created VNet links manually and want to import them into Terraform:

```bash
# Import blob VNet link
terraform import 'module.storage_account.azurerm_private_dns_zone_virtual_network_link.blob_primary[0]' \
  /subscriptions/{oldhub-sub-id}/resourceGroups/{dns-rg}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net/virtualNetworkLinks/{link-name}

# Import file VNet link
terraform import 'module.storage_account.azurerm_private_dns_zone_virtual_network_link.file_primary[0]' \
  /subscriptions/{oldhub-sub-id}/resourceGroups/{dns-rg}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net/virtualNetworkLinks/{link-name}
```

After importing, set `create_primary_dns_vnet_links = true` in your module call.
