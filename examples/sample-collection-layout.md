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
  logs/
    analyze.stdout.log
    analyze.stderr.log
    readiness.stdout.log
    readiness.stderr.log
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
      copilot-instructions.generated.md (if produced)
      stdout.log
      stderr.log
      status.json
    nested-root/
      AGENTS.generated.md (if produced)
      stdout.log
      stderr.log
      status.json
  diagnostics/
    copilot-version.*
    copilot-help.*
    copilot-headless-version.*
    copilot-override-version.* (if override set)
  context/
    README.md
    package.json
    ...
  prompts/
    adr-synthesis-prompt.md
    adr-review-prompt.md
```

Notes:
- Missing files are expected in constrained enterprise environments.
- Preserve all stderr/status artifacts; failures are part of the evidence.
