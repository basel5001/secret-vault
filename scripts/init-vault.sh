#!/usr/bin/env bash
# ==============================================================================
# init-vault.sh – Initialize Vault, store recovery keys in Secrets Manager
# ==============================================================================
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-https://vault.example.com}"
AWS_REGION="${AWS_REGION:-us-east-1}"
SECRET_PREFIX="${SECRET_PREFIX:-vault}"
RECOVERY_SHARES="${RECOVERY_SHARES:-5}"
RECOVERY_THRESHOLD="${RECOVERY_THRESHOLD:-3}"

export VAULT_ADDR

echo "==> Checking Vault status at ${VAULT_ADDR}..."
STATUS=$(vault status -format=json 2>/dev/null || true)

if echo "${STATUS}" | jq -e '.initialized == true' >/dev/null 2>&1; then
  echo "==> Vault is already initialized."
  exit 0
fi

echo "==> Initializing Vault with ${RECOVERY_SHARES} recovery shares (threshold: ${RECOVERY_THRESHOLD})..."
INIT_OUTPUT=$(vault operator init \
  -format=json \
  -recovery-shares="${RECOVERY_SHARES}" \
  -recovery-threshold="${RECOVERY_THRESHOLD}")

ROOT_TOKEN=$(echo "${INIT_OUTPUT}" | jq -r '.root_token')
RECOVERY_KEYS=$(echo "${INIT_OUTPUT}" | jq -r '.recovery_keys_b64 | join(",")')

echo "==> Storing root token in AWS Secrets Manager..."
aws secretsmanager create-secret \
  --name "${SECRET_PREFIX}/root-token" \
  --description "Vault root token" \
  --secret-string "${ROOT_TOKEN}" \
  --region "${AWS_REGION}" \
  --tags "Key=Project,Value=secret-vault" "Key=ManagedBy,Value=script" \
  2>/dev/null || \
aws secretsmanager put-secret-value \
  --secret-id "${SECRET_PREFIX}/root-token" \
  --secret-string "${ROOT_TOKEN}" \
  --region "${AWS_REGION}"

echo "==> Storing recovery keys in AWS Secrets Manager..."
aws secretsmanager create-secret \
  --name "${SECRET_PREFIX}/recovery-keys" \
  --description "Vault recovery keys (base64)" \
  --secret-string "${RECOVERY_KEYS}" \
  --region "${AWS_REGION}" \
  --tags "Key=Project,Value=secret-vault" "Key=ManagedBy,Value=script" \
  2>/dev/null || \
aws secretsmanager put-secret-value \
  --secret-id "${SECRET_PREFIX}/recovery-keys" \
  --secret-string "${RECOVERY_KEYS}" \
  --region "${AWS_REGION}"

echo "==> Authenticating with root token..."
export VAULT_TOKEN="${ROOT_TOKEN}"

echo "==> Enabling audit log (file → stdout)..."
vault audit enable file file_path=stdout log_raw=false 2>/dev/null || \
  echo "    Audit device already enabled."

echo "==> Enabling audit log (file → /vault/logs/audit.log)..."
vault audit enable -path=file-audit file file_path=/vault/logs/audit.log 2>/dev/null || \
  echo "    File audit device already enabled."

echo "==> Writing policies..."
for policy_file in policies/*.hcl; do
  policy_name=$(basename "${policy_file}" .hcl)
  vault policy write "${policy_name}" "${policy_file}"
  echo "    Policy '${policy_name}' written."
done

echo "==> Vault initialization complete."
echo "    Root token and recovery keys are stored in AWS Secrets Manager."
echo "    IMPORTANT: Revoke the root token after initial setup:"
echo "    vault token revoke \${ROOT_TOKEN}"
