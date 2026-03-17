#!/usr/bin/env node

import { Octokit } from '@octokit/rest';
import { Command } from 'commander';
import chalk from 'chalk';
import ora from 'ora';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const program = new Command();

program
  .name('find-user-contributions')
  .description('Find all repos in an organization that specific users have contributed to in the last 12 months')
  .requiredOption('-o, --org <organization>', 'GitHub organization name')
  .requiredOption('-u, --users <users>', 'Comma-separated list of user IDs or usernames')
  .option('-t, --token <token>', 'GitHub Personal Access Token (overrides GITHUB_PAT env var)')
  .option('-d, --days <days>', 'Number of days to look back (default: 365)', '365')
  .option('--json', 'Output results as JSON')
  .option('--csv', 'Output results as CSV')
  .parse(process.argv);

const options = program.opts();

function getGitHubToken() {
  return options.token || process.env.GITHUB_PAT;
}

function validateInputs() {
  const token = getGitHubToken();
  if (!token) {
    console.error(chalk.red('❌ GitHub token is required. Set GITHUB_PAT environment variable or use --token option'));
    process.exit(1);
  }

  if (!options.org) {
    console.error(chalk.red('❌ Organization is required (-o, --org)'));
    process.exit(1);
  }

  if (!options.users) {
    console.error(chalk.red('❌ Users list is required (-u, --users)'));
    process.exit(1);
  }
}

async function getOrganizationRepos(octokit, org) {
  const spinner = ora(`Fetching repositories for ${chalk.cyan(org)}...`).start();
  
  try {
    const repos = [];
    let page = 1;
    let hasMore = true;

    while (hasMore) {
      const response = await octokit.rest.repos.listForOrg({
        org,
        type: 'all',
        per_page: 100,
        page,
      });

      repos.push(...response.data);
      hasMore = response.data.length === 100;
      page++;
    }

    spinner.succeed(`Found ${chalk.green(repos.length)} repositories in ${chalk.cyan(org)}`);
    return repos;
  } catch (error) {
    spinner.fail(`Failed to fetch repositories for ${chalk.cyan(org)}`);
    throw error;
  }
}

async function getUserContributions(octokit, repo, usernames, daysAgo) {
  const sinceDate = new Date();
  sinceDate.setDate(sinceDate.getDate() - parseInt(daysAgo));
  
  const contributions = new Map();
  
  for (const username of usernames) {
    try {
      // Check commits by user
      const commits = await octokit.rest.repos.listCommits({
        owner: repo.owner.login,
        repo: repo.name,
        author: username,
        since: sinceDate.toISOString(),
        per_page: 1, // We only need to know if there's at least one
      });

      if (commits.data.length > 0) {
        contributions.set(username, {
          commits: commits.data.length,
          lastCommit: commits.data[0].commit.author.date,
        });
      }

      // Check pull requests by user
      const prs = await octokit.rest.pulls.list({
        owner: repo.owner.login,
        repo: repo.name,
        creator: username,
        state: 'all',
        since: sinceDate.toISOString(),
        per_page: 1,
      });

      if (prs.data.length > 0 && contributions.has(username)) {
        const existing = contributions.get(username);
        existing.pullRequests = prs.data.length;
        contributions.set(username, existing);
      } else if (prs.data.length > 0) {
        contributions.set(username, {
          commits: 0,
          pullRequests: prs.data.length,
          lastCommit: null,
        });
      }

      // Check issues by user (as contributor, not just commenter)
      const issues = await octokit.rest.issues.listForRepo({
        owner: repo.owner.login,
        repo: repo.name,
        creator: username,
        state: 'all',
        since: sinceDate.toISOString(),
        per_page: 1,
      });

      if (issues.data.length > 0 && contributions.has(username)) {
        const existing = contributions.get(username);
        existing.issues = issues.data.length;
        contributions.set(username, existing);
      } else if (issues.data.length > 0) {
        contributions.set(username, {
          commits: 0,
          pullRequests: 0,
          issues: issues.data.length,
          lastCommit: null,
        });
      }

    } catch (error) {
      // Skip if user not found or no access
      continue;
    }
  }

  return contributions;
}

