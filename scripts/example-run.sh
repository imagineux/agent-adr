#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  cat <<'USAGE'
Usage:
  ./scripts/example-run.sh /path/to/client/repo client-repo-name
USAGE
  exit 1
fi

CLIENT_REPO="$1"
NAME="$2"
OUT_DIR="./collections/$NAME"

./scripts/collect-agentrc.sh "$CLIENT_REPO" "$OUT_DIR"

node ./scripts/build-adr-prompt.mjs \
  --collection "$OUT_DIR" \
  --template ./templates/kimi-k2_5-adr-synthesis-template.md \
  --out "$OUT_DIR/adr-synthesis-prompt.md"

echo "Done. Prompt file: $OUT_DIR/adr-synthesis-prompt.md"
