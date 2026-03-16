# Sample Collection Layout

```text
collections/client-repo-name/
├── analyze.json
├── collection-metadata.json
├── collection-summary.json
├── copilot-instructions.generated.md          # optional; only when non-empty output is produced
├── instructions-status.json
├── notes.md
├── readiness.json
├── logs/
│   ├── instructions.stderr.log
│   └── instructions.stdout.log
└── context/
    ├── README.md                              # optional
    ├── package.json                           # optional
    ├── package-lock.json                      # optional
    ├── pnpm-lock.yaml                         # optional
    ├── yarn.lock                              # optional
    ├── bun.lock                               # optional
    ├── bun.lockb                              # optional
    ├── AGENTS.md                              # optional
    ├── CLAUDE.md                              # optional
    ├── CONTRIBUTING.md                        # optional
    ├── CODEOWNERS                             # optional
    ├── SECURITY.md                            # optional
    └── .github/
        ├── copilot-instructions.md            # optional
        └── instructions/                      # optional directory copy
```

Notes:
- The collection directory is outside the client repo.
- `instructions-status.json` is always written when collection reaches the optional instructions step.
- Failure of instructions generation does not fail the full collection.
