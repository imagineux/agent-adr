#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: ./scripts/example-run.sh /path/to/client/repo ./collections/client-repo-name"
  exit 1
fi

REPO="$1"
OUT="$2"

./scripts/collect-agentrc.sh "$REPO" "$OUT"
node scripts/build-strong-model-prompt.mjs --collection "$OUT" --out "$OUT/prompts"

echo "Done. Review bundle at: $OUT"
