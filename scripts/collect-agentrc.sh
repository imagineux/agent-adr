#!/usr/bin/env bash
set -uo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-repo-name [model]

Environment:
  AGENTRC_COPILOT_CLI_PATH   Optional explicit copilot CLI path override
  AGENTRC_MODEL              Optional model override (default: gpt-5-mini)
USAGE
}

json_escape() {
  local s="${1:-}"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

timestamp_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ"
}

write_status_json() {
  local file="$1" exit_code="$2" started_at="$3" ended_at="$4" command="$5"
  cat > "$file" <<JSON
{
  "started_at": "$(json_escape "$started_at")",
  "ended_at": "$(json_escape "$ended_at")",
  "exit_code": $exit_code,
  "command": "$(json_escape "$command")"
}
JSON
}

sha256_of_file() {
  local f="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    printf ''
  fi
}

run_command_capture() {
  local cmd="$1" stdout_file="$2" stderr_file="$3"
  local start end ec
  start="$(timestamp_now)"
  (eval "$cmd") >"$stdout_file" 2>"$stderr_file"
  ec=$?
  end="$(timestamp_now)"
  printf '%s|%s|%s' "$ec" "$start" "$end"
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -lt 2 ]]; then
  usage
  exit 1
fi

REPO_PATH="$1"
OUT_DIR="$2"
MODEL="${3:-${AGENTRC_MODEL:-gpt-5-mini}}"
COPILOT_OVERRIDE="${AGENTRC_COPILOT_CLI_PATH:-}"

if [[ ! -d "$REPO_PATH" ]]; then
  echo "Error: repo path does not exist: $REPO_PATH" >&2
  exit 2
fi

mkdir -p "$OUT_DIR" || { echo "Error: could not create output dir $OUT_DIR" >&2; exit 3; }

mkdir -p \
  "$OUT_DIR/metadata" \
  "$OUT_DIR/logs" \
  "$OUT_DIR/probes/flat-root" \
  "$OUT_DIR/probes/flat-areas" \
  "$OUT_DIR/probes/nested-root" \
  "$OUT_DIR/probes/nested-areas" \
  "$OUT_DIR/generated/flat-root" \
  "$OUT_DIR/generated/nested-root" \
  "$OUT_DIR/context" \
  "$OUT_DIR/prompts" \
  "$OUT_DIR/diagnostics"

export AGENTRC_DEBUG_COPILOT=1

RUN_TS="$(timestamp_now)"
HOSTNAME_VAL="$(hostname 2>/dev/null || true)"
UNAME_VAL="$(uname -a 2>/dev/null || true)"
NODE_VERSION="$(node --version 2>/dev/null || true)"
NPX_PATH="$(command -v npx 2>/dev/null || true)"
COPILOT_PATH="$(command -v copilot 2>/dev/null || true)"
GIT_SHA="$(git -C "$REPO_PATH" rev-parse HEAD 2>/dev/null || true)"
SHELL_NAME="${SHELL:-}"

cat > "$OUT_DIR/metadata/run.json" <<JSON
{
  "timestamp": "$(json_escape "$RUN_TS")",
  "repo_path": "$(json_escape "$REPO_PATH")",
  "git_sha": "$(json_escape "$GIT_SHA")",
  "model": "$(json_escape "$MODEL")",
  "agentrc_debug_copilot": "1",
  "copilot_override_path": "$(json_escape "$COPILOT_OVERRIDE")",
  "copilot_path_on_path": "$(json_escape "$COPILOT_PATH")"
}
JSON

cat > "$OUT_DIR/metadata/environment.json" <<JSON
{
  "hostname": "$(json_escape "$HOSTNAME_VAL")",
  "uname": "$(json_escape "$UNAME_VAL")",
  "shell": "$(json_escape "$SHELL_NAME")",
  "node_version": "$(json_escape "$NODE_VERSION")",
  "npx_path": "$(json_escape "$NPX_PATH")",
  "copilot_on_path": $([[ -n "$COPILOT_PATH" ]] && echo true || echo false),
  "runner": {
    "bash_version": "$(json_escape "${BASH_VERSION:-}")",
    "bun_version": "$(json_escape "$(bun --version 2>/dev/null || true)")"
  }
}
JSON

