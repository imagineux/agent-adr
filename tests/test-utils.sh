#!/usr/bin/env bash
# Test utilities for confidence harness

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters (global, modified by calling scripts)
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $*"; }

# Assertion functions
assert_file_exists() {
  local file="$1"
  local msg="${2:-File should exist: $file}"
  if [ -f "$file" ]; then
    log_debug "✓ File exists: $file"
    return 0
  else
    log_error "✗ ASSERTION FAILED: $msg"
    return 1
  fi
}

assert_file_missing() {
  local file="$1"
  local msg="${2:-File should NOT exist: $file}"
  if [ ! -f "$file" ]; then
    log_debug "✓ File correctly missing: $file"
    return 0
  else
    log_error "✗ ASSERTION FAILED: $msg"
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  local msg="${2:-Directory should exist: $dir}"
  if [ -d "$dir" ]; then
    log_debug "✓ Directory exists: $dir"
    return 0
  else
    log_error "✗ ASSERTION FAILED: $msg"
    return 1
  fi
}

assert_json_field() {
  local file="$1"
  local field="$2"
  local expected="$3"
  local actual
  
  if [ ! -f "$file" ]; then
    log_error "✗ JSON file does not exist: $file"
    return 1
  fi
  
  actual="$(python3 -c "
import json, sys
try:
  with open(sys.argv[1]) as f:
    data = json.load(f)
  val = data.get(sys.argv[2], '__MISSING__')
  if isinstance(val, bool):
    print(str(val).lower())
  else:
    print(str(val))
except Exception as e:
  print('__ERROR__')
" "$file" "$field" 2>/dev/null || echo '__ERROR__')"
  
  if [ "$actual" = "$expected" ]; then
    log_debug "✓ JSON field $field = $expected"
    return 0
  else
    log_error "✗ ASSERTION FAILED: $file $field expected '$expected' but got '$actual'"
    return 1
  fi
}

assert_json_field_exists() {
  local file="$1"
  local field="$2"
  
  if [ ! -f "$file" ]; then
    log_error "✗ JSON file does not exist: $file"
    return 1
  fi
  
  if python3 -c "import json, sys; json.load(open(sys.argv[1]))[sys.argv[2]]" "$file" "$field" >/dev/null 2>&1; then
    log_debug "✓ JSON field exists: $field"
    return 0
  else
    log_error "✗ ASSERTION FAILED: JSON field missing: $field in $file"
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local msg="${3:-File should contain pattern: $pattern}"
  
  if [ ! -f "$file" ]; then
    log_error "✗ File does not exist: $file"
    return 1
  fi
  
  if grep -q "$pattern" "$file"; then
    log_debug "✓ File contains pattern: $pattern"
    return 0
  else
    log_error "✗ ASSERTION FAILED: $msg"
    return 1
  fi
}

assert_file_missing_pattern() {
  local file="$1"
  local pattern="$2"
  local msg="${3:-File should NOT contain pattern: $pattern}"
  
  if [ ! -f "$file" ]; then
    log_debug "✓ File does not exist (pattern check irrelevant): $file"
    return 0
  fi
  
  if ! grep -q "$pattern" "$file"; then
    log_debug "✓ File correctly missing pattern: $pattern"
    return 0
  else
    log_error "✗ ASSERTION FAILED: $msg"
    return 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-Exit code should be $expected but was $actual}"
  
  if [ "$expected" = "$actual" ]; then
    log_debug "✓ Exit code correct: $expected"
    return 0
  else
    log_error "✗ ASSERTION FAILED: $msg"
    return 1
  fi
}

# Test runner
run_test() {
  local name="$1"
  shift
  TESTS_RUN=$((TESTS_RUN + 1))
  log_info "Running test: $name"
  
  if "$@"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    log_info "✓ PASSED: $name"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    log_error "✗ FAILED: $name"
    return 1
  fi
}

# Test summary
print_test_summary() {
  echo ""
  log_info "=== TEST SUMMARY ==="
  log_info "Tests run: $TESTS_RUN"
  log_info "Tests passed: $TESTS_PASSED"
  log_info "Tests failed: $TESTS_FAILED"
  
  if [ $TESTS_FAILED -eq 0 ]; then
    log_info "🎉 All tests passed!"
    return 0
  else
    log_error "💥 Some tests failed!"
    return 1
  fi
}

