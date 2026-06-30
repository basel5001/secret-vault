# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| latest  | Yes       |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it
responsibly:

1. **Do NOT open a public GitHub issue.**
2. Email: security@example.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will acknowledge your report within **48 hours** and provide a detailed
response within **5 business days**.

## Security Measures

This project implements the following security controls:

- **Auto-Unseal**: Vault uses AWS KMS for auto-unseal, eliminating manual
  unseal key management.
- **Audit Logging**: All Vault operations are logged to CloudWatch for
  forensic analysis.
- **Dynamic Secrets**: AWS IAM and database credentials are generated
  on-demand with short TTLs.
- **Namespace Isolation**: Kubernetes workloads can only access secrets
  within their own namespace.
- **Encryption at Rest**: DynamoDB storage backend uses KMS encryption.
- **Encryption in Transit**: TLS termination at ALB with TLS 1.3.
- **Secret Scanning**: CI pipeline includes gitleaks to prevent credential
  leaks in commits.
- **Infrastructure Scanning**: tfsec scans Terraform code for
  misconfigurations.

## Secret Rotation

All dynamic secrets are rotated automatically via short-lived leases. Root
credentials for the AWS and database secrets engines can be rotated with:

```bash
make rotate
```
