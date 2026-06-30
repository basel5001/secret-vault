################################################################################
# Vault ↔ Kubernetes Integration (CSI, Auth, SecretProviderClass)
################################################################################

terraform {
  required_providers {
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
# Vault CSI Provider (Helm)
# ------------------------------------------------------------------------------
resource "helm_release" "vault_csi" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = var.vault_namespace
  create_namespace = true
  version          = var.vault_helm_version

  set {
    name  = "global.externalVaultAddr"
    value = var.vault_address
  }

  set {
    name  = "injector.enabled"
    value = "true"
  }

  set {
    name  = "injector.externalVaultAddr"
    value = var.vault_address
  }

  set {
    name  = "csi.enabled"
    value = "true"
  }

  set {
    name  = "server.enabled"
    value = "false"
  }

  set {
    name  = "csi.agent.image.tag"
    value = var.vault_version
  }
}

# ------------------------------------------------------------------------------
# Kubernetes Auth Method in Vault
# ------------------------------------------------------------------------------
resource "vault_auth_backend" "kubernetes" {
  type        = "kubernetes"
  path        = "kubernetes"
  description = "Kubernetes authentication for ${var.cluster_name}"
}

resource "vault_kubernetes_auth_backend_config" "config" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = var.kubernetes_host
  kubernetes_ca_cert = var.kubernetes_ca_cert
  token_reviewer_jwt = var.token_reviewer_jwt
  issuer             = var.token_issuer
}

# ------------------------------------------------------------------------------
# Kubernetes Auth Roles (one per namespace)
# ------------------------------------------------------------------------------
resource "vault_kubernetes_auth_backend_role" "app" {
  for_each = toset(var.app_namespaces)

  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "${each.key}-role"
  bound_service_account_names      = [var.service_account_name]
  bound_service_account_namespaces = [each.key]
  token_policies                   = ["default", "app-policy"]
  token_ttl                        = var.token_ttl
  token_max_ttl                    = var.token_max_ttl
  audience                         = "vault"
}

# ------------------------------------------------------------------------------
# Kubernetes Service Account (per namespace)
# ------------------------------------------------------------------------------
resource "kubernetes_service_account" "vault_auth" {
  for_each = toset(var.app_namespaces)

  metadata {
    name      = var.service_account_name
    namespace = each.key

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "vault-integration"
    }
  }
}

# ------------------------------------------------------------------------------
# SecretProviderClass (per namespace)
# ------------------------------------------------------------------------------
resource "kubernetes_manifest" "secret_provider_class" {
  for_each = toset(var.app_namespaces)

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = "vault-secrets"
      namespace = each.key
    }

    spec = {
      provider = "vault"

      parameters = {
        vaultAddress = var.vault_address
        roleName     = "${each.key}-role"
        objects = yamlencode([
          {
            objectName = "db-password"
            secretPath = "secret/data/${each.key}/database"
            secretKey  = "password"
          },
          {
            objectName = "api-key"
            secretPath = "secret/data/${each.key}/api"
            secretKey  = "key"
          }
        ])
      }

      secretObjects = [
        {
          secretName = "vault-secrets"
          type       = "Opaque"
          data = [
            { objectName = "db-password", key = "db-password" },
            { objectName = "api-key", key = "api-key" }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.vault_csi]
}

# ------------------------------------------------------------------------------
# ClusterRoleBinding – Vault token reviewer
# ------------------------------------------------------------------------------
resource "kubernetes_cluster_role_binding" "vault_tokenreview" {
  metadata {
    name = "vault-tokenreview-binding"

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "vault"
    namespace = var.vault_namespace
  }
}
