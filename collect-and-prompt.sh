#!/usr/bin/env bash
set -uo pipefail

# Unified agent-adr collector: bash collection + Node.js prompt building + clipboard transfer
# - External collection bundle (outside client repo)
# - Artifact collection with optional low-tier generation
# - Four dry-run probes + two real generation attempts
# - In-memory prompt building with template replacement
# - Direct clipboard transfer for Kimi K2.5

usage() {
  cat <<'USAGE'
Usage:
  ./collect-and-prompt.sh /path/to/client/repo ./collections/client-repo-name [model]

Defaults:
  model = gpt-5-mini

Prerequisites:
  - Node.js (LTS recommended)
  - npx (comes with Node.js)
  - microsoft/agentrc accessible via npx

Environment Setup:
  nvm install lts-* && nvm use
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

# Validate Node.js environment early
if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: Node.js not found. Please install Node.js using nvm:" >&2
  echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash" >&2
  echo "  nvm install lts-* && nvm use" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "ERROR: npx not found. Please ensure Node.js/npm is properly installed:" >&2
  echo "  nvm install lts-* && nvm use" >&2
  exit 1
fi

# Check Node.js version against .nvmrc if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVMRC_FILE="$SCRIPT_DIR/.nvmrc"
if [ -f "$NVMRC_FILE" ]; then
  NVMRC_CONTENT="$(cat "$NVMRC_FILE")"
  if [ "$NVMRC_CONTENT" = "lts-*" ]; then
    # For LTS, just ensure we have a reasonably recent Node.js version
    CURRENT_NODE_VERSION="$(node --version | sed 's/v//' | cut -d. -f1)"
    if [ "$CURRENT_NODE_VERSION" -lt 18 ]; then
      echo "ERROR: Node.js version $(node --version) is too old for LTS requirement. Please use Node.js 18+" >&2
      echo "  Run: nvm install lts-* && nvm use" >&2
      exit 1
    fi
  else
    # For specific version requirements
    REQUIRED_NODE_VERSION="$NVMRC_CONTENT"
    CURRENT_NODE_VERSION="$(node --version | sed 's/v//' | cut -d. -f1)"
    if [ "$CURRENT_NODE_VERSION" -lt "$REQUIRED_NODE_VERSION" ]; then
      echo "ERROR: Node.js version $(node --version) is too old. Required: v$REQUIRED_NODE_VERSION+" >&2
      echo "  Run: nvm install lts-* && nvm use" >&2
      exit 1
    fi
  fi
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

# --- Execute collection (best-effort, continues on failure) ---
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

# Copy context files
copy_if_exists "README.md" "README.md"
copy_if_exists "package.json" "package.json"
copy_if_exists "tsconfig.json" "tsconfig.json"
copy_if_exists ".github/copilot-instructions.md" ".github/copilot-instructions.md"
copy_if_exists "AGENTS.md" "AGENTS.md"
copy_if_exists "CLAUDE.md" "CLAUDE.md"
copy_if_exists "CONTRIBUTING.md" "CONTRIBUTING.md"
copy_if_exists "CODEOWNERS" "CODEOWNERS"
copy_if_exists "SECURITY.md" "SECURITY.md"

# --- Node.js prompt building (inline) ---
echo "Building synthesis prompt in memory..."

export SCRIPT_DIR="$SCRIPT_DIR"
node <<'NODE_EOF'
const fs = require('fs');
const path = require('path');

// Get collection directory from environment
const collectionDir = process.env.OUT;
if (!collectionDir) {
  console.error('ERROR: OUT environment variable not set');
  process.exit(1);
}

// Helper functions
function readText(file) {
  try { return fs.readFileSync(file, 'utf8'); } catch { return null; }
}

function readJson(file) {
  const t = readText(file);
  if (!t) return null;
  try { return JSON.parse(t); } catch { return null; }
}

function snippet(text, max = 1600) {
  if (!text) return '(missing)';
  return text.length > max ? `${text.slice(0, max)}\n...[truncated]` : text;
}

function fencedJson(obj) {
  if (!obj) return '```json\nnull\n```';
  return `\`\`\`json\n${JSON.stringify(obj, null, 2)}\n\`\`\``;
}

// Load collection artifacts
const files = {
  analyze: path.join(collectionDir, 'analyze.json'),
  readiness: path.join(collectionDir, 'readiness.json'),
  summary: path.join(collectionDir, 'collection-summary.json'),
  overview: path.join(collectionDir, 'instructions-overview.md')
};

// Load probe and generation data
const probes = [
  {
    name: 'flat-root',
    status: readJson(path.join(collectionDir, 'probes', 'flat-root', 'status.json')),
    stderr: readText(path.join(collectionDir, 'probes', 'flat-root', 'stderr.log')),
  },
  {
    name: 'flat-areas',
    status: readJson(path.join(collectionDir, 'probes', 'flat-areas', 'status.json')),
    stderr: readText(path.join(collectionDir, 'probes', 'flat-areas', 'stderr.log')),
  },
  {
    name: 'nested-root',
    status: readJson(path.join(collectionDir, 'probes', 'nested-root', 'status.json')),
    stderr: readText(path.join(collectionDir, 'probes', 'nested-root', 'stderr.log')),
  },
  {
    name: 'nested-areas',
    status: readJson(path.join(collectionDir, 'probes', 'nested-areas', 'status.json')),
    stderr: readText(path.join(collectionDir, 'probes', 'nested-areas', 'stderr.log')),
  },
];

const generations = [
  {
    name: 'flat-root',
    status: readJson(path.join(collectionDir, 'generated', 'flat-root', 'status.json')),
    output: readText(path.join(collectionDir, 'generated', 'flat-root', 'copilot-instructions.generated.md')),
    stderr: readText(path.join(collectionDir, 'generated', 'flat-root', 'stderr.log')),
  },
  {
    name: 'nested-root',
    status: readJson(path.join(collectionDir, 'generated', 'nested-root', 'status.json')),
    output: readText(path.join(collectionDir, 'generated', 'nested-root', 'AGENTS.generated.md')),
    stderr: readText(path.join(collectionDir, 'generated', 'nested-root', 'stderr.log')),
  },
];

// Build context files section
const contextCandidates = [
  'README.md', 'package.json', 'tsconfig.json', 'AGENTS.md', 'CLAUDE.md', 'CONTRIBUTING.md', 'SECURITY.md',
  '.github/copilot-instructions.md', 'CODEOWNERS',
];

const contextItems = contextCandidates.map((rel) => {
  const full = path.join(collectionDir, 'context', rel);
  const content = readText(full);
  return { rel, content };
});

const contextFilesMd = contextItems.map((c) => `### context/${c.rel}
\`\`\`text
${snippet(c.content, 1400)}
\`\`\``).join('\n\n');

// Build generated instructions section
const generatedInstructionsMd = generations.map((g) => `### ${g.name}
\`\`\`md
${g.output ?? '(missing)'}
\`\`\``).join('\n\n');

// Load templates
const scriptDir = process.env.SCRIPT_DIR || path.dirname(process.argv[1]);
const templateContent = readText(path.join(scriptDir, 'templates', kimi-k2_5-adr-synthesis-template.md'));
const adrTemplate = readText(path.join(scriptDir, 'templates', 'ai-enablement-adr-template.md')) || '';

if (!templateContent) {
  console.error('ERROR: Kimi K2.5 template not found');
  process.exit(1);
}

// Replace template placeholders
const synthesis = templateContent
  .replace('{{COLLECTION_SUMMARY_JSON}}', JSON.stringify(readJson(files.summary), null, 2))
  .replace('{{ANALYZE_JSON}}', JSON.stringify(readJson(files.analyze), null, 2))
  .replace('{{READINESS_JSON}}', JSON.stringify(readJson(files.readiness), null, 2))
  .replace('{{INSTRUCTIONS_STATUS_JSON}}', JSON.stringify(generations.find(g => g.name === 'flat-root')?.status || {}, null, 2))
  .replace('{{GENERATED_INSTRUCTIONS_MD}}', generatedInstructionsMd)
  .replace('{{COPIED_CONTEXT_FILES_MD}}', contextFilesMd)
  .replace('{{EVALUATOR_NOTES_MD}}', `### Probe Results
${probes.map((p) => `#### ${p.name}
Status: ${fencedJson(p.status)}
Stderr:
\`\`\`text
${snippet(p.stderr, 1200)}
\`\`\``).join('\n\n')}`)
  .replace('{{ADR_TEMPLATE_MD}}', adrTemplate);

// Write prompt to file
const promptsDir = path.join(collectionDir, 'prompts');
fs.mkdirSync(promptsDir, { recursive: true });
const promptFile = path.join(promptsDir, 'adr-synthesis-prompt.md');
fs.writeFileSync(promptFile, synthesis);

console.log(`✅ Synthesis prompt built: ${promptFile}`);
console.log(`📋 Prompt length: ${synthesis.length} characters`);
NODE_EOF

# Check if Node.js prompt building succeeded
if [ $? -ne 0 ]; then
  echo "❌ Prompt building failed" >&2
  exit 1
fi

# --- Clipboard transfer ---
PROMPT_FILE="$OUT/prompts/adr-synthesis-prompt.md"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "❌ Prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

# Copy to clipboard based on OS
if command -v pbcopy >/dev/null 2>&1; then
  cat "$PROMPT_FILE" | pbcopy
  echo "✅ Prompt copied to clipboard (macOS)"
elif command -v xclip >/dev/null 2>&1; then
  cat "$PROMPT_FILE" | xclip -selection clipboard
  echo "✅ Prompt copied to clipboard (Linux)"
elif command -v clip.exe >/dev/null 2>&1; then
  cat "$PROMPT_FILE" | clip.exe
  echo "✅ Prompt copied to clipboard (Windows)"
else
  echo "❌ No clipboard command found" >&2
  echo "Install: macOS (built-in), Linux: sudo apt install xclip, Windows (built-in)" >&2
  exit 1
fi

echo "🎯 Ready for Kimi K2.5: https://kimi.moonshot.cn/"
echo "📁 Collection artifacts: $OUT"

if [ "$OVERALL_SUCCESS" = true ]; then
  echo "✅ Collection completed successfully"
  exit 0
else
  echo "⚠️  Collection completed with some failures (check logs)" >&2
  exit 1
fi
