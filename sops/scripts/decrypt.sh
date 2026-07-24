#!/usr/bin/env bash
set -euo pipefail

# Decrypt a SOPS-encrypted secrets file
# Usage: ./decrypt.sh <encrypted-file> [output-file]

INPUT="${1:?Usage: $0 <secrets.enc.yaml> [output.yaml]}"
OUTPUT="${2:-/dev/stdout}"

if ! command -v sops &>/dev/null; then
  echo "ERROR: sops not installed. Install from https://github.com/getsops/sops"
  exit 1
fi

echo "==> Decrypting ${INPUT}" >&2
sops --decrypt "${INPUT}" > "${OUTPUT}"

if [ "${OUTPUT}" != "/dev/stdout" ]; then
  echo "==> Done. Decrypted file: ${OUTPUT}" >&2
fi
