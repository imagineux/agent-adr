#!/usr/bin/env bash
set -euo pipefail

OUT_DIR=".agent-readiness-collection"
mkdir -p "$OUT_DIR"

echo "Collecting agentrc artifacts into $OUT_DIR"

npx github:microsoft/agentrc analyze --json > "$OUT_DIR/analyze.json"
npx github:microsoft/agentrc readiness --json > "$OUT_DIR/readiness.json"

if npx github:microsoft/agentrc instructions --dry-run > "$OUT_DIR/instructions.md" 2> "$OUT_DIR/instructions-error.log"; then
  echo "instructions generated successfully"
  rm -f "$OUT_DIR/instructions-error.log"
else
  echo "instructions generation failed; see $OUT_DIR/instructions-error.log"
fi

echo "Optional generators (best-effort):"
echo "  npx github:microsoft/agentrc generate mcp"
echo "  npx github:microsoft/agentrc generate vscode"

echo "Done. Consider adding notes to $OUT_DIR/notes.md and packaging artifacts:"
echo "  tar -czf agent-readiness-collection.tgz $OUT_DIR"
