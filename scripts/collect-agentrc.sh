#!/usr/bin/env bash
set -u

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-repo-name [model]

Defaults:
  model = gpt-5-mini
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -lt 2 ]; then
  usage
  exit 1
fi

REPO_PATH="$1"
OUT_ROOT="$2"
MODEL="${3:-gpt-5-mini}"

if [ ! -d "$REPO_PATH" ]; then
  echo "ERROR: repo path does not exist: $REPO_PATH" >&2
  exit 1
fi
mkdir -p "$OUT_ROOT" || { echo "ERROR: cannot create output directory: $OUT_ROOT" >&2; exit 1; }

OUT="$(cd "$OUT_ROOT" && pwd)"
TS_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HOSTNAME_VAL="$(hostname 2>/dev/null || true)"
UNAME_VAL="$(uname -a 2>/dev/null || true)"
NODE_VERSION="$(node --version 2>/dev/null || true)"
NPX_PATH="$(command -v npx 2>/dev/null || true)"
COPILOT_PATH="$(command -v copilot 2>/dev/null || true)"
COPILOT_OVERRIDE="${AGENTRC_COPILOT_CLI_PATH:-}"
SHELL_NAME="${SHELL:-}"

mkdir -p \
  "$OUT/metadata" "$OUT/logs" \
  "$OUT/probes/flat-root" "$OUT/probes/flat-areas" "$OUT/probes/nested-root" "$OUT/probes/nested-areas" \
  "$OUT/generated/flat-root" "$OUT/generated/nested-root" \
  "$OUT/context" "$OUT/prompts"

json_escape() { printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }
write_json_file() { printf '%s\n' "$2" > "$1"; }

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}';
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}';
  else echo ""; fi
}

capture_cmd() {
  local name="$1" cmd="$2" stdout_file="$3" stderr_file="$4" status_file="$5"
  local start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)" exit_code end_ts
  (
    cd "$REPO_PATH" || exit 1
    export AGENTRC_DEBUG_COPILOT=1
    [ -n "$COPILOT_OVERRIDE" ] && export AGENTRC_COPILOT_CLI_PATH="$COPILOT_OVERRIDE"
    bash -lc "$cmd" >"$stdout_file" 2>"$stderr_file"
  )
  exit_code=$?
  end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  write_json_file "$status_file" "{\n  \"name\": $(json_escape "$name"),\n  \"command\": $(json_escape "$cmd"),\n  \"start\": $(json_escape "$start_ts"),\n  \"end\": $(json_escape "$end_ts"),\n  \"exitCode\": $exit_code\n}"
  return 0
}

capture_probe() {
  local probe_name="$1" cmd="$2" probe_dir="$OUT/probes/$probe_name"
  local raw="$probe_dir/probe.raw.stdout.log" json_file="$probe_dir/probe.json" out_log="$probe_dir/probe.stdout.log"
  local err="$probe_dir/stderr.log" status="$probe_dir/status.json"
  local start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)" exit_code end_ts json_ok
  (
    cd "$REPO_PATH" || exit 1
    export AGENTRC_DEBUG_COPILOT=1
    [ -n "$COPILOT_OVERRIDE" ] && export AGENTRC_COPILOT_CLI_PATH="$COPILOT_OVERRIDE"
    bash -lc "$cmd" >"$raw" 2>"$err"
  )
  exit_code=$?
  end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if python3 -m json.tool "$raw" > "$json_file" 2>/dev/null; then
    json_ok=true
    rm -f "$raw" "$out_log"
  else
    json_ok=false
    mv "$raw" "$out_log"
    rm -f "$json_file"
  fi
  write_json_file "$status" "{\n  \"probe\": $(json_escape "$probe_name"),\n  \"command\": $(json_escape "$cmd"),\n  \"start\": $(json_escape "$start_ts"),\n  \"end\": $(json_escape "$end_ts"),\n  \"exitCode\": $exit_code,\n  \"jsonParseSucceeded\": $json_ok\n}"
  return 0
}

