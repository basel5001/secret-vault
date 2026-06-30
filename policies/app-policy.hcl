# Application policy – namespace-scoped access via Kubernetes identity
# Allows each service to read only secrets in its own namespace

# KV secrets scoped to the service's Kubernetes namespace
path "secret/data/{{identity.entity.aliases.auth_kubernetes_*.metadata.service_account_namespace}}/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/{{identity.entity.aliases.auth_kubernetes_*.metadata.service_account_namespace}}/*" {
  capabilities = ["read", "list"]
}

# AWS dynamic credentials scoped to namespace-specific role
path "aws/creds/{{identity.entity.aliases.auth_kubernetes_*.metadata.service_account_namespace}}-role" {
  capabilities = ["read"]
}

# Database dynamic credentials scoped to namespace-specific role
path "database/creds/{{identity.entity.aliases.auth_kubernetes_*.metadata.service_account_namespace}}-role" {
  capabilities = ["read"]
}

# Allow token self-lookup and renewal
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "sys/capabilities-self" {
  capabilities = ["read"]
}
