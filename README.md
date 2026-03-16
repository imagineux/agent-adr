# AI Enablement ADR Kit (Thin Layer on `agentrc`)

This repository is a **thin, practical layer** on top of [`microsoft/agentrc`](https://github.com/microsoft/agentrc).

It does **not** reimplement `agentrc`, and it does **not** directly modify client repositories in the core workflow.

## What this repo owns

This repo owns only the materials needed to turn `agentrc` outputs into a repository-specific AI enablement ADR:

- A collection runbook for operators working in client environments
- An ADR template for AI enablement recommendations
- A reusable synthesis skill/instruction set
- A Kimi K2-tuned meta-prompt for ADR generation
- An example artifact bundle layout

## Workflow model

### 1) Collect artifacts in the client environment
Run `agentrc` commands in the client repository and store outputs in a local collection folder (for example `.agent-readiness-collection/`).

### 2) Bring artifacts back to this environment
Share the collection bundle with this repo/workspace.

### 3) Synthesize an ADR in this environment
Use the ADR template plus the synthesis skill/prompt with a strong model (ChatGPT, Kimi K2, SWE-1.5, etc.) to produce a **repo-specific AI enablement ADR**.

## Main output

The main output is a practical ADR that explains:

- current repository maturity and AI enablement posture
- constraints and governance signals
- near-term instructions/skills/workflow recommendations
- learning priorities
- measurable experiments to validate improvement

## Repository contents

- `docs/agentrc-collection-runbook.md` — operator collection runbook
- `templates/ai-enablement-adr-template.md` — ADR template
- `skills/compose-ai-enablement-adr.md` — synthesis skill/instructions
- `prompts/kimi-k2-ai-enablement-adr.md` — Kimi K2 meta-prompt
- `examples/sample-artifact-layout.md` — sample artifact bundle structure
- `scripts/example-collect.sh` — optional helper script for collection

## Important boundaries

- `agentrc` is treated as an **external, experimental dependency** used only for data collection/generation.
- This repo is responsible for **guidance, normalization, and synthesis**.
- The core flow does **not** depend on writing changes directly into client repos.
