# ==============================================================================
# General
# ==============================================================================
variable "cluster_name" {
  description = "Name prefix for Vault cluster resources"
  type        = string
  default     = "xops-vault"
}

variable "vault_version" {
  description = "HashiCorp Vault version"
  type        = string
  default     = "1.15.4"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Networking
# ==============================================================================
variable "vpc_id" {
  description = "VPC ID for Vault deployment"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the Vault ALB"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

# ==============================================================================
# Vault Cluster
# ==============================================================================
variable "kms_key_arn" {
  description = "KMS key ARN for auto-unseal (blank to create new)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for Vault TLS endpoint"
  type        = string
}

variable "vault_desired_count" {
  description = "Number of Vault Fargate tasks"
  type        = number
  default     = 3
}

variable "vault_task_cpu" {
  description = "Vault task CPU units"
  type        = number
  default     = 512
}

variable "vault_task_memory" {
  description = "Vault task memory (MB)"
  type        = number
  default     = 1024
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

# ==============================================================================
# Vault Secrets Configuration
# ==============================================================================
variable "vault_token" {
  description = "Root/admin token for Vault configuration"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vault_aws_access_key" {
  description = "AWS access key for Vault AWS secrets engine"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vault_aws_secret_key" {
  description = "AWS secret key for Vault AWS secrets engine"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_default_lease_ttl" {
  description = "Default TTL for AWS dynamic creds (seconds)"
  type        = number
  default     = 3600
}

variable "aws_max_lease_ttl" {
  description = "Max TTL for AWS dynamic creds (seconds)"
  type        = number
  default     = 86400
}

variable "db_host" {
  description = "PostgreSQL host"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = ""
}

variable "db_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_default_lease_ttl" {
  description = "Default TTL for DB dynamic creds (seconds)"
  type        = number
  default     = 3600
}

variable "db_max_lease_ttl" {
  description = "Max TTL for DB dynamic creds (seconds)"
  type        = number
  default     = 86400
}

variable "approle_bound_cidrs" {
  description = "CIDR blocks allowed for AppRole auth"
  type        = list(string)
  default     = []
}

# ==============================================================================
# Kubernetes Integration
# ==============================================================================
variable "enable_k8s_integration" {
  description = "Enable Vault ↔ Kubernetes integration"
  type        = bool
  default     = false
}

variable "vault_helm_version" {
  description = "Vault Helm chart version"
  type        = string
  default     = "0.27.0"
}

variable "k8s_cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = ""
}

variable "kubernetes_host" {
  description = "Kubernetes API server URL"
  type        = string
  default     = ""
}

variable "kubernetes_ca_cert" {
  description = "Kubernetes CA certificate (PEM)"
  type        = string
  default     = ""
}

variable "k8s_token_reviewer_jwt" {
  description = "Kubernetes token reviewer JWT"
  type        = string
  sensitive   = true
  default     = ""
}

variable "k8s_token_issuer" {
  description = "Kubernetes OIDC token issuer URL"
  type        = string
  default     = ""
}

variable "k8s_app_namespaces" {
  description = "Kubernetes namespaces with Vault access"
  type        = list(string)
  default     = ["default"]
}
