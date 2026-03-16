# Sample Collection Layout

```text
collections/client-repo-name/
  analyze.json
  readiness.json
  collection-summary.json
  instructions-overview.md
  notes.md
  metadata/
    run.json
    environment.json
    commands.json
    analyze-status.json
    readiness-status.json
    diag-copilot-version.status.json
    diag-copilot-help.status.json
  logs/
    analyze.stdout.log
    analyze.stderr.log
    readiness.stdout.log
    readiness.stderr.log
    diag-copilot-version.stdout.log
    diag-copilot-version.stderr.log
  probes/
    flat-root/
      probe.json | probe.stdout.log
      stderr.log
      status.json
    flat-areas/
      probe.json | probe.stdout.log
      stderr.log
      status.json
    nested-root/
      probe.json | probe.stdout.log
      stderr.log
      status.json
    nested-areas/
      probe.json | probe.stdout.log
      stderr.log
      status.json
  generated/
    flat-root/
      copilot-instructions.generated.md
      stdout.log
      stderr.log
      status.json
    nested-root/
      AGENTS.generated.md
      stdout.log
      stderr.log
      status.json
  context/
    README.md
    package.json
    tsconfig.json
    AGENTS.md
    .github/copilot-instructions.md
    docs/adr/
    docs/architecture/
  prompts/
    adr-synthesis-prompt.md
    adr-review-prompt.md
```
