#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-repo-name
USAGE
}

log() {
  printf '[collect-agentrc] %s\n' "$*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' is not available." >&2
    exit 1
  fi
}

json_escape() {
  node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

REPO="$(cd "$1" 2>/dev/null && pwd || true)"
OUT="$2"

if [[ -z "$REPO" || ! -d "$REPO" ]]; then
  echo "Error: repo path '$1' does not exist or is not accessible." >&2
  exit 1
fi

if [[ ! -d "$REPO/.git" ]]; then
  log "Warning: '$REPO' is not a git repository (no .git directory)."
fi

require_cmd npx
require_cmd node

mkdir -p "$OUT" "$OUT/logs" "$OUT/context"

TIMESTAMP="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
GIT_SHA=""
if git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_SHA="$(git -C "$REPO" rev-parse HEAD 2>/dev/null || true)"
fi

ANALYZE_CMD="npx github:microsoft/agentrc analyze --repo \"$REPO\" --json --output \"$OUT/analyze.json\""
READINESS_CMD="npx github:microsoft/agentrc readiness --repo \"$REPO\" --json --output \"$OUT/readiness.json\""
INSTRUCTIONS_CMD="npx github:microsoft/agentrc instructions --repo \"$REPO\" --output \"$OUT/copilot-instructions.generated.md\" --force"

META_PATH="$OUT/collection-metadata.json"
cat > "$META_PATH" <<EOF_META
{
  "repoPath": $(json_escape "$REPO"),
  "gitSha": $(json_escape "$GIT_SHA"),
  "collectedAtUtc": $(json_escape "$TIMESTAMP"),
  "commands": {
    "analyze": $(json_escape "$ANALYZE_CMD"),
    "readiness": $(json_escape "$READINESS_CMD"),
    "instructions": $(json_escape "$INSTRUCTIONS_CMD")
  }
}
EOF_META

log "Running analyze..."
(eval "$ANALYZE_CMD")

log "Running readiness..."
(eval "$READINESS_CMD")

log "Running optional instructions generation..."
INSTR_STDOUT="$OUT/logs/instructions.stdout.log"
INSTR_STDERR="$OUT/logs/instructions.stderr.log"
set +e
(eval "$INSTRUCTIONS_CMD") >"$INSTR_STDOUT" 2>"$INSTR_STDERR"
INSTR_EXIT=$?
set -e

INSTR_FILE="$OUT/copilot-instructions.generated.md"
if [[ -s "$INSTR_FILE" ]]; then
  INSTR_HAS_CONTENT=true
else
  INSTR_HAS_CONTENT=false
fi
if [[ -e "$INSTR_FILE" ]]; then
  INSTR_EXISTS=true
else
  INSTR_EXISTS=false
fi

if [[ "$INSTR_EXIT" -eq 0 ]]; then
  INSTR_STATUS="success"
else
  INSTR_STATUS="failed"
  log "Instructions generation failed with exit code $INSTR_EXIT (continuing)."
fi

cat > "$OUT/instructions-status.json" <<EOF_INSTR
{
  "status": $(json_escape "$INSTR_STATUS"),
  "exitCode": $INSTR_EXIT,
  "outputFile": $(json_escape "$INSTR_FILE"),
  "outputFileExists": $INSTR_EXISTS,
  "outputFileNonEmpty": $INSTR_HAS_CONTENT,
  "stdoutLog": $(json_escape "logs/instructions.stdout.log"),
  "stderrLog": $(json_escape "logs/instructions.stderr.log")
}
EOF_INSTR

copy_if_exists() {
  local src="$1"
  local dest_rel="$2"
  local src_path="$REPO/$src"
  local dest_path="$OUT/context/$dest_rel"

  if [[ -e "$src_path" ]]; then
    mkdir -p "$(dirname "$dest_path")"
    cp -R "$src_path" "$dest_path"
    log "Copied context: $src"
  fi
}

log "Copying optional context files (best effort)..."
copy_if_exists "README.md" "README.md"
copy_if_exists "package.json" "package.json"
copy_if_exists "bun.lockb" "bun.lockb"
copy_if_exists "bun.lock" "bun.lock"
copy_if_exists "package-lock.json" "package-lock.json"
copy_if_exists "pnpm-lock.yaml" "pnpm-lock.yaml"
copy_if_exists "yarn.lock" "yarn.lock"
copy_if_exists ".github/copilot-instructions.md" ".github/copilot-instructions.md"
copy_if_exists "AGENTS.md" "AGENTS.md"
copy_if_exists "CLAUDE.md" "CLAUDE.md"
copy_if_exists ".github/instructions" ".github/instructions"
copy_if_exists "CONTRIBUTING.md" "CONTRIBUTING.md"
copy_if_exists "CODEOWNERS" "CODEOWNERS"
copy_if_exists "SECURITY.md" "SECURITY.md"

CONTEXT_FILE_COUNT="$(find "$OUT/context" -type f | wc -l | awk '{print $1}')"

cat > "$OUT/collection-summary.json" <<EOF_SUMMARY
{
  "repoPath": $(json_escape "$REPO"),
  "gitSha": $(json_escape "$GIT_SHA"),
  "collectedAtUtc": $(json_escape "$TIMESTAMP"),
  "requiredArtifacts": {
    "analyze": "analyze.json",
    "readiness": "readiness.json"
  },
  "optionalArtifacts": {
    "instructionsMarkdown": "copilot-instructions.generated.md",
    "instructionsStatus": "instructions-status.json",
    "contextDir": "context",
    "notes": "notes.md"
  },
  "instructions": {
    "status": $(json_escape "$INSTR_STATUS"),
    "exitCode": $INSTR_EXIT,
    "outputFileExists": $INSTR_EXISTS,
    "outputFileNonEmpty": $INSTR_HAS_CONTENT
  },
  "contextFilesCopied": $CONTEXT_FILE_COUNT
}
EOF_SUMMARY

if [[ ! -e "$OUT/notes.md" ]]; then
  cat > "$OUT/notes.md" <<'EOF_NOTES'
# Evaluator Notes

Use this file for manual observations during review.

- Repository intent:
- Architecture observations:
- Constraints and blockers:
- Risk notes:
- Follow-up questions:
EOF_NOTES
fi

log "Collection complete. Output directory: $OUT"
