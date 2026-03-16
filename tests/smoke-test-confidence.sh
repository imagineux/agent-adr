#!/usr/bin/env bash
# Comprehensive confidence test harness for agent-adr wrapper
# Tests all major behaviors using enhanced fake-agentrc.sh shim

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COLLECT_SCRIPT="$REPO_ROOT/scripts/collect-agentrc.sh"
PROMPT_BUILDER="$REPO_ROOT/scripts/build-strong-model-prompt.mjs"
FAKE_AGENTRC="$SCRIPT_DIR/fake-agentrc.sh"

# Source test utilities
source "$SCRIPT_DIR/test-utils.sh"

# Test workspace
TEST_WORKSPACE="${TEST_WORKSPACE:-/tmp/agent-adr-confidence-$$}"

# === SETUP AND TEARDOWN ===

setup() {
  log_info "Setting up confidence test workspace: $TEST_WORKSPACE"
  rm -rf "$TEST_WORKSPACE"
  mkdir -p "$TEST_WORKSPACE"
  
  # Verify scripts exist
  if [ ! -x "$COLLECT_SCRIPT" ]; then
    log_error "collect-agentrc.sh not found or not executable: $COLLECT_SCRIPT"
    exit 1
  fi
  
  if [ ! -f "$PROMPT_BUILDER" ]; then
    log_error "build-strong-model-prompt.mjs not found: $PROMPT_BUILDER"
    exit 1
  fi
  
  if [ ! -x "$FAKE_AGENTRC" ]; then
    log_error "fake-agentrc.sh not found or not executable: $FAKE_AGENTRC"
    exit 1
  fi
  
  log_info "Test workspace ready"
}

teardown() {
  if [ "${KEEP_TEST_ARTIFACTS:-}" != "1" ]; then
    log_info "Cleaning up test workspace"
    rm -rf "$TEST_WORKSPACE"
  else
    log_info "🔍 Kept test artifacts at: $TEST_WORKSPACE"
    log_info "Inspect with: find $TEST_WORKSPACE -type f -name '*.json' -o -name '*.md' -o -name '*.log' | sort"
  fi
}

# === TEST SCENARIOS ===

test_successful_collection() {
  local collection_dir="$TEST_WORKSPACE/collection-success"
  local repo="$TEST_WORKSPACE/repo-basic"
  
  # Create basic repo
  create_basic_repo "$repo"
  
  # Setup fake environment
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection with success behavior
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=success \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini"
  
  # Validate collection structure
  validate_collection_structure "$collection_dir" "true"
  
  # Validate specific success indicators
  assert_json_field "$collection_dir/collection-summary.json" "anyGeneratedOutput" "true"
  assert_json_field "$collection_dir/metadata/analyze-status.json" "exitCode" "0"
  assert_json_field "$collection_dir/metadata/readiness-status.json" "exitCode" "0"
  
  return 0
}

test_analyze_failure_continues() {
  local collection_dir="$TEST_WORKSPACE/collection-analyze-fail"
  local repo="$TEST_WORKSPACE/repo-analyze-fail"
  
  create_basic_repo "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection with analyze failure (should continue)
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=analyze-fail \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini" || true
  
  # Collection should continue despite analyze failure
  validate_collection_structure "$collection_dir" "true"
  
  # Verify analyze shows failure but other steps succeeded
  assert_json_field "$collection_dir/metadata/analyze-status.json" "exitCode" "1"
  assert_json_field "$collection_dir/metadata/readiness-status.json" "exitCode" "0"
  assert_json_field "$collection_dir/collection-summary.json" "anyGeneratedOutput" "true"
  
  return 0
}

test_probe_failures_continue() {
  local collection_dir="$TEST_WORKSPACE/collection-probe-fail"
  local repo="$TEST_WORKSPACE/repo-probe-fail"
  
  create_basic_repo "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection with probe failures (should continue)
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=probe-fail \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini" || true
  
  # Collection should continue despite probe failures
  validate_collection_structure "$collection_dir" "true"
  
  # Verify probes failed but generation succeeded
  assert_json_field "$collection_dir/probes/flat-root/status.json" "exitCode" "1"
  assert_json_field "$collection_dir/generated/flat-root/status.json" "exitCode" "0"
  assert_json_field "$collection_dir/collection-summary.json" "anyGeneratedOutput" "true"
  
  return 0
}

