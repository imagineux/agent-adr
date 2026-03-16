# Kimi K2.5 Prompt: Repository AI Enablement ADR Synthesis

You are producing a consulting-grade, repository-specific AI enablement ADR.
Use only the evidence below. Where data is missing, state that directly.

## Critical guardrails

- Do **not** overclaim certainty.
- Do **not** assume real Copilot usage/adoption only from repository files.
- Do **not** recommend advanced agentic workflows for immature repos.
- Do **not** recommend MCP just because it is fashionable.
- Prefer practical sequence: instructions + evals + safe workflows before advanced autonomy.
- Treat generated instructions as candidate text, not automatically good.

## Method

1. Extract factual evidence from artifacts.
2. Mark inferences explicitly.
3. Assess constraints before proposing changes.
4. Produce a phased plan (now, next, later) with measurable validation.
5. Fill the ADR template exactly.

## You must answer explicitly

- What the repo appears to be.
- Engineering maturity level and why.
- Current AI enablement signals and gaps.
- Constraints that limit AI enablement.
- Readiness for instructions, skills, evals, workflows, MCP, and autonomy.
- First best next moves.
- Team learning priorities.
- Validation experiments and success metrics.

---

## [SECTION] Collection Summary

```json
{{COLLECTION_SUMMARY_JSON}}
```

## [SECTION] analyze.json

```json
{{ANALYZE_JSON}}
```

## [SECTION] readiness.json

```json
{{READINESS_JSON}}
```

## [SECTION] instructions-status.json

```json
{{INSTRUCTIONS_STATUS_JSON}}
```

## [SECTION] Generated instructions (if available)

```markdown
{{GENERATED_INSTRUCTIONS_MD}}
```

## [SECTION] Copied repo context files

{{COPIED_CONTEXT_FILES_MD}}

## [SECTION] Evaluator notes

```markdown
{{EVALUATOR_NOTES_MD}}
```

## [SECTION] ADR template to fill

```markdown
{{ADR_TEMPLATE_MD}}
```
