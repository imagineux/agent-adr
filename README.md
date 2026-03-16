# AI Enablement ADR Companion (Thin Layer on `agentrc`)

This repository is a **thin, practical layer** on top of `agentrc`.

It does **not** reimplement `agentrc`, orchestrate end-to-end automation, or directly edit client repositories in the core workflow.

## What this repo owns

1. A markdown runbook for collecting artifacts with `agentrc` in a client environment.
2. A strong ADR template for repository-specific AI enablement decisions.
3. Reusable synthesis guidance (skill/prompt) to convert collected artifacts into an ADR.
4. A Kimi K2-focused meta-prompt for ADR generation.

## Operating model

### 1) In the client environment (collection)

Run:

- `agentrc analyze`
- `agentrc readiness`
- `agentrc instructions` (attempt)
- optional `agentrc generate mcp` / `agentrc generate vscode`

Save outputs into:

- `.agent-readiness-collection/`

### 2) Back in our environment (synthesis)

- Review collected artifacts.
- Apply the ADR template in this repo.
- Use a strong model (ChatGPT, Kimi K2, SWE-1.5, etc.) with the synthesis skill/prompt.
- Produce a **repo-specific AI enablement ADR**.

## Main output

The primary deliverable is a practical ADR that answers:

- what the repository appears to be and how mature it is
- AI readiness/adoption signals present in evidence
- governance/constraint signals
- what instructions/skills/workflows to add next
- what the team should learn next
- which experiments should validate improved AI enablement

## Repository contents

- `docs/agentrc-collection-runbook.md`
- `templates/ai-enablement-adr-template.md`
- `skills/compose-ai-enablement-adr.md`
- `prompts/kimi-k2-ai-enablement-adr.md`
- `examples/sample-artifact-layout.md`

Use these assets together to keep collection lightweight and synthesis rigorous.
