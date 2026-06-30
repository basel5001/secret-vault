variable "vault_version" {
  description = "HashiCorp Vault Docker image tag"
  type        = string
  default     = "1.15.4"
}

variable "cluster_name" {
  description = "Name prefix for all cluster resources"
  type        = string
  default     = "xops-vault"
}

variable "vpc_id" {
  description = "VPC ID where Vault will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for Vault tasks and ALB"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN of an existing KMS key for auto-unseal. Leave empty to create a new one."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the Vault endpoint (used for ACM certificate)"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "desired_count" {
  description = "Number of Vault ECS tasks"
  type        = number
  default     = 3
}

variable "task_cpu" {
  description = "CPU units for Vault task (1 vCPU = 1024)"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memory (MB) for Vault task"
  type        = number
  default     = 1024
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "log_level" {
  description = "Vault log level"
  type        = string
  default     = "info"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB on port 443"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}
