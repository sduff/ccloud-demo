terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.28.0"
    }

    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }
}

# Confluent Cloud API Key variables, stored in Terraform Cloud Variable Sets
variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

# Confluent Terraform Provider
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}


#resource "confluent_environment" "staging" {
#  display_name = "Terraform-Environment"
#}

## Stream Governance and Kafka clusters can be in different regions as well as different cloud providers,
## but you should to place both in the same cloud and region to restrict the fault isolation boundary.
#data "confluent_schema_registry_region" "essentials" {
#  cloud   = "AWS"
#  region  = "us-east-2"
#  package = "ESSENTIALS"
#}
#
#resource "confluent_schema_registry_cluster" "essentials" {
#  package = data.confluent_schema_registry_region.essentials.package
#
#  environment {
#    id = confluent_environment.staging.id
#  }
#
#  region {
#    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
#    id = data.confluent_schema_registry_region.essentials.id
#  }
#}
#
## Update the config to use a cloud provider and region of your choice.
## https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster
#resource "confluent_kafka_cluster" "basic" {
#  display_name = "schema-test"
#  availability = "SINGLE_ZONE"
#  cloud        = "AWS"
#  region       = "us-east-2"
#  basic {}
#  environment {
#    id = confluent_environment.staging.id
#  }
#}
#
#// 'app-manager' service account is required in this configuration to create 'purchase' topic and grant ACLs
#// to 'app-producer' and 'app-consumer' service accounts.
#resource "confluent_service_account" "app-manager" {
#  display_name = "sduff-app-manager"
#  description  = "Service account to manage 'schema-test' Kafka cluster"
#}
#
#resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
#  principal   = "User:${confluent_service_account.app-manager.id}"
#  role_name   = "CloudClusterAdmin"
#  crn_pattern = confluent_kafka_cluster.basic.rbac_crn
#}
#
#resource "confluent_api_key" "app-manager-kafka-api-key" {
#  display_name = "app-manager-kafka-api-key"
#  description  = "Kafka API Key that is owned by 'sduff-app-manager' service account"
#  owner {
#    id          = confluent_service_account.app-manager.id
#    api_version = confluent_service_account.app-manager.api_version
#    kind        = confluent_service_account.app-manager.kind
#  }
#
#  managed_resource {
#    id          = confluent_kafka_cluster.basic.id
#    api_version = confluent_kafka_cluster.basic.api_version
#    kind        = confluent_kafka_cluster.basic.kind
#
#    environment {
#      id = confluent_environment.staging.id
#    }
#  }
#
#  # The goal is to ensure that confluent_role_binding.app-manager-kafka-cluster-admin is created before
#  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
#  # confluent_kafka_topic, confluent_kafka_acl resources.
#
#  # 'depends_on' meta-argument is specified in confluent_api_key.app-manager-kafka-api-key to avoid having
#  # multiple copies of this definition in the configuration which would happen if we specify it in
#  # confluent_kafka_topic, confluent_kafka_acl resources instead.
#  depends_on = [
#    confluent_role_binding.app-manager-kafka-cluster-admin
#  ]
#}
#
#resource "confluent_kafka_topic" "purchase" {
#  kafka_cluster {
#    id = confluent_kafka_cluster.basic.id
#  }
#  topic_name    = "purchase"
#  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
#  credentials {
#    key    = confluent_api_key.app-manager-kafka-api-key.id
#    secret = confluent_api_key.app-manager-kafka-api-key.secret
#  }
#}
#
#resource "confluent_kafka_topic" "purchase_new" {
#  kafka_cluster {
#    id = confluent_kafka_cluster.basic.id
#  }
#  topic_name    = "purchase_new"
#  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
#  credentials {
#    key    = confluent_api_key.app-manager-kafka-api-key.id
#    secret = confluent_api_key.app-manager-kafka-api-key.secret
#  }
#}
#
#resource "confluent_kafka_topic" "purchase_alt" {
#  kafka_cluster {
#    id = confluent_kafka_cluster.basic.id
#  }
#  topic_name    = "purchase_alt"
#  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
#  credentials {
#    key    = confluent_api_key.app-manager-kafka-api-key.id
#    secret = confluent_api_key.app-manager-kafka-api-key.secret
#  }
#}

#resource "confluent_service_account" "env-manager" {
#  display_name = "env-manager"
#  description  = "Service account to manage 'Terraform-Environment' environment"
#}

