# agent-adr (single-script collector)

A minimal operator utility for collecting repository evidence with [`microsoft/agentrc`](https://github.com/microsoft/agentrc) and building a high-quality ADR synthesis prompt for stronger reasoning models.

## Quick Start

```bash
# 1. Clone and setup
git clone https://github.com/imagineux/agent-adr.git
cd agent-adr
nvm install lts-* && nvm use

# 2. Run collection and copy to clipboard
./collect-and-prompt.sh /path/to/client/repo ../collections/client-name

# 3. Paste into Kimi K2.5
# Prompt is automatically in your clipboard
```

For restricted environments with certificate issues, the git clone method works reliably where curl-based installations fail.

See [USAGE.md](USAGE.md) for complete step-by-step guide.

## What this repo is (and is not)

This repo is intentionally **thin**.

- ✅ Uses `agentrc` as a scanner/collector in the target environment.
- ✅ Optionally attempts `agentrc instructions` generation (best effort).
- ✅ Stores all collected artifacts in a directory **outside** the target repo.
- ✅ Builds a large, structured prompt bundle with our own synthesis templates.
- ✅ Includes a reusable ADR template + synthesis skill.

- ❌ Not a full CLI platform.
- ❌ Not a reimplementation of `agentrc`.
- ❌ Not coupled to the Copilot SDK.
- ❌ Not writing into the target repo during normal collection.

## Why this exists

We use `agentrc` only as an artifact collector and optional instruction generator.

We own:
- Collection runbook
- Prompt templates
- ADR template
- Final synthesis layer and recommendations

We do **not** delegate final recommendations or ADR authorship to `agentrc`.

## Workflow model

1. **Run single command** using `./collect-and-prompt.sh`
2. **Prompt automatically copied** to clipboard
3. **Paste into Kimi K2.5** for synthesis
4. **Review and deliver** repo-specific AI enablement ADR

## Prerequisites

- Bash
- Node.js (LTS - use `nvm install lts-*` to install the latest LTS version)
- `npx` able to run `github:microsoft/agentrc`
- `python3` (required by agentrc for some operations)

## Happy path

```bash
# Clone and setup (one-time)
git clone https://github.com/imagineux/agent-adr.git
cd agent-adr
nvm install lts-* && nvm use

# Collect artifacts and copy prompt to clipboard
./collect-and-prompt.sh /path/to/target/repo ../collections/target-repo-name

# Paste into Kimi K2.5 - prompt is ready in your clipboard
```

## Core script

### `collect-and-prompt.sh`

Usage:
```bash
./collect-and-prompt.sh /path/to/client/repo ../collections/client-repo-name [model]
```

What it does:
- Validates Node.js environment
- Enforces `AGENTRC_DEBUG_COPILOT=1`
- Preserves `AGENTRC_COPILOT_CLI_PATH` if provided
- Overrides model for instruction flow (default: `gpt-5-mini`)
- Captures stdout/stderr/exit/status for analyze/readiness/probes/generation attempts
- Copies context files best-effort
- **Builds synthesis prompt in memory using Node.js**
- **Copies final prompt directly to clipboard**
- Aborts if output directory would be inside the client repo

Outputs:
- **Prompt copied to clipboard** - Ready for Kimi K2.5 synthesis
- `prompts/adr-synthesis-prompt.md` - Backup copy of prompt
- Complete collection artifacts in `../collections/client-repo-name/`

## Safety and Hardening

This wrapper has been hardened for enterprise use:

- **Repo Boundary Guard**: Collection will abort if the output directory is inside the target repo (prevents accidental repo contamination)
- **Argv-based Command Execution**: Commands are executed via arrays rather than string eval, making them safe for paths with spaces, `$`, backticks, or quotes
- **Failure Robustness**: Collection continues across probe/generation failures; all artifacts produce status/log files even on failure
- **In-Memory Processing**: Prompt building happens entirely in memory with no intermediate files

## Output artifacts

A typical collection includes:
- `analyze.json`
- `readiness.json`
- `collection-summary.json`
- `instructions-overview.md`
- Probe and generation attempts with status/logs
- `context/` (best-effort copied files)
- `prompts/adr-synthesis-prompt.md` (backup copy)

## Templates

- `templates/adr-synthesis-template.md` — synthesis prompt
- `templates/ai-enablement-adr-template.md` — structured ADR output contract

## Installation

**Single blessed method: Git clone**
```bash
git clone https://github.com/imagineux/agent-adr.git
cd agent-adr
nvm install lts-* && nvm use
```

This works in all environments, including those with certificate restrictions where curl-based installers fail.

## Usage

**Single command does everything:**
```bash
./collect-and-prompt.sh /path/to/repo ../collections/repo-name
```

The prompt will be automatically copied to your clipboard, ready for Kimi K2.5.

## AI Enablement Framework

### 8-Layer Maturity Model

This tool uses an 8-layer framework to assess AI readiness:

1. **Repository & documentation basics** - Clean, well-documented codebase
2. **Build/test reliability** - Consistent CI/CD and quality gates  
3. **Work decomposition & task clarity** - Tasks broken into AI-assistable units
4. **AI-facing instructions quality** - Clear, context-aware AI guidance
5. **Evaluation and feedback loops** - Systematic assessment of AI output quality
6. **Safe workflow automation** - Repeatable AI-augmented processes
7. **Cross-tool integration** - AI capabilities connected across development stack
8. **Adaptive/autonomous operation** - Learning and improvement loops

### Available AI Capabilities

| Capability | Description | Maturity Level Required |
|------------|-------------|------------------------|
| **Copilot CLI** | Command-line AI assistance for development tasks | Layer 3-4 |
| **Copilot Instructions** | Repository-specific AI behavior guidance | Layer 4 |
| **Prompting Skills** | Human-AI interaction patterns and techniques | Layer 3-5 |
| **Evaluation Frameworks** | Systematic assessment of AI output quality | Layer 5-6 |
| **GitHub Actions Hooks** | Automated workflow integration points | Layer 6-7 |

### Decision-Making Framework

When evaluating AI enablement investments:

| Factor | Weight | Questions to Ask |
|--------|--------|------------------|
| **Impact** | 30% | Does this significantly improve developer productivity or code quality? |
| **Feasibility** | 25% | Do we have the skills and infrastructure to implement this effectively? |
| **Risk** | 20% | What are the safety, security, or quality risks? |
| **Cost** | 15% | What is the implementation and maintenance cost? |
| **Strategic Alignment** | 10% | Does this support our broader technical and business goals? |
