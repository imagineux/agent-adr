# Sample Artifact Bundle Layout

Use this as a reference for what to return from the client environment.

```text
.agent-readiness-collection/
  analyze.json
  readiness.json
  instructions.md
  mcp.json
  vscode-settings.json
  notes.md
```

## Notes

- `analyze.json` and `readiness.json` are the minimum required files.
- `instructions.md` is optional if generation fails.
- `notes.md` should capture command issues, constraints, and context needed for synthesis.
