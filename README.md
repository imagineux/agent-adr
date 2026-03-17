# agent-adr (Streamlined Batch Analysis)

A streamlined batch analysis tool for repository AI readiness assessment using [`microsoft/agentrc`](https://github.com/microsoft/agentrc).

## Quick Start

```bash
# 1. Install globally
npm install -g github:imagineux/agent-adr

# 2. Set up authentication
agent-adr auth-setup

# 3. Run batch analysis
agent-adr batch                    # Interactive org and repo selection
agent-adr batch --org microsoft   # Skip org selection

# 4. Team-based auto discovery (NEW!)
agent-adr auto-batch               # Interactive team and user selection (all repos)
agent-adr auto-batch --org okja-engineering --pattern "ai-*"  # Targeted analysis
```

## What this repo is (and is not)

This repo is intentionally **minimal** and **focused**.

- ✅ Uses `agentrc` for repository analysis and readiness assessment
- ✅ Provides interactive organization and repository selection
- ✅ Generates consolidated JSON summary of batch analysis
- ✅ Handles both local and remote repositories

- ❌ Not a full CLI platform with multiple commands
- ❌ No prompt generation or AI synthesis templates
- ❌ No TUI mode or interactive workflows
- ❌ No educational frameworks or ADR templates

## Why this exists

We use `agentrc` as the analysis engine and focus on:
- **Simple batch workflow** - Authenticate → Select org → Analyze repos → JSON summary
- **Repository readiness data** - Analysis and readiness scores for portfolio assessment
- **Consolidated output** - Single JSON file with all repository data

## Workflow model

1. **Install globally** - `npm install -g github:imagineux/agent-adr`
2. **Set up authentication** - `agent-adr auth-setup`
3. **Run batch analysis** - `agent-adr batch`
4. **Review JSON summary** - Check `.agent-adr-cache/batch-summary.json`

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

## Core Commands

### `agent-adr batch` (primary command)

Interactive batch repository analysis:

```bash
# Interactive organization and repository selection
agent-adr batch

# Target specific organization
agent-adr batch --org microsoft
```

**Workflow:**
1. **Authentication Check** - Validates GitHub PAT access
2. **Organization Selection** - Choose from your available organizations
3. **Repository Selection** - Multi-select repositories to analyze  
4. **Batch Analysis** - Automatic analysis with real-time progress
5. **JSON Summary** - Consolidated results in `.agent-adr-cache/batch-summary.json`

### `agent-adr auto-batch` (team-based discovery)

Interactive team-based repository discovery and analysis:

```bash
# Simple interactive command
agent-adr auto-batch

# With pre-selected organization
agent-adr auto-batch --org okja-engineering

# With custom repository pattern
agent-adr auto-batch --org okja-engineering --pattern "ai-*"

# With custom time window
agent-adr auto-batch --org okja-engineering --days 180
```

**Workflow:**
1. **Organization Selection** - Choose from your accessible organizations
2. **Team Discovery** - Browse available teams in the selected organization  
3. **Team Selection** - Multi-select teams to analyze
4. **User Review** - All team members pre-selected, deselect any you want to exclude
5. **Repository Discovery** - Find repos contributed by selected users (last 12 months)
6. **Pattern Filtering** - `--pattern <pattern>` - Repository name pattern (default: `*`, matches all repos)
7. **Confirmation** - Review discovered repositories before analysis
8. **Batch Analysis** - Automatic analysis of all discovered repositories

**Key Features:**
- **Team-Based**: Automatically discover teams and their members
- **Contribution-Driven**: Analysis based on actual code contributions, not just permissions
- **Pattern Matching**: Filter repositories by naming patterns (e.g., `ai-*`, `service-*`)
- **Interactive Selection**: Flexible user selection with deselection options
- **Time Windows**: Configurable lookback periods for contribution analysis

### `generate-ai-report` (report generation)

Generate comprehensive report combining analysis data with documentation:

```bash
# Generate report with default paths
generate-ai-report

# Custom paths
generate-ai-report /path/to/batch-summary.json /path/to/output.md

# Using npm script
npm run report
```

**Output:** Single markdown file containing:
- Executive summary of analysis results
- Repository overview table
- Detailed analysis and readiness data
- **AI ADR Synthesis Prompt** - Ready-to-use prompt for AI models
- Complete documentation (ADR template, educational framework, portfolio guide)
- Next steps and implementation guidance

### `agent-adr auth-setup`

Configure GitHub authentication:

```bash
# Interactive token setup
agent-adr auth-setup

# Direct token provision
agent-adr auth-setup --token "ghp_your_token_here"
```

## Output Structure

**Analysis Data:**
```
.agent-adr-cache/
├── batch-summary.json    # Consolidated analysis results
└── reports/              # Generated comprehensive reports
    └── comprehensive-ai-readiness-report.md
```

**Batch Summary JSON Structure:**
```json
{
  "timestamp": "2024-03-16T16:05:00.000Z",
  "totalRepos": 5,
  "successfulRepos": 4,
  "failedRepos": 1,
  "repositories": ["owner/repo1", "owner/repo2", ...],
  "results": {
    "owner/repo1": {
      "results": {
        "analyze": { "success": true, "stdout": "...", "elapsed": 45 },
        "readiness": { "success": true, "stdout": "...", "elapsed": 32 }
      },
      "overallSuccess": true
    }
  }
}
```

## Example Session

```bash
$ agent-adr batch

🔍 Discovering GitHub repositories...
✔ Connected as: your-username

? Select organization: 
❯ your-username - Personal repositories
  organization1 - Company repos  

? Select repositories to analyze:
❯ ◯ repo1 - Description here (🌍 public)
  ◯ repo2 - Private project (🔒 private)

✅ Selected 2 repositories:
  - owner/repo1
  - owner/repo2

🚀 Starting batch analysis...
📦 Processing repository 1/2: owner/repo1
✅ Completed owner/repo1
📦 Processing repository 2/2: owner/repo2
✅ Completed owner/repo2

✅ Batch analysis complete!
📊 Summary JSON created: .agent-adr-cache/batch-summary.json
📈 Analyzed 2/2 repositories successfully
```

## Data Collected

For each repository, the tool collects:

### Analysis Data (`analyze.json`)
- Repository structure and languages
- Frameworks and dependencies
- Build system information
- Documentation assessment

### Readiness Data (`readiness.json`)
- Overall AI readiness score (0-100)
- Engineering maturity assessment
- Infrastructure readiness
- Documentation quality
- Safety and governance evaluation

## Safety and Hardening

This tool has been hardened for enterprise use:

- **Secure Authentication** - PAT tokens stored securely in user config
- **Safe Command Execution** - Commands executed via arrays, not string eval
- **Error Handling** - Continues analysis across individual repository failures
- **Temporary Cleanup** - Automatic cleanup of temporary cloned repositories

## Documentation

The tool includes comprehensive documentation for teams preparing ADRs based on analysis results:

### [ADR Template](docs/adr-template.md)
Structured template for creating AI Enablement Architecture Decision Records based on your analysis data.

### [Educational Framework](docs/educational-framework.md)
8-layer maturity model for assessing AI readiness and planning implementation strategies.

### [Synthesis Prompt Template](docs/synthesis-prompt-template.md)
Comprehensive AI prompt template with placeholders for generating detailed Architecture Decision Records using your preferred AI model.

### [Portfolio Analysis Guide](docs/portfolio-analysis-guide.md)
Complete guide for interpreting batch analysis results and making strategic decisions.

## Using Documentation with Analysis Results

1. **Run batch analysis**: `agent-adr batch`
2. **Review results**: Check `.agent-adr-cache/batch-summary.json`
3. **Generate comprehensive report**: `generate-ai-report`
4. **Find your report**: Check `.agent-adr-cache/reports/comprehensive-ai-readiness-report.md`
5. **Copy AI Synthesis Prompt**: Use the prompt section in the generated report
6. **Generate ADR with AI**: Paste the prompt into ChatGPT, Claude, or your preferred AI model
7. **Refine with templates**: Use [ADR Template](docs/adr-template.md) and [Educational Framework](docs/educational-framework.md) to enhance the AI-generated content
8. **Plan implementation**: Follow [Portfolio Analysis Guide](docs/portfolio-analysis-guide.md) for strategic rollout

## Complete Workflow Example

```bash
# 1. Set up authentication
agent-adr auth-setup

# 2. Run batch analysis
agent-adr batch --org Okja-Engineering

# 3. Generate comprehensive report (saved to .agent-adr-cache/reports/)
generate-ai-report

# 4. Find your report at: .agent-adr-cache/reports/comprehensive-ai-readiness-report.md
# 5. Copy the AI Synthesis Prompt from the report and paste into your AI model
# 6. Use the generated ADR with the documentation templates to finalize your strategy
```

All analysis data and reports are now organized in the `.agent-adr-cache/` directory:
- `batch-summary.json` - Raw analysis results
- `reports/` - Generated comprehensive reports with AI synthesis prompts

## Troubleshooting

### Common Issues

**"No GitHub authentication found"**
```bash
agent-adr auth-setup
```

**"Organization not found or not accessible"**
- Ensure your PAT has `read:org` scope
- Verify you're a member of the target organization

**"Repository access failed"**
- Check PAT has `repo` scope
- Verify repository permissions
- For private repos, ensure you're a collaborator

### Debug Mode

Set environment variable for detailed logging:
```bash
export DEBUG=agent-adr:*
agent-adr batch
```

## License

MIT License - see LICENSE file for details.
