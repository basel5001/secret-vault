#!/usr/bin/env bash
# ==============================================================================
# rotate-secrets.sh – Rotate dynamic secrets (AWS IAM, DB credentials)
# ==============================================================================
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-https://vault.example.com}"
export VAULT_ADDR

if [[ -z "${VAULT_TOKEN:-}" ]]; then
  echo "ERROR: VAULT_TOKEN is required." >&2
  exit 1
fi
export VAULT_TOKEN

echo "============================================================"
echo " Secret Rotation – $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "============================================================"

# --------------------------------------------------------------------------
# 1. Rotate AWS secrets engine root credentials
# --------------------------------------------------------------------------
echo ""
echo "==> Rotating AWS secrets engine root credentials..."
if vault read aws/config/root >/dev/null 2>&1; then
  vault write -f aws/config/rotate-root
  echo "    AWS root credentials rotated."
else
  echo "    AWS secrets engine not configured – skipping."
fi

# --------------------------------------------------------------------------
# 2. Rotate database root credentials
# --------------------------------------------------------------------------
echo ""
echo "==> Rotating database root credentials..."
if vault read database/config/postgresql >/dev/null 2>&1; then
  vault write -f database/rotate-root/postgresql
  echo "    PostgreSQL root credentials rotated."
else
  echo "    Database secrets engine not configured – skipping."
fi

# --------------------------------------------------------------------------
# 3. Revoke all leases for AWS and Database
# --------------------------------------------------------------------------
echo ""
echo "==> Revoking existing AWS leases..."
vault lease revoke -prefix aws/creds/ 2>/dev/null && \
  echo "    AWS leases revoked." || \
  echo "    No active AWS leases to revoke."

echo ""
echo "==> Revoking existing database leases..."
vault lease revoke -prefix database/creds/ 2>/dev/null && \
  echo "    Database leases revoked." || \
  echo "    No active database leases to revoke."

# --------------------------------------------------------------------------
# 4. Verify
# --------------------------------------------------------------------------
echo ""
echo "==> Current lease counts:"
echo "    AWS:      $(vault list -format=json sys/leases/lookup/aws/creds/ 2>/dev/null | jq -r 'length // 0' || echo 0)"
echo "    Database: $(vault list -format=json sys/leases/lookup/database/creds/ 2>/dev/null | jq -r 'length // 0' || echo 0)"

echo ""
echo "==> Rotation complete."
