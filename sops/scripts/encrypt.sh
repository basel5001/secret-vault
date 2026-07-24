#!/usr/bin/env bash
set -euo pipefail

# Encrypt a secrets file using SOPS
# Usage: ./encrypt.sh <input-file> [output-file]

INPUT="${1:?Usage: $0 <input.yaml> [output.enc.yaml]}"
OUTPUT="${2:-${INPUT%.yaml}.enc.yaml}"

if ! command -v sops &>/dev/null; then
  echo "ERROR: sops not installed. Install from https://github.com/getsops/sops"
  exit 1
fi

echo "==> Encrypting ${INPUT} -> ${OUTPUT}"
sops --encrypt --config "$(dirname "$0")/../.sops.yaml" "${INPUT}" > "${OUTPUT}"
echo "==> Done. Encrypted file: ${OUTPUT}"