test_generation_failure_handled() {
  local collection_dir="$TEST_WORKSPACE/collection-gen-fail"
  local repo="$TEST_WORKSPACE/repo-gen-fail"
  
  create_basic_repo "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection with generation failure
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=gen-fail \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini" || true
  
  # Collection should complete but with no generated output
  validate_collection_structure "$collection_dir" "false"
  
  # Verify generation failed
  assert_json_field "$collection_dir/generated/flat-root/status.json" "exitCode" "1"
  assert_json_field "$collection_dir/generated/nested-root/status.json" "exitCode" "1"
  assert_file_missing "$collection_dir/generated/flat-root/copilot-instructions.generated.md"
  assert_file_missing "$collection_dir/generated/nested-root/AGENTS.generated.md"
  assert_json_field "$collection_dir/collection-summary.json" "anyGeneratedOutput" "false"
  
  return 0
}

test_partial_output_handled() {
  local collection_dir="$TEST_WORKSPACE/collection-partial"
  local repo="$TEST_WORKSPACE/repo-partial"
  
  create_basic_repo "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection with partial output
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=partial-output \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini" || true
  
  # File exists but generation reported failure
  validate_collection_structure "$collection_dir" "false"
  
  # Verify partial output scenario
  assert_file_exists "$collection_dir/generated/flat-root/copilot-instructions.generated.md"
  assert_json_field "$collection_dir/generated/flat-root/status.json" "exitCode" "1"
  assert_json_field "$collection_dir/collection-summary.json" "anyGeneratedOutput" "false"
  
  return 0
}

test_network_error_handled() {
  local collection_dir="$TEST_WORKSPACE/collection-network-error"
  local repo="$TEST_WORKSPACE/repo-network-error"
  
  create_basic_repo "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection with network error
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=network-error \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini" || true
  
  # Should handle network errors gracefully
  validate_collection_structure "$collection_dir" "false"
  
  # Verify network error handling
  assert_json_field "$collection_dir/probes/flat-root/status.json" "exitCode" "1"
  assert_json_field "$collection_dir/generated/flat-root/status.json" "exitCode" "1"
  
  return 0
}

test_repo_boundary_guard() {
  local collection_dir="$TEST_WORKSPACE/repo-basic/collections/test"  # Inside repo!
  local repo="$TEST_WORKSPACE/repo-basic"
  
  create_basic_repo "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # This should fail because output is inside the repo
  if PATH="$TEST_WORKSPACE/bin:$PATH" \
     FAKE_AGENTRC_BEHAVIOR=success \
     bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini" 2>&1; then
    log_error "Expected failure when output is inside repo"
    return 1
  fi
  
  # Verify no collection directory was created
  assert_dir_missing "$collection_dir"
  
  return 0
}

test_paths_with_spaces() {
  local collection_dir="$TEST_WORKSPACE/collection with spaces"
  local repo="$TEST_WORKSPACE/repo-spaces"
  
  create_basic_repo "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection with spaces in path
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=success \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini"
  
  validate_collection_structure "$collection_dir" "true"
  
  return 0
}

test_prompt_builder_success() {
  local collection_dir="$TEST_WORKSPACE/collection-prompts"
  local repo="$TEST_WORKSPACE/repo-prompts"
  
  create_repo_with_instructions "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # First run successful collection
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=success \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini"
  
  # Run prompt builder
  node "$PROMPT_BUILDER" --collection "$collection_dir" --out "$collection_dir/prompts"
  
  # Validate prompt structure
  validate_prompt_structure "$collection_dir/prompts"
  
  # Check that context files are included
  assert_file_contains "$collection_dir/prompts/adr-synthesis-prompt.md" "context/README.md"
  assert_file_contains "$collection_dir/prompts/adr-synthesis-prompt.md" "context/AGENTS.md"
  
  return 0
}

test_prompt_builder_with_failures() {
  local collection_dir="$TEST_WORKSPACE/collection-prompts-failures"
  local repo="$TEST_WORKSPACE/repo-prompts-failures"
  
  create_basic_repo "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection with generation failures
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=gen-fail \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini" || true
  
  # Run prompt builder
  node "$PROMPT_BUILDER" --collection "$collection_dir" --out "$collection_dir/prompts"
  
  # Validate prompt structure
  validate_prompt_structure "$collection_dir/prompts"
  
  # Check that missing files are explicitly marked
  assert_file_contains "$collection_dir/prompts/adr-synthesis-prompt.md" "(missing)"
  
  # Check that failure diagnostics are included (stderr may not always be present)
  if grep -q "stderr" "$collection_dir/prompts/adr-synthesis-prompt.md"; then
    log_debug "✓ Failure diagnostics (stderr) included in prompt"
  else
    log_debug "ℹ No stderr content found (may be expected for some failure scenarios)"
  fi
  
  return 0
}

