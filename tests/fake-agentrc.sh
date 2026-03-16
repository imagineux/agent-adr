#!/usr/bin/env bash
# Enhanced fake agentrc shim for confidence testing
# Simulates various behaviors with deterministic, predictable outputs

set -uo pipefail

# Behavior control via environment variables
FAKE_AGENTRC_BEHAVIOR="${FAKE_AGENTRC_BEHAVIOR:-success}"
FAKE_AGENTRC_DELAY="${FAKE_AGENTRC_DELAY:-0}"
FAKE_AGENTRC_EXIT_DELAY="${FAKE_AGENTRC_EXIT_DELAY:-0}"

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

# Helper to generate consistent timestamps
fake_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Generate deterministic outputs based on behavior and subcommand
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
  "hasCI": true,
  "hasTests": true,
  "hasDocs": true,
  "confidence": "high"
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
  "recommendations": ["Add AGENTS.md", "Add copilot-instructions.md"],
  "confidence": "medium"
}
JSON
        else
          echo "Readiness check: PASSED (score: 75/100)"
        fi
        ;;
      instructions)
        if [ "$dry_run" = true ]; then
          # Dry-run returns JSON probe result
          cat <<JSON
{
  "strategy": "${strategy:-flat}",
  "model": "${model:-gpt-5-mini}",
  "areas": $areas,
  "wouldGenerate": true,
  "estimatedTokens": 1200,
  "confidence": "high"
}
JSON
        else
          # Real generation - write to output file
          if [ -n "$output_path" ]; then
            mkdir -p "$(dirname "$output_path")"
            cat > "$output_path" <<'MD'
# Generated Copilot Instructions

## Repository Context
- Type: Node.js application with Express framework
- Languages: TypeScript, JavaScript
- Testing: Jest
- Package Manager: npm
- CI/CD: GitHub Actions

## Development Guidelines
1. Follow existing TypeScript patterns and naming conventions
2. Write unit tests for new features using Jest
3. Update API documentation in README.md
4. Use semantic versioning for releases
5. Follow GitFlow branching strategy

## Code Style
- Use Prettier for code formatting
- Follow ESLint rules
- Add JSDoc comments for public functions
- Prefer functional programming patterns

## Testing Requirements
- Maintain >80% test coverage
- Write integration tests for API endpoints
- Mock external dependencies in unit tests
- Add tests for bug fixes

## Security Considerations
- Validate all user inputs
- Use environment variables for secrets
- Implement proper error handling
- Follow OWASP security guidelines

## Performance Guidelines
- Optimize database queries
- Implement caching where appropriate
- Monitor application performance
- Use async/await for asynchronous operations
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
        echo "ERROR: Failed to analyze repository - unable to detect project structure" >&2
        echo "DEBUG: Could not find package.json or other project markers" >&2
        exit 1
        ;;
      readiness)
        if [ "$json_output" = true ]; then
          cat <<'JSON'
{
  "ready": false,
  "score": 30,
  "issues": ["No README.md", "Missing test framework", "No CI configuration"],
  "recommendations": [],
  "confidence": "low"
}
JSON
        else
          echo "Readiness: POOR (30/100) - missing critical files"
        fi
        ;;
      instructions)
        if [ "$dry_run" = true ]; then
          cat <<JSON
{
  "strategy": "${strategy:-flat}",
  "model": "${model:-gpt-5-mini}",
  "areas": $areas,
  "wouldGenerate": true,
  "estimatedTokens": 800,
  "confidence": "low"
}
JSON
        else
          if [ -n "$output_path" ]; then
            mkdir -p "$(dirname "$output_path")"
            cat > "$output_path" <<'MD'
# Basic Instructions

Limited instructions generated due to analysis failure.

Add basic documentation and tests.
MD
          fi
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
          cat <<'JSON'
{"repoType": "node", "confidence": "medium"}
JSON
        else
          cat <<'JSON'
{"ready": true, "score": 80, "confidence": "medium"}
JSON
        fi
        ;;
      instructions)
        if [ "$dry_run" = true ]; then
          # Probes fail with specific error
          echo "ERROR: Dry-run probe failed - model unavailable or network error" >&2
          echo "DEBUG: Failed to connect to AI service, timeout after 30s" >&2
          exit 1
        else
          # Real gen succeeds
          if [ -n "$output_path" ]; then
            mkdir -p "$(dirname "$output_path")"
            cat > "$output_path" <<'MD'
# Generated Instructions

Instructions generated despite probe failures.

## Basic Guidelines
1. Write clean code
2. Add tests
3. Document changes
MD
          fi
          echo "Generated despite probe failures"
        fi
        ;;
    esac
    ;;

  gen-fail)
    case "$subcommand" in
      analyze|readiness)
        if [ "$subcommand" = "analyze" ]; then
          cat <<'JSON'
{"repoType": "node", "confidence": "high"}
JSON
        else
          cat <<'JSON'
{"ready": true, "score": 85, "confidence": "high"}
JSON
        fi
        ;;
      instructions)
        if [ "$dry_run" = true ]; then
          cat <<JSON
{
  "strategy": "${strategy:-flat}",
  "model": "${model:-gpt-5-mini}",
  "areas": $areas,
  "wouldGenerate": true,
  "estimatedTokens": 1000,
  "confidence": "medium"
}
JSON
        else
          echo "ERROR: Generation failed - AI service returned error" >&2
          echo "DEBUG: HTTP 429: Rate limit exceeded, retry after 60s" >&2
          echo "DEBUG: Model gpt-5-mini currently overloaded" >&2
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
          cat > "$output_path" <<'MD'
# Partial Instructions

This output is incomplete due to generation interruption.

## Repository Context
- Type: Node.js application

## Guidelines
1. Follow existing patterns
2. 
MD
          echo "ERROR: Generation incomplete - service interrupted mid-generation" >&2
          echo "DEBUG: Connection lost after 45% completion" >&2
          exit 1
        fi
        ;;
      *)
        # Other commands succeed
        echo '{"status": "ok", "confidence": "medium"}'
        ;;
    esac
    ;;

  network-error)
    case "$subcommand" in
      instructions)
        echo "ERROR: Network connectivity issues" >&2
        echo "DEBUG: DNS resolution failed for api.openai.com" >&2
        echo "DEBUG: Check network connectivity and proxy settings" >&2
        exit 1
        ;;
      *)
        echo '{"status": "ok", "confidence": "low"}'
        ;;
    esac
    ;;

  *)
    echo "Unknown behavior: $FAKE_AGENTRC_BEHAVIOR" >&2
    echo "Available behaviors: success, analyze-fail, probe-fail, gen-fail, partial-output, network-error" >&2
    exit 1
    ;;
esac

# Simulate exit delay if requested
if [ "$FAKE_AGENTRC_EXIT_DELAY" -gt 0 ] 2>/dev/null; then
  sleep "$FAKE_AGENTRC_EXIT_DELAY"
fi

exit 0
