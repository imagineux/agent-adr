# Skill: Compose AI Enablement ADR

## Purpose
Produce a repository-specific AI enablement ADR from a collection bundle, while treating low-tier instruction output as optional and fallible evidence.

## Required Inputs
- `analyze.json`
- `readiness.json`
- Probe status/results under `probes/`
- Generation status/results under `generated/`
- Diagnostics logs under `logs/` and `diagnostics/`
- Context files under `context/`
- ADR template (`templates/ai-enablement-adr-template.md`)

## Synthesis Method
1. Build an evidence inventory with pass/fail/missing markers.
2. Separate factual observations from inferences and unknowns.
3. Assess engineering maturity before AI enablement ambition.
4. Treat generation failures as first-class process signals.
5. Recommend phased, constraint-first changes with owners.
6. Map each major recommendation back to concrete evidence.

## Anti-Patterns
- Invented telemetry or adoption statistics.
- Generic best-practice sludge without repo evidence.
- Assuming generated instructions are good because they exist.
- Over-recommending MCP or advanced agents too early.
- Failing to distinguish facts/inferences/unknowns.
- Ignoring collection failures and diagnostics.

## Output Contract
- Complete ADR with all template sections filled.
- Evidence map and confidence labels for key recommendations.
- 30/60/90 day practical roadmap.
- Explicit non-goals and caveats.

## Quality Bar
- Consulting-grade clarity and prioritization.
- Every material claim grounded in artifact evidence.
- Actionable recommendations suitable for next sprint planning.
- Honest uncertainty handling (no false precision).
