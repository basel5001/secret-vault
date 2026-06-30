output "kubernetes_auth_path" {
  description = "Vault Kubernetes auth backend mount path"
  value       = vault_auth_backend.kubernetes.path
}

output "auth_roles" {
  description = "Map of namespace → Vault Kubernetes auth role name"
  value       = { for ns in var.app_namespaces : ns => "${ns}-role" }
}

output "service_accounts" {
  description = "Map of namespace → service account name"
  value       = { for ns, sa in kubernetes_service_account.vault_auth : ns => sa.metadata[0].name }
}

output "csi_release_name" {
  description = "Helm release name for the Vault CSI provider"
  value       = helm_release.vault_csi.name
}

output "csi_namespace" {
  description = "Namespace where the Vault CSI provider is installed"
  value       = helm_release.vault_csi.namespace
}