capture_generation() {
  local name="$1" cmd="$2" out_file="$3" dir="$4"
  local stdout_file="$dir/stdout.log" stderr_file="$dir/stderr.log" status_file="$dir/status.json"
  local start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)" exit_code end_ts exists size sha
  (
    cd "$REPO_PATH" || exit 1
    export AGENTRC_DEBUG_COPILOT=1
    [ -n "$COPILOT_OVERRIDE" ] && export AGENTRC_COPILOT_CLI_PATH="$COPILOT_OVERRIDE"
    bash -lc "$cmd" >"$stdout_file" 2>"$stderr_file"
  )
  exit_code=$?
  end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [ -f "$out_file" ]; then exists=true; size="$(wc -c < "$out_file" | tr -d ' ')"; sha="$(sha256_file "$out_file")";
  else exists=false; size=0; sha=""; fi
  write_json_file "$status_file" "{\n  \"name\": $(json_escape "$name"),\n  \"command\": $(json_escape "$cmd"),\n  \"start\": $(json_escape "$start_ts"),\n  \"end\": $(json_escape "$end_ts"),\n  \"exitCode\": $exit_code,\n  \"outputPath\": $(json_escape "$out_file"),\n  \"outputExists\": $exists,\n  \"outputFileSize\": $size,\n  \"outputSha256\": $(json_escape "$sha")\n}"
  return 0
}

capture_diag_cmd() {
  local name="$1" cmd="$2" safe
  safe="$(printf '%s' "$name" | tr ' /' '__')"
  capture_cmd "diag:$name" "$cmd" "$OUT/logs/diag-${safe}.stdout.log" "$OUT/logs/diag-${safe}.stderr.log" "$OUT/metadata/diag-${safe}.status.json"
}

probe_exit_code() {
  [ -f "$1" ] && python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("exitCode",1))' "$1" 2>/dev/null || echo 1
}
status_bool() { [ "$1" = "0" ] && echo true || echo false; }

copy_if_exists() {
  local src="$1" dest="$2"
  if [ -e "$REPO_PATH/$src" ]; then
    mkdir -p "$(dirname "$OUT/context/$dest")"
    cp -R "$REPO_PATH/$src" "$OUT/context/$dest" 2>/dev/null || true
  fi
}

export AGENTRC_DEBUG_COPILOT=1
[ -n "$COPILOT_OVERRIDE" ] && export AGENTRC_COPILOT_CLI_PATH="$COPILOT_OVERRIDE"

GIT_SHA=""
command -v git >/dev/null 2>&1 && GIT_SHA="$(git -C "$REPO_PATH" rev-parse HEAD 2>/dev/null || true)"

ANALYZE_CMD="npx github:microsoft/agentrc analyze --json --output \"$OUT/analyze.json\""
READINESS_CMD="npx github:microsoft/agentrc readiness --json --output \"$OUT/readiness.json\""
P_FLAT_ROOT="npx github:microsoft/agentrc instructions --dry-run --json --model \"$MODEL\""
P_FLAT_AREAS="npx github:microsoft/agentrc instructions --dry-run --json --areas --model \"$MODEL\""
P_NESTED_ROOT="npx github:microsoft/agentrc instructions --dry-run --json --strategy nested --model \"$MODEL\""
P_NESTED_AREAS="npx github:microsoft/agentrc instructions --dry-run --json --strategy nested --areas --model \"$MODEL\""
G_FLAT="npx github:microsoft/agentrc instructions --output \"$OUT/generated/flat-root/copilot-instructions.generated.md\" --model \"$MODEL\" --force"
G_NESTED="npx github:microsoft/agentrc instructions --strategy nested --output \"$OUT/generated/nested-root/AGENTS.generated.md\" --model \"$MODEL\" --force"

write_json_file "$OUT/metadata/run.json" "{\n  \"repoPath\": $(json_escape "$(cd "$REPO_PATH" && pwd)"),\n  \"repoGitSha\": $(json_escape "$GIT_SHA"),\n  \"outputPath\": $(json_escape "$OUT"),\n  \"timestamp\": $(json_escape "$TS_UTC"),\n  \"model\": $(json_escape "$MODEL")\n}"

