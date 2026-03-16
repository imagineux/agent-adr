# agent-adr (thin enterprise-safe wrapper around `microsoft/agentrc`)

This repository is intentionally narrow in scope.

- It is **not** a replacement for `agentrc`.
- It is **not** a Copilot SDK app.
- It is **not** an AI platform.

It does one job: safely collect `agentrc` outputs + diagnostics in client environments, then package those artifacts for stronger-model ADR synthesis.

## What we trust vs. own

### We trust `agentrc` for
- Repository analysis
- Readiness reporting
- Optional low-tier instruction-generation attempts

### We do **not** trust `agentrc` for
- Final recommendations
- Final ADR authorship
- Guaranteed-stable instruction generation

### We own
- Collection workflow
- Failure/diagnostics capture
- Artifact normalization
- ADR template
- Strong-model synthesis prompt
- Strong-model review prompt

## Why this wrapper exists

Instruction generation can fail in enterprise environments (network, auth, CLI mismatch, policy constraints). This wrapper treats those failures as expected evidence and preserves them cleanly.

## Deliverables

- `scripts/collect-agentrc.sh`
- `scripts/build-strong-model-prompt.mjs`
- `templates/ai-enablement-adr-template.md`
- `templates/strong-model-synthesis-template.md`
- `templates/strong-model-review-template.md`
- `skills/compose-ai-enablement-adr.md`
- `examples/sample-collection-layout.md`

## Operator flow

1. Run collection on the client machine.
2. Inspect the resulting artifact bundle.
3. Build synthesis/review prompts.
4. Paste synthesis prompt into Kimi K2.5 / SWE-1.5 / GPT-5.4 Pro.
5. Optionally run the review prompt against the first-pass ADR.
6. Deliver the final ADR.

## Quickstart

```bash
./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-repo-name
node scripts/build-strong-model-prompt.mjs --collection ./collections/client-repo-name --out ./collections/client-repo-name/prompts
```

Optional end-to-end helper:

```bash
./scripts/example-run.sh /path/to/client/repo ./collections/client-repo-name
```

## Collection behavior highlights

- Forces `AGENTRC_DEBUG_COPILOT=1` during collection.
- Preserves `AGENTRC_COPILOT_CLI_PATH` when provided.
- Explicitly overrides instructions model (default `gpt-5-mini`).
- Runs 4 dry-run probes and 2 real generation attempts.
- Captures stdout/stderr/exit status/timestamps per command.
- Records generated output existence, size, and SHA256 when possible.
- Copies context files best-effort into `context/`.
- Writes `collection-summary.json`, `instructions-overview.md`, and `notes.md`.

## Prompt builder outputs

`build-strong-model-prompt.mjs` produces:

- `prompts/adr-synthesis-prompt.md`
- `prompts/adr-review-prompt.md`

Both prompts include missing-artifact markers and failed-step stderr snippets so failure signals are never silently discarded.