# Collection validation helpers
validate_collection_structure() {
  local collection_dir="$1"
  local should_have_generated="${2:-true}"
  
  # Core metadata files
  assert_file_exists "$collection_dir/collection-summary.json"
  assert_file_exists "$collection_dir/metadata/run.json"
  assert_file_exists "$collection_dir/metadata/environment.json"
  assert_file_exists "$collection_dir/metadata/commands.json"
  assert_file_exists "$collection_dir/metadata/analyze-status.json"
  assert_file_exists "$collection_dir/metadata/readiness-status.json"
  
  # Log files
  assert_file_exists "$collection_dir/logs/analyze.stdout.log"
  assert_file_exists "$collection_dir/logs/readiness.stdout.log"
  
  # Probe directories and status files
  for probe in flat-root flat-areas nested-root nested-areas; do
    assert_dir_exists "$collection_dir/probes/$probe"
    assert_file_exists "$collection_dir/probes/$probe/status.json"
  done
  
  # Generation directories and status files
  assert_dir_exists "$collection_dir/generated/flat-root"
  assert_dir_exists "$collection_dir/generated/nested-root"
  assert_file_exists "$collection_dir/generated/flat-root/status.json"
  assert_file_exists "$collection_dir/generated/nested-root/status.json"
  
  # Generated output files (conditional)
  if [ "$should_have_generated" = "true" ]; then
    assert_file_exists "$collection_dir/generated/flat-root/copilot-instructions.generated.md"
    assert_file_exists "$collection_dir/generated/nested-root/AGENTS.generated.md"
    assert_json_field "$collection_dir/collection-summary.json" "anyGeneratedOutput" "true"
  else
    assert_json_field "$collection_dir/collection-summary.json" "anyGeneratedOutput" "false"
  fi
  
  # Overview and notes
  assert_file_exists "$collection_dir/instructions-overview.md"
  assert_file_exists "$collection_dir/notes.md"
}

validate_prompt_structure() {
  local prompt_dir="$1"
  
  assert_dir_exists "$prompt_dir"
  assert_file_exists "$prompt_dir/adr-synthesis-prompt.md"
  assert_file_exists "$prompt_dir/adr-review-prompt.md"
  
  # Check prompt content structure
  assert_file_contains "$prompt_dir/adr-synthesis-prompt.md" "Strong-Model ADR Synthesis Prompt"
  assert_file_contains "$prompt_dir/adr-review-prompt.md" "Strong-Model ADR Review Prompt"
  
  # Check that missing files are marked
  if grep -q "(missing)" "$prompt_dir/adr-synthesis-prompt.md"; then
    log_debug "✓ Missing files properly marked in synthesis prompt"
  else
    log_debug "ℹ No missing files detected in synthesis prompt"
  fi
}

# Fixture creation helpers
create_basic_repo() {
  local repo_path="$1"
  
  mkdir -p "$repo_path"
  cat > "$repo_path/package.json" <<'JSON'
{
  "name": "test-repo",
  "version": "1.0.0",
  "description": "A test repository",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
JSON
  
  cat > "$repo_path/README.md" <<'MD'
# Test Repository

This is a test repository for confidence testing.

## Usage

npm install
npm test
npm start
MD
  
  mkdir -p "$repo_path/.github/workflows"
  cat > "$repo_path/.github/workflows/ci.yml" <<'YAML'
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
YAML
}

create_repo_with_instructions() {
  local repo_path="$1"
  
  create_basic_repo "$repo_path"
  
  mkdir -p "$repo_path/.github"
  cat > "$repo_path/.github/copilot-instructions.md" <<'MD'
# Copilot Instructions

This repository uses Express.js with TypeScript.

## Guidelines
1. Use TypeScript for new files
2. Write tests for all new functions
3. Follow existing code patterns
4. Update documentation

## Testing
- Use Jest for unit tests
- Maintain >80% coverage
MD
  
  cat > "$repo_path/AGENTS.md" <<'MD'
# AI Agent Instructions

## Repository Context
- Node.js Express application
- TypeScript codebase
- Jest testing framework

## Development Workflow
1. Create feature branch
2. Write tests first
3. Implement functionality
4. Update documentation
5. Submit PR for review
MD
}

create_minimal_repo() {
  local repo_path="$1"
  
  mkdir -p "$repo_path"
  cat > "$repo_path/package.json" <<'JSON'
{
  "name": "minimal-repo",
  "version": "0.1.0"
}
JSON
}

# Environment setup helpers
setup_fake_bin() {
  local workspace="$1"
  local fake_agentrc="$2"
  
  mkdir -p "$workspace/bin"
  
  # Create agentrc symlink
  ln -sf "$fake_agentrc" "$workspace/bin/agentrc"
  chmod +x "$fake_agentrc"
  
  # Create npx wrapper
  cat > "$workspace/bin/npx" <<'NPXWRAPPER'
#!/usr/bin/env bash
# npx wrapper that intercepts github:microsoft/agentrc and redirects to fake agentrc
if [ "$1" = "github:microsoft/agentrc" ]; then
  shift
  exec agentrc "$@"
fi
# If not intercepting, call real npx (try common locations)
for real_npx in /usr/local/bin/npx /usr/bin/npx /opt/homebrew/bin/npx "$HOME/.npm/bin/npx"; do
  if [ -x "$real_npx" ]; then
    exec "$real_npx" "$@"
  fi
done
# Fallback: try to find npx in original PATH
exec npx "$@"
NPXWRAPPER
  chmod +x "$workspace/bin/npx"
  
  # Export PATH for test environment
  export PATH="$workspace/bin:$PATH"
}
