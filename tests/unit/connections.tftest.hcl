mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/test-rg/providers/Microsoft.BotService/botServices/test-bot"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000003"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}

run "matches_connection_parameters_by_key" {
  command = apply

  variables {
    location                  = "global"
    microsoft_app_id          = "00000000-0000-0000-0000-000000000001"
    name                      = "test-bot"
    resource_group_name       = "test-rg"
    enable_telemetry          = false
    schema_validation_enabled = false
    connections = {
      oauth = {
        properties = {
          clientSecret = sensitive("not-a-real-secret")
          parameters = [
            {
              key   = "clientId"
              value = "00000000-0000-0000-0000-000000000001"
            },
            {
              key   = "clientSecret"
              value = sensitive("not-a-real-secret")
            },
            {
              key   = "tenantId"
              value = "00000000-0000-0000-0000-000000000002"
            }
          ]
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.connections["oauth"].list_unique_id_property["properties.parameters"] == "key"
    error_message = "Connection parameter lists must be matched by key so server-side reordering does not misalign values."
  }
}
