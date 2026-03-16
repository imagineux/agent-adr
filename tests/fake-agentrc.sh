#!/usr/bin/env bash
# Fake agentrc shim for testing
# Simulates various behaviors based on environment variables

set -uo pipefail

FAKE_AGENTRC_BEHAVIOR="${FAKE_AGENTRC_BEHAVIOR:-success}"
FAKE_AGENTRC_DELAY="${FAKE_AGENTRC_DELAY:-0}"

# Parse arguments to determine subcommand and options
subcommand=""
output_path=""
dry_run=false
strategy=""
areas=false
model=""
force=false
json_output=false

while [ $# -gt 0 ]; do
  case "$1" in
    analyze|readiness|instructions)
      subcommand="$1"
      shift
      ;;
    --output)
      output_path="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --strategy)
      strategy="$2"
      shift 2
      ;;
    --areas)
      areas=true
      shift
      ;;
    --model)
      model="$2"
      shift 2
      ;;
    --force)
      force=true
      shift
      ;;
    --json)
      json_output=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Simulate delay if requested
if [ "$FAKE_AGENTRC_DELAY" -gt 0 ] 2>/dev/null; then
  sleep "$FAKE_AGENTRC_DELAY"
fi

# Generate output based on behavior and subcommand
case "$FAKE_AGENTRC_BEHAVIOR" in
  success)
    case "$subcommand" in
      analyze)
        if [ "$json_output" = true ]; then
          cat <<'JSON'
{
  "repoType": "node",
  "languages": ["typescript", "javascript"],
  "frameworks": ["express"],
  "testFrameworks": ["jest"],
  "packageManager": "npm",
  "hasDocker": false,
  "hasCI": true
}
JSON
        else
          echo "Repository analysis complete."
        fi
        ;;
      readiness)
        if [ "$json_output" = true ]; then
          cat <<'JSON'
{
  "ready": true,
  "score": 75,
  "issues": [],
  "recommendations": ["Add AGENTS.md", "Add copilot-instructions.md"]
}
JSON
        else
          echo "Readiness check: PASSED (score: 75/100)"
        fi
        ;;
      instructions)
        if [ "$dry_run" = true ]; then
          # Dry-run returns JSON probe result
          cat <<'JSON'
{
  "strategy": "flat",
  "model": "gpt-5-mini",
  "wouldGenerate": true,
  "estimatedTokens": 1200
}
JSON
        else
          # Real generation - write to output file
          if [ -n "$output_path" ]; then
            mkdir -p "$(dirname "$output_path")"
            cat > "$output_path" <<'MD'
# Generated Instructions

These are fake generated instructions for testing purposes.

## Repository Context
- Type: Node.js application
- Languages: TypeScript, JavaScript

## Guidelines
1. Follow existing code patterns
2. Write tests for new features
3. Update documentation as needed
MD
          fi
          echo "Instructions generated successfully."
        fi
        ;;
    esac
    exit 0
    ;;

  analyze-fail)
    case "$subcommand" in
      analyze)
        echo "ERROR: Failed to analyze repository" >&2
        exit 1
        ;;
      readiness)
        if [ "$json_output" = true ]; then
          cat <<'JSON'
{"ready": false, "score": 30, "issues": ["No README.md"], "recommendations": []}
JSON
        else
          echo "Readiness: POOR (30/100)"
        fi
        ;;
      instructions)
        if [ "$dry_run" = true ]; then
          cat <<'JSON'
{"strategy": "flat", "model": "gpt-5-mini", "wouldGenerate": true}
JSON
        else
          mkdir -p "$(dirname "$output_path")"
          cat > "$output_path" <<'MD'
# Generated Instructions

Test instructions.
MD
          echo "Generated (analyze failed but gen succeeded)"
        fi
        ;;
    esac
    ;;

  probe-fail)
    case "$subcommand" in
      analyze|readiness)
        # These succeed
        if [ "$subcommand" = "analyze" ]; then
          echo '{"repoType": "node"}'
        else
          echo '{"ready": true, "score": 80}'
        fi
        ;;
      instructions)
        if [ "$dry_run" = true ]; then
          # Probes fail
          echo "ERROR: Dry-run probe failed" >&2
          exit 1
        else
          # Real gen succeeds
          if [ -n "$output_path" ]; then
            mkdir -p "$(dirname "$output_path")"
            echo "# Generated" > "$output_path"
          fi
          echo "Generated despite probe failures"
        fi
        ;;
    esac
    ;;

  gen-fail)
    case "$subcommand" in
      analyze|readiness)
        echo '{"status": "ok"}'
        ;;
      instructions)
        if [ "$dry_run" = true ]; then
          cat <<'JSON'
{"strategy": "flat", "wouldGenerate": true}
JSON
        else
          echo "ERROR: Generation failed" >&2
          echo "Partial output may exist" >&2
          # Don't create output file - simulating failed generation
          exit 1
        fi
        ;;
    esac
    ;;

  partial-output)
    case "$subcommand" in
      instructions)
        if [ "$dry_run" = false ] && [ -n "$output_path" ]; then
          mkdir -p "$(dirname "$output_path")"
          # Write partial/corrupted output
          echo "# Partial Instructions" > "$output_path"
          echo "This output is incomplete..." >> "$output_path"
          echo "ERROR: Generation incomplete" >&2
          exit 1
        fi
        ;;
      *)
        echo '{"status": "ok"}'
        ;;
    esac
    ;;

  *)
    echo "Unknown behavior: $FAKE_AGENTRC_BEHAVIOR" >&2
    exit 1
    ;;
esac

exit 0