#resource "confluent_role_binding" "env-manager-environment-admin" {
#  principal   = "User:${confluent_service_account.env-manager.id}"
#  role_name   = "EnvironmentAdmin"
#  crn_pattern = confluent_environment.staging.resource_name
#}
#
#resource "confluent_api_key" "env-manager-schema-registry-api-key" {
#  display_name = "env-manager-schema-registry-api-key"
#  description  = "Schema Registry API Key that is owned by 'Terraform-Environment' service account"
#  owner {
#    id          = confluent_service_account.env-manager.id
#    api_version = confluent_service_account.env-manager.api_version
#    kind        = confluent_service_account.env-manager.kind
#  }
#
#  managed_resource {
#    id          = confluent_schema_registry_cluster.essentials.id
#    api_version = confluent_schema_registry_cluster.essentials.api_version
#    kind        = confluent_schema_registry_cluster.essentials.kind
#
#    environment {
#      id = confluent_environment.staging.id
#    }
#  }
#
#  # The goal is to ensure that confluent_role_binding.env-manager-environment-admin is created before
#  # confluent_api_key.env-manager-schema-registry-api-key is used to create instances of
#  # confluent_schema resources.
#
#  # 'depends_on' meta-argument is specified in confluent_api_key.env-manager-schema-registry-api-key to avoid having
#  # multiple copies of this definition in the configuration which would happen if we specify it in
#  # confluent_schema resources instead.
#  depends_on = [
#    confluent_role_binding.env-manager-environment-admin
#  ]
#}
#
#resource "confluent_schema" "purchase" {
#  schema_registry_cluster {
#    id = confluent_schema_registry_cluster.essentials.id
#  }
#  rest_endpoint = confluent_schema_registry_cluster.essentials.rest_endpoint
#  subject_name = "purchase-value"
#  format = "AVRO"
#  schema = file("./purchase.avsc")
#  credentials {
#    key    = confluent_api_key.env-manager-schema-registry-api-key.id
#    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
#  }
#}
#
#resource "confluent_schema" "purchase_new_schema" {
#  schema_registry_cluster {
#    id = confluent_schema_registry_cluster.essentials.id
#  }
#  rest_endpoint = confluent_schema_registry_cluster.essentials.rest_endpoint
#  subject_name = "purchase_new-value"
#  format = "AVRO"
#  schema = file("./purchase.avsc")
#  credentials {
#    key    = confluent_api_key.env-manager-schema-registry-api-key.id
#    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
#  }
#}
#

###

# Create a service account
# Create an API key

# Create a KeyVault
# Store API Key in KeyVault

provider "azurerm" {
  features {}
}
#
## Create a resource Group
#resource "azurerm_resource_group" "rg" {
#  name ="apac-ps-confluent-cloud-rg"
#  location = "australiasoutheast"
#  tags = {
#    owner_email = "sduff@confluent.io"
#  }
#}
#
## Create a KeyVault
#data "azurerm_client_config" "current" {}
#
#resource "azurerm_key_vault" "keyvault" {
#  depends_on                  = [azurerm_resource_group.rg]
#  name                        = "kv-apac-ps"
#  location                    = azurerm_resource_group.rg.location
#  resource_group_name         = azurerm_resource_group.rg.name
#  enabled_for_disk_encryption = true
#  tenant_id                   = data.azurerm_client_config.current.tenant_id
#  soft_delete_retention_days  = 7
#  purge_protection_enabled    = false
#
#  sku_name = "standard"
#
#  access_policy {
#    tenant_id = data.azurerm_client_config.current.tenant_id
#    object_id = data.azurerm_client_config.current.object_id
#
#    key_permissions = [
#      "Get",
#    ]
#
#    secret_permissions = [
#      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
#    ]
#
#    storage_permissions = [
#      "Get",
#    ]
#  }
#
#  tags = {
#    owner_email = "sduff@confluent.io"
#  }
#}
#
## Create a new secret and store in the keyvault
#resource "azurerm_key_vault_secret" "app_mgr_secret" {
#  name         = confluent_service_account.app-manager.display_name
#  value        = "${confluent_api_key.app-manager-kafka-api-key.id}:${confluent_api_key.app-manager-kafka-api-key.secret}"
#  key_vault_id = azurerm_key_vault.keyvault.id
#  depends_on   = [azurerm_key_vault.keyvault]
#}
