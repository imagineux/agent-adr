# AgentRC Collection Runbook (Client Environment)

## Purpose

Use this runbook to collect **evidence artifacts** from a client repository using `agentrc` so we can produce a repository-specific AI enablement ADR in our own environment.

This process is intentionally thin:
- `agentrc` is used only for analysis/generation in the client environment.
- We collect outputs into a local bundle.
- We bring the bundle back to our environment for normalization, synthesis, and ADR authoring.
- We do **not** directly edit the client repo as part of this collection flow.

## Prerequisites

- Access to the client repository checkout.
- Node.js + `npx` available.
- Permission to run read-only repo analysis commands.
- A local collection folder in the client repo root.

> Recommended collection directory:
>
> `.agent-readiness-collection/`

## Collection Directory Setup

From the client repo root:

```bash
mkdir -p .agent-readiness-collection
```

Optional: record basic context so synthesis has repo metadata:

```bash
git rev-parse --short HEAD > .agent-readiness-collection/commit.txt
git branch --show-current > .agent-readiness-collection/branch.txt
```

## Exact Commands to Run

Run these from the client repo root.

### 1) Analyze (required)

```bash
npx github:microsoft/agentrc analyze --json > .agent-readiness-collection/analyze.json
```

### 2) Readiness (required)

```bash
npx github:microsoft/agentrc readiness --json > .agent-readiness-collection/readiness.json
```

### 3) Instructions dry-run (optional but recommended)

```bash
npx github:microsoft/agentrc instructions --dry-run > .agent-readiness-collection/instructions.md
```

### 4) Optional generation commands

```bash
npx github:microsoft/agentrc generate mcp
npx github:microsoft/agentrc generate vscode
```

If these generate files directly rather than stdout, copy those generated artifacts into `.agent-readiness-collection/` and note source paths in `notes.md`.

## Practical Fallbacks for Output Capture

Some environments/commands may not cleanly support direct stdout redirection.

Use one of these fallbacks:

1. Pipe through `tee`:

```bash
npx github:microsoft/agentrc instructions --dry-run | tee .agent-readiness-collection/instructions.md
```

2. Copy terminal output manually into a file:

- Create `.agent-readiness-collection/instructions.md`
- Paste captured output
- Add a short header noting it was copied manually

3. If a command writes to files in-place:

- Keep generated files untouched in client repo
- Copy snapshots into `.agent-readiness-collection/`
- Record original paths + command used in `.agent-readiness-collection/notes.md`

## If `instructions` Fails

Treat `instructions` as non-blocking.

1. Capture the failure output:

```bash
npx github:microsoft/agentrc instructions --dry-run > .agent-readiness-collection/instructions.md 2> .agent-readiness-collection/instructions-error.log
```

2. Add a note in `.agent-readiness-collection/notes.md` with:
- command run
- timestamp
- error summary
- whether retry was attempted

3. Continue with ADR synthesis using `analyze.json` and `readiness.json`.

## Required vs Optional Artifacts

### Required (minimum viable collection)

- `.agent-readiness-collection/analyze.json`
- `.agent-readiness-collection/readiness.json`
- Repo context summary (one of):
  - copied `README.md` excerpt, or
  - short `.agent-readiness-collection/notes.md` summary of repo purpose/stack

### Optional (recommended)

- `.agent-readiness-collection/instructions.md`
- `.agent-readiness-collection/instructions-error.log` (if failure)
- MCP generation output (`mcp.json`, config, or transcript)
- VS Code generation output (`vscode-settings.json`, snippets, or transcript)
- Commit/branch metadata (`commit.txt`, `branch.txt`)

## Packaging and Sharing Artifacts

From the client repo root:

```bash
tar -czf agent-readiness-collection.tgz .agent-readiness-collection
```

Alternative zip format:

```bash
zip -r agent-readiness-collection.zip .agent-readiness-collection
```

Share only the bundle to the ADR synthesis environment.

## Hand-off Checklist (to ADR Synthesis Team)

Before hand-off, verify:

- `analyze.json` exists and is non-empty
- `readiness.json` exists and is non-empty
- `instructions.md` included or failure reason documented
- any optional generated artifacts are labeled
- notes identify command versions/date if possible

## Caveats and Operator Notes

- `agentrc` is experimental; output shape and quality may change between runs/versions.
- Results may be non-deterministic; treat as **signals**, not ground truth.
- Generated instructions/templates are suggestions and are not pre-validated for a client’s governance model.
- Do not interpret local repository telemetry as enterprise-wide Copilot/AI adoption evidence.
- Preserve raw artifacts; avoid editing them before synthesis.
