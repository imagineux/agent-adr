# Sample Artifact Bundle Layout

Example structure for a collected client artifact bundle:

```text
.agent-readiness-collection/
  analyze.json
  readiness.json
  instructions.md
  mcp.json
  vscode-settings.json
  notes.md
```

Notes:

- `analyze.json` and `readiness.json` are the minimum required core artifacts.
- `instructions.md` is optional but usually high value.
- `mcp.json` and `vscode-settings.json` are optional enrichments.
- `notes.md` should capture command failures, environment caveats, and context.
