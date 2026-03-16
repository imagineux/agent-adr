# Kimi K2 Meta-Prompt: Generate Repo-Specific AI Enablement ADR

Use this prompt with Kimi K2 after collecting artifacts from a client environment.

---

You are generating an **AI enablement Architecture Decision Record (ADR)** for a single software repository.

Your job is to synthesize evidence from provided artifacts and produce a practical, phased recommendation set.

## Critical operating constraints

- Treat `agentrc` outputs as experimental signals, not ground truth.
- Do not invent facts that are not present in the artifacts.
- Do not overstate confidence.
- Do not claim enterprise-wide Copilot/AI adoption from repo-local evidence.
- Do not assume generated instructions are production-validated.
- Do not recommend high-complexity agentic systems for immature repos.
- Avoid generic best-practice filler; tie every recommendation to observed evidence.
- Prefer phased, constraint-first recommendations over broad transformation plans.

## Inputs (paste below)

### 1) analyze.json

```json
[PASTE analyze.json HERE]
```

### 2) readiness.json

```json
[PASTE readiness.json HERE]
```

### 3) instructions output (optional)

```markdown
[PASTE instructions.md OR FAILURE NOTES HERE]
```

### 4) optional MCP / VS Code generation outputs

```text
[PASTE mcp / vscode outputs HERE]
```

### 5) optional repo notes

```markdown
[PASTE README SUMMARY, STACK NOTES, KNOWN CONSTRAINTS HERE]
```

## Task

1. Read all artifacts carefully.
2. Identify:
   - what the repo appears to be
   - engineering maturity signals
   - current AI enablement maturity signals
   - governance/constraint signals
   - unknowns and evidence gaps
3. Recommend the **first best** AI enablement moves for this repo.
4. Recommend what the team should learn next.
5. Propose measurable experiments to validate improvement.
6. Generate a complete ADR using the exact structure below.

## Required ADR structure

Use these headings exactly:

- Title
- Status
- Date
- Repository
- Context
- Observed repo facts
- What is unknown / not inferable
- Current engineering maturity
- Current AI enablement maturity
- Governance / constraints
- 8-layer maturity interpretation
- Decision
- Recommended next investments
  - instructions
  - skills
  - workflows
  - governance / guardrails
  - learning / enablement
- Suggested artifacts to add
- Experiments to validate improvement
- Success metrics
- Risks / caveats
- Consequences
- Follow-up checkpoints

## Writing quality bar

- Be specific and operational.
- Label assumptions explicitly.
- Distinguish facts vs inferences.
- Include confidence where evidence is weak.
- Keep recommendations realistically scoped for the observed maturity.
- Do not recommend too much at once; prioritize.

Now produce the ADR.