write_json_file "$OUT/metadata/environment.json" "{\n  \"timestamp\": $(json_escape "$TS_UTC"),\n  \"hostname\": $(json_escape "$HOSTNAME_VAL"),\n  \"uname\": $(json_escape "$UNAME_VAL"),\n  \"shell\": $(json_escape "$SHELL_NAME"),\n  \"runner\": \"bash\",\n  \"nodeVersion\": $(json_escape "$NODE_VERSION"),\n  \"npxPath\": $(json_escape "$NPX_PATH"),\n  \"copilotOnPath\": $([ -n "$COPILOT_PATH" ] && echo true || echo false),\n  \"copilotPath\": $(json_escape "$COPILOT_PATH"),\n  \"agentrcCopilotOverridePath\": $(json_escape "$COPILOT_OVERRIDE"),\n  \"agentrcDebugCopilot\": true\n}"

write_json_file "$OUT/metadata/commands.json" "{\n  \"usesNpxGithubMicrosoftAgentrc\": true,\n  \"analyze\": $(json_escape "$ANALYZE_CMD"),\n  \"readiness\": $(json_escape "$READINESS_CMD"),\n  \"probes\": [$(json_escape "$P_FLAT_ROOT"), $(json_escape "$P_FLAT_AREAS"), $(json_escape "$P_NESTED_ROOT"), $(json_escape "$P_NESTED_AREAS")],\n  \"generations\": [$(json_escape "$G_FLAT"), $(json_escape "$G_NESTED")]\n}"

capture_cmd "analyze" "$ANALYZE_CMD" "$OUT/logs/analyze.stdout.log" "$OUT/logs/analyze.stderr.log" "$OUT/metadata/analyze-status.json"
capture_cmd "readiness" "$READINESS_CMD" "$OUT/logs/readiness.stdout.log" "$OUT/logs/readiness.stderr.log" "$OUT/metadata/readiness-status.json"

capture_probe "flat-root" "$P_FLAT_ROOT"
capture_probe "flat-areas" "$P_FLAT_AREAS"
capture_probe "nested-root" "$P_NESTED_ROOT"
capture_probe "nested-areas" "$P_NESTED_AREAS"

capture_generation "flat-root" "$G_FLAT" "$OUT/generated/flat-root/copilot-instructions.generated.md" "$OUT/generated/flat-root"
capture_generation "nested-root" "$G_NESTED" "$OUT/generated/nested-root/AGENTS.generated.md" "$OUT/generated/nested-root"

capture_diag_cmd "copilot-version" "copilot --version"
capture_diag_cmd "copilot-help" "copilot --help"
[ -n "$COPILOT_OVERRIDE" ] && capture_diag_cmd "override-version" "\"$COPILOT_OVERRIDE\" --version"
[ -n "$COPILOT_OVERRIDE" ] && capture_diag_cmd "override-headless-version" "\"$COPILOT_OVERRIDE\" --headless --version"
[ -n "$COPILOT_PATH" ] && capture_diag_cmd "copilot-headless-version" "\"$COPILOT_PATH\" --headless --version"

copy_if_exists "README.md" "README.md"
copy_if_exists "package.json" "package.json"
copy_if_exists "bun.lockb" "bun.lockb"
copy_if_exists "bun.lock" "bun.lock"
copy_if_exists "package-lock.json" "package-lock.json"
copy_if_exists "pnpm-lock.yaml" "pnpm-lock.yaml"
copy_if_exists "yarn.lock" "yarn.lock"
copy_if_exists "tsconfig.json" "tsconfig.json"
copy_if_exists ".github/copilot-instructions.md" ".github/copilot-instructions.md"
copy_if_exists "AGENTS.md" "AGENTS.md"
copy_if_exists "CLAUDE.md" "CLAUDE.md"
copy_if_exists ".github/instructions" ".github/instructions"
copy_if_exists "CONTRIBUTING.md" "CONTRIBUTING.md"
copy_if_exists "CODEOWNERS" "CODEOWNERS"
copy_if_exists "SECURITY.md" "SECURITY.md"
copy_if_exists "docs/adr" "docs/adr"
copy_if_exists "docs/architecture" "docs/architecture"

FR_CODE="$(probe_exit_code "$OUT/probes/flat-root/status.json")"
FA_CODE="$(probe_exit_code "$OUT/probes/flat-areas/status.json")"
NR_CODE="$(probe_exit_code "$OUT/probes/nested-root/status.json")"
NA_CODE="$(probe_exit_code "$OUT/probes/nested-areas/status.json")"
GF_CODE="$(probe_exit_code "$OUT/generated/flat-root/status.json")"
GN_CODE="$(probe_exit_code "$OUT/generated/nested-root/status.json")"

