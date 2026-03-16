# agent-adr

A **thin wrapper** around [`microsoft/agentrc`](https://github.com/microsoft/agentrc) for collecting repository evidence and building a high-quality ADR synthesis prompt.

## What this repo is (and is not)

This repo exists to run a small collection workflow in a client environment and then produce a reusable prompt bundle for a stronger model.

It intentionally **does not**:
- reimplement `agentrc`
- provide a full CLI platform
- depend on Copilot SDK directly
- write into the client repo during normal collection

It intentionally **does** own:
- the collection runbook
- the prompt templates
- the ADR template
- the final synthesis layer

## Workflow model

1. **Collection in client environment**
   - Run `agentrc` commands against the client repo.
   - Store outputs in a separate collection directory (outside client repo).
2. **Synthesis in your environment**
   - Assemble artifacts into a single, structured prompt.
   - Paste prompt into a stronger model (Kimi K2.5, SWE-1.5, GPT-5.4 Pro).
3. **Human review and delivery**
   - Review model output.
   - Finalize and deliver a repo-specific AI enablement ADR.

## Scripts

### 1) Collect artifacts

```bash
./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-repo-name
```

This script:
- runs required `analyze` and `readiness` calls
- attempts optional instructions generation (best effort)
- captures logs + status for instructions success/failure
- copies optional context files if present
- writes summary and metadata for downstream synthesis

> Notes
> - Instructions generation is intentionally optional and can fail without failing the run.
> - The script uses `--output ... --force` for instructions (not `--dry-run`) so generated markdown can be captured when available.

### 2) Build synthesis prompt

```bash
node scripts/build-adr-prompt.mjs \
  --collection ./collections/client-repo-name \
  --template templates/kimi-k2_5-adr-synthesis-template.md \
  --out ./collections/client-repo-name/adr-synthesis-prompt.md
```

This script:
- reads the collection artifacts
- clearly marks missing files
- injects JSON in fenced code blocks
- includes instruction failure details when relevant
- emits one final prompt file ready to paste into a stronger model

## Happy path (5 steps)

1. Run collection script against a client repo.
2. Inspect collection directory contents and logs.
3. Build synthesis prompt with selected template.
4. Paste prompt into Kimi / SWE / GPT-5.4 Pro.
5. Review generated ADR, edit for judgment/context, and deliver.

## File layout

- `scripts/collect-agentrc.sh` — collection runbook
- `scripts/build-adr-prompt.mjs` — prompt assembly
- `templates/ai-enablement-adr-template.md` — ADR structure
- `templates/llm-adr-synthesis-template.md` — generic strong-model synthesis template
- `templates/kimi-k2_5-adr-synthesis-template.md` — Kimi-optimized synthesis template
- `skills/compose-ai-enablement-adr.md` — reusable ADR composition skill
- `examples/sample-collection-layout.md` — example output layout
- `scripts/example-run.sh` — convenience example

## Positioning

`agentrc` is treated as scanner/generator infrastructure.

This repo owns the **synthesis layer** and final recommendation framing, so final ADR judgment remains explicit, auditable, and under operator control.
