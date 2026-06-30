output "kv_mount_path" {
  description = "Path of the KV v2 secrets engine"
  value       = vault_mount.kv.path
}

output "aws_backend_path" {
  description = "Path of the AWS secrets engine"
  value       = vault_aws_secret_backend.aws.path
}

output "database_backend_path" {
  description = "Path of the database secrets engine"
  value       = vault_mount.database.path
}

output "approle_path" {
  description = "Path of the AppRole auth method"
  value       = vault_auth_backend.approle.path
}

output "policy_names" {
  description = "List of created Vault policy names"
  value = [
    vault_policy.admin.name,
    vault_policy.readonly.name,
    vault_policy.app.name,
    vault_policy.rotation.name,
  ]
}

output "aws_developer_role" {
  description = "AWS secrets engine developer role name"
  value       = vault_aws_secret_backend_role.developer.name
}

output "aws_readonly_role" {
  description = "AWS secrets engine readonly role name"
  value       = vault_aws_secret_backend_role.readonly.name
}

output "db_app_role" {
  description = "Database secrets engine app role name"
  value       = vault_database_secret_backend_role.app.name
}

output "db_readonly_role" {
  description = "Database secrets engine readonly role name"
  value       = vault_database_secret_backend_role.readonly.name
}
