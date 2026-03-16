# Skill: Compose a Repo-Specific AI Enablement ADR

## Purpose

Convert a collected artifact bundle (from `agentrc` and supplemental notes) into a practical, evidence-based ADR that recommends the next best AI enablement moves for one repository.

This skill prioritizes:

- factual grounding
- explicit unknowns
- phased recommendations
- measurable experiments

## Required inputs

Minimum:

- `analyze.json`
- `readiness.json`
- repository notes (README/docs summary if artifacts are sparse)

Optional:

- `instructions.md` from `agentrc instructions --dry-run`
- outputs from `generate mcp` / `generate vscode`
- operator notes on command failures or odd behavior

## Synthesis rules

1. **Facts first, then interpretation**
   - Extract explicit facts from artifacts.
   - Tag each important claim with confidence (high/medium/low).
   - Keep interpretation separate from observation.

2. **Be honest about missing telemetry**
   - If enterprise-wide Copilot/AI adoption is not present, say so.
   - Do not infer organization-wide maturity from one local scan.

3. **Unknowns are first-class output**
   - Include a clear “unknown / not inferable” section.
   - Explain how each unknown could change recommendations.

4. **Maturity-matched recommendations**
   - For immature repos, recommend foundational improvements first.
   - For moderately mature repos, add targeted workflows and guardrails.
   - Reserve advanced agentic patterns for teams with evidence of readiness.

5. **Constraint-first planning**
   - Respect security/compliance/tooling constraints in every recommendation.
   - Prefer low-risk, reversible steps before broad rollout.

6. **Decision quality over volume**
   - Recommend fewer, higher-leverage actions with clear owners and DoD.
   - Avoid laundry lists.

## Anti-patterns (must avoid)

- Inventing repo details not present in artifacts
- Overstating confidence from sparse outputs
- Claiming generated instructions are production-ready without validation
- Recommending advanced autonomous multi-agent systems for low-maturity repos
- Generic best-practice filler disconnected from observed evidence

## Output contract

Produce a complete ADR that includes:

- Repo context and observed facts
- Unknowns and uncertainty handling
- Engineering maturity + AI enablement maturity calls
- Governance/constraint implications
- 8-layer maturity interpretation
- Decision statement
- Recommended investments (instructions, skills, workflows, guardrails, learning)
- Suggested artifacts
- Validation experiments with measurable outcomes
- Success metrics, risks, consequences, and checkpoints

## Style guidance

- Use clear operator language, not academic prose.
- Be specific and pragmatic (“add X file with Y purpose”).
- Keep tone neutral, non-hypey, and non-defensive.
- Mark assumptions explicitly.
- Prefer phased plans:
  - **Phase 1**: baseline instructions + workflow hygiene
  - **Phase 2**: targeted automation + guardrails
  - **Phase 3**: scale experiments if metrics support it

## Guardrail reminders

- Do **not** invent repo details not present in artifacts.
- Do **not** overstate confidence.
- Do **not** recommend advanced agentic complexity for immature repos.
- **Prefer phased, constraint-first recommendations.**
