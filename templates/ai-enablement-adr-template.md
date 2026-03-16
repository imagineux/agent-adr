# ADR: [Repository] AI Enablement Recommendations

- **Title:** [Concise decision-oriented title]
- **Status:** Draft | Proposed | Accepted | Superseded
- **Date:** YYYY-MM-DD
- **Repository:** [org/repo]

---

## Context

Describe why this ADR is being created now, what artifact set was reviewed, and what decision horizon is being targeted (for example, next 30/60/90 days).

---

## Observed repo facts

List only directly observed facts from collected artifacts and repo documentation.

- Fact 1:
- Fact 2:
- Fact 3:

Include evidence references where possible (artifact filename + key section).

---

## What is unknown / not inferable

Explicitly list unknowns, missing telemetry, and constraints that prevent confident conclusions.

- Unknown 1:
- Unknown 2:

---

## Current engineering maturity

Summarize delivery/process maturity signals relevant to AI enablement (for example: documentation quality, testing discipline, build reliability, ownership clarity, tooling consistency).

- **Current state:**
- **Strengths:**
- **Gaps:**

---

## Current AI enablement maturity

Assess practical AI readiness/adoption for this specific repository.

- **Current state:**
- **Evidence-backed strengths:**
- **Evidence-backed limitations:**
- **Confidence level:** Low | Medium | High (with reason)

---

## Governance / constraints

Capture known policy, security, compliance, data handling, and process constraints that shape recommendations.

- Constraint 1:
- Constraint 2:

---

## 8-layer maturity interpretation

Interpret maturity across the following layers (score optional; rationale required):

1. **Codebase hygiene**
2. **Docs and discoverability**
3. **Local developer workflows**
4. **CI/CD and quality gates**
5. **AI guidance artifacts (instructions/skills/prompts)**
6. **Model/tool integration readiness**
7. **Governance and safety controls**
8. **Measurement and learning loops**

For each layer provide:

- **Observed signals**
- **Current maturity** (Low / Medium / High)
- **Primary blocker or leverage point**

---

## Decision

State the core decision clearly. Example pattern:

> We will prioritize phased AI enablement in this repository by first establishing foundational guidance and guardrails, then introducing scoped workflow automation, while measuring impact through explicit experiment metrics.

---

## Recommended next investments

### 1) Instructions

Recommend repository-scoped instruction artifacts to add/update first.

- Recommendation:
- Why now:
- Owner:
- Effort:

### 2) Skills

Recommend reusable skills/macros/playbooks appropriate to current maturity.

- Recommendation:
- Why now:
- Owner:
- Effort:

### 3) Workflows

Recommend practical workflow changes (planning, coding, review, release) that AI should support.

- Recommendation:
- Why now:
- Owner:
- Effort:

### 4) Governance / guardrails

Recommend minimal viable controls that enable safe adoption without over-constraining progress.

- Recommendation:
- Why now:
- Owner:
- Effort:

### 5) Learning / enablement

Recommend concrete learning steps for maintainers and contributors.

- Recommendation:
- Why now:
- Owner:
- Effort:

---

## Suggested artifacts to add

List specific files/directories to create in or around the repo.

- `docs/ai-contribution-guide.md` — purpose
- `.github/copilot-instructions.md` (or equivalent) — purpose
- `skills/[name].md` — purpose
- `prompts/[name].md` — purpose
- `metrics/ai-enablement-baseline.md` — purpose

---

## Experiments to validate improvement

Define small, measurable experiments.

For each experiment include:

- **Hypothesis**
- **Change introduced**
- **Metric(s)**
- **Baseline needed**
- **Evaluation window**
- **Rollback/stop condition**

---

## Success metrics

Track both delivery outcomes and enablement quality.

- Cycle-time indicator(s):
- Quality indicator(s):
- Adoption indicator(s):
- Governance indicator(s):
- Learning indicator(s):

---

## Risks / caveats

Be explicit about uncertainty and failure modes.

- Risk 1:
- Risk 2:
- Caveat 1:

---

## Consequences

Describe expected trade-offs and organizational impact.

- Positive:
- Negative:
- Deferred work:

---

## Follow-up checkpoints

Schedule short review checkpoints.

- **T+2 weeks:** verify initial artifact adoption
- **T+6 weeks:** review experiment results and refine investments
- **T+12 weeks:** decide whether to scale, pause, or redirect
