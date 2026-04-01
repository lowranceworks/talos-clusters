#!/usr/bin/env bash
#
# Pre-commit hook: block decrypted sensitive files from being committed.
# These are the plaintext counterparts of SOPS-encrypted files.
#

set -euo pipefail

RED='\033[0;31m'
NC='\033[0m'

FORBIDDEN_FILENAMES=(
  controlplane.yaml
  worker.yaml
  secrets.yaml
  kubeconfig
  talosconfig
  tailscale.patch.yaml
)

staged_files=$(git diff --cached --name-only --diff-filter=ACMR)

if [ -z "$staged_files" ]; then
  exit 0
fi

ERRORS=0

for file in $staged_files; do
  basename=$(basename "$file")
  for forbidden in "${FORBIDDEN_FILENAMES[@]}"; do
    if [ "$basename" = "$forbidden" ]; then
      echo -e "${RED}BLOCKED${NC} Decrypted file staged: ${file}"
      echo "         Run 'task encrypt:all' before committing."
      ERRORS=$((ERRORS + 1))
    fi
  done
done

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
