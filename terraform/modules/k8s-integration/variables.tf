variable "vault_address" {
  description = "External Vault endpoint URL"
  type        = string
}

variable "vault_version" {
  description = "Vault agent/CSI image tag"
  type        = string
  default     = "1.15.4"
}

variable "vault_helm_version" {
  description = "Vault Helm chart version"
  type        = string
  default     = "0.27.0"
}

variable "vault_namespace" {
  description = "Kubernetes namespace for Vault components"
  type        = string
  default     = "vault"
}

variable "cluster_name" {
  description = "Kubernetes cluster name (for identification)"
  type        = string
}

variable "kubernetes_host" {
  description = "Kubernetes API server URL"
  type        = string
}

variable "kubernetes_ca_cert" {
  description = "PEM-encoded CA certificate for the Kubernetes API"
  type        = string
}

variable "token_reviewer_jwt" {
  description = "JWT token for Vault to validate service account tokens"
  type        = string
  sensitive   = true
}

variable "token_issuer" {
  description = "Kubernetes token issuer (oidc issuer URL)"
  type        = string
  default     = ""
}

variable "app_namespaces" {
  description = "List of Kubernetes namespaces that should access Vault secrets"
  type        = list(string)
  default     = ["default"]
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account for Vault auth"
  type        = string
  default     = "vault-auth"
}

variable "token_ttl" {
  description = "Default TTL for Kubernetes auth tokens (seconds)"
  type        = number
  default     = 3600
}

variable "token_max_ttl" {
  description = "Max TTL for Kubernetes auth tokens (seconds)"
  type        = number
  default     = 86400
}