async function findUserContributions() {
  validateInputs();

  const octokit = new Octokit({
    auth: getGitHubToken(),
  });

  const usernames = options.users.split(',').map(u => u.trim());
  const daysAgo = parseInt(options.days);
  const sinceDate = new Date();
  sinceDate.setDate(sinceDate.getDate() - daysAgo);

  console.log(chalk.blue(`🔍 Finding contributions for ${chalk.cyan(usernames.length)} users in ${chalk.cyan(options.org)}`));
  console.log(chalk.gray(`Looking back ${daysAgo} days (since ${sinceDate.toISOString().split('T')[0]})`));
  console.log();

  try {
    // Test authentication
    const authSpinner = ora('Verifying GitHub authentication...').start();
    const { data: user } = await octokit.rest.users.getAuthenticated();
    authSpinner.succeed(`Authenticated as ${chalk.cyan(user.login)}`);

    // Get organization repositories
    const repos = await getOrganizationRepos(octokit, options.org);

    // Check each repository for user contributions
    const results = [];
    const progressSpinner = ora('Checking repositories for user contributions...').start();
    
    for (let i = 0; i < repos.length; i++) {
      const repo = repos[i];
      progressSpinner.text = `Checking repository ${i + 1}/${repos.length}: ${repo.full_name}`;
      
      const contributions = await getUserContributions(octokit, repo, usernames, daysAgo);
      
      if (contributions.size > 0) {
        const contributionData = {
          repository: repo.full_name,
          description: repo.description,
          language: repo.language,
          private: repo.private,
          contributions: Object.fromEntries(contributions),
          totalContributors: contributions.size,
        };
        results.push(contributionData);
      }

      // Add small delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    progressSpinner.succeed(`Checked ${repos.length} repositories`);

    // Display results
    console.log();
    console.log(chalk.blue(`📊 Results: Found ${chalk.green(results.length)} repositories with user contributions`));
    console.log();

    if (results.length === 0) {
      console.log(chalk.yellow('No repositories found with contributions from the specified users.'));
      return;
    }

    if (options.json) {
      console.log(JSON.stringify(results, null, 2));
    } else if (options.csv) {
      console.log('Repository,Description,Language,Private,Contributors,User,Commits,PRs,Issues');
      results.forEach(repo => {
        Object.entries(repo.contributions).forEach(([user, contrib]) => {
          console.log(`"${repo.repository}","${repo.description || ''}","${repo.language || ''}",${repo.private},${repo.totalContributors},${user},${contrib.commits || 0},${contrib.pullRequests || 0},${contrib.issues || 0}`);
        });
      });
    } else {
      results.forEach(repo => {
        console.log(chalk.cyan(`📦 ${repo.repository}`));
        console.log(chalk.gray(`   ${repo.description || 'No description'}`));
        console.log(chalk.gray(`   Language: ${repo.language || 'Unknown'} | Private: ${repo.private ? 'Yes' : 'No'}`));
        console.log(chalk.gray(`   Contributors: ${repo.totalContributors}`));
        
        Object.entries(repo.contributions).forEach(([user, contrib]) => {
          console.log(chalk.green(`   👤 ${user}:`));
          if (contrib.commits > 0) console.log(chalk.gray(`      Commits: ${contrib.commits}`));
          if (contrib.pullRequests > 0) console.log(chalk.gray(`      Pull Requests: ${contrib.pullRequests}`));
          if (contrib.issues > 0) console.log(chalk.gray(`      Issues: ${contrib.issues}`));
          if (contrib.lastCommit) console.log(chalk.gray(`      Last Commit: ${new Date(contrib.lastCommit).toLocaleDateString()}`));
        });
        console.log();
      });
    }

    // Summary statistics
    const totalUsers = new Set();
    results.forEach(repo => {
      Object.keys(repo.contributions).forEach(user => totalUsers.add(user));
    });

    console.log(chalk.blue('📈 Summary Statistics:'));
    console.log(chalk.gray(`   Total repositories with contributions: ${results.length}`));
    console.log(chalk.gray(`   Total users who contributed: ${totalUsers.size}`));
    console.log(chalk.gray(`   Organizations searched: 1 (${options.org})`));
    console.log(chalk.gray(`   Time period: Last ${daysAgo} days`));

  } catch (error) {
    console.error(chalk.red('❌ Error:'), error.message);
    if (error.status === 401) {
      console.error(chalk.red('Authentication failed. Please check your GitHub token.'));
    } else if (error.status === 403) {
      console.error(chalk.red('Rate limit exceeded or insufficient permissions.'));
    } else if (error.status === 404) {
      console.error(chalk.red('Organization not found or not accessible.'));
    }
    process.exit(1);
  }
}

// Run the command
findUserContributions().catch(error => {
  console.error(chalk.red('❌ Unexpected error:'), error);
  process.exit(1);
});
