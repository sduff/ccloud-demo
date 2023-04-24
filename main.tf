#  _______       __ __            _______       _______          __
# |   _   .-----|  |__.----.--.--|   _   .-----|   _   .-----.--|  .-----.
# |.  1   |  _  |  |  |  __|  |  |.  1   |__ --|.  1___|  _  |  _  |  -__|
# |.  ____|_____|__|__|____|___  |.  _   |_____|.  |___|_____|_____|_____|
# |:  |                    |_____|:  |   |     |:  1   |
# |::.|                          |::.|:. |     |::.. . |
# `---'---               __  ____'--- ---'     `-------'     ___                       ______ __
# |_     _|.-----.-----.|  ||_     _|.-----.----.----.---.-.'  _|.-----.----.--------.|   __ \  |.---.-.-----.
#   |   |  |  -__|__ --||   _||   |  |  -__|   _|   _|  _  |   _||  _  |   _|        ||    __/  ||  _  |     |
#   |___|  |_____|_____||____||___|  |_____|__| |__| |___._|__|  |_____|__| |__|__|__||___|  |__||___._|__|__|

terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.39.0"
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

data "confluent_environment" "development" {
  display_name = "Terraform-Environment"
}

data "confluent_user" "user-account" {
  display_name = "sduff"
}

#
# ----------------------------------------#
# Terraform plan for as many bad policies #
# ----------------------------------------#
#

# Cluster
# - non approved cloud
# - non approved region
# - dedicated

resource "confluent_kafka_cluster" "dedicated" {
  display_name = "bad_dedicated_kafka_cluster"
  availability = "MULTI_ZONE"
  cloud        = "GCP"
  region       = "europe-central2-a"
  dedicated {
    cku = 2
  }

  environment {
    id = data.confluent_environment.development.id
  }

  lifecycle {
    prevent_destroy = true
  }
}

# API Key
# - has invalid name
# - owner is a user, not a service account

resource "confluent_api_key" "user-api-key" {
  display_name = "bad-policy-user-api-key"
  description  = "Bad Policy User API Key"
  owner {
    id          = data.confluent_user.user-account.id
    api_version = data.confluent_user.user-account.api_version
    kind        = data.confluent_user.user-account.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = data.confluent_environment.development.id
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Cluster Config
# - enable auto.create.topics.enable

resource "confluent_kafka_cluster_config" "config" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  rest_endpoint = confluent_kafka_cluster.dedicated.rest_endpoint
  config = {
    "auto.create.topics.enable" = "true"
  }
  credentials {
    key    = confluent_api_key.user-api-key.id
    secret = confluent_api_key.user-api-key.secret
  }
}

# Create a Service Account
# - invalid name

resource "confluent_service_account" "bad-sa" {
  display_name = "bad-policy-service-account"
  description  = "Bad Policy Service Account"
}

# Create RBAC
# - invalid role

resource "confluent_role_binding" "rb" {
  principal   = "User:${data.confluent_user.user-account.id}"
  role_name   = "OrganizationalAdmin"
  crn_pattern = confluent_environment.dedicated.resource_name
}

# Create Topic 1
# - invalid topic name
# - lower partition count
# - config retention.ms

resource "confluent_kafka_topic" "topic01" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  topic_name         = "topic01"
  partitions_count   = 1
  rest_endpoint      = confluent_kafka_cluster.dedicated.rest_endpoint
  credentials {
    key    = confluent_api_key.user-api-key.id
    secret = confluent_api_key.user-api-key.secret
  }
  config = {
    "retention.ms"                        = "999999999"
  }
  lifecycle {
    prevent_destroy = true
  }
}

# Create Topic 2
# - invalid topic name
# - high partition count
# - config retention.bytes

resource "confluent_kafka_topic" "topic02" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  topic_name         = "topic02"
  partitions_count   = 25
  rest_endpoint      = confluent_kafka_cluster.dedicated.rest_endpoint
  credentials {
    key    = confluent_api_key.user-api-key.id
    secret = confluent_api_key.user-api-key.secret
  }
  config = {
    "retention.bytes"                     = "1073741824"
  }
  lifecycle {
    prevent_destroy = true
  }
}

# Attempt to create a non-approved resource

resource "confluent_invitation" "bad-invite" {
      email = "hacker@example.com"
}

# :(
# No resource for testing "preventing the deletion of topics"
