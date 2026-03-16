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
3. **Synthesize in our environment** with `scripts/build-adr-prompt.mjs` + selected template.
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

# 3) Build a synthesis prompt bundle
node scripts/build-adr-prompt.mjs \
  --collection ./collections/client-repo-name \
  --template templates/kimi-k2_5-adr-synthesis-template.md \
  --out ./collections/client-repo-name/adr-synthesis-prompt.md

# 4) Paste prompt into Kimi / SWE / GPT-5.4 Pro
# 5) Review generated ADR, refine if needed, deliver
```

## Core scripts

### `scripts/collect-agentrc.sh`

Usage:

```bash
./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-repo-name
```

What it does:
- Validates inputs.
- Runs required `agentrc` collection commands:
  - `analyze` (JSON)
  - `readiness` (JSON)
- Attempts optional `instructions` generation using:
  - `--output <file> --force` (not `--dry-run`)
- Captures instruction stdout/stderr logs.
- Records instruction step status and exit code.
- Copies optional context files/directories if present.
- Writes summary + notes scaffold.

### `scripts/build-adr-prompt.mjs`

Usage:

```bash
node scripts/build-adr-prompt.mjs \
  --collection ./collections/client-repo-name \
  --template templates/kimi-k2_5-adr-synthesis-template.md \
  --out ./collections/client-repo-name/adr-synthesis-prompt.md
```

What it does:
- Loads collection artifacts and context.
- Labels missing artifacts explicitly.
- Injects JSON and markdown into template placeholders.
- Produces a deterministic final prompt file ready for strong-model synthesis.

## Output artifacts

A typical collection includes:
- `analyze.json`
- `readiness.json`
- `instructions-status.json`
- `copilot-instructions.generated.md` (if generation succeeded)
- `logs/instructions.stdout.log`
- `logs/instructions.stderr.log`
- `context/` (best-effort copied files)
- `collection-summary.json`
- `notes.md`

See `examples/sample-collection-layout.md`.

## Templates and skill

- `templates/ai-enablement-adr-template.md` — structured ADR output contract.
- `templates/llm-adr-synthesis-template.md` — generic strong-model synthesis prompt.
- `templates/kimi-k2_5-adr-synthesis-template.md` — Kimi-optimized copy/paste prompt.
- `skills/compose-ai-enablement-adr.md` — reusable ADR composition skill/instructions.

## Design principles

- Small surface area.
- Explicit evidence handling.
- Honest uncertainty reporting.
- Constraint-first recommendations.
- No overengineering.
