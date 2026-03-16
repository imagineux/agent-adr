# Skill: Compose AI Enablement ADR

## Purpose

Compose a repository-specific AI enablement ADR from mixed evidence (scanner outputs, repo context, and evaluator notes) with clear confidence boundaries and practical sequencing.

## Required Inputs

- `collection-summary.json`
- `analyze.json`
- `readiness.json`
- `instructions-status.json`
- `copilot-instructions.generated.md` (optional)
- copied context files from `collection/context/` (optional)
- evaluator notes (`notes.md`, optional)
- ADR scaffold (`templates/ai-enablement-adr-template.md`)

## Synthesis Steps

1. **Establish evidence base**
   - Enumerate artifacts present vs missing.
   - Note confidence implications of missing telemetry.
2. **Separate fact from inference**
   - Record explicit facts first.
   - Derive interpretations second.
3. **Assess current maturity**
   - Engineering maturity (delivery hygiene, testing, ownership, docs).
   - AI enablement maturity (instructions, evals, workflows, safety).
4. **Map constraints**
   - Security/compliance/platform/team constraints.
   - Operational limits that affect recommendation feasibility.
5. **Decide and sequence**
   - Recommend phased, constraint-first next investments.
   - Keep scope narrow enough for adoption.
6. **Define validation loop**
   - Propose experiments and measurable outcomes.
   - Include checkpoint cadence and ownership.

## Anti-Patterns

- Invented telemetry or fabricated adoption statistics.
- Generic “best practices” wallpaper detached from repo evidence.
- Treating missing files as automatic dysfunction without nuance.
- Assuming generated instructions are high quality just because they exist.
- Recommending too many simultaneous changes with no adoption path.

## Output Contract

Produce one markdown ADR that:
- follows the provided ADR template exactly
- is repo-specific and evidence-linked
- clearly states unknowns/limits
- includes phased recommendations (now / next / later)
- includes experiments, success metrics, and follow-up checkpoints

## Quality Bar

- Consulting-grade: direct, specific, and pragmatic.
- Evidence-grounded: every material claim traceable to artifact evidence.
- Honest uncertainty: confidence labels where evidence is thin.
- Operationally realistic: recommendations fit team maturity and constraints.
