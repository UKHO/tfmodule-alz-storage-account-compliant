# Azure Storage Account with Full CMK - ALZ Compliant

## Overview
This is an **azapi-based implementation** of an Azure Landing Zone (ALZ) compliant storage account with **full customer-managed key support** for all services. Unlike the AVM-based approach, this implementation provides:

✅ **Full CMK Support** - Customer-managed keys for ALL services (blob, file, queue, table)  
✅ **Queue/Table CMK** - Enables CMK for queue and table services (azurerm limitation solved)  
✅ **Single Resource** - One azapi_resource manages all properties  
✅ **ALZ Compliant** - All compliance settings configured at creation time  

## Key Features

### ALZ Compliance (100%)
All Azure Landing Zone policies are satisfied **natively**:

- ✅ HTTPS traffic only
- ✅ Minimum TLS 1.2
- ✅ Infrastructure encryption enabled
- ✅ Public network access disabled
- ✅ Shared access keys disabled
- ✅ Default to OAuth authentication
- ✅ Blob public access disabled
- ✅ Cross-tenant replication disabled
- ✅ **Copy scope restricted to AAD**
- ✅ **Local users (SFTP) disabled**
- ✅ **Network bypass = [] (strictest)**
- ✅ SFTP explicitly disabled
- ✅ Blob versioning enabled
- ✅ Soft delete for blobs and containers
- ✅ Point-in-time restore

### Private Endpoints
**Dual Endpoint Strategy** for cross-subscription DNS resolution:

1. **Primary Endpoints** (oldhub DNS zones)
   - Clean names: `{storage}-blob-pe`, `{storage}-file-pe`
   - DNS zones in oldhub subscription (282900b8-5415-4137-afcc-fd13fe9a64a7)
   - Controlled by: `enable_primary_private_endpoints = true`
   - **Optional VNet Links**: Set `create_primary_dns_vnet_links = true` to create private DNS zone virtual network links to the spoke VNet

2. **Secondary Endpoints** (hub DNS zones)
   - Suffixed names: `{storage}-blob-pe-hub`, `{storage}-file-pe-hub`
   - DNS zones in hub subscription (f2332963-f81e-4c39-953c-c04510584ba2)
   - Controlled by: `enable_secondary_private_endpoints = true`
   - Purpose: Cross-subscription DNS resolution testing
   - **Note**: Secondary DNS zones don't require VNet links (assumed already configured)

### Multi-Subscription Support
Three provider aliases for flexible DNS zone access:
- `default` - Storage account deployment subscription
- `oldhub` - Primary DNS zones
- `hub` - Secondary DNS zones

## Code Organization

The Terraform module is organized into logical files for better maintainability:

```
├── main.tf                 - Module overview and file organization
├── data-sources.tf         - All data source lookups (RG, Key Vault, subnets, DNS zones)
├── locals.tf               - Local value calculations and references
├── identity-rbac.tf        - User-assigned identity and RBAC assignments  
├── key-vault-keys.tf       - Key Vault keys for customer-managed encryption
├── storage-account.tf      - Main storage account resource (azapi implementation)
├── private-endpoints.tf    - Private endpoints for blob/file services
├── variables.tf            - Input variable definitions
├── outputs.tf              - Module outputs
└── versions.tf             - Provider version constraints
```

Each file has a single responsibility, making it easy to locate and modify specific functionality.

## Architecture Differences from AVM Implementation

| Feature | AVM Implementation | Pure AzureRM Implementation |
|---------|-------------------|---------------------------|
| **Base Module** | Azure Verified Module | Native azapi_resource |
| **ALZ Settings** | Partial + azapi workarounds | All native properties |
| **Queue/Table CMK** | Not supported | Full CMK support |
| **network_bypass** | azapi post-deployment | Native networkAcls |
| **State Complexity** | Multiple resources | Single storage account |
| **Drift Risk** | Medium (azapi updates) | Low (native properties) |
| **Debugging** | Complex (module + azapi) | Simple (direct resources) |

## Deployment

### Prerequisites
- Azure CLI authenticated
- Terraform >= 1.5
- Access to three subscriptions:
  - Target subscription (storage account)
  - oldhub subscription (primary DNS zones)
  - hub subscription (secondary DNS zones)

