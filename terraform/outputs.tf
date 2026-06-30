# ==============================================================================
# Vault Cluster Outputs
# ==============================================================================
output "vault_endpoint" {
  description = "Vault HTTPS endpoint"
  value       = module.vault_cluster.vault_endpoint
}

output "vault_alb_dns" {
  description = "Internal ALB DNS name"
  value       = module.vault_cluster.vault_alb_dns
}

output "vault_sg_id" {
  description = "Vault security group ID"
  value       = module.vault_cluster.vault_sg_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for auto-unseal"
  value       = module.vault_cluster.kms_key_arn
}

output "iam_role_arn" {
  description = "Vault task IAM role ARN"
  value       = module.vault_cluster.iam_role_arn
}

output "dynamodb_table" {
  description = "DynamoDB backend table name"
  value       = module.vault_cluster.dynamodb_table_name
}

# ==============================================================================
# Vault Secrets Outputs
# ==============================================================================
output "kv_mount_path" {
  description = "KV v2 mount path"
  value       = module.vault_secrets.kv_mount_path
}

output "aws_backend_path" {
  description = "AWS secrets engine path"
  value       = module.vault_secrets.aws_backend_path
}

output "database_backend_path" {
  description = "Database secrets engine path"
  value       = module.vault_secrets.database_backend_path
}

# ==============================================================================
# Kubernetes Integration Outputs
# ==============================================================================
output "k8s_auth_path" {
  description = "Vault Kubernetes auth path"
  value       = var.enable_k8s_integration ? module.k8s_integration[0].kubernetes_auth_path : ""
}

output "k8s_auth_roles" {
  description = "Kubernetes auth role mappings"
  value       = var.enable_k8s_integration ? module.k8s_integration[0].auth_roles : {}
}
