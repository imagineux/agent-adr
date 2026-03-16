# Kimi K2 Meta-Prompt: Generate Repository AI Enablement ADR

Copy/paste this prompt into Kimi K2 and replace the bracketed sections.

---

You are producing a **repository-specific AI enablement ADR** from collected artifacts.

Your goals:
1. Read artifacts carefully.
2. Distinguish observed facts from interpretations.
3. Assess engineering maturity and AI enablement maturity.
4. Explain constraints and headroom.
5. Recommend the first best AI enablement moves.
6. Recommend what the team should learn next.
7. Generate the ADR using the required template structure.

## Important constraints

- Do **not** invent telemetry or repository details.
- Do **not** pretend organization-wide Copilot adoption is known if only local artifacts are available.
- Do **not** assume generated instructions are already validated.
- Do **not** produce generic best-practice filler.
- Do **not** recommend too much at once.
- Prefer phased, constraint-first recommendations.
- Clearly mark unknowns and assumptions.

## Inputs

### analyze.json

```json
[PASTE_ANALYZE_JSON_HERE]
```

### readiness.json

```json
[PASTE_READINESS_JSON_HERE]
```

### instructions output (optional)

```md
[PASTE_INSTRUCTIONS_MD_OR_ERROR_HERE]
```

### MCP / VS Code outputs (optional)

```text
[PASTE_OPTIONAL_GENERATED_OUTPUTS_HERE]
```

### Additional repo notes (optional)

```md
[PASTE_REPO_NOTES_HERE]
```

## Required output format

Produce a complete ADR with exactly these sections in order:

1. Title
2. Status
3. Date
4. Repository
5. Context
6. Observed repo facts
7. What is unknown / not inferable
8. Current engineering maturity
9. Current AI enablement maturity
10. Governance / constraints
11. 8-layer maturity interpretation
12. Decision
13. Recommended next investments
    - instructions
    - skills
    - workflows
    - governance / guardrails
    - learning / enablement
14. Suggested artifacts to add
15. Experiments to validate improvement
16. Success metrics
17. Risks / caveats
18. Consequences
19. Follow-up checkpoints

## Quality requirements

- Every major claim should be tied to evidence from provided inputs.
- If evidence is missing, say “unknown” and explain impact.
- Include confidence level (Low/Medium/High) for maturity judgments.
- Keep recommendations prioritized and feasible (30/60/90-day horizon).
- Make experiments measurable with baseline, metric, and evaluation window.
- Keep tone practical, sober, and implementation-oriented.

Now generate the ADR.
