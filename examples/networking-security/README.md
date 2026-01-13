# Networking and Security Example

This comprehensive example demonstrates **ALL** networking and security features for Azure Bot Service in ONE place, including private endpoints, private endpoint connections, and network security perimeter.

## Why Use azapi in Some Places?

The module uses **two different providers** for good reasons:

1. **azurerm_private_endpoint** (standard provider) - For creating private endpoints
   - Stable, GA API
   - Used by `var.private_endpoints`

2. **azapi_resource** (preview API provider) - For:
   - **Private Endpoint Connection approvals** (`var.private_endpoint_connections`) - Preview API only
   - **Network Security Perimeter** (`var.network_security_perimeter_configurations`) - Preview API only
   - These features require preview API versions that aren't in the stable azurerm provider yet

## Four Options Demonstrated

### Option 1: Module-Managed Private Endpoint ✅ RECOMMENDED
```hcl
module "bot" {
  private_endpoints = {
    primary = {
      subnet_resource_id = azurerm_subnet.subnet.id
      private_dns_zone_resource_ids = [azurerm_private_dns_zone.bot.id]
    }
  }
}
```
- **Uses:** `azurerm_private_endpoint` (stable provider)
- **Best for:** Most common scenario - you control the private endpoint

### Option 2: Manual Private Endpoint
```hcl
resource "azurerm_private_endpoint" "manual" {
  private_connection_resource_id = module.bot.resource_id
  subresource_names = ["Bot"]
}
```
- **Uses:** `azurerm_private_endpoint` directly (outside module)
- **Best for:** When you need custom configuration not supported by module

### Option 3: Private Endpoint Connection Approval
```hcl
module "bot" {
  private_endpoint_connections = {
    connection = {
      private_link_service_connection_state = {
        status = "Approved"
      }
    }
  }
}
```
- **Uses:** `azapi_resource` (REQUIRED - preview API only)
- **Best for:** Approving/rejecting external private endpoint requests
- **Note:** This manages incoming connections, not creating your own PEs

### Option 4: Network Security Perimeter
```hcl
module "bot" {
  public_network_access = "SecuredByPerimeter"
  network_security_perimeter_configurations = {
    primary = { name = "nsp-config" }
  }
}
```
- **Uses:** `azapi_resource` (REQUIRED - preview API only)
- **Best for:** Alternative to private endpoints for network security
- **Note:** Requires NSP infrastructure to be created separately

## Can They Be Combined?

**No, you should choose ONE approach per bot:**
- Private endpoints OR Network Security Perimeter (not both)
- Module-managed PE OR manual PE (not both for the same bot)
- Connection approval is separate - only needed for external PE requests

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Key Takeaways

1. **Most users should use Option 1** (module-managed private endpoints with `var.private_endpoints`)
2. **azapi is required** for connection approvals and NSP because they're preview features
3. **Don't mix approaches** - choose one networking security model per bot service
4. The separate `main.privateendpoint.tf` and `main.privateendpointconnections.tf` files are **both needed** because they serve different purposes

## Outputs

- `module_managed_pe_bot_id` - Bot using module's private endpoint feature
- `manual_pe_bot_id` - Bot with manually created private endpoint
- `approval_bot_id` - Bot demonstrating connection approval workflow
- `nsp_bot_id` - Bot configured with Network Security Perimeter
