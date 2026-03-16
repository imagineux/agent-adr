# Kimi K2.5 Prompt: Repository AI Enablement ADR Synthesis

You are acting as a principal consultant for AI enablement in software delivery organizations.

Produce a high-quality, repository-specific ADR from the provided evidence.

## Critical Guardrails

- Do not overclaim certainty.
- Do not assume actual Copilot usage from repo files alone.
- Do not infer adoption metrics that are not provided.
- Do not recommend advanced agentic workflows for immature repositories.
- Do not recommend MCP simply because it is fashionable.
- Prefer a maturity staircase: instructions + evals + safe workflows before advanced autonomy.
- Treat generated instructions as optional candidate content, not authoritative truth.

## Reasoning Discipline

- Distinguish facts, interpretations, and assumptions.
- Explicitly mark missing evidence and confidence limits.
- Use the artifacts below as primary evidence.
- If artifacts conflict, call out the conflict and resolve conservatively.

## Deliverable

Return a complete markdown ADR using the included ADR template.
Keep it practical, sequenced, and constraint-aware.
Avoid generic “best practices” wallpaper.

## Required Coverage

- What the repo appears to be.
- Current engineering maturity.
- Current AI enablement maturity.
- Constraints and governance boundaries.
- Readiness for instructions, skills, evals, workflows, MCP.
- First best next moves (prioritized and phased).
- Team learning/upskilling priorities.
- Experiments and success metrics that validate improvement.

---

## Collection Summary

{{COLLECTION_SUMMARY}}

## agentrc Analyze Output

{{ANALYZE_JSON}}

## agentrc Readiness Output

{{READINESS_JSON}}

## Instructions Generation Status

{{INSTRUCTIONS_STATUS}}

## Generated Instructions Content (if available)

{{GENERATED_INSTRUCTIONS}}

## Copied Repository Context Files

{{COPIED_CONTEXT_FILES}}

## Evaluator Notes

{{EVALUATOR_NOTES}}

## ADR Template to Fill

{{ADR_TEMPLATE}}
