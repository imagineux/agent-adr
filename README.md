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
- agentrc (automatically installed as npm dependency)
- GitHub Personal Access Token (for private repositories)

## Authentication Setup

For accessing private GitHub repositories, you'll need to configure authentication:

```bash
# Interactive setup (recommended)
agent-adr auth-setup

# Or provide token directly
agent-adr auth-setup --token "ghp_your_token_here"

# Or use environment variable
export GITHUB_PAT="ghp_your_token_here"
```

**Required Token Scopes:**
- `repo` - Full repository access
- `read:org` - Read organization data (for batch processing)

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
# Single repository
agent-adr /path/to/client/repo --output ../collections/client-repo-name
agent-adr owner/repo --output ../collections/client-repo-name  # GitHub remote
agent-adr https://github.com/owner/repo --output ../collections/client-repo-name

# Multiple repositories (individual processing)
agent-adr owner/repo1 owner/repo2 owner/repo3 --output ../collections/batch-analysis

# Batch processing (recommended for multiple repos)
agent-adr owner/repo1 owner/repo2 owner/repo3 --output ../collections/batch-analysis --batch

# Interactive repository discovery (NEW!)
agent-adr discover
agent-adr discover --org microsoft

# Options
--output DIR         Output directory for collection artifacts and prompts (required)
--education          Use educational synthesis template with comprehensive framework
--model MODEL        AI model to use (default: gpt-5-mini)
--timeout SECONDS    Timeout per command in seconds (default: 300)
--interactive        Interactive mode - review and confirm each step
--batch              Process multiple repositories using agentrc batch command
```

**Repository Formats:**
- Local path: `/path/to/local/repo`
- GitHub identifier: `owner/repo`
- Full GitHub URL: `https://github.com/owner/repo`

Remote repos are accessed directly via GitHub API (no cloning required).

What it does:
- Validates Node.js environment
- Enforces `AGENTRC_DEBUG_COPILOT=1`
- Preserves `AGENTRC_COPILOT_CLI_PATH` if provided
- Overrides model for instruction flow (default: `gpt-5-mini`)
- **Accesses remote repos via GitHub API** (no temporary directories)
- Supports batch processing of multiple repositories
- Captures stdout/stderr/exit/status for analyze/readiness/probes/generation attempts
- Copies context files for local repos only
- **Builds synthesis prompt in memory using Node.js**
- **Saves prompt to file for easy copy/paste**
- Aborts if output directory would be inside the client repo (local repos only)

Outputs:
- **Prompt saved to file** - Ready for any advanced AI model synthesis
- `prompts/adr-synthesis-prompt.md` - Complete synthesis prompt
- Complete collection artifacts in `../collections/client-repo-name/`

## New Features: GitHub API Integration & Batch Processing

### Key Improvements
- **No More Cloning**: Remote repositories are accessed directly via GitHub API
- **Private Repo Support**: Full support for private repositories with PAT authentication
- **Batch Processing**: Process multiple repositories efficiently using agentrc's batch command
- **Better Performance**: Leverages agentrc's internal optimization and caching
- **Enterprise Ready**: Proper authentication and error handling

### Authentication
- Secure PAT storage in `~/.config/agent-adr/config.json`
- Environment variable fallback (`GITHUB_PAT`)
- Token validation during setup
- Required scopes: `repo`, `read:org`

### Batch Processing Benefits
- Parallel processing of multiple repositories
- Single command execution across repos
- Consolidated output for cross-repo analysis
- Leverages agentrc's built-in remote capabilities

## Interactive Repository Discovery

**New: Step-by-step repository selection workflow**

```bash
# Interactive discovery with organization and repository selection
agent-adr discover

# Target specific organization with filtering
agent-adr discover --org microsoft
agent-adr discover --org microsoft --name "TypeScript-*"
agent-adr discover --org mycompany --name "tps-*" --private
agent-adr discover --org myorg --language "TypeScript" --description "*API*"
```

**Workflow Steps:**
1. **Authentication Check** - Validates GitHub PAT access
2. **Organization Selection** - Choose from your available organizations
3. **Repository Selection** - Multi-select repositories to analyze  
4. **Configuration** - Set output directory and processing options
5. **Automatic Execution** - Runs analysis with selected repositories

**Filtering Options:**
```bash
--org <org>              Target specific organization
--name <pattern>         Filter by repository name (supports wildcards)
--description <pattern>  Filter by description text (supports wildcards)  
--language <language>    Filter by primary programming language
--private               Show only private repositories
--public                Show only public repositories
```

**Pattern Matching:**
- Use `*` as wildcard: `"tps-*"` matches "tps-api", "tps-web", etc.
- Case insensitive: `"typescript"` matches "TypeScript" and "typescript"
- Description filtering searches repository descriptions

**Examples:**
```bash
# Find all repos starting with "tps-" in my company
agent-adr discover --org mycompany --name "tps-*"

# Find TypeScript repositories with "API" in description
agent-adr discover --org myorg --language TypeScript --description "*API*"

# Find only private repositories with "service" in name
agent-adr discover --org mycompany --name "*service*" --private
```

**Benefits:**
- ✅ No need to manually type repository names
- ✅ See repository descriptions and privacy status
- ✅ Browse your accessible organizations and repos
- ✅ Interactive multi-selection with validation
- ✅ Powerful filtering with pattern matching
- ✅ Automatic batch processing optimization

**Example Session:**
```bash
$ agent-adr discover

🔍 Discovering GitHub repositories...
✔ Connected as: your-username

? Select organization: 
❯ your-username - Personal repositories
  organization1 - Company repos  
  organization2 - Open source projects

? Select repositories to analyze:
❯ ◯ repo1 - Description here (🌍 public)
  ◯ repo2 - Private project (🔒 private)
  ◯ repo3 - Another repo (🌍 public)

? Output directory for collection: ../collections/my-analysis
? Use batch processing for better performance? Yes

🚀 Starting analysis...
```

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
