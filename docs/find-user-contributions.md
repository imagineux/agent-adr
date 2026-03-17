# find-user-contributions

Find all repositories in a GitHub organization that specific users have contributed to in the last 12 months.

## Usage

```bash
# Basic usage
find-user-contributions -o microsoft -u "user1,user2,user3"

# With custom time period
find-user-contributions -o microsoft -u "user1,user2" -d 180

# Output as JSON
find-user-contributions -o microsoft -u "user1,user2" --json

# Output as CSV
find-user-contributions -o microsoft -u "user1,user2" --csv

# With explicit token
find-user-contributions -o microsoft -u "user1,user2" -t "ghp_your_token"
```

## Options

- `-o, --org <organization>`: GitHub organization name (required)
- `-u, --users <users>`: Comma-separated list of user IDs or usernames (required)
- `-t, --token <token>`: GitHub Personal Access Token (overrides GITHUB_PAT env var)
- `-d, --days <days>`: Number of days to look back (default: 365)
- `--json`: Output results as JSON
- `--csv`: Output results as CSV

## Authentication

Set your GitHub Personal Access Token as an environment variable:

```bash
export GITHUB_PAT="ghp_your_token_here"
```

**Required Token Scopes:**
- `repo` - Full repository access
- `read:org` - Read organization data

## What it checks

For each repository in the organization, the script checks for:

1. **Commits** - Commits authored by the specified users
2. **Pull Requests** - Pull requests created by the users
3. **Issues** - Issues created by the users

Only repositories with at least one contribution from any of the specified users are included in the results.

## Output Examples

### Default Output
```
📦 microsoft/TypeScript
   TypeScript is a language for application scale JavaScript development
   Language: TypeScript | Private: No
   Contributors: 2
   👤 user1:
      Commits: 5
      Pull Requests: 2
      Last Commit: 3/15/2024
   👤 user2:
      Issues: 1
```

### JSON Output
```json
[
  {
    "repository": "microsoft/TypeScript",
    "description": "TypeScript is a language for application scale JavaScript development",
    "language": "TypeScript",
    "private": false,
    "contributions": {
      "user1": {
        "commits": 5,
        "pullRequests": 2,
        "lastCommit": "2024-03-15T10:30:00Z"
      }
    },
    "totalContributors": 1
  }
]
```

### CSV Output
```csv
Repository,Description,Language,Private,Contributors,User,Commits,PRs,Issues
"microsoft/TypeScript","TypeScript is a language for application scale JavaScript development","TypeScript",False,1,user1,5,2,0
```

## Rate Limiting

The script includes built-in rate limiting protection:
- Small delays between API calls
- Efficient pagination (100 items per request)
- Minimal API calls per repository

## Installation

If you've installed agent-adr globally, the command will be available immediately:

```bash
npm install -g github:imagineux/agent-adr
find-user-contributions -o your-org -u "user1,user2"
```

For local development:

```bash
git clone https://github.com/imagineux/agent-adr.git
cd agent-adr
npm install
./bin/find-user-contributions.mjs -o your-org -u "user1,user2"
```
