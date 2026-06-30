variable "vault_address" {
  description = "Vault cluster endpoint URL"
  type        = string
}

variable "vault_token" {
  description = "Vault root/admin token for initial configuration"
  type        = string
  sensitive   = true
}

# --- AWS Secrets Engine ---
variable "aws_access_key" {
  description = "AWS access key for Vault AWS secrets engine"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key for Vault AWS secrets engine"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for the secrets engine"
  type        = string
  default     = "us-east-1"
}

variable "aws_default_lease_ttl" {
  description = "Default lease TTL in seconds for AWS credentials"
  type        = number
  default     = 3600
}

variable "aws_max_lease_ttl" {
  description = "Max lease TTL in seconds for AWS credentials"
  type        = number
  default     = 86400
}

# --- Database Secrets Engine ---
variable "db_host" {
  description = "PostgreSQL host"
  type        = string
}

variable "db_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_admin_username" {
  description = "PostgreSQL admin username (Vault will use this to manage roles)"
  type        = string
  sensitive   = true
}

variable "db_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "db_default_lease_ttl" {
  description = "Default lease TTL in seconds for database credentials"
  type        = number
  default     = 3600
}

variable "db_max_lease_ttl" {
  description = "Max lease TTL in seconds for database credentials"
  type        = number
  default     = 86400
}

# --- AppRole ---
variable "approle_bound_cidrs" {
  description = "CIDR blocks allowed to authenticate via AppRole"
  type        = list(string)
  default     = []
}

# --- Tags ---
variable "tags" {
  description = "Tags applied to Vault resources"
  type        = map(string)
  default     = {}
}