test_minimal_repo_collection() {
  local collection_dir="$TEST_WORKSPACE/collection-minimal"
  local repo="$TEST_WORKSPACE/repo-minimal"
  
  create_minimal_repo "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection on minimal repo
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=success \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini"
  
  validate_collection_structure "$collection_dir" "true"
  
  # Should still work with minimal repo
  assert_json_field "$collection_dir/collection-summary.json" "anyGeneratedOutput" "true"
  
  return 0
}

test_context_copying() {
  local collection_dir="$TEST_WORKSPACE/collection-context"
  local repo="$TEST_WORKSPACE/repo-context"
  
  create_repo_with_instructions "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=success \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir" "gpt-5-mini"
  
  # Validate context files were copied
  assert_file_exists "$collection_dir/context/README.md"
  assert_file_exists "$collection_dir/context/package.json"
  assert_file_exists "$collection_dir/context/AGENTS.md"
  assert_file_exists "$collection_dir/context/.github/copilot-instructions.md"
  
  return 0
}

test_deterministic_behavior() {
  local collection_dir1="$TEST_WORKSPACE/collection-deterministic-1"
  local collection_dir2="$TEST_WORKSPACE/collection-deterministic-2"
  local repo="$TEST_WORKSPACE/repo-deterministic"
  
  create_basic_repo "$repo"
  setup_fake_bin "$TEST_WORKSPACE" "$FAKE_AGENTRC"
  
  # Run collection twice with same inputs
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=success \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir1" "gpt-5-mini"
  
  PATH="$TEST_WORKSPACE/bin:$PATH" \
  FAKE_AGENTRC_BEHAVIOR=success \
    bash "$COLLECT_SCRIPT" "$repo" "$collection_dir2" "gpt-5-mini"
  
  # Compare key files for determinism (excluding timestamps)
  local summary1 summary2
  summary1="$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
# Remove timestamp fields for comparison
data.pop('timestamp', None)
print(json.dumps(data, sort_keys=True))
" "$collection_dir1/collection-summary.json")"
  
  summary2="$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
# Remove timestamp fields for comparison
data.pop('timestamp', None)
print(json.dumps(data, sort_keys=True))
" "$collection_dir2/collection-summary.json")"
  
  if [ "$summary1" = "$summary2" ]; then
    log_debug "✓ Deterministic behavior confirmed (excluding timestamps)"
    return 0
  else
    log_debug "Summary1: $summary1"
    log_debug "Summary2: $summary2"
    log_error "✗ Non-deterministic behavior detected"
    return 1
  fi
}

# === MAIN EXECUTION ===

main() {
  log_info "🚀 Starting confidence tests for agent-adr wrapper"
  log_info "COLLECT_SCRIPT: $COLLECT_SCRIPT"
  log_info "PROMPT_BUILDER: $PROMPT_BUILDER"
  log_info "FAKE_AGENTRC: $FAKE_AGENTRC"
  
  setup
  trap teardown EXIT
  
  # Run all test scenarios
  run_test "successful_collection" test_successful_collection
  run_test "analyze_failure_continues" test_analyze_failure_continues
  run_test "probe_failures_continue" test_probe_failures_continue
  run_test "generation_failure_handled" test_generation_failure_handled
  run_test "partial_output_handled" test_partial_output_handled
  run_test "network_error_handled" test_network_error_handled
  run_test "repo_boundary_guard" test_repo_boundary_guard
  run_test "paths_with_spaces" test_paths_with_spaces
  run_test "prompt_builder_success" test_prompt_builder_success
  run_test "prompt_builder_with_failures" test_prompt_builder_with_failures
  run_test "minimal_repo_collection" test_minimal_repo_collection
  run_test "context_copying" test_context_copying
  run_test "deterministic_behavior" test_deterministic_behavior
  
  # Print final summary
  print_test_summary
}

# Execute main function
main "$@"
