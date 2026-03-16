# Skill: Compose AI Enablement ADR from Collected Artifacts

## Purpose

Produce a repository-specific AI enablement ADR from collected `agentrc` artifacts and repo context notes.

This skill is for **synthesis and decision support**, not code generation in the client repo.

---

## Required inputs

Minimum:

- `analyze.json`
- `readiness.json`

Optional but useful:

- `instructions.md` (or failure log)
- MCP / VS Code generation outputs
- README/docs summary notes
- operator notes about collection quality or constraints

If required inputs are missing, produce a constrained ADR and explicitly identify the missing inputs.

---

## Synthesis rules

1. **Separate facts from inferences.**
   - Facts: directly observed in artifacts.
   - Inferences: reasonable interpretations with confidence labels.

2. **Treat missing telemetry honestly.**
   - If data is absent or failed to generate, state “unknown” clearly.
   - Do not backfill with generic assumptions.

3. **Use conservative confidence.**
   - High confidence only for directly evidenced claims.
   - Medium/low for inferred maturity or adoption signals.

4. **Ground recommendations in repo maturity.**
   - Early maturity repos: prioritize basics (clarity, guardrails, repeatable workflows).
   - Higher maturity repos: add evaluation loops and selective automation.

5. **Constraint-first planning.**
   - Respect governance, security, and change-control boundaries before proposing scale.

6. **Phase recommendations.**
   - Near-term (0–30 days), mid-term (30–90 days), later (90+ days).

7. **Prefer measurable experiments.**
   - Each experiment needs a hypothesis, metric, and decision threshold.

8. **Keep enterprise claims scoped.**
   - Local repo artifacts do **not** prove enterprise-wide Copilot/AI adoption.

---

## Anti-patterns (must avoid)

- Inventing repository details not present in artifacts.
- Overstating confidence or certainty.
- Treating generated `instructions` as validated production guidance.
- Recommending advanced agentic complexity for immature repos.
- Producing generic “best practices” without repo-specific rationale.
- Suggesting direct edits to client repos as part of core collection workflow.

---

## Output contract

Produce one ADR using the repository ADR template and include:

1. Evidence-backed observed facts.
2. Explicit unknowns and data-quality caveats.
3. Engineering maturity and AI enablement maturity judgments with rationale.
4. 8-layer maturity interpretation.
5. A decision statement.
6. Prioritized investments across:
   - instructions
   - skills
   - workflows
   - governance/guardrails
   - learning/enablement
7. Suggested artifacts to add.
8. 2–5 measurable experiments.
9. Success metrics and follow-up checkpoints.

Use concise, operator-friendly language and avoid marketing tone.

---

## Style guidance

- Write like an internal consultant advising a delivery team.
- Be specific, concrete, and implementation-aware.
- Prefer bullet points and short rationale blocks.
- Mark assumptions explicitly.
- Use “unknown” when evidence is insufficient.
- Recommend the **next best step**, not the maximum possible sophistication.
