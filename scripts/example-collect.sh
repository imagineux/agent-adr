#!/usr/bin/env bash
set -euo pipefail

COLLECTION_DIR=".agent-readiness-collection"
mkdir -p "$COLLECTION_DIR"

echo "[1/4] analyze"
npx github:microsoft/agentrc analyze --json > "$COLLECTION_DIR/analyze.json"

echo "[2/4] readiness"
npx github:microsoft/agentrc readiness --json > "$COLLECTION_DIR/readiness.json"

echo "[3/4] instructions (best effort)"
if npx github:microsoft/agentrc instructions --dry-run > "$COLLECTION_DIR/instructions.md"; then
  echo "instructions captured"
else
  echo "instructions failed; writing stderr log"
  npx github:microsoft/agentrc instructions --dry-run > "$COLLECTION_DIR/instructions.md" 2> "$COLLECTION_DIR/instructions-error.log" || true
fi

echo "[4/4] optional metadata"
(git rev-parse --short HEAD > "$COLLECTION_DIR/commit.txt") || true
(git branch --show-current > "$COLLECTION_DIR/branch.txt") || true

echo "Done. Collected artifacts in $COLLECTION_DIR"
