# Agent Readiness ADR Kit

A thin, practical layer on top of [`agentrc`](https://github.com/microsoft/agentrc) for repository-specific AI enablement recommendations.

## What this repo is

This repo does **not** reimplement `agentrc`.

It owns only:
- a runbook for collecting `agentrc` artifacts in a client environment
- an ADR template for AI enablement decisions
- reusable synthesis instructions/skills for turning artifacts into an ADR
- a Kimi K2-focused meta-prompt for high-quality ADR drafting

## Operating model

1. **Client environment (collection):**
   - run `agentrc` commands (`analyze`, `readiness`, optional `instructions`/generation)
   - save outputs to `.agent-readiness-collection/`
2. **Our environment (synthesis):**
   - review gathered artifacts
   - apply the ADR template
   - use synthesis skill/prompt with a strong model (e.g., ChatGPT, Kimi K2, SWE-1.5)
   - produce a repo-specific AI enablement ADR

Core assumption: `agentrc` is an external, experimental dependency used for collection/generation signals, while this repo handles guidance, normalization, and ADR synthesis.

## Main output

A practical ADR that answers:
- what the repo appears to be and how mature it is
- current AI readiness/adoption signals
- governance and constraint signals
- what instructions/skills/workflows to add next
- what the team should learn next
- what experiments validate improved AI enablement

## Repository contents

- `docs/agentrc-collection-runbook.md` — operator guide for artifact collection in client repos
- `templates/ai-enablement-adr-template.md` — ADR template for repo-specific recommendations
- `skills/compose-ai-enablement-adr.md` — reusable synthesis skill/instructions
- `prompts/kimi-k2-ai-enablement-adr.md` — Kimi K2 meta-prompt for ADR generation
- `examples/sample-artifact-layout.md` — sample artifact bundle structure
- `scripts/example-collect.sh` — optional lightweight collection script

## Scope boundaries

This repo intentionally does **not** include:
- a full TypeScript CLI
- a full agent orchestration system
- Copilot SDK dependency
- direct client-repo modification as part of the core flow
