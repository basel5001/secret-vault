# Secret Vault

Self-hosted HashiCorp Vault deployment on AWS, fully managed as code with Terraform.

## Architecture

```
                    ┌──────────────────────────────────────────┐
                    │              AWS Account                  │
                    │                                          │
  Users/Apps ──────►│  ALB (TLS 1.3)                           │
                    │      │                                   │
                    │      ▼                                   │
                    │  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
                    │  │  Vault  │  │  Vault  │  │  Vault  │  │
                    │  │ (ECS)   │  │ (ECS)   │  │ (ECS)   │  │
                    │  └────┬────┘  └────┬────┘  └────┬────┘  │
                    │       │            │            │        │
                    │       ▼            ▼            ▼        │
                    │  ┌──────────────────────────────────┐    │
                    │  │     DynamoDB (HA Backend)         │    │
                    │  └──────────────────────────────────┘    │
                    │                                          │
                    │  ┌──────────┐  ┌───────────────────┐     │
                    │  │ AWS KMS  │  │ CloudWatch Logs   │     │
                    │  │(Unseal)  │  │ (Audit)           │     │
                    │  └──────────┘  └───────────────────┘     │
                    └──────────────────────────────────────────┘

  Kubernetes ──────► Vault CSI Provider ──► Vault K8s Auth ──► Secrets
```

## Features

- **ECS Fargate** deployment with auto-scaling
- **AWS KMS auto-unseal** -- no manual unseal keys
- **DynamoDB HA backend** with point-in-time recovery
- **Dynamic secrets** for AWS IAM and PostgreSQL
- **KV v2** secrets engine for static secrets
- **Kubernetes CSI** integration for pod secret injection
- **AppRole auth** for machine-to-machine authentication
- **Audit logging** to CloudWatch
- **Automated rotation** of root credentials
- **Snapshot backups** to S3 with KMS encryption

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.5.0
- Docker & Docker Compose (for local dev)
- Vault CLI (optional, for direct interaction)

## Quick Start

### Local Development

```bash
# Start Vault in dev mode
make dev

# Access UI at http://localhost:8200/ui (token: root)

# Stop
make dev-down
```

### Production Deployment

```bash
# Copy and fill in environment variables
cp .env.example .env
source .env

# Initialize Terraform
make init

# Review changes
make plan

# Deploy
make apply

# Initialize Vault (first time only)
make vault-init
```

## Secret Rotation

Dynamic secrets (AWS IAM, database credentials) are automatically rotated
via short-lived leases. To manually rotate root credentials:

```bash
make rotate
```

## Backups

Create a Vault snapshot and upload to S3:

```bash
make backup
```

## Kubernetes Integration

Enable K8s integration in your `terraform.tfvars`:

```hcl
enable_k8s_integration = true
k8s_cluster_name       = "production"
kubernetes_host        = "https://k8s-api.example.com"
k8s_app_namespaces     = ["app-a", "app-b", "app-c"]
```

Pods mount secrets via the CSI driver:

```yaml
volumes:
  - name: vault-secrets
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: vault-secrets
```

## Policies

| Policy       | Description                                         |
| ------------ | --------------------------------------------------- |
| `admin`      | Full access to all Vault paths                      |
| `readonly`   | Read-only access to KV secrets                      |
| `app-policy` | Namespace-scoped access for Kubernetes workloads     |
| `rotation`   | Permission to rotate root credentials               |

## Project Structure

```
secret-vault/
├── terraform/
│   ├── main.tf                    # Root module
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Outputs
│   ├── provider.tf                # Provider config
│   ├── backend.tf                 # S3 state backend
│   └── modules/
│       ├── vault-cluster/         # ECS + ALB + DynamoDB + KMS
│       ├── vault-secrets/         # Secrets engines + policies
│       └── k8s-integration/       # CSI + K8s auth
├── configs/
│   └── vault-config.hcl           # Vault server configuration
├── scripts/
│   ├── init-vault.sh              # Initialize & store keys
│   ├── rotate-secrets.sh          # Rotate dynamic secrets
│   └── backup-vault.sh            # Snapshot to S3
├── policies/
│   ├── admin.hcl                  # Admin policy
│   ├── readonly.hcl               # Read-only policy
│   └── app-policy.hcl             # App (K8s-scoped) policy
├── docker-compose.yml             # Local dev environment
├── Makefile                       # Common operations
└── .github/workflows/
    ├── ci.yml                     # Validate + tfsec + shellcheck
    └── security.yml               # Gitleaks secret scanning
```

## SOPS Integration

For GitOps-friendly encrypted secrets (secrets-in-git), see the [`sops/`](sops/) directory. SOPS allows you to commit encrypted secrets directly to Git using age or AWS KMS encryption, complementing Vault's dynamic secret capabilities.

```bash
# Encrypt a secrets file
./sops/scripts/encrypt.sh my-secrets.yaml

# Decrypt
./sops/scripts/decrypt.sh sops/examples/secrets.enc.yaml
```

See [`sops/README.md`](sops/README.md) for full documentation.

## License

[MIT](LICENSE)
