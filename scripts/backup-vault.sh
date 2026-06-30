#!/usr/bin/env bash
# ==============================================================================
# backup-vault.sh – Create Vault snapshot and upload to S3
# ==============================================================================
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-https://vault.example.com}"
S3_BUCKET="${S3_BUCKET:-xops-vault-backups}"
AWS_REGION="${AWS_REGION:-us-east-1}"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-/tmp/vault-snapshots}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

export VAULT_ADDR

if [[ -z "${VAULT_TOKEN:-}" ]]; then
  echo "ERROR: VAULT_TOKEN is required." >&2
  exit 1
fi
export VAULT_TOKEN

TIMESTAMP=$(date -u '+%Y%m%d-%H%M%S')
SNAPSHOT_FILE="${SNAPSHOT_DIR}/vault-snapshot-${TIMESTAMP}.snap"

mkdir -p "${SNAPSHOT_DIR}"

echo "==> Creating Vault Raft snapshot..."
vault operator raft snapshot save "${SNAPSHOT_FILE}"

SNAPSHOT_SIZE=$(du -h "${SNAPSHOT_FILE}" | cut -f1)
echo "    Snapshot created: ${SNAPSHOT_FILE} (${SNAPSHOT_SIZE})"

echo "==> Uploading snapshot to s3://${S3_BUCKET}/snapshots/..."
aws s3 cp "${SNAPSHOT_FILE}" \
  "s3://${S3_BUCKET}/snapshots/vault-snapshot-${TIMESTAMP}.snap" \
  --region "${AWS_REGION}" \
  --sse aws:kms \
  --storage-class STANDARD_IA

echo "    Upload complete."

echo "==> Verifying upload..."
aws s3 ls "s3://${S3_BUCKET}/snapshots/vault-snapshot-${TIMESTAMP}.snap" \
  --region "${AWS_REGION}" >/dev/null 2>&1 && \
  echo "    Verification OK." || \
  { echo "ERROR: Upload verification failed!" >&2; exit 1; }

echo "==> Cleaning up local snapshot..."
rm -f "${SNAPSHOT_FILE}"

echo "==> Pruning snapshots older than ${RETENTION_DAYS} days from S3..."
CUTOFF_DATE=$(date -u -v-${RETENTION_DAYS}d '+%Y-%m-%d' 2>/dev/null || \
              date -u -d "${RETENTION_DAYS} days ago" '+%Y-%m-%d')

aws s3api list-objects-v2 \
  --bucket "${S3_BUCKET}" \
  --prefix "snapshots/" \
  --region "${AWS_REGION}" \
  --query "Contents[?LastModified<='${CUTOFF_DATE}'].Key" \
  --output text | tr '\t' '\n' | while read -r key; do
    if [[ -n "${key}" && "${key}" != "None" ]]; then
      echo "    Deleting old snapshot: ${key}"
      aws s3 rm "s3://${S3_BUCKET}/${key}" --region "${AWS_REGION}"
    fi
  done

echo "==> Backup complete."