ANY_GEN=false
[ -f "$OUT/generated/flat-root/copilot-instructions.generated.md" ] && ANY_GEN=true
[ -f "$OUT/generated/nested-root/AGENTS.generated.md" ] && ANY_GEN=true

write_json_file "$OUT/collection-summary.json" "{\n  \"timestamp\": $(json_escape "$(date -u +%Y-%m-%dT%H:%M:%SZ)"),\n  \"repoPath\": $(json_escape "$(cd "$REPO_PATH" && pwd)"),\n  \"model\": $(json_escape "$MODEL"),\n  \"copilotOnPath\": $([ -n "$COPILOT_PATH" ] && echo true || echo false),\n  \"copilotPath\": $(json_escape "$COPILOT_PATH"),\n  \"copilotOverridePath\": $(json_escape "$COPILOT_OVERRIDE"),\n  \"dryRun\": {\n    \"flatRoot\": {\"exitCode\": $FR_CODE, \"success\": $(status_bool "$FR_CODE")},\n    \"flatAreas\": {\"exitCode\": $FA_CODE, \"success\": $(status_bool "$FA_CODE")},\n    \"nestedRoot\": {\"exitCode\": $NR_CODE, \"success\": $(status_bool "$NR_CODE")},\n    \"nestedAreas\": {\"exitCode\": $NA_CODE, \"success\": $(status_bool "$NA_CODE")}\n  },\n  \"generation\": {\n    \"flatRoot\": {\"exitCode\": $GF_CODE, \"success\": $(status_bool "$GF_CODE"), \"outputExists\": $([ -f "$OUT/generated/flat-root/copilot-instructions.generated.md" ] && echo true || echo false)},\n    \"nestedRoot\": {\"exitCode\": $GN_CODE, \"success\": $(status_bool "$GN_CODE"), \"outputExists\": $([ -f "$OUT/generated/nested-root/AGENTS.generated.md" ] && echo true || echo false)}\n  },\n  \"anyGeneratedOutput\": $ANY_GEN\n}"

ERR_SNIPPETS="$(find "$OUT" -type f \( -name 'stderr.log' -o -name '*.stderr.log' \) -print 2>/dev/null | xargs -r cat 2>/dev/null | sed 's/^[[:space:]]*//' | sed '/^$/d' | sort | uniq -c | sort -nr | head -n 12 || true)"

cat > "$OUT/instructions-overview.md" <<OVERVIEW
# Instructions Collection Overview

## Model and CLI context
- Model override used: $MODEL
- Copilot CLI found on PATH: $([ -n "$COPILOT_PATH" ] && echo "yes ($COPILOT_PATH)" || echo "no")
- AGENTRC_COPILOT_CLI_PATH override used: $([ -n "$COPILOT_OVERRIDE" ] && echo "yes ($COPILOT_OVERRIDE)" || echo "no")

## Dry-run probes
- flat-root: exit $FR_CODE
- flat-areas: exit $FA_CODE
- nested-root: exit $NR_CODE
- nested-areas: exit $NA_CODE

## Real generation attempts
- flat-root: exit $GF_CODE, output exists: $([ -f "$OUT/generated/flat-root/copilot-instructions.generated.md" ] && echo yes || echo no)
- nested-root: exit $GN_CODE, output exists: $([ -f "$OUT/generated/nested-root/AGENTS.generated.md" ] && echo yes || echo no)

## Common failure messages (best-effort)
\`\`\`
$ERR_SNIPPETS
\`\`\`

## Any generated instruction file exists
- $ANY_GEN
OVERVIEW

cat > "$OUT/notes.md" <<'NOTES'
# Notes

- Collection is best-effort and continues across failures.
- Dry-run probes still exercise generation flow and are treated as probes, not no-op checks.
- Readiness/analyze failures are retained in metadata and logs.
- Generation failures preserve stderr, stdout, exit codes, and output file checks.
NOTES

echo "Collection completed: $OUT"
