# agent-adr (thin `agentrc` wrapper)

A minimal operator utility for collecting repository evidence with [`microsoft/agentrc`](https://github.com/microsoft/agentrc) and building a high-quality ADR synthesis prompt for stronger reasoning models.

## What this repo is (and is not)

This repo is intentionally **thin**.

- ✅ Uses `agentrc` as a scanner/collector in the **client environment**.
- ✅ Optionally attempts `agentrc instructions` generation (best effort).
- ✅ Stores all collected artifacts in a directory **outside** the client repo.
- ✅ Builds a large, structured prompt bundle with our own synthesis templates.
- ✅ Includes a reusable ADR template + synthesis skill.

- ❌ Not a full CLI platform.
- ❌ Not a reimplementation of `agentrc`.
- ❌ Not coupled to the Copilot SDK.
- ❌ Not writing into the client repo during normal collection.

## Why this exists

We use `agentrc` only as an artifact collector and optional instruction generator.

We own:
- Collection runbook
- Prompt templates
- ADR template
- Final synthesis layer and recommendations

We do **not** delegate final recommendations or ADR authorship to `agentrc`.

## Workflow model

1. **Collect in client environment** using `scripts/collect-agentrc.sh`.
2. Review output artifacts and logs.
3. **Synthesize in our environment** with `scripts/build-strong-model-prompt.mjs`.
4. Paste prompt into a stronger model (Kimi K2.5, SWE-1.5, GPT-5.4 Pro, etc.).
5. Review and deliver a repo-specific AI enablement ADR.

## Prerequisites

- Bash
- Node.js (for prompt builder; stdlib only)
- `npx` able to run `github:microsoft/agentrc`

## Happy path

```bash
# 1) Collect artifacts from a client repo into a separate directory
./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-repo-name

# 2) Inspect collection outputs
find ./collections/client-repo-name -maxdepth 3 -type f | sort

# 3) Build strong-model prompts
node scripts/build-strong-model-prompt.mjs --collection ./collections/client-repo-name --out ./collections/client-repo-name/prompts

# 4) Paste synthesis prompt into Kimi / SWE / GPT-5.4 Pro
# 5) Optionally run review prompt against first-pass ADR
# 6) Review generated ADR, refine if needed, deliver
```

## Safety and Hardening

This wrapper has been hardened for enterprise use:

- **Repo Boundary Guard**: Collection will abort if the output directory is inside the client repo (prevents accidental repo contamination)
- **Argv-based Command Execution**: Commands are executed via arrays rather than string eval, making them safe for paths with spaces, `$`, backticks, or quotes
- **Deterministic Smoke Tests**: Test harness with fake agentrc shim simulates success/failure scenarios
- **Failure Robustness**: Collection continues across probe/generation failures; all artifacts produce status/log files even on failure

## Core scripts

### `scripts/collect-agentrc.sh`

Usage:
```bash
./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-repo-name
```

What it does:
- Enforces `AGENTRC_DEBUG_COPILOT=1`
- Preserves `AGENTRC_COPILOT_CLI_PATH` if provided
- Overrides model for instruction flow (default: `gpt-5-mini`)
- Captures stdout/stderr/exit/status for analyze/readiness/probes/generation attempts
- Copies context files best-effort
- Writes summary + notes
- Aborts if output directory would be inside the client repo

### `scripts/build-strong-model-prompt.mjs`

Usage:
```bash
node scripts/build-strong-model-prompt.mjs --collection ./collections/client-repo-name --out ./collections/client-repo-name/prompts
```

What it does:
- Loads collection artifacts and context
- Labels missing artifacts explicitly
- Injects JSON and markdown into template placeholders
- Produces deterministic final prompt files ready for strong-model synthesis

Outputs:
- `prompts/adr-synthesis-prompt.md`
- `prompts/adr-review-prompt.md`

## Output artifacts

A typical collection includes:
- `analyze.json`
- `readiness.json`
- `collection-summary.json`
- `instructions-overview.md`
- Probe and generation attempts with status/logs
- `context/` (best-effort copied files)
- `prompts/` (built synthesis and review prompts)

See `examples/sample-collection-layout.md`.

## Templates and skill

- `templates/ai-enablement-adr-template.md` — structured ADR output contract
- `templates/strong-model-synthesis-template.md` — generic strong-model synthesis prompt
- `templates/strong-model-review-template.md` — adversarial review prompt
- `skills/compose-ai-enablement-adr.md` — reusable ADR composition skill/instructions

## Testing

The `tests/` directory contains comprehensive testing infrastructure:

### Confidence Harness (Recommended)
```bash
# Run full confidence test suite
./tests/smoke-test-confidence.sh

# Keep artifacts for inspection
KEEP_TEST_ARTIFACTS=1 ./tests/smoke-test-confidence.sh
```

**What the confidence harness proves:**
- ✅ Wrapper collects artifacts correctly across all scenarios
- ✅ Failures are preserved and surfaced in prompts  
- ✅ Repo boundary guard prevents contamination
- ✅ Paths with spaces/special characters work safely
- ✅ Prompt builder handles missing/failure artifacts gracefully
- ✅ Deterministic behavior (no randomness or external dependencies)

**What it does NOT prove:**
- ❌ Real `agentrc` behavior or output quality
- ❌ Actual Copilot CLI integration
- ❌ Network connectivity to AI services
- ❌ Production environment performance

### Test Scenarios Covered
1. **Success Path**: Full successful collection with all probes and generations
2. **Analyze Failure**: analyze fails but collection continues
3. **Probe Failures**: dry-run probes fail but real generation succeeds  
4. **Generation Failures**: real generation fails with proper error capture
5. **Partial Output**: Generation creates file but reports failure
6. **Network Errors**: Connectivity issues handled gracefully
7. **Repo Boundary Guard**: Output inside repo is rejected
8. **Path Safety**: Paths with spaces and special characters
9. **Prompt Builder**: Both synthesis and review prompts generated correctly
10. **Missing Files**: Failed generations marked as "(missing)" in prompts
11. **Context Copying**: Context files copied when available
12. **Deterministic Behavior**: Same inputs produce same outputs

### Test Utilities
- `test-utils.sh` - Common assertion and validation functions
- `create-fixtures.sh` - Generate test repositories with different characteristics

### Running Tests in CI
```bash
# CI-friendly execution (no artifacts kept)
./tests/smoke-test-confidence.sh

# Using Makefile (recommended)
make test

# With timeout for CI environments
timeout 300 make test || exit 1

# Keep artifacts for debugging
KEEP_TEST_ARTIFACTS=1 make test
make test-keep-artifacts
```

### Quick Test Commands
```bash
# Fast confidence check
make test

# Inspect test artifacts  
make test-keep-artifacts
ls -la /tmp/agent-adr-confidence-*/

# Clean up
make clean
```

All tests run in < 30 seconds without network dependencies, making them ideal for CI pipelines.

## Client Deployment Guide

This section helps consultants deploy agent-adr in client environments for maximum value.

### Quick Setup Options

**Option 1: Subtree (Repeat Clients)**
```bash
# In client repo - integrates agent-adr as part of their codebase
git subtree add --prefix=tools/agent-adr https://github.com/imagineux/agent-adr.git main --squash
cd tools/agent-adr && make test && cd ../..
```

**Option 2: Copy-and-Forget (One-off Assessments)**
```bash
# Simple copy - no Git complexity
git clone https://github.com/imagineux/agent-adr.git /tmp/agent-adr
cp -r /tmp/agent-adr/scripts /tmp/agent-adr/tests /tmp/agent-adr/templates /tmp/agent-adr/skills ./tools/
cp /tmp/agent-adr/Makefile ./tools/
echo "tools/" >> .gitignore
rm -rf /tmp/agent-adr
```

**Option 3: Simple Wrapper Script**
```bash
# Create client-friendly wrapper in repo root
cat > collect-evidence.sh <<'SCRIPT'
#!/usr/bin/env bash
echo "🔍 Collecting AI enablement evidence..."
./tools/agent-adr/scripts/collect-agentrc.sh . ./collections/$(basename "$PWD")
echo "📊 Building analysis prompts..."
node ./tools/agent-adr/scripts/build-strong-model-prompt.mjs \
  --collection ./collections/$(basename "$PWD") \
  --out ./collections/$(basename "$PWD")/prompts
echo "✅ Collection complete! Check ./collections/$(basename "$PWD")"
SCRIPT
chmod +x collect-evidence.sh
```

### Choosing Your Deployment Method

| Method | Best For | Pros | Cons |
|--------|----------|------|------|
| **Subtree** | Repeat clients, ongoing relationships | Version tracking, easy updates | Requires Git knowledge |
| **Copy-and-Forget** | One-off assessments, security-conscious | Zero Git complexity, works offline | Manual updates required |
| **Wrapper Script** | Simple client experience | One-command operation | Additional setup step |

### Recommended Directory Structure
```
client-repo/
├── src/
├── package.json
├── .gitignore  ← Contains "tools/" (if copy-and-forget)
├── collect-evidence.sh  ← Simple wrapper (optional)
└── tools/agent-adr/  ← Agent-ADR tools
    ├── scripts/
    ├── tests/
    ├── templates/
    ├── skills/
    └── Makefile
```

### Verification Steps
```bash
# Test that everything works
cd tools/agent-adr
make test

# Test collection on client repo
cd ../..
./tools/agent-adr/scripts/collect-agentrc.sh . ./collections/test-run
ls -la ./collections/test-run/
```

## Client Workflow Strategy

### Phase 1: Collection (On-site)
```bash
# 1. Quick confidence check
make test

# 2. Collect evidence from client repo
./tools/agent-adr/scripts/collect-agentrc.sh . ./collections/client-name

# 3. Immediate inspection
cat ./collections/client-name/collection-summary.json
cat ./collections/client-name/instructions-overview.md
```

**What to look for:**
- Generation success/failure patterns
- Missing context files (quick wins)
- Error patterns and blockers

### Phase 2: Analysis (Your Environment)
```bash
# 4. Build prompts
node ./tools/agent-adr/scripts/build-strong-model-prompt.mjs \
  --collection ./collections/client-name \
  --out ./collections/client-name/prompts

# 5. Review prompt quality
grep -A 5 -B 5 "missing\|failed\|error" ./collections/client-name/prompts/adr-synthesis-prompt.md
```

### Phase 3: Synthesis (Strong Model)
- Paste `adr-synthesis-prompt.md` into Kimi K2.5/SWE-1.5/GPT-5.4 Pro
- Get first-pass ADR
- Review for evidence-based recommendations

### Phase 4: Review (Quality Assurance)
- Run `adr-review-prompt.md` against first-pass ADR
- Incorporate adversarial feedback
- Finalize recommendations

## Maximizing Client Value

### Evidence-Based Recommendations
```bash
# Use actual generated instructions as discussion starters
cat ./collections/client-name/generated/flat-root/copilot-instructions.generated.md

# Show concrete failure modes
find ./collections/client-name -name "*.log" -exec grep -l "ERROR\|FAIL" {} \;

# Highlight missing context as quick wins
ls -la ./collections/client-name/context/
```

### Communication Strategy

**Position as Evidence Collection, Not Assessment**
- ✅ "We're collecting facts about your current setup"
- ✅ "This uses your actual codebase, not generic templates"
- ✅ "Failures are valuable diagnostics, not problems"

**What to Emphasize**
- Real context from their codebase
- Concrete examples from their files
- Practical, implementable next steps
- Honest uncertainty where evidence is incomplete

**What to Downplay**
- Specific AI model capabilities
- Technical implementation details
- Perfect automation expectations

### Success Indicators

**Good Client Engagement**
- Client asks "What would it take to fix X?"
- Client wants to see generated instructions
- Client shares results with their team
- Client requests portfolio analysis

**Red Flags**
- Client focuses on tool limitations
- Client expects instant AI solutions
- Client wants to skip evidence review
- Client has no context files to copy

## Practical Tips & Tricks

### Baseline Establishment
```bash
# Always collect before any AI enablement work
./tools/agent-adr/scripts/collect-agentrc.sh . ./collections/baseline-$(date +%Y-%m-%d)

# Use for comparison later
diff -r ./collections/baseline-2024-01-01 ./collections/after-changes/
```

### Portfolio Analysis
```bash
# Run across multiple repos
for repo in client-repo-1 client-repo-2 client-repo-3; do
  cd ../$repo
  ./tools/agent-adr/scripts/collect-agentrc.sh . ./collections/portfolio-analysis
  cd -
done

# Compare patterns
find . -name "collection-summary.json" -exec grep -l "anyGeneratedOutput.*true" {} \;
```

### Iterative Improvement
```bash
# Track progress over time
./tools/agent-adr/scripts/collect-agentrc.sh . ./collections/iteration-1
# ... make improvements ...
./tools/agent-adr/scripts/collect-agentrc.sh . ./collections/iteration-2

# Compare maturity progression
jq '.dryRun.flatRoot.success' ./collections/iteration-1/collection-summary.json
jq '.dryRun.flatRoot.success' ./collections/iteration-2/collection-summary.json
```

### Common Troubleshooting

**Node.js Issues**
```bash
# Check Node version
node --version  # Should be 16+

# Install dependencies if needed
npm install -g npx
```

**Permission Issues**
```bash
# Make scripts executable
chmod +x tools/agent-adr/scripts/collect-agentrc.sh
chmod +x tools/agent-adr/tests/smoke-test-confidence.sh
```

**Path Issues**
```bash
# Test with spaces in path
mkdir -p "test with spaces"
./tools/agent-adr/scripts/collect-agentrc.sh . "./collections/test with spaces"
```

## Design Principles

- Small surface area
- Explicit evidence handling
- Honest uncertainty reporting
- Constraint-first recommendations
- No overengineering
- Enterprise-safe operation
