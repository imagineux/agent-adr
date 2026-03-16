#!/usr/bin/env bash
set -euo pipefail

COLLECT_DIR=".agent-readiness-collection"
mkdir -p "$COLLECT_DIR"

echo "Collecting analyze.json..."
npx github:microsoft/agentrc analyze --json > "$COLLECT_DIR/analyze.json"

echo "Collecting readiness.json..."
npx github:microsoft/agentrc readiness --json > "$COLLECT_DIR/readiness.json"

echo "Collecting instructions.md (best effort)..."
if npx github:microsoft/agentrc instructions --dry-run > "$COLLECT_DIR/instructions.md"; then
  echo "instructions collected"
else
  echo "instructions command failed; saving note"
  {
    echo "# instructions command failed"
    echo "Captured at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Please run manually and paste stderr/stdout here."
  } > "$COLLECT_DIR/instructions-error.md"
fi

echo "Done. Artifacts in $COLLECT_DIR"
