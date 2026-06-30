################################################################################
# Secret Vault – Root Module
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# ------------------------------------------------------------------------------
# Vault Cluster (ECS Fargate + DynamoDB + KMS)
# ------------------------------------------------------------------------------
module "vault_cluster" {
  source = "./modules/vault-cluster"

  cluster_name        = var.cluster_name
  vault_version       = var.vault_version
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  kms_key_arn         = var.kms_key_arn
  domain_name         = var.domain_name
  environment         = var.environment
  desired_count       = var.vault_desired_count
  task_cpu            = var.vault_task_cpu
  task_memory         = var.vault_task_memory
  log_retention_days  = var.log_retention_days
  allowed_cidr_blocks = var.allowed_cidr_blocks
  tags                = local.common_tags
}

# ------------------------------------------------------------------------------
# Vault Secrets Engines & Policies (applied after cluster is up)
# ------------------------------------------------------------------------------
module "vault_secrets" {
  source = "./modules/vault-secrets"

  vault_address = module.vault_cluster.vault_endpoint
  vault_token   = var.vault_token

  # AWS secrets engine
  aws_access_key        = var.vault_aws_access_key
  aws_secret_key        = var.vault_aws_secret_key
  aws_region            = var.aws_region
  aws_default_lease_ttl = var.aws_default_lease_ttl
  aws_max_lease_ttl     = var.aws_max_lease_ttl

  # Database secrets engine
  db_host              = var.db_host
  db_port              = var.db_port
  db_name              = var.db_name
  db_admin_username    = var.db_admin_username
  db_admin_password    = var.db_admin_password
  db_default_lease_ttl = var.db_default_lease_ttl
  db_max_lease_ttl     = var.db_max_lease_ttl

  # AppRole
  approle_bound_cidrs = var.approle_bound_cidrs

  tags = local.common_tags

  depends_on = [module.vault_cluster]
}

# ------------------------------------------------------------------------------
# Kubernetes Integration (CSI + Auth)
# ------------------------------------------------------------------------------
module "k8s_integration" {
  source = "./modules/k8s-integration"
  count  = var.enable_k8s_integration ? 1 : 0

  vault_address      = module.vault_cluster.vault_endpoint
  vault_version      = var.vault_version
  vault_helm_version = var.vault_helm_version
  cluster_name       = var.k8s_cluster_name
  kubernetes_host    = var.kubernetes_host
  kubernetes_ca_cert = var.kubernetes_ca_cert
  token_reviewer_jwt = var.k8s_token_reviewer_jwt
  token_issuer       = var.k8s_token_issuer
  app_namespaces     = var.k8s_app_namespaces

  depends_on = [module.vault_secrets]
}

# ------------------------------------------------------------------------------
# Common Tags
# ------------------------------------------------------------------------------
locals {
  common_tags = merge(var.tags, {
    Project     = "secret-vault"
    ManagedBy   = "terraform"
    Environment = var.environment
  })
}
