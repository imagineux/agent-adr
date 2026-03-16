#!/usr/bin/env bash
set -euo pipefail

CLIENT_REPO="${1:-/path/to/client/repo}"
COLLECTION_DIR="${2:-./collections/client-repo-name}"
MODEL="${3:-gpt-5-mini}"

./scripts/collect-agentrc.sh "$CLIENT_REPO" "$COLLECTION_DIR" "$MODEL"
node ./scripts/build-strong-model-prompt.mjs --collection "$COLLECTION_DIR" --out "$COLLECTION_DIR/prompts"

echo "Done. Review:"
echo "  $COLLECTION_DIR/collection-summary.json"
echo "  $COLLECTION_DIR/instructions-overview.md"
echo "  $COLLECTION_DIR/prompts/adr-synthesis-prompt.md"
echo "  $COLLECTION_DIR/prompts/adr-review-prompt.md"
