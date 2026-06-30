ui = true
cluster_name = "xops-vault"

storage "dynamodb" {
  ha_enabled = "true"
  region     = "us-east-1"
  table      = "vault-storage"
}

seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "REPLACE_WITH_KMS_KEY_ID"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"  # TLS terminated at ALB
}

telemetry {
  prometheus_retention_time = "24h"
  disable_hostname          = true
}
