mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/test-rg/providers/Microsoft.BotService/botServices/test-bot"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000003"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000003"
    }
  }
}

variables {
  location            = "centralindia"
  microsoft_app_id    = "00000000-0000-0000-0000-000000000001"
  name                = "test-bot"
  resource_group_name = "test-rg"

  channels = {
    default = {
      channel_name = "default-channel"
    }
    explicit = {
      channel_name = "explicit-channel"
      location     = "westeurope"
    }
  }

  connections = {
    default = {
      properties = {}
    }
    explicit = {
      location   = "centralindia"
      properties = {}
    }
  }
}

run "centralindia_locations_are_preserved" {
  command = apply

  assert {
    condition = (
      azapi_resource.this.location == "centralindia" &&
      azapi_resource.channels["default"].location == "centralindia" &&
      azapi_resource.connections["default"].location == "centralindia"
    )
    error_message = "Bot Service, channel, and connection defaults must preserve centralindia."
  }

  assert {
    condition = (
      azapi_resource.channels["explicit"].location == "westeurope" &&
      azapi_resource.connections["explicit"].location == "centralindia"
    )
    error_message = "Explicit channel and connection locations must be preserved."
  }
}

run "westeurope_locations_are_preserved" {
  command = apply

  variables {
    location = "westeurope"
  }

  assert {
    condition = (
      azapi_resource.this.location == "westeurope" &&
      azapi_resource.channels["default"].location == "westeurope" &&
      azapi_resource.connections["default"].location == "westeurope"
    )
    error_message = "Bot Service, channel, and connection defaults must preserve westeurope."
  }
}

run "westus_locations_are_preserved" {
  command = apply

  variables {
    location = "westus"
  }

  assert {
    condition = (
      azapi_resource.this.location == "westus" &&
      azapi_resource.channels["default"].location == "westus" &&
      azapi_resource.connections["default"].location == "westus"
    )
    error_message = "Bot Service, channel, and connection defaults must preserve westus."
  }
}

run "other_region_maps_product_resources_to_global" {
  command = apply

  variables {
    location = "eastus2"

    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
      }
    }
  }

  assert {
    condition = (
      azapi_resource.this.location == "global" &&
      azapi_resource.channels["default"].location == "global" &&
      azapi_resource.connections["default"].location == "global"
    )
    error_message = "An unsupported Bot Service region must map the Bot, channels, and connections to global."
  }

  assert {
    condition     = azapi_resource.telemetry[0].location == "eastus2"
    error_message = "Telemetry must continue to use the original supplied region."
  }

  assert {
    condition     = azapi_resource.private_endpoint_managed_dns["primary"].location == "eastus2"
    error_message = "Private endpoints must retain the supplied regional location rather than use the Bot Service fallback."
  }

  assert {
    condition = (
      azapi_resource.channels["explicit"].location == "westeurope" &&
      azapi_resource.connections["explicit"].location == "centralindia"
    )
    error_message = "Explicit channel and connection locations must remain unchanged when the Bot Service uses global."
  }
}

run "global_location_is_allowed_when_telemetry_is_disabled" {
  command = apply

  variables {
    location         = "global"
    enable_telemetry = false
  }

  assert {
    condition = (
      azapi_resource.this.location == "global" &&
      azapi_resource.channels["default"].location == "global" &&
      azapi_resource.connections["default"].location == "global" &&
      length(azapi_resource.telemetry) == 0
    )
    error_message = "Direct global location must be allowed with telemetry disabled."
  }
}

run "global_location_with_telemetry_is_rejected" {
  command = plan

  variables {
    enable_telemetry = true
    location         = "global"
  }

  expect_failures = [
    var.location
  ]
}
