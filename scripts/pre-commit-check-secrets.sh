#!/usr/bin/env bash
#
# Pre-commit hook: scan staged diff for common secret patterns.
# This catches cases where sensitive data is added to new or unexpected files.
#

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

SECRET_PATTERNS=(
  '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'
  'client-certificate-data:\s*[A-Za-z0-9+/=]{20,}'
  'client-key-data:\s*[A-Za-z0-9+/=]{20,}'
  'certificate-authority-data:\s*[A-Za-z0-9+/=]{20,}'
  'token:\s*[a-z0-9]{6}\.[a-z0-9]{16}'
  'secretboxEncryptionSecret:\s*[A-Za-z0-9+/=]{20,}'
  'TS_AUTHKEY[=:]\s*tskey-'
)

staged_diff=$(git diff --cached --diff-filter=ACMR -U0)

if [ -z "$staged_diff" ]; then
  exit 0
fi

ERRORS=0

for pattern in "${SECRET_PATTERNS[@]}"; do
  matches=$(echo "$staged_diff" | grep -En "^\+" | grep -Ev "^\d+:\+\+\+" | grep -Ei -- "$pattern" || true)
  if [ -n "$matches" ]; then
    echo -e "${RED}BLOCKED${NC} Potential secret detected matching pattern:"
    echo "         ${YELLOW}${pattern}${NC}"
    echo "$matches" | head -5 | while IFS= read -r line; do
      truncated=$(echo "$line" | cut -c1-120)
      echo "         $truncated"
    done
    ERRORS=$((ERRORS + 1))
  fi
done

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