ANALYZE_CMD="cd \"$REPO_PATH\" && npx github:microsoft/agentrc analyze --json --output \"$OUT_DIR/analyze.json\""
READINESS_CMD="cd \"$REPO_PATH\" && npx github:microsoft/agentrc readiness --json --output \"$OUT_DIR/readiness.json\""

cat > "$OUT_DIR/metadata/commands.json" <<JSON
{
  "analyze": "$(json_escape "$ANALYZE_CMD")",
  "readiness": "$(json_escape "$READINESS_CMD")",
  "probes": [
    "npx github:microsoft/agentrc instructions --dry-run --json --model $MODEL",
    "npx github:microsoft/agentrc instructions --dry-run --json --areas --model $MODEL",
    "npx github:microsoft/agentrc instructions --dry-run --json --strategy nested --model $MODEL",
    "npx github:microsoft/agentrc instructions --dry-run --json --strategy nested --areas --model $MODEL"
  ],
  "generations": [
    "npx github:microsoft/agentrc instructions --output $OUT_DIR/generated/flat-root/copilot-instructions.generated.md --model $MODEL --force",
    "npx github:microsoft/agentrc instructions --strategy nested --output $OUT_DIR/generated/nested-root/AGENTS.generated.md --model $MODEL --force"
  ]
}
JSON

# analyze
analyze_result="$(run_command_capture "$ANALYZE_CMD" "$OUT_DIR/logs/analyze.stdout.log" "$OUT_DIR/logs/analyze.stderr.log")"
IFS='|' read -r analyze_ec analyze_start analyze_end <<< "$analyze_result"
write_status_json "$OUT_DIR/metadata/analyze-status.json" "$analyze_ec" "$analyze_start" "$analyze_end" "$ANALYZE_CMD"

# readiness
readiness_result="$(run_command_capture "$READINESS_CMD" "$OUT_DIR/logs/readiness.stdout.log" "$OUT_DIR/logs/readiness.stderr.log")"
IFS='|' read -r readiness_ec readiness_start readiness_end <<< "$readiness_result"
write_status_json "$OUT_DIR/metadata/readiness-status.json" "$readiness_ec" "$readiness_start" "$readiness_end" "$READINESS_CMD"

run_probe() {
  local name="$1" cmd="$2" dir="$OUT_DIR/probes/$name"
  local stdout_tmp="$dir/probe.stdout.tmp"
  local stderr_file="$dir/stderr.log"
  local result ec started ended
  result="$(run_command_capture "$cmd" "$stdout_tmp" "$stderr_file")"
  IFS='|' read -r ec started ended <<< "$result"

  local json_ok=false
  if node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));" "$stdout_tmp" >/dev/null 2>&1; then
    mv "$stdout_tmp" "$dir/probe.json"
    json_ok=true
  else
    mv "$stdout_tmp" "$dir/probe.stdout.log"
  fi

  cat > "$dir/status.json" <<JSON
{
  "probe": "$(json_escape "$name")",
  "command": "$(json_escape "$cmd")",
  "started_at": "$(json_escape "$started")",
  "ended_at": "$(json_escape "$ended")",
  "exit_code": $ec,
  "json_parse_succeeded": $json_ok
}
JSON
}

run_probe "flat-root" "cd \"$REPO_PATH\" && npx github:microsoft/agentrc instructions --dry-run --json --model \"$MODEL\""
run_probe "flat-areas" "cd \"$REPO_PATH\" && npx github:microsoft/agentrc instructions --dry-run --json --areas --model \"$MODEL\""
run_probe "nested-root" "cd \"$REPO_PATH\" && npx github:microsoft/agentrc instructions --dry-run --json --strategy nested --model \"$MODEL\""
run_probe "nested-areas" "cd \"$REPO_PATH\" && npx github:microsoft/agentrc instructions --dry-run --json --strategy nested --areas --model \"$MODEL\""

