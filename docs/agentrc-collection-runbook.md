# agentrc Collection Runbook (Client Environment)

## Purpose

This runbook provides a practical, repeatable way to collect AI-readiness artifacts from a client repository using `agentrc`.

The goal is **collection only** in the client environment. We do not mutate the client repo as part of the core flow. Collected artifacts are brought back to our environment and synthesized into a repository-specific ADR.

---

## Scope and operating model

- `agentrc` is treated as an **external, experimental dependency**.
- Collection happens in the **client repository**.
- Synthesis and recommendations happen in **our repository/environment**.
- Generated outputs (especially `instructions`) are **inputs for review**, not auto-accepted truth.

---

## Prerequisites

Before running commands:

1. You have shell access to the client repository root.
2. You can run `npx` commands in that environment.
3. You have permission to capture and export non-sensitive analysis artifacts.
4. You have reviewed any client policy constraints on data sharing.

Create the collection directory:

```bash
mkdir -p .agent-readiness-collection
```

---

## Collection commands (copy/paste)

Run from the client repository root.

### 1) Analyze

```bash
npx github:microsoft/agentrc analyze --json > .agent-readiness-collection/analyze.json
```

### 2) Readiness

```bash
npx github:microsoft/agentrc readiness --json > .agent-readiness-collection/readiness.json
```

### 3) Instructions (attempt)

```bash
npx github:microsoft/agentrc instructions --dry-run > .agent-readiness-collection/instructions.md
```

### 4) Optional generation commands

```bash
npx github:microsoft/agentrc generate mcp
npx github:microsoft/agentrc generate vscode
```

If these optional commands produce files in-place, copy relevant outputs into `.agent-readiness-collection/` with clear names (for example `mcp.json`, `vscode-settings.json`, or command transcripts).

---

## If stdout redirection is awkward

Some environments or shells make direct redirection inconvenient. Use a practical fallback:

```bash
npx github:microsoft/agentrc analyze --json | tee .agent-readiness-collection/analyze.json
npx github:microsoft/agentrc readiness --json | tee .agent-readiness-collection/readiness.json
npx github:microsoft/agentrc instructions --dry-run | tee .agent-readiness-collection/instructions.md
```

If a command writes structured files directly instead of stdout, preserve those files and add a short `notes.md` explaining what was produced and where.

---

## Required vs optional artifacts

### Required (minimum)

- `.agent-readiness-collection/analyze.json`
- `.agent-readiness-collection/readiness.json`

### Recommended

- `.agent-readiness-collection/instructions.md` (if `instructions` succeeds)
- brief repo context notes (README/docs summary) when raw outputs lack context

### Optional

- MCP generation output (e.g., `mcp.json`)
- VS Code generation output (e.g., `vscode-settings.json`)
- command transcript / operator notes

---

## What to do if `instructions` fails

Failure to generate `instructions` is non-blocking.

1. Capture the failure output into a note file:

```bash
npx github:microsoft/agentrc instructions --dry-run 2>&1 | tee .agent-readiness-collection/instructions-error.log
```

2. Continue with `analyze.json` and `readiness.json`.
3. Add a short explanation in `.agent-readiness-collection/notes.md`:
   - command attempted
   - failure type (timeout, unsupported repo shape, etc.)
   - any retried flags/steps

The ADR synthesis should explicitly record this as missing telemetry, not silently fill in assumptions.

---

## Minimum viable collection

Use this when time is limited:

1. `analyze.json`
2. `readiness.json`
3. short README/docs summary if needed for context
4. optional `instructions` output (or failure log)

This is enough to produce a constrained, honest first-pass ADR with clear unknowns.

---

## Package and share artifacts back for synthesis

From the client repo root:

```bash
tar -czf agent-readiness-collection.tgz .agent-readiness-collection
```

Or with zip:

```bash
zip -r agent-readiness-collection.zip .agent-readiness-collection
```

Share only the artifact bundle and any approved contextual notes. Do **not** include unrelated repository files unless explicitly required.

---

## Caveats and interpretation guidance

- `agentrc` behavior is experimental and may change.
- Outputs may be non-deterministic across runs.
- Generated suggestions are not validated implementation plans.
- Local repository signals are **not** proof of enterprise-wide Copilot or AI adoption.
- Treat all collection outputs as evidence to interpret, not authoritative truth.

When in doubt, prefer explicit unknowns and conservative recommendations.
