# Skill: Compose AI Enablement ADR

## Purpose

Produce a practical, evidence-grounded AI enablement ADR for a specific repository using collected artifacts (including optional `agentrc` instruction output) without overclaiming certainty.

## Required inputs

- `collection-summary.json`
- `analyze.json`
- `readiness.json`
- `instructions-status.json`
- `copilot-instructions.generated.md` (optional)
- copied `context/` files (optional)
- `notes.md` (optional)
- `templates/ai-enablement-adr-template.md`

## Synthesis steps

1. **Inventory evidence**
   - Confirm what artifacts are present/missing.
   - Mark data-quality issues up front.
2. **Extract facts**
   - Pull concrete, verifiable facts from JSON and context files.
   - Keep facts separate from interpretation.
3. **Interpret maturity**
   - Assess engineering maturity and AI enablement maturity with explicit confidence limits.
4. **Constraint-first planning**
   - Identify governance, risk, capacity, and tooling constraints.
   - Shape recommendations to near-term reality.
5. **Phase recommendations**
   - Prioritize small, high-leverage moves first.
   - Defer advanced autonomy unless readiness is evident.
6. **Define validation**
   - Propose measurable experiments and success metrics.
7. **Write ADR**
   - Fill every ADR section crisply and specifically.

## Anti-patterns

- Invented telemetry (usage numbers, adoption stats, productivity deltas).
- Generic "best practices" wallpaper with no repo tie-in.
- Treating missing files as automatic dysfunction without nuance.
- Assuming generated instructions are good only because they exist.
- Recommending too many changes at once.

## Output contract

- Must follow the ADR template structure exactly.
- Must separate facts, inferences, and recommendations.
- Must include unknowns/limits and confidence caveats.
- Must provide phased next investments and validation experiments.

## Quality bar

- Repo-specific, practical, and implementable within team constraints.
- Honest uncertainty where evidence is incomplete.
- Direct language; no buzzword inflation.
- Recommendations sequenced for adoption, not theater.
