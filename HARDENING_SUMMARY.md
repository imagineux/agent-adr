# agent-adr Hardening Summary

## Overview
The `agent-adr` wrapper has been hardened to fix correctness and shell-safety issues while preserving the enterprise-safe architecture. The hardened version is now safe to merge and use in production environments.

## Priority Fixes Implemented

### 1. Fixed `set -u` Local Declaration Bugs

**Issue:** In `capture_probe()`, the original code had:
```bash
capture_probe() {
  local probe_name="$1" cmd="$2" probe_dir="$OUT/probes/$probe_name"
  # ...
}
```

With `set -u` enabled, when bash parses `local probe_name="$1" cmd="$2" probe_dir="$OUT/probes/$probe_name"`, it expands `$probe_name` in the same declaration where it's being assigned. If `probe_name` is unset, this causes bash to abort.

**Fix:** Separated the declarations:
```bash
capture_probe() {
  local probe_name="$1"
  shift
  local probe_dir="$OUT/probes/$probe_name"
  # ...
}
```

All functions using multiple local declarations were audited and fixed to avoid this pattern.

### 2. Removed Stringly Shell Execution

**Issue:** Original code used `bash -lc "$cmd"` where `$cmd` contained user-controlled paths:
```bash
bash -lc "$cmd" >"$stdout_file" 2>"$stderr_file"
```

This is dangerous when paths contain spaces, `$`, `$(...)`, backticks, or quotes. The command string would be re-parsed by bash, creating injection vulnerabilities.

**Fix:** Replaced with argv-based execution:
```bash
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
```

Commands are now passed as arrays:
```bash
cmd_analyze=(npx github:microsoft/agentrc analyze --json --output "$OUT/analyze.json")
run_in_repo "$stdout" "$stderr" "${cmd_analyze[@]}"
```

**Command Rendering:** A separate `cmd_to_string()` function using `printf %q` safely converts argv arrays to strings for metadata logging without re-execution risk.

### 3. Added Repo Boundary Safety Guard

**Issue:** The script made output paths absolute but had no assertion that they didn't fall inside the client repo. This could lead to accidental repo contamination.

**Fix:** Added `is_path_inside()` function that performs path prefix checking:
```bash
is_path_inside() {
  local child="$1"
  local parent="$2"
  local child_normalized="${child%/}/"
  local parent_normalized="${parent%/}/"
  case "$child_normalized" in
    "$parent_normalized"*) return 0 ;;
    *) return 1 ;;
  esac
}

if is_path_inside "$OUT" "$REPO_PATH"; then
  echo "ERROR: output root is inside the client repo..." >&2
  exit 1
fi
```

This prevents collection when the output directory is accidentally placed inside the repo.

### 4. Improved Failure Robustness

**Issue:** Original script would abort on first failure and didn't explicitly surface missing files in prompts.

**Fix:** 
- All capture calls now use `|| true` to continue on failure:
```bash
capture_cmd "analyze" ... "${cmd_analyze[@]}" || true
capture_probe "flat-root" "${cmd_probe_flat_root[@]}" || true
capture_generation "flat-root" ... "${cmd_gen_flat[@]}" || true
```

- Status/log files are always written even when operations fail
- The `build-strong-model-prompt.mjs` script explicitly marks missing files with `(missing)` in prompts

### 5. Added Deterministic Smoke Tests

**Created:**
- `tests/fake-agentrc.sh` - A shim that simulates agentrc behaviors:
  - `success` - All operations succeed
  - `analyze-fail` - Analyze fails but collection continues
  - `probe-fail` - Dry-run probes fail but generation succeeds
  - `gen-fail` - Generation fails (no output file)
  - `partial-output` - Generation fails but partial output exists

- `tests/smoke-test.sh` - Comprehensive test harness verifying:
  - Bundle directory structure
  - Status JSON files exist for all operations
  - Logs written even on failure
  - Repo boundary guard rejects invalid configurations
  - Paths with spaces are handled correctly
  - Prompt builder emits both prompt files
  - Missing files are explicitly marked in prompt output

## Files Modified

| File | Changes |
|------|---------|
| `scripts/collect-agentrc.sh` | Complete rewrite with hardening fixes |
| `README.md` | Added Safety and Hardening section, Testing section |
| `tests/fake-agentrc.sh` | New: Simulates agentrc behaviors for testing |
| `tests/smoke-test.sh` | New: Comprehensive test harness |

## UX Preservation

The hardened version preserves all existing functionality:
- Same command-line invocation
- Same directory structure in collection bundles
- Same output files (JSON, logs, markdown)
- Same synthesis and review prompts
- Same diagnostics capture
- Same model override default (`gpt-5-mini`)

## Verification

To verify the hardening:
1. Run smoke tests: `./tests/smoke-test.sh`
2. Preserve artifacts for inspection: `KEEP_TEST_ARTIFACTS=1 ./tests/smoke-test.sh`
3. Manually test with paths containing spaces: `./scripts/collect-agentrc.sh "/path/with spaces/repo" "./collections/test"`
4. Attempt to place output inside repo (should fail): `./scripts/collect-agentrc.sh ./repo ./repo/collections`

## Security Improvements

| Risk | Before | After |
|------|--------|-------|
| Path injection via spaces | Vulnerable | Safe (argv arrays) |
| Path injection via `$` expansion | Vulnerable | Safe (argv arrays) |
| Path injection via backticks | Vulnerable | Safe (argv arrays) |
| Accidental repo contamination | Unprotected | Blocked by boundary guard |
| `set -u` expansion bugs | Present | Fixed |
| Silent failures | Possible | Explicit status/log files |
