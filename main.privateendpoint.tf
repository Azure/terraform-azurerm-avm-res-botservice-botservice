# TODO remove this code & var.private_endpoints if private link is not support.  Note it must be included in this module if it is supported.
resource "azapi_resource" "private_endpoint_managed_dns" {
  for_each = var.private_endpoints

  type      = "Microsoft.Network/privateEndpoints@2023-11-01"
  location  = each.value.location != null ? each.value.location : var.location
  name      = each.value.name != null ? each.value.name : "pe-${var.name}"
  parent_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}/resourceGroups/${each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name}"
  tags      = each.value.tags
  body = {
    properties = merge(
      {
        subnet = {
          id = each.value.subnet_resource_id
        }
        privateLinkServiceConnections = [{
          name = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
          properties = {
            privateLinkServiceId = azapi_resource.this.id
            groupIds             = ["Bot"]
          }
        }]
      },
      each.value.network_interface_name != null ? {
        customNetworkInterfaceName = each.value.network_interface_name
      } : {},
      length(each.value.ip_configurations) > 0 ? {
        ipConfigurations = [for ip_config in each.value.ip_configurations : {
          name = ip_config.name
          properties = {
            privateIPAddress = ip_config.private_ip_address
            groupId          = "Bot"
            memberName       = "Bot"
          }
        }]
      } : {},
      length(each.value.private_dns_zone_resource_ids) > 0 ? {
        privateDnsZoneGroups = [{
          name = each.value.private_dns_zone_group_name
          properties = {
            privateDnsZoneConfigs = [for idx, zone_id in each.value.private_dns_zone_resource_ids : {
              name = "config${idx}"
              properties = {
                privateDnsZoneId = zone_id
              }
            }]
          }
        }]
      } : {}
    )
  }
  schema_validation_enabled = false
  ignore_missing_property   = true
}

# The PE resource when we are managing **not** the private_dns_zone_group block
# An example use case is customers using Azure Policy to create private DNS zones
# e.g. <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale>
resource "azapi_resource" "private_endpoint_unmanaged_dns" {
  for_each = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }

  type      = "Microsoft.Network/privateEndpoints@2023-11-01"
  location  = each.value.location != null ? each.value.location : var.location
  name      = each.value.name != null ? each.value.name : "pe-${var.name}"
  parent_id = "/subscriptions/${data.azapi_client_config.this.subscription_id}/resourceGroups/${each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name}"
  tags      = each.value.tags
  body = {
    properties = merge(
      {
        subnet = {
          id = each.value.subnet_resource_id
        }
        privateLinkServiceConnections = [{
          name = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
          properties = {
            privateLinkServiceId = azapi_resource.this.id
            groupIds             = ["Bot"]
          }
        }]
      },
      each.value.network_interface_name != null ? {
        customNetworkInterfaceName = each.value.network_interface_name
      } : {},
      length(each.value.ip_configurations) > 0 ? {
        ipConfigurations = [for ip_config in each.value.ip_configurations : {
          name = ip_config.name
          properties = {
            privateIPAddress = ip_config.private_ip_address
            groupId          = "Bot"
            memberName       = "Bot"
          }
        }]
      } : {}
    )
  }
  schema_validation_enabled = false
  ignore_missing_property   = true
  lifecycle {
    ignore_changes = [body.properties.privateDnsZoneGroups]
  }
}

locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
}

resource "azapi_update_resource" "private_endpoint_asg_association" {
  for_each = local.private_endpoint_application_security_group_associations

  type        = "Microsoft.Network/privateEndpoints@2023-11-01"
  resource_id = var.private_endpoints_manage_dns_zone_group ? azapi_resource.private_endpoint_managed_dns[each.value.pe_key].id : azapi_resource.private_endpoint_unmanaged_dns[each.value.pe_key].id
  body = {
    properties = {
      applicationSecurityGroups = [{
        id = each.value.asg_resource_id
      }]
    }
  }
}
