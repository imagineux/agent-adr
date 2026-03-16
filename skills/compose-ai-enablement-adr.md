# Skill: Compose Repo-Specific AI Enablement ADR

## Purpose

Convert collected repository artifacts (from `agentrc` and operator notes) into a practical, evidence-based ADR that recommends the **next best** AI enablement steps for a single repository.

This skill optimizes for:
- factual accuracy
- honest uncertainty handling
- phased recommendations
- operational usefulness for engineering teams

## Required Inputs

Minimum:
- `analyze.json`
- `readiness.json`

Recommended:
- `instructions.md` (or failure log)
- optional MCP / VS Code generation outputs
- repository notes (README summary, stack summary, known constraints)

If required inputs are missing, explicitly report insufficiency and produce a constrained draft with clear assumptions.

## Synthesis Rules

1. **Facts first, interpretation second**
   - Extract observable facts from artifacts.
   - Label inferences separately.

2. **Separate repo-local evidence from enterprise assumptions**
   - Do not claim org-wide Copilot/AI adoption based on local files alone.
   - Treat readiness outputs as indicators, not definitive truth.

3. **Handle missing telemetry honestly**
   - Explicitly list unknowns.
   - Explain decision impact of each unknown.

4. **Use maturity-aligned recommendations**
   - Immature repos: prioritize documentation clarity, safe instructions, low-risk workflow improvements.
   - Mature repos: layer in reusable skills, tighter governance, experiment-driven automation.

5. **Constraint-first prioritization**
   - Respect compliance/security/change-control constraints before proposing acceleration.

6. **Phased plan over big-bang plan**
   - Recommend staged investments (now/next/later).

7. **Actionability requirement**
   - Each recommendation should identify likely owner, effort, dependencies, and measurable outcome.

## Anti-Patterns (Do Not Do)

- Do not invent repo details not present in artifacts.
- Do not overstate confidence where evidence is thin.
- Do not present generated instructions as already validated in production.
- Do not recommend advanced agentic complexity for immature repos.
- Do not produce generic “AI best practices” without tying them to observed repo signals.
- Do not collapse unknowns into assumptions without labeling them.

## Output Contract

Produce a complete ADR using `templates/ai-enablement-adr-template.md` with all sections filled.

The output must:
- include explicit “Observed repo facts” vs “What is unknown / not inferable”
- include current engineering and AI enablement maturity assessments
- include 8-layer interpretation with immediate gaps and next moves
- provide prioritized investments across:
  - instructions
  - skills
  - workflows
  - governance/guardrails
  - learning/enablement
- define measurable experiments and success metrics
- include risks/caveats and follow-up checkpoints

## Style Guidance

- Tone: practical, consulting-grade, no hype.
- Use concise, concrete language.
- Prefer bullets/tables over long narrative blocks.
- Be specific about confidence and evidence quality.
- Recommend the smallest useful next step before advanced patterns.
- Highlight tradeoffs and sequencing decisions.

## Suggested Workflow

1. Parse artifacts and draft a fact inventory.
2. Build unknowns list and confidence annotations.
3. Score engineering and AI maturity at a coarse level (1–5).
4. Map findings across the 8 maturity layers.
5. Draft decision + phased recommendations.
6. Add experiments, metrics, and checkpoints.
7. Run a final anti-pattern check before publishing.
