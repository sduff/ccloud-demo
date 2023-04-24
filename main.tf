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

data "confluent_environment" "development" {
  display_name = "Terraform-Environment"
}

# dedicated
resource "confluent_kafka_cluster" "dedicated" {
  display_name = "dedicated_kafka_cluster_2"
  availability = "MULTI_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"
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

# basic
resource "confluent_kafka_cluster" "basic" {
  display_name = "basic_kafka_cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"
  basic {}

  environment {
    id = data.confluent_environment.development.id
  }

  lifecycle {
    prevent_destroy = true
  }
}
