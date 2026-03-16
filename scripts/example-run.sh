#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 /path/to/client/repo ./collections/client-repo-name"
  exit 1
fi

REPO="$1"
OUT="$2"

./scripts/collect-agentrc.sh "$REPO" "$OUT"

node scripts/build-adr-prompt.mjs \
  --collection "$OUT" \
  --template templates/kimi-k2_5-adr-synthesis-template.md \
  --out "$OUT/adr-synthesis-prompt.md"

echo "Done. Prompt file: $OUT/adr-synthesis-prompt.md"