run_generation() {
  local name="$1" outfile="$2" cmd="$3" dir="$OUT_DIR/generated/$name"
  local res ec started ended
  res="$(run_command_capture "$cmd" "$dir/stdout.log" "$dir/stderr.log")"
  IFS='|' read -r ec started ended <<< "$res"

  local exists=false size=0 sha=""
  if [[ -f "$outfile" ]]; then
    exists=true
    size=$(wc -c < "$outfile" | tr -d ' ')
    sha="$(sha256_of_file "$outfile")"
  fi

  cat > "$dir/status.json" <<JSON
{
  "generation": "$(json_escape "$name")",
  "command": "$(json_escape "$cmd")",
  "started_at": "$(json_escape "$started")",
  "ended_at": "$(json_escape "$ended")",
  "exit_code": $ec,
  "output_exists": $exists,
  "output_file": "$(json_escape "$outfile")",
  "output_file_size": $size,
  "output_file_sha256": "$(json_escape "$sha")"
}
JSON
}

GEN1_OUT="$OUT_DIR/generated/flat-root/copilot-instructions.generated.md"
GEN1_CMD="cd \"$REPO_PATH\" && npx github:microsoft/agentrc instructions --output \"$GEN1_OUT\" --model \"$MODEL\" --force"
run_generation "flat-root" "$GEN1_OUT" "$GEN1_CMD"

GEN2_OUT="$OUT_DIR/generated/nested-root/AGENTS.generated.md"
GEN2_CMD="cd \"$REPO_PATH\" && npx github:microsoft/agentrc instructions --strategy nested --output \"$GEN2_OUT\" --model \"$MODEL\" --force"
run_generation "nested-root" "$GEN2_OUT" "$GEN2_CMD"

run_diag() {
  local name="$1" cmd="$2" dir="$OUT_DIR/diagnostics"
  local res ec started ended
  res="$(run_command_capture "$cmd" "$dir/$name.stdout.log" "$dir/$name.stderr.log")"
  IFS='|' read -r ec started ended <<< "$res"
  write_status_json "$dir/$name.status.json" "$ec" "$started" "$ended" "$cmd"
}

if [[ -n "$COPILOT_PATH" ]]; then
  run_diag "copilot-version" "$COPILOT_PATH --version"
  run_diag "copilot-help" "$COPILOT_PATH --help"
  run_diag "copilot-headless-version" "$COPILOT_PATH --headless --version"
else
  echo "copilot not on PATH" > "$OUT_DIR/diagnostics/copilot-not-found.txt"
fi

if [[ -n "$COPILOT_OVERRIDE" ]]; then
  run_diag "copilot-override-version" "\"$COPILOT_OVERRIDE\" --version"
  run_diag "copilot-override-headless-version" "\"$COPILOT_OVERRIDE\" --headless --version"
fi

copy_if_exists() {
  local src="$1" dst="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -R "$src" "$dst" 2>/dev/null || true
  fi
}

copy_if_exists "$REPO_PATH/README.md" "$OUT_DIR/context/README.md"
copy_if_exists "$REPO_PATH/package.json" "$OUT_DIR/context/package.json"
copy_if_exists "$REPO_PATH/bun.lockb" "$OUT_DIR/context/bun.lockb"
copy_if_exists "$REPO_PATH/bun.lock" "$OUT_DIR/context/bun.lock"
copy_if_exists "$REPO_PATH/package-lock.json" "$OUT_DIR/context/package-lock.json"
copy_if_exists "$REPO_PATH/pnpm-lock.yaml" "$OUT_DIR/context/pnpm-lock.yaml"
copy_if_exists "$REPO_PATH/yarn.lock" "$OUT_DIR/context/yarn.lock"
copy_if_exists "$REPO_PATH/tsconfig.json" "$OUT_DIR/context/tsconfig.json"
copy_if_exists "$REPO_PATH/.github/copilot-instructions.md" "$OUT_DIR/context/.github/copilot-instructions.md"
copy_if_exists "$REPO_PATH/AGENTS.md" "$OUT_DIR/context/AGENTS.md"
copy_if_exists "$REPO_PATH/CLAUDE.md" "$OUT_DIR/context/CLAUDE.md"
copy_if_exists "$REPO_PATH/.github/instructions" "$OUT_DIR/context/.github/instructions"
copy_if_exists "$REPO_PATH/CONTRIBUTING.md" "$OUT_DIR/context/CONTRIBUTING.md"
copy_if_exists "$REPO_PATH/CODEOWNERS" "$OUT_DIR/context/CODEOWNERS"
copy_if_exists "$REPO_PATH/SECURITY.md" "$OUT_DIR/context/SECURITY.md"
copy_if_exists "$REPO_PATH/docs/adr" "$OUT_DIR/context/docs/adr"
copy_if_exists "$REPO_PATH/docs/architecture" "$OUT_DIR/context/docs/architecture"

