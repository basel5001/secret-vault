provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "secret-vault"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}

provider "vault" {
  address = var.vault_token != "" ? module.vault_cluster.vault_endpoint : "http://127.0.0.1:8200"
  token   = var.vault_token

  skip_child_token = true
}

provider "helm" {
  kubernetes {
    host                   = var.kubernetes_host
    cluster_ca_certificate = var.kubernetes_ca_cert
    token                  = var.k8s_token_reviewer_jwt
  }
}

provider "kubernetes" {
  host                   = var.kubernetes_host
  cluster_ca_certificate = var.kubernetes_ca_cert
  token                  = var.k8s_token_reviewer_jwt
}
