#!/usr/bin/env bash
set -euo pipefail

OUT_DIR=".agent-readiness-collection"
mkdir -p "$OUT_DIR"

echo "Collecting agentrc artifacts into $OUT_DIR"

npx github:microsoft/agentrc analyze --json > "$OUT_DIR/analyze.json"
npx github:microsoft/agentrc readiness --json > "$OUT_DIR/readiness.json"

if npx github:microsoft/agentrc instructions --dry-run > "$OUT_DIR/instructions.md"; then
  echo "instructions collected"
else
  echo "instructions failed; capturing error"
  npx github:microsoft/agentrc instructions --dry-run > /dev/null 2> "$OUT_DIR/instructions-error.txt" || true
fi

echo "Optional generators (may write files directly):"
echo "  npx github:microsoft/agentrc generate mcp"
echo "  npx github:microsoft/agentrc generate vscode"

echo "Done. Package with: tar -czf agent-readiness-collection.tgz $OUT_DIR"
