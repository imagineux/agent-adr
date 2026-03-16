#!/usr/bin/env bash
set -uo pipefail

# Hardened collection wrapper around microsoft/agentrc
# - External collection bundle (outside client repo)
# - Artifact collection with optional low-tier generation
# - Four dry-run probes + two real generation attempts
# - Diagnostics capture
# - Outputs for adr-synthesis-prompt.md and adr-review-prompt.md

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

# Validate and canonicalize paths before any real work
REPO_PATH_INPUT="$1"
OUT_ROOT_INPUT="$2"
MODEL="${3:-gpt-5-mini}"

# --- Path validation and canonicalization ---
# Resolve REPO_PATH to absolute path
if [ ! -d "$REPO_PATH_INPUT" ]; then
  echo "ERROR: repo path does not exist: $REPO_PATH_INPUT" >&2
  exit 1
fi
REPO_PATH="$(cd "$REPO_PATH_INPUT" && pwd)"

# Resolve OUT_ROOT to absolute path
mkdir -p "$OUT_ROOT_INPUT" || { echo "ERROR: cannot create output directory: $OUT_ROOT_INPUT" >&2; exit 1; }
OUT="$(cd "$OUT_ROOT_INPUT" && pwd)"

# --- Repo boundary safety guard ---
# Ensure output root is NOT inside the client repo (prevent accidental repo contamination)
is_path_inside() {
  local child="$1"
  local parent="$2"
  # Normalize both paths to ensure they end with / for prefix matching
  local child_normalized="${child%/}/"
  local parent_normalized="${parent%/}/"
  case "$child_normalized" in
    "$parent_normalized"*) return 0 ;;
    *) return 1 ;;
  esac
}

if is_path_inside "$OUT" "$REPO_PATH"; then
  echo "ERROR: output root is inside the client repo. This is disallowed to prevent repo contamination." >&2
  echo "  Repo: $REPO_PATH" >&2
  echo "  Output: $OUT" >&2
  exit 1
fi
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

# --- Helper functions ---
json_escape() { printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }
write_json_file() { printf '%s\n' "$2" > "$1"; }

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}';
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}';
  else echo ""; fi
}

# Run a command in the repo directory with proper env, capturing outputs
# Usage: run_in_repo <stdout_file> <stderr_file> <command> [args...]
# Returns: exit code from command
run_in_repo() {
  local stdout_file="$1"
  local stderr_file="$2"
  shift 2
  (
    cd "$REPO_PATH" || exit 1
    export AGENTRC_DEBUG_COPILOT=1
    [ -n "$COPILOT_OVERRIDE" ] && export AGENTRC_COPILOT_CLI_PATH="$COPILOT_OVERRIDE"
    "$@" > "$stdout_file" 2> "$stderr_file"
  )
  return $?
}

# Render a command to string for logging/metadata (argv -> string)
# Uses printf %q for safe shell-quoting of each argument
cmd_to_string() {
  local out=""
  for arg in "$@"; do
    out="$out $(printf '%q' "$arg")"
  done
  echo "${out# }"
}

capture_cmd() {
  local name="$1"
  shift
  local stdout_file="$1"
  local stderr_file="$2"
  local status_file="$3"
  shift 3

  local start_ts exit_code end_ts
  start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  run_in_repo "$stdout_file" "$stderr_file" "$@"
  exit_code=$?

  end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local cmd_str
  cmd_str="$(cmd_to_string "$@")"
  write_json_file "$status_file" "{
  \"name\": $(json_escape "$name"),
  \"command\": $(json_escape "$cmd_str"),
  \"start\": $(json_escape "$start_ts"),
  \"end\": $(json_escape "$end_ts"),
  \"exitCode\": $exit_code
}"
  return 0
}

capture_probe() {
  local probe_name="$1"
  shift
  local probe_dir="$OUT/probes/$probe_name"
  local raw="$probe_dir/probe.raw.stdout.log"
  local json_file="$probe_dir/probe.json"
  local out_log="$probe_dir/probe.stdout.log"
  local err="$probe_dir/stderr.log"
  local status="$probe_dir/status.json"

  local start_ts exit_code end_ts json_ok
  start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  run_in_repo "$raw" "$err" "$@"
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
  local cmd_str
  cmd_str="$(cmd_to_string "$@")"
  write_json_file "$status" "{
  \"probe\": $(json_escape "$probe_name"),
  \"command\": $(json_escape "$cmd_str"),
  \"start\": $(json_escape "$start_ts"),
  \"end\": $(json_escape "$end_ts"),
  \"exitCode\": $exit_code,
  \"jsonParseSucceeded\": $json_ok
}"
  return 0
}

