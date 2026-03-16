# Kimi K2.5 Prompt: Repository AI Enablement ADR Synthesis with Educational Framework

You are producing a consulting-grade, repository-specific AI enablement ADR using evidence from agentrc collection and comprehensive educational resources.

## Critical guardrails

- Do **not** overclaim certainty.
- Do **not** assume real Copilot usage/adoption only from repository files.
- Do **not** recommend advanced agentic workflows for immature repos.
- Do **not** recommend MCP just because it is fashionable.
- Prefer practical sequence: instructions + evals + safe workflows before advanced autonomy.
- Treat generated instructions as candidate text, not automatically good.
- Ground all recommendations in the 8-layer maturity framework and educational resources.

## Method

1. Extract factual evidence from artifacts.
2. Mark inferences explicitly.
3. Assess constraints before proposing changes.
4. Map to educational framework and decision matrix.
5. Produce a phased plan (now, next, later) with measurable validation.
6. Fill the ADR template completely including educational appendix.

## You must answer explicitly

- What the repo appears to be and its current 8-layer maturity level
- Which specific educational resources and learning path are most relevant
- Readiness for instructions, skills, evals, workflows, MCP, and autonomy
- First best next moves and team learning priorities
- How the decision framework applies to recommended investments
- Validation experiments and success metrics with clear learning progression

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
# Title

AI Enablement ADR: `<repo-name>`

## Status

Proposed | Accepted | Superseded

## Date

`YYYY-MM-DD`

## Repository

- Name:
- URL/Origin:
- Commit/Snapshot Assessed:

## Context

Describe the business and engineering context for this repository and why AI enablement decisions are needed now, including the recognition that we are underutilizing AI capabilities.

## Observed Facts

List verifiable facts only, with evidence references to collected artifacts.

## Unknowns / Limits

Explicitly capture missing telemetry, uncertain assumptions, and collection blind spots.

## Current Engineering Maturity

Assess practical engineering maturity (e.g., test posture, CI hygiene, standards, reviewability, documentation quality).

## Current AI Enablement Maturity

Assess practical AI readiness (instructions, task decomposition affordances, evaluability, governance, safe automation signals).

## Governance / Constraints

Document constraints that materially shape recommendations:
- Compliance / legal / data sensitivity
- Security and access boundaries
- Team capacity and skill depth
- Tooling/runtime constraints

## 8-Layer Maturity Interpretation

Provide concise interpretation across these layers:
1. Repository & documentation basics
2. Build/test reliability
3. Work decomposition & task clarity
4. AI-facing instructions quality
5. Evaluation and feedback loops
6. Safe workflow automation
7. Cross-tool integration (only if justified)
8. Adaptive/autonomous operation (only if justified)

## Decision

State what the team should adopt now, defer, and explicitly avoid in this phase.

## Recommended Next Investments

### Instructions

### Skills

### Workflows

### Governance / Guardrails

### Learning / Upskilling

## Suggested Artifacts to Add

List concrete files/configs/playbooks to add or improve.

## Experiments to Validate Improvement

Define small, measurable experiments with owner + timeframe.

## Success Metrics

Define practical metrics and expected directional changes.

## Risks / Caveats

Call out implementation and adoption risks.

## Consequences

Describe trade-offs, including what becomes easier and what remains hard.

## Follow-Up Checkpoints

Specify review checkpoints (e.g., 2 weeks, 6 weeks, quarter) and reassessment criteria.

---

## Appendix: AI Enablement Framework & Resources

### Strategic Context

**Business Imperative:** We recognize we are underutilizing AI capabilities. This ADR establishes the foundation for systematic improvement by providing:
- Clear assessment of current state
- Structured path forward with defined maturity levels
- Educational resources and decision frameworks
- Practical next steps grounded in evidence

### Research & Framework References

