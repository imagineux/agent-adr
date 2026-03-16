# AI Enablement ADR Kit (Thin Layer on `agentrc`)

This repository is a **thin, practical layer** on top of [`microsoft/agentrc`](https://github.com/microsoft/agentrc).

It does **not** reimplement `agentrc`, orchestrate agent workflows, or write directly into client repositories.

## What this repo owns

- A runbook for collecting repository readiness artifacts in a **client environment**
- A reusable ADR template for **repo-specific AI enablement recommendations**
- A synthesis skill/prompt for turning artifacts into a grounded ADR
- A Kimi K2–specific meta-prompt for ADR generation

## Operating model

1. **Collection happens in the client environment**
   - Run `agentrc` commands (`analyze`, `readiness`, `instructions`, optional generators)
   - Save outputs into a temporary artifact folder (for example, `.agent-readiness-collection/`)

2. **Synthesis happens in our environment**
   - Review the collected artifacts
   - Apply the ADR template
   - Use a strong model with the synthesis skill/prompt
   - Produce a repo-specific AI enablement ADR

## Primary output

The main output is a practical ADR that explains:

- What the repository appears to be and how mature it is
- Current AI readiness/adoption signals (and unknowns)
- Constraints and governance implications
- Recommended next investments (instructions, skills, workflows, guardrails, learning)
- Validation experiments and success metrics

## Start here

- Runbook: `docs/agentrc-collection-runbook.md`
- ADR template: `templates/ai-enablement-adr-template.md`
- Synthesis skill: `skills/compose-ai-enablement-adr.md`
- Kimi K2 prompt: `prompts/kimi-k2-ai-enablement-adr.md`
- Example artifact bundle layout: `examples/sample-artifact-layout.md`
- Optional helper script: `scripts/example-collect.sh`