capture_generation() {
  local name="$1"
  shift
  local out_file="$1"
  local dir="$2"
  shift 2
  local stdout_file="$dir/stdout.log"
  local stderr_file="$dir/stderr.log"
  local status_file="$dir/status.json"

  local start_ts exit_code end_ts exists size sha
  start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  run_in_repo "$stdout_file" "$stderr_file" "$@"
  exit_code=$?

  end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [ -f "$out_file" ]; then
    exists=true
    size="$(wc -c < "$out_file" | tr -d ' ')"
    sha="$(sha256_file "$out_file")"
  else
    exists=false
    size=0
    sha=""
  fi
  local cmd_str
  cmd_str="$(cmd_to_string "$@")"
  write_json_file "$status_file" "{
  \"name\": $(json_escape "$name"),
  \"command\": $(json_escape "$cmd_str"),
  \"start\": $(json_escape "$start_ts"),
  \"end\": $(json_escape "$end_ts"),
  \"exitCode\": $exit_code,
  \"outputPath\": $(json_escape "$out_file"),
  \"outputExists\": $exists,
  \"outputFileSize\": $size,
  \"outputSha256\": $(json_escape "$sha")
}"
  return 0
}

capture_diag_cmd() {
  local name="$1"
  shift
  local safe
  safe="$(printf '%s' "$name" | tr ' /' '__')"
  capture_cmd "diag:$name" "$OUT/logs/diag-${safe}.stdout.log" "$OUT/logs/diag-${safe}.stderr.log" "$OUT/metadata/diag-${safe}.status.json" "$@"
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

# --- Build command arrays (argv-based, safe for special characters) ---
# Note: agentrc command via npx
cmd_analyze=(npx github:microsoft/agentrc analyze --json --output "$OUT/analyze.json")
cmd_readiness=(npx github:microsoft/agentrc readiness --json --output "$OUT/readiness.json")
cmd_probe_flat_root=(npx github:microsoft/agentrc instructions --dry-run --json --model "$MODEL")
cmd_probe_flat_areas=(npx github:microsoft/agentrc instructions --dry-run --json --areas --model "$MODEL")
cmd_probe_nested_root=(npx github:microsoft/agentrc instructions --dry-run --json --strategy nested --model "$MODEL")
cmd_probe_nested_areas=(npx github:microsoft/agentrc instructions --dry-run --json --strategy nested --areas --model "$MODEL")
cmd_gen_flat=(npx github:microsoft/agentrc instructions --output "$OUT/generated/flat-root/copilot-instructions.generated.md" --model "$MODEL" --force)
cmd_gen_nested=(npx github:microsoft/agentrc instructions --strategy nested --output "$OUT/generated/nested-root/AGENTS.generated.md" --model "$MODEL" --force)

write_json_file "$OUT/metadata/run.json" "{
  \"repoPath\": $(json_escape "$REPO_PATH"),
  \"repoGitSha\": $(json_escape "$GIT_SHA"),
  \"outputPath\": $(json_escape "$OUT"),
  \"timestamp\": $(json_escape "$TS_UTC"),
  \"model\": $(json_escape "$MODEL")
}"

write_json_file "$OUT/metadata/environment.json" "{
  \"timestamp\": $(json_escape "$TS_UTC"),
  \"hostname\": $(json_escape "$HOSTNAME_VAL"),
  \"uname\": $(json_escape "$UNAME_VAL"),
  \"shell\": $(json_escape "$SHELL_NAME"),
  \"runner\": \"bash\",
  \"nodeVersion\": $(json_escape "$NODE_VERSION"),
  \"npxPath\": $(json_escape "$NPX_PATH"),
  \"copilotOnPath\": $([ -n "$COPILOT_PATH" ] && echo true || echo false),
  \"copilotPath\": $(json_escape "$COPILOT_PATH"),
  \"agentrcCopilotOverridePath\": $(json_escape "$COPILOT_OVERRIDE"),
  \"agentrcDebugCopilot\": true
}"

# Render commands for metadata (as strings)
ANALYZE_CMD_STR="$(cmd_to_string "${cmd_analyze[@]}")"
READINESS_CMD_STR="$(cmd_to_string "${cmd_readiness[@]}")"
P_FLAT_ROOT_STR="$(cmd_to_string "${cmd_probe_flat_root[@]}")"
P_FLAT_AREAS_STR="$(cmd_to_string "${cmd_probe_flat_areas[@]}")"
P_NESTED_ROOT_STR="$(cmd_to_string "${cmd_probe_nested_root[@]}")"
P_NESTED_AREAS_STR="$(cmd_to_string "${cmd_probe_nested_areas[@]}")"
G_FLAT_STR="$(cmd_to_string "${cmd_gen_flat[@]}")"
G_NESTED_STR="$(cmd_to_string "${cmd_gen_nested[@]}")"

write_json_file "$OUT/metadata/commands.json" "{
  \"usesNpxGithubMicrosoftAgentrc\": true,
  \"analyze\": $(json_escape "$ANALYZE_CMD_STR"),
  \"readiness\": $(json_escape "$READINESS_CMD_STR"),
  \"probes\": [$(json_escape "$P_FLAT_ROOT_STR"), $(json_escape "$P_FLAT_AREAS_STR"), $(json_escape "$P_NESTED_ROOT_STR"), $(json_escape "$P_NESTED_AREAS_STR")],
  \"generations\": [$(json_escape "$G_FLAT_STR"), $(json_escape "$G_NESTED_STR")]
}"

# --- Execute collection (best-effort, continues on failure) ---
# Track overall success - any critical failure causes exit 1
OVERALL_SUCCESS=true

