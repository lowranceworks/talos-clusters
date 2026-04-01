#!/usr/bin/env bash
#
# Pre-commit hook: verify that .enc.yaml / .enc files contain SOPS metadata.
# If the metadata is missing, the file may have been overwritten with plaintext.
#

set -euo pipefail

RED='\033[0;31m'
NC='\033[0m'

ERRORS=0

for file in "$@"; do
  case "$file" in
    *.enc.yaml|*.enc)
      if ! git show ":${file}" 2>/dev/null | grep -q "sops:"; then
        echo -e "${RED}BLOCKED${NC} Encrypted file missing SOPS metadata: ${file}"
        echo "         This file may contain unencrypted secrets."
        echo "         Re-encrypt with: sops --encrypt <source> > ${file}"
        ERRORS=$((ERRORS + 1))
      fi
      ;;
  esac
done

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
