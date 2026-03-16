# agent-adr (single-script collector)

A minimal operator utility for collecting repository evidence with [`microsoft/agentrc`](https://github.com/microsoft/agentrc) and building a high-quality ADR synthesis prompt for stronger reasoning models.

## Quick Start

```bash
# 1. Install globally
npm install -g github:imagineux/agent-adr

# 2. Run collection (local or remote)
agent-adr /path/to/client/repo --output ../collections/client-name
agent-adr microsoft/vscode --output ../collections/vscode

# 3. With educational framework (comprehensive analysis)
agent-adr microsoft/vscode --output ../collections/vscode --education

# 4. Paste into your preferred advanced AI model
# Copy the prompt from: ../collections/client-name/prompts/adr-synthesis-prompt.md
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

1. **Install globally** - `npm install -g github:imagineux/agent-adr`
2. **Run single command** using `agent-adr --output`
3. **Prompt saved to output directory** - Ready to copy/paste
4. **Paste into your preferred advanced AI model** for synthesis
5. **Review and deliver** repo-specific AI enablement ADR

## Prerequisites

- Bash
- Node.js 18+ (use `nvm install 18` to install)
- npm (comes with Node.js)
- git (for cloning remote repos)
- agentrc (automatically installed as npm dependency)

## Installation

```bash
# Global installation (recommended)
npm install -g github:imagineux/agent-adr

# Or local development setup
git clone https://github.com/imagineux/agent-adr.git
cd agent-adr
npm install
```

## Happy path

```bash
# Global installation - one time setup
npm install -g github:imagineux/agent-adr

# Collect artifacts and generate prompt
agent-adr /path/to/target/repo --output ../collections/target-repo-name

# Copy prompt from output directory - ready to paste into your preferred advanced AI model
```

## Core script

### `agent-adr` (global command)

Usage:
```bash
agent-adr /path/to/client/repo --output ../collections/client-repo-name [model] [timeout]
agent-adr owner/repo --output ../collections/client-repo-name [model] [timeout]  # GitHub remote
agent-adr https://github.com/owner/repo --output ../collections/client-repo-name [model] [timeout]

Arguments:
  repo-path           Local path or GitHub repository (owner/repo or full URL)
  --output OUTPUT     Output directory for collection artifacts and prompts
  model               AI model to use (default: gpt-5-mini)
  timeout             Timeout per command in seconds (default: 300)
```

Remote repos are automatically cloned to a temporary directory for analysis.

What it does:
- Validates Node.js environment
- Enforces `AGENTRC_DEBUG_COPILOT=1`
- Preserves `AGENTRC_COPILOT_CLI_PATH` if provided
- Overrides model for instruction flow (default: `gpt-5-mini`)
- Clones remote repos to temporary directories (auto-cleanup)
- Captures stdout/stderr/exit/status for analyze/readiness/probes/generation attempts
- Copies context files best-effort
- **Builds synthesis prompt in memory using Node.js**
- **Saves prompt to file for easy copy/paste**
- Aborts if output directory would be inside the client repo (local repos only)

Outputs:
- **Prompt saved to file** - Ready for any advanced AI model synthesis
- `prompts/adr-synthesis-prompt.md` - Complete synthesis prompt
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

The tool uses different synthesis templates based on the analysis depth required:

### Standard Template (`adr-synthesis-template.md`)
- Basic repository analysis and AI readiness assessment
- Focused on practical recommendations
- Suitable for quick assessments and mature repositories

### Educational Template (`adr-synthesis-with-education-template.md`) 
- **Template composition** - Includes standard template + educational framework
- **8-layer maturity model** for comprehensive AI readiness assessment
- **Evaluation matrix** for recommendation sequencing and risk assessment
- **Enhanced analysis requirements** - team readiness, resource planning, validation experiments
- Suitable for organizations new to AI or needing comprehensive transformation plans

### ADR Output Template (`ai-enablement-adr-template.md`)
- Structured format for the final Architecture Decision Record
- Standard sections for consistent documentation
- Used by both synthesis templates for output formatting

**Template selection:**
```bash
# Standard analysis
agent-adr repo --output ../collections/repo

# Educational analysis with comprehensive framework
agent-adr repo --output ../collections/repo --education
```

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
# Local repository
agent-adr /path/to/repo --output ../collections/repo-name

# GitHub repository (owner/repo format)
agent-adr microsoft/vscode --output ../collections/vscode

# Full GitHub URL
agent-adr https://github.com/microsoft/vscode --output ../collections/vscode

# Custom model and timeout
agent-adr microsoft/vscode --output ../collections/vscode gpt-4o 600
```

Remote repos are automatically cloned to temporary directories and cleaned up afterward.

The prompt will be saved to `../collections/repo-name/prompts/adr-synthesis-prompt.md`, ready for any advanced AI model.

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