# Required analyze/readiness: still capture status/log even on failure
capture_cmd "analyze" "$OUT/logs/analyze.stdout.log" "$OUT/logs/analyze.stderr.log" "$OUT/metadata/analyze-status.json" "${cmd_analyze[@]}" || { OVERALL_SUCCESS=false; true; }
capture_cmd "readiness" "$OUT/logs/readiness.stdout.log" "$OUT/logs/readiness.stderr.log" "$OUT/metadata/readiness-status.json" "${cmd_readiness[@]}" || { OVERALL_SUCCESS=false; true; }

# Probes: continue on failure, track if any failed
capture_probe "flat-root" "${cmd_probe_flat_root[@]}" || { OVERALL_SUCCESS=false; true; }
capture_probe "flat-areas" "${cmd_probe_flat_areas[@]}" || { OVERALL_SUCCESS=false; true; }
capture_probe "nested-root" "${cmd_probe_nested_root[@]}" || { OVERALL_SUCCESS=false; true; }
capture_probe "nested-areas" "${cmd_probe_nested_areas[@]}" || { OVERALL_SUCCESS=false; true; }

# Real generations: continue on failure, track output existence
capture_generation "flat-root" "$OUT/generated/flat-root/copilot-instructions.generated.md" "$OUT/generated/flat-root" "${cmd_gen_flat[@]}" || { OVERALL_SUCCESS=false; true; }
capture_generation "nested-root" "$OUT/generated/nested-root/AGENTS.generated.md" "$OUT/generated/nested-root" "${cmd_gen_nested[@]}" || { OVERALL_SUCCESS=false; true; }

capture_diag_cmd "copilot-version" copilot --version || true
capture_diag_cmd "copilot-help" copilot --help || true
[ -n "$COPILOT_OVERRIDE" ] && capture_diag_cmd "override-version" "$COPILOT_OVERRIDE" --version || true
[ -n "$COPILOT_OVERRIDE" ] && capture_diag_cmd "override-headless-version" "$COPILOT_OVERRIDE" --headless --version || true
[ -n "$COPILOT_PATH" ] && capture_diag_cmd "copilot-headless-version" "$COPILOT_PATH" --headless --version || true

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
copy_if_exists "docs/" "docs/"

FR_CODE="$(probe_exit_code "$OUT/probes/flat-root/status.json")"
FA_CODE="$(probe_exit_code "$OUT/probes/flat-areas/status.json")"
NR_CODE="$(probe_exit_code "$OUT/probes/nested-root/status.json")"
NA_CODE="$(probe_exit_code "$OUT/probes/nested-areas/status.json")"
GF_CODE="$(probe_exit_code "$OUT/generated/flat-root/status.json")"
GN_CODE="$(probe_exit_code "$OUT/generated/nested-root/status.json")"

ANY_GEN=false
[ -f "$OUT/generated/flat-root/copilot-instructions.generated.md" ] && ANY_GEN=true
[ -f "$OUT/generated/nested-root/AGENTS.generated.md" ] && ANY_GEN=true

write_json_file "$OUT/collection-summary.json" "{
  \"timestamp\": $(json_escape "$(date -u +%Y-%m-%dT%H:%M:%SZ)"),
  \"repoPath\": $(json_escape "$REPO_PATH"),
  \"model\": $(json_escape "$MODEL"),
  \"copilotOnPath\": $([ -n "$COPILOT_PATH" ] && echo true || echo false),
  \"copilotPath\": $(json_escape "$COPILOT_PATH"),
  \"copilotOverridePath\": $(json_escape "$COPILOT_OVERRIDE"),
  \"dryRun\": {
    \"flatRoot\": {\"exitCode\": $FR_CODE, \"success\": $(status_bool "$FR_CODE")},
    \"flatAreas\": {\"exitCode\": $FA_CODE, \"success\": $(status_bool "$FA_CODE")},
    \"nestedRoot\": {\"exitCode\": $NR_CODE, \"success\": $(status_bool "$NR_CODE")},
    \"nestedAreas\": {\"exitCode\": $NA_CODE, \"success\": $(status_bool "$NA_CODE")}
  },
  \"generation\": {
    \"flatRoot\": {\"exitCode\": $GF_CODE, \"success\": $(status_bool "$GF_CODE"), \"outputExists\": $([ -f "$OUT/generated/flat-root/copilot-instructions.generated.md" ] && echo true || echo false)},
    \"nestedRoot\": {\"exitCode\": $GN_CODE, \"success\": $(status_bool "$GN_CODE"), \"outputExists\": $([ -f "$OUT/generated/nested-root/AGENTS.generated.md" ] && echo true || echo false)}
  },
  \"anyGeneratedOutput\": $ANY_GEN
}"

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
- Missing files are explicitly marked as MISSING in synthesized prompts.
- Repo boundary guard prevents accidental writes into the client repo.
- Commands are executed via argv arrays, not string eval, for shell-safety.
NOTES

if [ "$OVERALL_SUCCESS" = true ]; then
  echo "Collection completed successfully: $OUT"
  exit 0
else
  echo "Collection completed with failures: $OUT" >&2
  exit 1
fi
