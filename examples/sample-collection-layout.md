# Sample Collection Layout

```text
collections/
  client-repo-name/
    analyze.json
    readiness.json
    copilot-instructions.generated.md            # optional; may be missing/empty
    instructions-status.json
    collection-metadata.json
    collection-summary.json
    notes.md
    logs/
      instructions.stdout.log
      instructions.stderr.log
    context/
      README.md                                  # optional
      package.json                               # optional
      AGENTS.md                                  # optional
      .github/
        copilot-instructions.md                  # optional
        instructions/                            # optional directory
```

Use this layout as the expected input for `scripts/build-adr-prompt.mjs`.
