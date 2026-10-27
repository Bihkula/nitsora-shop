terraform {
  required_version = ">= 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # State lives in S3. The bucket name is passed at init time (see below),
  # because this block can't use variables.
  backend "s3" {
    key          = "persistent/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "nitsora"
      Stack   = "persistent"
    }
  }
}

# ------------------------------------------------------------ passwords

resource "random_password" "db" {
  for_each = toset(["dev", "prod"])
  length   = 32
  special  = false # goes inside a database URL, where symbols cause trouble
}

resource "random_password" "jwt" {
  for_each = toset(["dev", "prod"])
  length   = 64
  special  = false
}

resource "random_password" "internal" {
  for_each = toset(["dev", "prod"])
  length   = 40
  special  = false
}

resource "random_password" "admin" {
  for_each = toset(["dev", "prod", "grafana"])
  length   = 20
  special  = false
}

# ------------------------------------------------------------ the secrets file

locals {
  env_secrets = {
    for env in ["dev", "prod"] : env => {
      DB_PASSWORD            = random_password.db[env].result
      JWT_SECRET             = random_password.jwt[env].result
      INTERNAL_TOKEN         = random_password.internal[env].result
      ADMIN_EMAIL            = "admin@example.com"
      ADMIN_PASSWORD         = random_password.admin[env].result
      STRIPE_SECRET_KEY      = ""
      STRIPE_WEBHOOK_SECRET  = ""
      STRIPE_PUBLISHABLE_KEY = ""
    }
  }
}

resource "aws_s3_object" "secrets" {
  bucket                 = var.state_bucket
  key                    = "secrets/nitsora-secrets.json"
  content_type           = "application/json"
  server_side_encryption = "AES256"

  content = jsonencode({
    dev  = local.env_secrets["dev"]
    prod = local.env_secrets["prod"]
    grafana = {
      "admin-user"     = "admin"
      "admin-password" = random_password.admin["grafana"].result
    }
  })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [content]
  }
}

output "secrets_file" {
  value = "s3://${var.state_bucket}/${aws_s3_object.secrets.key}"
}