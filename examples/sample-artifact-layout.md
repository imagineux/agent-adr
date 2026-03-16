# Sample Artifact Bundle Layout

Example structure of a collected client-side artifact bundle:

```text
.agent-readiness-collection/
  analyze.json
  readiness.json
  instructions.md
  instructions-error.log
  mcp.json
  vscode-settings.json
  notes.md
  commit.txt
  branch.txt
```

Notes:
- `analyze.json` and `readiness.json` are the minimum required machine-readable artifacts.
- `instructions.md` is recommended but optional if generation fails.
- `notes.md` should capture context, failures, and anything not obvious from JSON outputs.
