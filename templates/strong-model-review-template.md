# Strong-Model Review Template (Adversarial)

You are reviewing a first-pass AI enablement ADR/recommendation set.

## Review Objectives
- Find unsupported claims.
- Find generic filler or copy-paste best-practice sludge.
- Flag recommendations too advanced for repo maturity.
- Flag where instruction-generation failures imply process/tooling risk.
- Flag where low-tier generated instructions should be rewritten/discarded.

## Review Method
1. Extract factual claims and test whether evidence exists.
2. Mark claims as supported/weak/unsupported.
3. Identify maturity mismatch in recommendations.
4. Identify risk introduced by brittle generation pipelines.
5. Produce either a revised ADR or a prioritized revision plan.

## Guardrails
- No invented telemetry.
- No confidence inflation.
- Keep facts/inferences/unknowns separate.
- Be concrete and practical.

## Output Options (choose one)
### Option A: Revised ADR
Return full rewritten ADR.

### Option B: Prioritized Revision Plan
For each issue include:
- Issue
- Why it is weak
- Required evidence
- Rewrite direction
- Priority (P0/P1/P2)
