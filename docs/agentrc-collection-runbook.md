# `agentrc` Collection Runbook (Client Environment)

## Purpose

Use this runbook to collect a **portable artifact bundle** from a client repository using `agentrc`.
Those artifacts are then brought back to our environment for normalization and ADR synthesis.

This flow is intentionally lightweight:

- We treat `agentrc` as an external, experimental dependency
- We do not directly modify client repositories in the core workflow
- We separate **collection** (client side) from **analysis/synthesis** (our side)

---

## Prerequisites

- Access to the client repository checkout
- Node.js + `npx` available in that environment
- Ability to run shell commands locally in the repo
- Permission to export and share non-sensitive outputs

> If outputs may contain sensitive metadata, apply the client’s data handling policy before sharing.

---

## Collection directory

From the client repo root, create a collection folder:

```bash
mkdir -p .agent-readiness-collection
```

All command outputs should be saved under this directory.

---

## Required collection commands

Run from the client repository root:

```bash
npx github:microsoft/agentrc analyze --json > .agent-readiness-collection/analyze.json
npx github:microsoft/agentrc readiness --json > .agent-readiness-collection/readiness.json
npx github:microsoft/agentrc instructions --dry-run > .agent-readiness-collection/instructions.md
```

### If stdout redirection is awkward

Some environments or wrappers may make redirection unreliable. Practical fallback:

1. Run the command without redirection
2. Copy terminal output into the target file manually
3. Note this in `.agent-readiness-collection/notes.md`

Example fallback:

```bash
npx github:microsoft/agentrc analyze --json
# paste output into .agent-readiness-collection/analyze.json
```

---

## Optional collection commands

Run these only if useful and supported:

```bash
npx github:microsoft/agentrc generate mcp
npx github:microsoft/agentrc generate vscode
```

If these commands emit files directly, copy or move relevant outputs into `.agent-readiness-collection/` (or document their location in `notes.md`).

---

## What to do if `instructions` fails

`instructions` may fail due to repo shape, environment assumptions, or experimental behavior. If it fails:

1. Capture stderr/stdout text into `.agent-readiness-collection/instructions-error.md`
2. Add a short note in `.agent-readiness-collection/notes.md`
3. Continue with available artifacts (`analyze.json`, `readiness.json`)

Do **not** block the whole flow on this step.

---

## Minimum viable collection

At minimum, return:

- `.agent-readiness-collection/analyze.json` (**required**)
- `.agent-readiness-collection/readiness.json` (**required**)
- A short repo summary from README/docs if needed (`notes.md` or copied excerpts)
- `instructions.md` if available (**optional but helpful**)

Optional enrichments:

- `mcp.json` or generated MCP-related output
- VS Code settings/recommendations from `generate vscode`
- Known constraints, compliance notes, or toolchain caveats

---

## Packaging artifacts for handoff

From the client repo root:

```bash
tar -czf agent-readiness-collection.tgz .agent-readiness-collection
```

Or zip format:

```bash
zip -r agent-readiness-collection.zip .agent-readiness-collection
```

Share only via approved channel. Include:

- Collection timestamp
- Repository name/version/branch or commit SHA
- Any known command failures or partial outputs

---

## Caveats (experimental + non-deterministic behavior)

- `agentrc` is experimental and may change output format over time
- Output quality and completeness can vary by repository structure
- Re-running commands may produce materially different guidance
- Generated `instructions` are a starting draft, not validated policy
- Local artifacts are a **signal set**, not authoritative telemetry for enterprise-wide adoption

When synthesizing ADRs, treat artifacts as evidence with confidence levels, not absolute truth.
