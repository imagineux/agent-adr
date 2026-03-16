#!/usr/bin/env bash
# Simple smoke tests for collect-agentrc.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COLLECT_SCRIPT="$REPO_ROOT/scripts/collect-agentrc.sh"

# Test workspace
TEST_WORKSPACE="${TEST_WORKSPACE:-/tmp/agent-adr-smoke-$$}"
FAKE_AGENTRC="$SCRIPT_DIR/fake-agentrc.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

setup() {
  rm -rf "$TEST_WORKSPACE"
  mkdir -p "$TEST_WORKSPACE/fake-repo"
  echo '{"name": "test"}' > "$TEST_WORKSPACE/fake-repo/package.json"
  
  # Simple fake agentrc that just succeeds
  cat > "$TEST_WORKSPACE/fake-agentrc" <<'FAKE'
#!/usr/bin/env bash
echo '{"repoType": "node"}'
exit 0
FAKE
  chmod +x "$TEST_WORKSPACE/fake-agentrc"
  
  # Simple npx wrapper
  cat > "$TEST_WORKSPACE/npx" <<'NPX'
#!/usr/bin/env bash
if [ "$1" = "github:microsoft/agentrc" ]; then
  shift
  exec "$TEST_WORKSPACE/fake-agentrc" "$@"
fi
echo "npx called with: $*" >&2
exit 1
NPX
  chmod +x "$TEST_WORKSPACE/npx"
}

cleanup() {
  rm -rf "$TEST_WORKSPACE"
}

assert_file_exists() {
  [ -f "$1" ] && return 0 || { log_error "Missing file: $1"; return 1; }
}

assert_json_has_field() {
  local file="$1" field="$2"
  python3 -c "import json; json.load(open('$file'))['$field']" 2>/dev/null && return 0 || { log_error "Missing field $field in $file"; return 1; }
}

run_test() {
  local name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  log_info "Test: $name"
  if "$2"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    log_info "✓ PASSED: $name"
    return 0
  else
    log_error "✗ FAILED: $name"
    return 1
  fi
}

# Test 1: Basic collection works
test_basic_collection() {
  local collection_dir="$TEST_WORKSPACE/collection"
  PATH="$TEST_WORKSPACE:$PATH" bash "$COLLECT_SCRIPT" "$TEST_WORKSPACE/fake-repo" "$collection_dir"
  
  # Check essential files exist
  assert_file_exists "$collection_dir/collection-summary.json"
  assert_file_exists "$collection_dir/metadata/run.json"
  assert_file_exists "$collection_dir/metadata/analyze-status.json"
  assert_file_exists "$collection_dir/metadata/readiness-status.json"
  
  # Check JSON structure
  assert_json_has_field "$collection_dir/collection-summary.json" "repoPath"
  assert_json_has_field "$collection_dir/metadata/run.json" "timestamp"
}

# Test 2: Repo boundary guard works
test_repo_boundary_guard() {
  local collection_dir="$TEST_WORKSPACE/fake-repo/collections/test"  # Inside repo!
  
  # Should fail with error
  if PATH="$TEST_WORKSPACE:$PATH" bash "$COLLECT_SCRIPT" "$TEST_WORKSPACE/fake-repo" "$collection_dir" 2>/dev/null; then
    log_error "Should have failed when output is inside repo"
    return 1
  fi
  return 0
}

# Test 3: Paths with spaces work
test_paths_with_spaces() {
  local collection_dir="$TEST_WORKSPACE/collection with spaces"
  mkdir -p "$collection_dir"
  
  PATH="$TEST_WORKSPACE:$PATH" bash "$COLLECT_SCRIPT" "$TEST_WORKSPACE/fake-repo" "$collection_dir"
  assert_file_exists "$collection_dir/collection-summary.json"
}

# Test 4: Prompt builder works
test_prompt_builder() {
  local collection_dir="$TEST_WORKSPACE/collection-prompts"
  PATH="$TEST_WORKSPACE:$PATH" bash "$COLLECT_SCRIPT" "$TEST_WORKSPACE/fake-repo" "$collection_dir"
  
  node "$REPO_ROOT/scripts/build-strong-model-prompt.mjs" --collection "$collection_dir" --out "$collection_dir/prompts"
  
  assert_file_exists "$collection_dir/prompts/adr-synthesis-prompt.md"
  assert_file_exists "$collection_dir/prompts/adr-review-prompt.md"
}

main() {
  log_info "Running simple smoke tests"
  
  setup
  trap cleanup EXIT
  
  run_test "basic_collection" test_basic_collection
  run_test "repo_boundary_guard" test_repo_boundary_guard
  run_test "paths_with_spaces" test_paths_with_spaces
  run_test "prompt_builder" test_prompt_builder
  
  echo ""
  log_info "Results: $TESTS_PASSED/$TESTS_RUN tests passed"
  
  if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
    log_info "All tests passed!"
    exit 0
  else
    log_error "Some tests failed!"
    exit 1
  fi
}

main "$@"
