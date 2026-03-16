# Skill: Compose Repository AI Enablement ADR

## Purpose

Convert collected `agentrc` artifacts and repo notes into a practical, repository-specific ADR that recommends the **next best AI enablement moves**.

This skill is for synthesis, not data fabrication.

---

## Required inputs

At minimum:

- `analyze.json`
- `readiness.json`

Optional but useful:

- `instructions.md` or `instructions-error.txt`
- generated MCP/VS Code artifacts
- operator notes (`notes.md`)
- repo README/docs summary
- target ADR template (`templates/ai-enablement-adr-template.md`)

If required inputs are missing, state that clearly and proceed with reduced-confidence output.

---

## Synthesis rules

1. **Separate facts from inferences**
   - Facts must map to explicit artifact evidence.
   - Inferences must be labeled as interpretation.

2. **Treat missing telemetry honestly**
   - If enterprise adoption telemetry is unavailable, say so.
   - Do not imply organization-wide Copilot/tool adoption from local repo signals alone.

3. **Use confidence labels**
   - Mark key conclusions with Low/Medium/High confidence.
   - Confidence should reflect evidence quantity and quality.

4. **Prioritize phased recommendations**
   - Start with foundational guidance/guardrails for immature repos.
   - Introduce complexity only when prerequisites exist.

5. **Map recommendations to maturity**
   - Immature repo: prefer simple instructions, minimal workflows, basic measurements.
   - Mature repo: can propose richer skills, tighter integrations, broader experiments.

6. **Propose measurable experiments**
   - Every major recommendation should connect to measurable outcomes.

7. **Align with repository reality**
   - Respect observed stack, team process, and governance signals.

---

## Anti-patterns (do not do these)

- Do not invent repo details not present in artifacts.
- Do not overstate confidence or certainty.
- Do not claim generated instructions are already validated in production.
- Do not recommend advanced agentic orchestration for clearly immature repos.
- Do not dump generic AI best-practice filler detached from observed facts.
- Do not hide unknowns; call them out explicitly.

---

## Output contract

Produce a complete ADR using the template structure with:

1. Evidence-grounded observed facts
2. Explicit unknowns and assumptions
3. Engineering maturity + AI enablement maturity assessment
4. 8-layer interpretation
5. A clear decision statement
6. Prioritized recommendations across:
   - instructions
   - skills
   - workflows
   - governance/guardrails
   - learning/enablement
7. Suggested artifacts to add
8. Experiments with metrics, baselines, and evaluation windows
9. Risks/caveats, consequences, and follow-up checkpoints

When evidence is thin, provide a **minimal viable decision set** with explicit caveats.

---

## Style guidance

- Use direct operator language, not marketing language.
- Be specific about files, owners, and sequencing.
- Keep recommendation count constrained (focus on first best moves).
- Prefer “do this next because …” over abstract frameworks.
- Default to constraint-first recommendations.
