################################################################################
# Vault Secrets Engines, Auth Methods & Policies
################################################################################

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

# ------------------------------------------------------------------------------
# KV v2 Secrets Engine
# ------------------------------------------------------------------------------
resource "vault_mount" "kv" {
  path        = "secret"
  type        = "kv-v2"
  description = "KV Version 2 secrets engine"

  options = {
    version = "2"
  }
}

# ------------------------------------------------------------------------------
# AWS Secrets Engine – Dynamic IAM Credentials
# ------------------------------------------------------------------------------
resource "vault_aws_secret_backend" "aws" {
  path        = "aws"
  description = "AWS dynamic credentials engine"

  access_key                = var.aws_access_key
  secret_key                = var.aws_secret_key
  region                    = var.aws_region
  default_lease_ttl_seconds = var.aws_default_lease_ttl
  max_lease_ttl_seconds     = var.aws_max_lease_ttl
}

resource "vault_aws_secret_backend_role" "developer" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "developer-role"
  credential_type = "iam_user"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ]
      Resource = "*"
    }]
  })
}

resource "vault_aws_secret_backend_role" "readonly" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "readonly-role"
  credential_type = "iam_user"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket", "dynamodb:GetItem", "dynamodb:Query"]
      Resource = "*"
    }]
  })
}

# ------------------------------------------------------------------------------
# Database Secrets Engine – PostgreSQL Dynamic Credentials
# ------------------------------------------------------------------------------
resource "vault_mount" "database" {
  path        = "database"
  type        = "database"
  description = "Database dynamic credentials engine"
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.database.path
  name          = "postgresql"
  allowed_roles = ["app-role", "readonly-role"]

  postgresql {
    connection_url = "postgresql://{{username}}:{{password}}@${var.db_host}:${var.db_port}/${var.db_name}?sslmode=require"
    username       = var.db_admin_username
    password       = var.db_admin_password
  }
}

resource "vault_database_secret_backend_role" "app" {
  backend             = vault_mount.database.path
  name                = "app-role"
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"]
  revocation_statements = ["REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\"; DROP ROLE IF EXISTS \"{{name}}\";"]
  default_ttl         = var.db_default_lease_ttl
  max_ttl             = var.db_max_lease_ttl
}

resource "vault_database_secret_backend_role" "readonly" {
  backend             = vault_mount.database.path
  name                = "readonly-role"
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"]
  revocation_statements = ["REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\"; DROP ROLE IF EXISTS \"{{name}}\";"]
  default_ttl         = var.db_default_lease_ttl
  max_ttl             = var.db_max_lease_ttl
}

# ------------------------------------------------------------------------------
# AppRole Auth Method
# ------------------------------------------------------------------------------
resource "vault_auth_backend" "approle" {
  type        = "approle"
  path        = "approle"
  description = "AppRole authentication for services"
}

resource "vault_approle_auth_backend_role" "app" {
  backend        = vault_auth_backend.approle.path
  role_name      = "app"
  token_policies = ["default", "app-policy"]
  token_ttl      = 3600
  token_max_ttl  = 14400

  secret_id_bound_cidrs = var.approle_bound_cidrs
  token_bound_cidrs     = var.approle_bound_cidrs
}

# ------------------------------------------------------------------------------
# Policies
# ------------------------------------------------------------------------------
resource "vault_policy" "admin" {
  name   = "admin"
  policy = file("${path.module}/../../../policies/admin.hcl")
}

resource "vault_policy" "readonly" {
  name   = "readonly"
  policy = file("${path.module}/../../../policies/readonly.hcl")
}

resource "vault_policy" "app" {
  name   = "app-policy"
  policy = file("${path.module}/../../../policies/app-policy.hcl")
}

resource "vault_policy" "rotation" {
  name = "rotation-policy"

  policy = <<-EOT
    # Allow rotating credentials
    path "aws/config/rotate-root" {
      capabilities = ["update"]
    }
    path "database/rotate-root/postgresql" {
      capabilities = ["update"]
    }
    path "sys/leases/revoke-prefix/aws/*" {
      capabilities = ["update"]
    }
    path "sys/leases/revoke-prefix/database/*" {
      capabilities = ["update"]
    }
  EOT
}

# ------------------------------------------------------------------------------
# Audit Device – File (stdout for container logging)
# ------------------------------------------------------------------------------
resource "vault_audit" "stdout" {
  type        = "file"
  description = "Audit log to stdout for container log collection"

  options = {
    file_path = "stdout"
    log_raw   = "false"
  }
}
