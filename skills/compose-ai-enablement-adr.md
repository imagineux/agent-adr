# Skill: compose-ai-enablement-adr

## Purpose
Compose a repo-specific AI enablement ADR from a collection bundle produced by the thin agentrc wrapper.

## Required Inputs
- `analyze.json`
- `readiness.json`
- dry-run probe statuses/logs
- generation attempt statuses/logs
- generated instruction drafts (if any)
- context files copied from client repo
- collection summary + environment metadata

## Synthesis Method
1. Extract hard facts from artifacts.
2. Separate facts from inference and unknowns.
3. Score engineering and AI enablement maturity conservatively.
4. Evaluate low-tier generation attempts as candidate drafts only.
5. Account for failures and constraints before recommending expansions.
6. Produce phased recommendations with validation experiments.

## Anti-Patterns
- Invented telemetry.
- Generic best-practice sludge.
- Assuming generated instructions are good because they exist.
- Over-recommending MCP or advanced agents.
- Failing to distinguish facts / inferences / unknowns.
- Ignoring collection failures and diagnostics.

## Output Contract
Produce an ADR that includes:
- decision and rationale
- evidence and uncertainty
- near-term actions and ownership candidates
- phased improvement plan
- measurable success metrics
- risks and follow-up checkpoints

## Quality Bar
- Practical, direct, consulting-grade tone.
- Claims tied to evidence.
- Uncertainty explicitly labeled.
- Recommendations right-sized to current maturity.