### Provider Configuration

**Important**: This module requires provider configurations to be passed from the caller. Configure providers in your root module:

```hcl
# Configure the default provider for the target subscription
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  subscription_id            = var.subscription_id
  storage_use_azuread        = true
  skip_provider_registration = true
}

# Configure the oldhub provider for primary DNS zones
provider "azurerm" {
  alias                      = "oldhub"
  features {}
  subscription_id            = var.oldhub_subscription_id
  skip_provider_registration = true
}

# Configure the hub provider for secondary DNS zones
provider "azurerm" {
  alias                      = "hub"
  features {}
  subscription_id            = var.hub_subscription_id
  skip_provider_registration = true
}
```

### Module Usage

```hcl
module "storage_account" {
  source = "git::https://github.com/UKHO/tfmodule-alz-storage-account-compliant.git?ref=main"
  
  # Pass provider configurations
  providers = {
    azurerm        = azurerm
    azurerm.oldhub = azurerm.oldhub
    azurerm.hub    = azurerm.hub
  }
  
  # Required variables
  resource_group_name            = "your-rg"
  storage_account_name           = "yourstorageacct"
  key_vault_name                 = "your-keyvault"
  virtual_network_name           = "your-vnet"
  subnet_name                    = "pe-subnet"
  vnet_resource_group_name       = "vnet-rg"
  oldhub_dns_zone_resource_group = "primary-dns-rg"
  hub_dns_zone_resource_group    = "secondary-dns-rg"
  
  # Optional: Enable/disable private endpoints
  enable_primary_private_endpoints   = true
  enable_secondary_private_endpoints = false
  
  # Optional: Create VNet links for primary DNS zones (if spoke VNet not already linked)
  create_primary_dns_vnet_links      = true
  
  # Now supports count, for_each, and depends_on!
  count = var.create_storage ? 1 : 0
  
  depends_on = [
    azurerm_resource_group.main_rg
  ]
}
```

### Quick Start

```bash
# Initialize
terraform init

# Review plan
terraform plan

# Deploy with primary endpoints only
terraform apply

# Optional: Enable secondary endpoints for testing
# Edit terraform.tfvars: enable_secondary_private_endpoints = true
terraform apply
```

### Phased Deployment

**Phase 1: Storage Account + Primary Endpoints**
```hcl
enable_primary_private_endpoints   = true
enable_secondary_private_endpoints = false
create_primary_dns_vnet_links      = true  # Set to false if VNet already linked
```

**Phase 2: Add Secondary for Cross-Sub DNS Testing**
```hcl
enable_primary_private_endpoints   = true
enable_secondary_private_endpoints = true
create_primary_dns_vnet_links      = true  # Only for primary DNS zones
```

**Phase 3: Choose Final Configuration**
After testing, keep only the endpoint set you need.

### Private DNS Zone Virtual Network Links

The module can optionally create virtual network links between the spoke VNet and the primary (oldhub) private DNS zones. This is required for DNS resolution to work from the spoke VNet to the private endpoints.

**When to use `create_primary_dns_vnet_links = true`:**
- First time deploying storage account in a spoke VNet
- Spoke VNet is **not yet linked** to the oldhub private DNS zones
- You need automatic DNS resolution for storage private endpoints

**When to use `create_primary_dns_vnet_links = false` (default):**
- Spoke VNet is **already linked** to the oldhub private DNS zones (e.g., via hub-spoke peering setup)
- Central networking team manages DNS zone links
- Want to avoid duplicate VNet link creation

**Note**: Secondary (hub) DNS zones don't need VNet links as they are assumed to be already configured for cross-subscription scenarios.

## Configuration

### Required Variables
```hcl
resource_group_name              = "your-rg"
storage_account_name             = "yourstorageacct"
key_vault_name                   = "your-keyvault"
virtual_network_name             = "your-vnet"
subnet_name                      = "pe-subnet"
vnet_resource_group_name         = "vnet-rg"
oldhub_dns_zone_resource_group   = "primary-dns-rg"
hub_dns_zone_resource_group      = "secondary-dns-rg"
```

