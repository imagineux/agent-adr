# `agentrc` Collection Runbook (Client Environment)

## Purpose

Use this runbook to collect a consistent artifact bundle from a client repository using `agentrc`, then return that bundle for ADR synthesis in our own environment.

This collection flow exists to:

- create a repeatable baseline of repository signals
- capture AI readiness outputs without editing client code as part of the core path
- separate **collection** (client environment) from **analysis/synthesis** (our environment)

---

## Scope and operating model

- Run commands **inside the client repository**.
- Save outputs to a local collection folder: `.agent-readiness-collection/`.
- Export and share the collection bundle.
- Perform ADR synthesis after artifacts are imported back into our environment.

---

## Prerequisites

- Access to the client repository working copy.
- Node.js + `npx` available in the shell.
- Permission to run read/analyze tooling in the client environment.
- Network access if `npx github:microsoft/agentrc` needs to fetch package content.

> `agentrc` is experimental and may change behavior or output shape over time.

---

## Recommended collection directory

From the client repository root:

```bash
mkdir -p .agent-readiness-collection
```

---

## Exact commands to run

Run from client repo root.

```bash
npx github:microsoft/agentrc analyze --json > .agent-readiness-collection/analyze.json
npx github:microsoft/agentrc readiness --json > .agent-readiness-collection/readiness.json
npx github:microsoft/agentrc instructions --dry-run > .agent-readiness-collection/instructions.md
```

Optional generators (capture outputs if useful):

```bash
npx github:microsoft/agentrc generate mcp
npx github:microsoft/agentrc generate vscode
```

If generator commands write files directly instead of stdout, copy those generated files into `.agent-readiness-collection/` and record what was copied in `notes.md`.

---

## Practical fallback when stdout redirection is awkward

Some shells/tools can be noisy or mix logs with JSON on stdout. If direct redirection is unreliable:

1. Run command without redirection.
2. Paste clean output into the expected file manually.
3. Add a note in `.agent-readiness-collection/notes.md` describing what happened.

Example `notes.md` entry:

```md
- `agentrc readiness --json` emitted extra logs to stdout.
- Clean JSON was manually copied into `readiness.json`.
- Timestamp: 2026-01-15T14:22:00Z
```

---

## If `instructions` fails

Failure of `instructions` should **not** block collection.

Do this instead:

1. Keep `analyze.json` and `readiness.json` as the minimum required set.
2. Capture the error output in `.agent-readiness-collection/instructions-error.txt`.
3. Add a short `notes.md` entry with command, error summary, and timestamp.
4. Continue to packaging and sharing.

This keeps synthesis grounded in available facts while being explicit about missing artifacts.

---

## Required vs optional artifacts

### Required

- `.agent-readiness-collection/analyze.json`
- `.agent-readiness-collection/readiness.json`

### Strongly recommended

- `.agent-readiness-collection/notes.md`
- repo context summary (README excerpt, docs summary, or short operator notes)

### Optional

- `.agent-readiness-collection/instructions.md`
- `.agent-readiness-collection/instructions-error.txt`
- `.agent-readiness-collection/mcp.json` (or generated MCP config files)
- `.agent-readiness-collection/vscode-settings.json` (or generated VS Code config files)

---

## Minimum viable collection (MVC)

If time is constrained, collect at least:

- `analyze.json`
- `readiness.json`
- README/docs summary (can be `notes.md`)
- optional `instructions.md` (if available)

This is sufficient to produce an initial, caveated ADR.

---

## Package and share artifacts

From client repo root:

```bash
tar -czf agent-readiness-collection.tgz .agent-readiness-collection/
```

Alternative zip format:

```bash
zip -r agent-readiness-collection.zip .agent-readiness-collection/
```

Share the archive back to the ADR synthesis environment along with:

- repository name/org
- branch or commit SHA used for collection
- collection timestamp
- any access constraints relevant to interpretation

---

## Caveats and interpretation guidance

- `agentrc` is experimental; outputs can be non-deterministic across versions/runs.
- Generated instructions are proposals, not validated policy.
- Absence of signals is not proof of absence of capability.
- Treat results as directional evidence to support structured ADR decisions, not absolute truth.
