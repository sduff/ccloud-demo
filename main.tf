terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.26.0"
    }
  }
}

variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Existing Environment, "team"
data "confluent_environment" "env" {
  display_name = "team"
}

# Existing service account, "tf-svc-acct", with OrgAdmin
data "confluent_service_account" "sa-org" {
  display_name = "tf-svc-acct"
}

resource "confluent_api_key" "tf-svc-acct-api-key" {
  display_name = "tf-svc-acct-api-key"
  description  = "TF Service Account API Key"
  owner {
    id          = data.confluent_service_account.env-manager.id
    api_version = data.confluent_service_account.env-manager.api_version
    kind        = data.confluent_service_account.env-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.staging.id
    }
  }
}

resource "confluent_kafka_topic" "topic0" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name    = "orders"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.env-manager-kafka-api-key.id
    secret = confluent_api_key.env-manager-kafka-api-key.secret
  }
}
