# Auto-Batch: Interactive Team-Based Repository Discovery

Automatically discover repositories that team members have contributed to and run batch analysis without manual repository selection.

## Quick Start

```bash
# Simple interactive command
agent-adr auto-batch

# With pre-selected organization
agent-adr auto-batch --org okja-engineering

# With custom repository pattern
agent-adr auto-batch --org okja-engineering --pattern "service-*"

# With custom time window
agent-adr auto-batch --org okja-engineering --days 180
```

## How It Works

### Interactive Workflow

1. **Organization Selection** - Choose from your accessible organizations
2. **Team Discovery** - Browse available teams in the selected organization  
3. **Team Selection** - Multi-select teams to analyze (checkbox interface)
4. **User Review** - All team members pre-selected, deselect any you want to exclude
5. **Repository Discovery** - Find repos contributed by selected users (last 12 months)
6. **Pattern Filtering** - Filter repositories by name pattern (default: `*`, matches all repos)
7. **Confirmation** - Review discovered repositories before analysis
8. **Batch Analysis** - Automatic analysis of all discovered repositories

### Command Options

- `--org <organization>` - Pre-select organization (skips organization selection)
- `--pattern <pattern>` - Repository name pattern (default: `*`, matches all repos, case-insensitive)
- `--days <days>` - Number of days to look back for contributions (default: 365)

## Example Session

```bash
$ agent-adr auto-batch --org okja-engineering

🚀 Starting interactive team-based repository discovery...

✔ Connected as: imagineux

📂 Using specified organization: okja-engineering

🔍 Discovering teams in okja-engineering...

? Select teams to analyze:
❯ ◯ Engineering Managers (0 members)
  ◯ Individual Contributors (1 member)

👥 Discovering users from 1 teams...

? Review users (deselect any you want to exclude):
❯ ☒ imagineux - Teams: individual-contributors

✅ Selected 1 users from 1 teams

🔍 Finding repositories contributed by selected users in the last 365 days...

📊 Found 7 repositories with user contributions
📋 Showing all 7 repositories

📦 Discovered repositories:
  - okja-engineering/api-service (Go, Private)
  - okja-engineering/web-frontend (TypeScript, Public)
  - okja-engineering/ai-service (Go, Private)
  - okja-engineering/ai-frontend (TypeScript, Public)
  - okja-engineering/utils (JavaScript, Public)
  - okja-engineering/config (HCL, Private)
  - okja-engineering/docs (Markdown, Public)

? Run batch analysis on 7 repositories? Yes

🚀 Starting batch analysis...
✅ Batch analysis complete!
📊 Summary JSON created: .agent-adr-cache/batch-summary.json
📈 Analyzed 7/7 repositories successfully
```

## Pattern Matching

Repository name patterns use simple wildcard matching. By default, auto-batch shows all repositories (`*` pattern), but you can filter:

- `ai-*` - Matches repositories starting with "ai-"
- `service-*` - Matches repositories starting with "service-"
- `*-api` - Matches repositories ending with "-api"
- `*test*` - Matches repositories containing "test" anywhere

Patterns are case-insensitive.

## Authentication

The same authentication as other agent-adr commands:

```bash
# Set up authentication
agent-adr auth-setup

# Or use environment variable
export GITHUB_PAT="ghp_your_token_here"
```

**Required Token Scopes:**
- `repo` - Full repository access
- `read:org` - Read organization data (for team discovery)

## Output

The auto-batch command generates the same output as the regular batch command:

- **JSON Summary**: `.agent-adr-cache/batch-summary.json`
- **Analysis Data**: Individual repository analysis in subdirectories
- **Readiness Scores**: AI readiness assessment for each repository

## Use Cases

### Team Performance Analysis
```bash
# Analyze all repositories your engineering team has worked on
agent-adr auto-batch --org your-company --pattern "*"
```

### Project-Specific Analysis
```bash
# Find all ai-related repositories your team contributed to
agent-adr auto-batch --org your-company --pattern "ai-*"
```

### Recent Activity Analysis
```bash
# Focus on contributions from the last 6 months
agent-adr auto-batch --org your-company --days 180
```

### Cross-Team Analysis
```bash
# Select multiple teams to get a broader view
agent-adr auto-batch --org your-company
# (then select multiple teams in the interactive interface)
```

## Rate Limiting

The tool includes built-in rate limiting protection:
- Small delays between API calls
- Efficient pagination (100 items per request)
- Minimal API calls per repository

## Troubleshooting

### "No teams found"
- Your organization may not have teams set up
- Your token may not have `read:org` scope
- You may not be a member of any teams

### "No repositories found matching the pattern"
- Try a broader pattern (e.g., `*` instead of `ai-*`)
- Check if users have contributed in the time window
- Verify pattern syntax

### "Authentication failed"
```bash
agent-adr auth-setup
```

### Debug Mode
```bash
export DEBUG=agent-adr:*
agent-adr auto-batch
```

## Integration with Other Tools

The output is fully compatible with other agent-adr tools:

```bash
# Run auto-batch discovery
agent-adr auto-batch --org okja-engineering

# Generate comprehensive report
generate-ai-report

# Use with find-user-contributions for detailed analysis
find-user-contributions -o okja-engineering -u "user1,user2" --json
```