**Note**: Subscription IDs are now configured via provider blocks in the calling module, not as variables.

### Optional Customization
```hcl
account_replication_type           = "GRS"     # Default: "ZRS"
blob_delete_retention_days         = 14        # Default: 7
enable_primary_private_endpoints   = true      # Default: true
enable_secondary_private_endpoints = false     # Default: false
create_primary_dns_vnet_links      = false     # Default: false (set true if VNet not already linked)
```

## Outputs

Key outputs available after deployment:

```hcl
storage_account_name              # Generated unique name
storage_account_id                # Resource ID
blob_primary_private_endpoint_ip  # Primary endpoint IP
alz_compliance_status             # All compliance settings
```

## ALZ Policy Compliance

All policies satisfied **without exceptions**:

| Policy | Status | Implementation |
|--------|--------|----------------|
| Storage accounts should restrict network access | ✅ | `network_rules.default_action = "Deny"` |
| Network ACL bypass option should be restricted | ✅ | `network_rules.bypass = []` |
| Storage accounts should use private link | ✅ | Private endpoints configured |
| Public network access should be disabled | ✅ | `public_network_access_enabled = false` |
| Secure transfer should be enabled | ✅ | `enable_https_traffic_only = true` |
| Storage accounts should restrict copy scope | ✅ | `allowed_copy_scope = "AAD"` |
| Local users should be restricted | ✅ | `local_user_enabled = false` |
| Shared key access should be disabled | ✅ | `shared_access_key_enabled = false` |
| Infrastructure encryption should be enabled | ✅ | `infrastructure_encryption_enabled = true` |

## Validation

Run policy scan:
```bash
# Trigger on-demand policy evaluation
az policy state trigger-scan --resource-group "your-rg"

# Check compliance
az policy state list --resource-group "your-rg" \
  --filter "ResourceId eq '/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}'" \
  --query "[?complianceState=='NonCompliant'].{Policy:policyDefinitionName, State:complianceState}"
```

Expected result: **0 non-compliant policies**

## Troubleshooting

### Issue: Private Endpoint Connection Failed
**Solution**: Ensure subnet has `enforce_private_link_endpoint_network_policies = true`

### Issue: DNS Resolution Not Working
**Solution**: 
1. Check DNS zone linked to VNet
2. Verify private endpoint DNS zone group configuration
3. Test with both primary and secondary endpoints

### Issue: Access Denied Errors
**Solution**: This is expected! Public access is disabled. Access must be via:
- Private endpoints
- Azure Portal (uses Azure backbone)
- Azure services with system-assigned managed identity

## Migration from AVM Implementation

If migrating from the archived AVM implementation:

1. **Destroy old resources** (or rename via state manipulation)
   ```bash
   cd ..
   terraform destroy
   ```

2. **Deploy new implementation**
   ```bash
   cd azurerm-native-implementation
   terraform init
   terraform apply
   ```

3. **Verify compliance**
   ```bash
   az policy state trigger-scan --resource-group "your-rg"
   ```

## Advantages of This Approach

1. **Native Properties** - All settings in one resource
2. **No State Drift** - No post-deployment updates needed
3. **Simpler Debugging** - Direct resource inspection
4. **Better Performance** - Single resource update cycle
5. **Standard Patterns** - Follows Terraform best practices
6. **Easier Maintenance** - No module version dependencies

## Next Steps

1. ✅ Deploy with primary endpoints
2. ✅ Validate ALZ compliance (should be 100%)
3. ⚠️ Test connectivity from applications
4. 📊 Monitor for any policy violations
5. 📝 Document final architecture
6. 🔒 Enable secondary endpoints if cross-subscription DNS needed

## Support

This implementation uses Terraform resources optimized for full CMK support:
- `azapi_resource` (Microsoft.Storage/storageAccounts) - [Documentation](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/azapi_resource)
- `azurerm_private_endpoint` - [Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint)
- `azurerm_user_assigned_identity` - [Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity)
- `azurerm_key_vault_key` - [Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key)

## License

This configuration is provided as-is for Azure Landing Zone deployments.
