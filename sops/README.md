# SOPS Integration

[Mozilla SOPS](https://github.com/getsops/sops) enables encrypted secrets to be stored directly in Git, providing a GitOps-friendly alternative to runtime secret fetching from Vault.

## When to Use SOPS vs Vault

| Use Case | Recommended |
|----------|-------------|
| Secrets needed at deploy-time (CI/CD) | SOPS |
| Dynamic/rotated secrets | Vault |
| Secrets in Git (encrypted) | SOPS |
| Per-app short-lived credentials | Vault |
| Disaster recovery of secrets | SOPS (in Git) |

## Setup

### 1. Install SOPS

```bash
# macOS
brew install sops

# Linux
curl -LO https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
chmod +x sops-v3.8.1.linux.amd64 && sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
```

### 2. Install age (encryption backend)

```bash
# macOS
brew install age

# Linux
apt install age
```

### 3. Generate a key

```bash
age-keygen -o key.txt
# Add the public key to .sops.yaml creation_rules
# Store key.txt securely (e.g., in Vault, or distribute to team)
```

### 4. Configure

Edit `.sops.yaml` to set your age public key or AWS KMS ARN.

## Usage

### Encrypt a file

```bash
./scripts/encrypt.sh my-secrets.yaml
# Creates my-secrets.enc.yaml
```

### Decrypt a file

```bash
./scripts/decrypt.sh examples/secrets.enc.yaml decrypted.yaml
```

### Edit in-place

```bash
SOPS_AGE_KEY_FILE=~/key.txt sops examples/secrets.enc.yaml
```

## CI/CD Integration

In GitHub Actions, store the age private key as a secret (`SOPS_AGE_KEY`) and:

```yaml
- name: Decrypt secrets
  env:
    SOPS_AGE_KEY: ${{ secrets.SOPS_AGE_KEY }}
  run: sops --decrypt sops/examples/secrets.enc.yaml > /tmp/secrets.yaml
```

## AWS KMS Support

To use AWS KMS instead of age, update `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: .*\.yaml$
    kms: arn:aws:kms:us-east-1:123456789012:key/your-key-id
```

No local key file needed -- IAM handles authentication.
