# Strong-Model Synthesis Template (AI Enablement ADR)

Use this template when consuming a collection bundle from the thin agentrc wrapper.

## Ground Rules
- Treat agentrc outputs as evidence, not authority.
- Separate **Facts**, **Inferences**, and **Unknowns**.
- Treat dry-run instruction output as suggestion only.
- Treat generated instruction drafts as candidate artifacts, not approved artifacts.
- Explicitly account for generation failures and diagnostics.
- Do not invent Copilot or enterprise adoption metrics.
- Avoid overconfidence; state confidence levels.
- Recommend phased, constraint-first improvement.

## You Must Explicitly Answer
1. What the repo appears to be.
2. Engineering maturity level and rationale.
3. AI enablement signals present/missing.
4. Governance/constraint signals and implications.
5. Readiness for instructions, skills, evals, workflows, MCP.
6. Which low-tier outputs are directionally useful.
7. What must be rewritten by a stronger model.
8. First best next moves.
9. Team learning priorities.
10. Experiments to validate improvement.

## Output Contract
Produce a practical, consulting-grade ADR that is:
- repo-specific
- evidence-anchored
- explicit about uncertainty
- conservative with advanced recommendations
- actionable in phases
