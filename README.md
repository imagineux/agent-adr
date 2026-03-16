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

The `tests/` directory contains:
- `smoke-test.sh` - Simple test harness for core safety features
- `fake-agentrc.sh` - Complex agentrc simulator (legacy)

Run tests with `KEEP_TEST_ARTIFACTS=1` to preserve test output for inspection.

## Design principles

- Small surface area
- Explicit evidence handling
- Honest uncertainty reporting
- Constraint-first recommendations
- No overengineering
- Enterprise-safe operation
