# agent-adr: Thin enterprise-safe wrapper around `microsoft/agentrc`

This repository is intentionally narrow.

It is **not** a replacement for `agentrc`.
It is **not** a Copilot SDK app.
It is **not** an AI platform.

It does one job: collect `agentrc` evidence safely, preserve failures/diagnostics, and prepare prompt bundles for stronger-model ADR synthesis and review.

## What we trust vs. what we own

### We trust `agentrc` for
- Repo analysis
- Readiness reporting
- Optional low-tier instruction generation attempts

### We do **not** trust `agentrc` for
- Final recommendations
- Final ADR authoring
- Guaranteed-stable instruction generation

### We own
- Collection workflow
- Diagnostics capture
- Artifact normalization
- ADR template
- Strong-model synthesis/review prompts

## Main deliverables
- **Collection bundle** (portable, outside client repo)
- **ADR template**
- **Strong-model synthesis prompt**
- **Strong-model review prompt**

## Scripts

### 1) Collect artifacts safely
```bash
./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-repo-name
```

Behavior highlights:
- Enforces `AGENTRC_DEBUG_COPILOT=1`
- Preserves `AGENTRC_COPILOT_CLI_PATH` if provided
- Overrides model for instruction flow (default: `gpt-5-mini`)
- Captures stdout/stderr/exit/status for analyze/readiness/probes/generation attempts
- Copies context files best-effort
- Writes summary + notes

### 2) Build strong-model prompts
```bash
node scripts/build-strong-model-prompt.mjs --collection ./collections/client-repo-name --out ./collections/client-repo-name/prompts
```

Outputs:
- `prompts/adr-synthesis-prompt.md`
- `prompts/adr-review-prompt.md`

## Short operator flow
1. Run collection on client machine.
2. Inspect bundle (`collection-summary.json`, `instructions-overview.md`, logs).
3. Build prompts.
4. Paste synthesis prompt into a stronger model (Kimi K2.5 / SWE-1.5 / GPT-5.4 Pro).
5. Optionally run review prompt against first-pass ADR.
6. Deliver final ADR.

## Important stance on instruction generation
Instruction generation can be flaky in enterprise environments.

Even `instructions --dry-run` still exercises generation flow, so failures are expected and treated as useful diagnostics. Generated instruction files are handled as candidate drafts, not approved outputs.

## Example
See `examples/sample-collection-layout.md` for expected bundle layout.
