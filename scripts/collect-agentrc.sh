#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 /path/to/client/repo ./collections/client-repo-name
USAGE
}

json_escape() {
  local s="${1//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

REPO_INPUT="$1"
OUT="$2"
REPO="$(cd "$REPO_INPUT" 2>/dev/null && pwd || true)"

if [[ -z "$REPO" || ! -d "$REPO" ]]; then
  echo "[error] Invalid repo path: $REPO_INPUT" >&2
  exit 1
fi

mkdir -p "$OUT/logs" "$OUT/context"

timestamp_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
repo_sha=""
if git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  repo_sha="$(git -C "$REPO" rev-parse HEAD 2>/dev/null || true)"
fi

analyze_cmd="npx github:microsoft/agentrc analyze --repo \"$REPO\" --json --output \"$OUT/analyze.json\""
readiness_cmd="npx github:microsoft/agentrc readiness --repo \"$REPO\" --json --output \"$OUT/readiness.json\""
instructions_cmd="npx github:microsoft/agentrc instructions --repo \"$REPO\" --output \"$OUT/copilot-instructions.generated.md\" --force"

cat > "$OUT/collection-metadata.json" <<JSON
{
  "repoPath": "$(json_escape "$REPO")",
  "gitSha": "$(json_escape "$repo_sha")",
  "collectedAtUtc": "$(json_escape "$timestamp_utc")",
  "commands": {
    "analyze": "$(json_escape "$analyze_cmd")",
    "readiness": "$(json_escape "$readiness_cmd")",
    "instructions": "$(json_escape "$instructions_cmd")"
  }
}
JSON

echo "[info] Running analyze..."
(eval "$analyze_cmd")

echo "[info] Running readiness..."
(eval "$readiness_cmd")

echo "[info] Running instructions (best-effort)..."
set +e
(eval "$instructions_cmd") >"$OUT/logs/instructions.stdout.log" 2>"$OUT/logs/instructions.stderr.log"
instructions_exit=$?
set -e

instructions_output="$OUT/copilot-instructions.generated.md"
instructions_output_exists=false
instructions_output_nonempty=false
if [[ -f "$instructions_output" ]]; then
  instructions_output_exists=true
  if [[ -s "$instructions_output" ]]; then
    instructions_output_nonempty=true
  fi
fi

instructions_success=false
if [[ "$instructions_exit" -eq 0 && "$instructions_output_nonempty" == true ]]; then
  instructions_success=true
fi

cat > "$OUT/instructions-status.json" <<JSON
{
  "attempted": true,
  "command": "$(json_escape "$instructions_cmd")",
  "exitCode": $instructions_exit,
  "success": $instructions_success,
  "outputFile": "copilot-instructions.generated.md",
  "outputExists": $instructions_output_exists,
  "outputNonEmpty": $instructions_output_nonempty,
  "stdoutLog": "logs/instructions.stdout.log",
  "stderrLog": "logs/instructions.stderr.log"
}
JSON

copy_if_exists() {
  local rel="$1"
  local src="$REPO/$rel"
  local dst="$OUT/context/$rel"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -R "$src" "$dst"
    echo "[info] Copied context: $rel"
  else
    echo "[info] Context missing (skipped): $rel"
  fi
}

copy_if_exists "README.md"
copy_if_exists "package.json"
copy_if_exists "bun.lockb"
copy_if_exists "bun.lock"
copy_if_exists "package-lock.json"
copy_if_exists "pnpm-lock.yaml"
copy_if_exists "yarn.lock"
copy_if_exists ".github/copilot-instructions.md"
copy_if_exists "AGENTS.md"
copy_if_exists "CLAUDE.md"
copy_if_exists ".github/instructions"
copy_if_exists "CONTRIBUTING.md"
copy_if_exists "CODEOWNERS"
copy_if_exists "SECURITY.md"

analyze_ok=false
readiness_ok=false
[[ -s "$OUT/analyze.json" ]] && analyze_ok=true
[[ -s "$OUT/readiness.json" ]] && readiness_ok=true

cat > "$OUT/collection-summary.json" <<JSON
{
  "repoPath": "$(json_escape "$REPO")",
  "gitSha": "$(json_escape "$repo_sha")",
  "collectedAtUtc": "$(json_escape "$timestamp_utc")",
  "requiredArtifacts": {
    "analyzeJson": $analyze_ok,
    "readinessJson": $readiness_ok
  },
  "instructions": {
    "success": $instructions_success,
    "exitCode": $instructions_exit,
    "outputExists": $instructions_output_exists,
    "outputNonEmpty": $instructions_output_nonempty
  }
}
JSON

cat > "$OUT/notes.md" <<'MD'
# Evaluator Notes

Use this file for manual observations, constraints, and context not captured by automation.
MD

if [[ "$instructions_success" == true ]]; then
  echo "[info] Collection complete. Instructions generated successfully."
else
  echo "[warn] Collection complete. Instructions generation failed or returned empty output. See logs and instructions-status.json."
fi

echo "[info] Output directory: $OUT"