summarize_probe_line() {
  local name="$1" status="$OUT_DIR/probes/$name/status.json"
  local code json_ok
  code=$(node -e "const s=require('fs').readFileSync(process.argv[1],'utf8');console.log(JSON.parse(s).exit_code)" "$status" 2>/dev/null || echo "unknown")
  json_ok=$(node -e "const s=require('fs').readFileSync(process.argv[1],'utf8');console.log(JSON.parse(s).json_parse_succeeded)" "$status" 2>/dev/null || echo "unknown")
  echo "- $name: exit_code=$code json_parse_succeeded=$json_ok"
}

GEN_FLAT_STATUS="$OUT_DIR/generated/flat-root/status.json"
GEN_NESTED_STATUS="$OUT_DIR/generated/nested-root/status.json"

cat > "$OUT_DIR/collection-summary.json" <<JSON
{
  "repo_path": "$(json_escape "$REPO_PATH")",
  "output_dir": "$(json_escape "$OUT_DIR")",
  "model": "$(json_escape "$MODEL")",
  "analyze_exit_code": $analyze_ec,
  "readiness_exit_code": $readiness_ec,
  "copilot_on_path": $([[ -n "$COPILOT_PATH" ]] && echo true || echo false),
  "copilot_override_used": $([[ -n "$COPILOT_OVERRIDE" ]] && echo true || echo false),
  "flat_generated_exists": $(node -e "const f=require('fs');try{const s=JSON.parse(f.readFileSync(process.argv[1],'utf8'));console.log(s.output_exists?'true':'false')}catch{console.log('false')}" "$GEN_FLAT_STATUS"),
  "nested_generated_exists": $(node -e "const f=require('fs');try{const s=JSON.parse(f.readFileSync(process.argv[1],'utf8'));console.log(s.output_exists?'true':'false')}catch{console.log('false')}" "$GEN_NESTED_STATUS")
}
JSON

common_failures="$( (cat "$OUT_DIR"/probes/*/stderr.log "$OUT_DIR"/generated/*/stderr.log 2>/dev/null || true) | awk 'length($0)>0' | sort | uniq -c | sort -nr | head -n 10 )"

cat > "$OUT_DIR/instructions-overview.md" <<MD
# Instructions Overview

## Dry-run probes
$(summarize_probe_line "flat-root")
$(summarize_probe_line "flat-areas")
$(summarize_probe_line "nested-root")
$(summarize_probe_line "nested-areas")

## Real generation
- flat-root: $(cat "$GEN_FLAT_STATUS" 2>/dev/null || echo "missing status")
- nested-root: $(cat "$GEN_NESTED_STATUS" 2>/dev/null || echo "missing status")

## Copilot CLI
- found on PATH: $([[ -n "$COPILOT_PATH" ]] && echo "yes ($COPILOT_PATH)" || echo "no")
- override provided: $([[ -n "$COPILOT_OVERRIDE" ]] && echo "yes ($COPILOT_OVERRIDE)" || echo "no")

## Any generated instruction file present?
- $([[ -f "$GEN1_OUT" || -f "$GEN2_OUT" ]] && echo "yes" || echo "no")

## Common failure messages (top 10)
\`\`\`
$common_failures
\`\`\`
MD

cat > "$OUT_DIR/notes.md" <<MD
# Collection Notes

- Collection completed at: $(timestamp_now)
- Repository path: $REPO_PATH
- Output directory: $OUT_DIR
- Model used: $MODEL
- AGENTRC_DEBUG_COPILOT: 1
- Copilot override path: ${COPILOT_OVERRIDE:-<none>}
- Analyze exit code: $analyze_ec
- Readiness exit code: $readiness_ec

Review logs in:
- logs/
- probes/*/stderr.log
- generated/*/stderr.log
- diagnostics/
MD

echo "Collection complete: $OUT_DIR"
