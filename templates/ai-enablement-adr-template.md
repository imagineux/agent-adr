# ADR: [Concise decision title]

- **Status:** Proposed | Accepted | Superseded
- **Date:** YYYY-MM-DD
- **Repository:** `org/repo` (or internal path)

## Context

Summarize why this ADR exists now.

- What triggered the assessment?
- What decisions need to be made?
- What constraints are already known?

## Observed repo facts

Document only evidence-backed facts from collected artifacts.

- Repository purpose/domain (based on README, code layout, metadata)
- Architecture/runtime signals
- Delivery/testing/tooling signals
- Existing AI-related files, policies, workflows, or prompts
- `agentrc analyze` and `readiness` observations

> Include evidence references to artifact files where possible.

## What is unknown / not inferable

Be explicit about missing telemetry and limits.

- What cannot be inferred from local artifacts
- Which outputs are missing, failed, or stale
- What additional discovery would reduce uncertainty

## Current engineering maturity

Provide a practical maturity read for this repo.

Cover (as applicable):

- Build/release/test reliability
- Operational discipline (ownership, runbooks, incident patterns)
- Documentation quality
- Change safety and governance
- Standardization and maintainability

Use simple labels: **Early / Developing / Established / Advanced** with rationale.

## Current AI enablement maturity

Assess AI readiness/adoption in this specific repo context.

- Prompt/instruction assets
- Skill/workflow structure
- Guardrails and policy clarity
- Evaluation/feedback loops
- Developer onboarding for AI-assisted work

Use simple labels: **Early / Developing / Established / Advanced** with rationale.

## Governance / constraints

Capture constraints that shape safe recommendations.

- Security/privacy/compliance limits
- Repo contribution controls
- Toolchain/network/runtime constraints
- Organizational process constraints

Call out non-negotiables and decision boundaries.

## 8-layer maturity interpretation

Interpret findings across these eight layers:

1. **Codebase hygiene & discoverability**
2. **Docs & intent clarity**
3. **Build/test/release confidence**
4. **Operational readiness & ownership**
5. **AI instructions & task scaffolding**
6. **AI workflow integration**
7. **Governance, risk & policy controls**
8. **Learning loops & measurable improvement**

For each layer, include:

- current state
- key gap(s)
- practical next step

## Decision

State the decision this ADR makes.

Example framing:

- We will implement a phased AI enablement baseline for this repository.
- We will prioritize constraint-first guidance and measurable workflow improvements before advanced agentic orchestration.

## Recommended next investments

### 1) Instructions

- What repo-specific instruction files to add or revise
- Which roles/use-cases they should cover
- Why these are first priority

### 2) Skills

- What reusable skills to introduce next
- Scope boundaries for each skill
- Dependencies and maintenance expectations

### 3) Workflows

- Which practical workflows to standardize first (PR prep, triage, tests, docs updates, etc.)
- Human approval points
- Rollout order (phase 1/2/3)

### 4) Governance / guardrails

- Required guardrails before scaling AI usage
- Validation/evidence requirements
- Escalation/override paths

### 5) Learning / enablement

- What teams should learn next
- Training/practice format
- Suggested timeline and owners

## Suggested artifacts to add

List concrete files/assets to create in the repo.

Example categories:

- `/docs/ai/` operating guides
- instruction files (task-specific)
- skill definitions and examples
- prompt templates
- evaluation checklists
- experiment logs and scorecards

## Experiments to validate improvement

Define 2–5 bounded experiments.

For each experiment include:

- hypothesis
- change introduced
- success metric(s)
- measurement window
- rollback condition

Prefer low-risk experiments that can run in normal delivery cycles.

## Success metrics

Define leading and lagging indicators.

Examples:

- cycle time on scoped tasks
- first-pass PR quality
- review rework rate
- instruction adherence rate
- defect escape indicators
- user/operator confidence ratings

Include baseline, target, and check cadence where possible.

## Risks / caveats

Call out realistic risks.

Examples:

- false confidence from incomplete telemetry
- over-automation before process maturity
- prompt/skill drift without ownership
- governance lag behind usage growth

Include mitigations.

## Consequences

Document expected outcomes and trade-offs.

- What improves immediately
- What costs increase (time, maintenance, review effort)
- What remains unresolved after this ADR

## Follow-up checkpoints

Set explicit review points.

- **30 days:** confirm baseline assets were created and adopted
- **60 days:** assess experiment results and adjust scope
- **90 days:** decide whether to scale, revise, or pause the approach

Assign owners for each checkpoint and required inputs.