| Framework | Source | Key Insight | Relevance |
|-----------|--------|-------------|-----------|
| **8-Layer AI Adoption Framework** | Internal research based on DORA, Microsoft AI adoption studies | Progressive maturity from basics to autonomous operation | Provides structured path for incremental improvement |
| **DORA Metrics** | Google Cloud DORA research | High-performing teams deploy frequently with low failure rates | Establishes engineering maturity baseline |
| **Microsoft AI Adoption Research** | Microsoft internal studies | Successful AI adoption requires both tooling and cultural change | Validates need for skills + governance approach |
| **GitHub Copilot Research** | GitHub productivity studies | Proper instruction quality correlates with AI assistance value | Justifies focus on instructions and evals |
| **AWS AI Maturity Model** | AWS enterprise AI adoption framework | AI adoption requires systematic approach across org layers | Supports comprehensive governance needs |

### Available AI Capabilities

| Capability | Description | Maturity Level Required | Learning Resources |
|------------|-------------|------------------------|-------------------|
| **Copilot CLI** | Command-line AI assistance for development tasks | Layer 3-4 | [GitHub Copilot CLI docs](https://docs.github.com/en/copilot/copilot-cli) |
| **Copilot Instructions** | Repository-specific AI behavior guidance | Layer 4 | [Instructions documentation](https://docs.github.com/en/copilot/managing-copilot-in-your-organization/managing-copilot-policies-in-your-organization) |
| **Prompting Skills** | Human-AI interaction patterns and techniques | Layer 3-5 | [Prompt engineering guide](https://docs.github.com/en/copilot/prompt-engineering) |
| **Evaluation Frameworks** | Systematic assessment of AI output quality | Layer 5-6 | Internal evaluation templates |
| **GitHub Actions Hooks** | Automated workflow integration points | Layer 6-7 | [Actions documentation](https://docs.github.com/en/actions) |

### Education & Upskilling Path

#### Foundation (Layers 1-3)
- **Repository Hygiene**: Documentation, README standards, code organization
- **CI/CD Basics**: Reliable builds, testing, deployment practices
- **Task Decomposition**: Breaking work into AI-assistable units

#### Core AI Skills (Layers 4-5)
- **Instruction Writing**: Crafting clear, context-aware AI guidance
- **Prompt Engineering**: Effective human-AI interaction patterns
- **Output Evaluation**: Assessing AI assistance quality and safety

#### Advanced Integration (Layers 6-8)
- **Workflow Automation**: Safe, repeatable AI-augmented processes
- **Cross-Tool Integration**: Connecting AI capabilities across development stack
- **Adaptive Systems**: Learning and improvement loops

### Team Learning Resources

#### Internal Resources
- **AI Enablement Playbook**: Team-specific patterns and practices
- **Instruction Library**: Curated examples of effective AI guidance
- **Evaluation Templates**: Standardized assessment frameworks
- **Success Case Studies**: Internal examples of effective AI adoption

#### External Learning
- **GitHub Copilot Training**: Official certification and learning paths
- **Prompt Engineering Courses**: Systematic skill development
- **AI Safety & Ethics**: Responsible AI implementation guidelines
- **Industry Case Studies**: Learning from similar organizations

### Decision-Making Framework

When evaluating AI enablement investments, use this decision matrix:

| Factor | Weight | Questions to Ask |
|--------|--------|------------------|
| **Impact** | 30% | Does this significantly improve developer productivity or code quality? |
| **Feasibility** | 25% | Do we have the skills and infrastructure to implement this effectively? |
| **Risk** | 20% | What are the safety, security, or quality risks? |
| **Cost** | 15% | What is the implementation and maintenance cost? |
| **Strategic Alignment** | 10% | Does this support our broader technical and business goals? |

### Success Indicators by Maturity Level

- **Layer 1-2**: Repository is well-documented, builds reliably
- **Layer 3-4**: Tasks are clearly decomposed, AI instructions are effective
- **Layer 5-6**: AI outputs are systematically evaluated, workflows are automated
- **Layer 7-8**: AI capabilities are integrated across tools, system adapts and improves

### Next Steps for Team Education

1. **Assess Current Skills**: Use team survey to identify knowledge gaps
2. **Prioritize Learning**: Focus on skills matching current maturity level + 1
3. **Create Learning Plan**: Mix of formal training, peer learning, and hands-on practice
4. **Measure Progress**: Track skill acquisition and AI adoption metrics
5. **Iterate**: Adjust education strategy based on results and feedback

---
```
