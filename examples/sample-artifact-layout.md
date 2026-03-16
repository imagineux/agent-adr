# Sample Artifact Bundle Layout

Example structure for a collected bundle:

```text
.agent-readiness-collection/
  analyze.json
  readiness.json
  instructions.md
  instructions-error.txt
  mcp.json
  vscode-settings.json
  notes.md
```

Notes:

- `analyze.json` and `readiness.json` are the minimum required artifacts.
- `instructions.md` is optional; if generation fails, keep `instructions-error.txt`.
- `notes.md` should capture collection date, commit SHA/branch, and anomalies.
