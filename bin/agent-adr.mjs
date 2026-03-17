#!/usr/bin/env node

/**
 * agent-adr: Repository AI Enablement ADR Synthesis Tool
 * 
 * Collects repository evidence with agentrc and builds synthesis prompts
 * for AI enablement architecture decision records.
 */

import fs from 'fs';
import path from 'path';
import { spawn } from 'child_process';
import { Command } from 'commander';
import inquirer from 'inquirer';
import ora from 'ora';
import { fileURLToPath } from 'url';
import os from 'os';
import { Octokit } from '@octokit/rest';
import dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config();

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const scriptDir = path.dirname(__dirname);

const program = new Command();

// Program configuration
program
  .name('agent-adr')
  .description('Batch repository analysis for AI readiness assessment')
  .version('1.0.0');

// Add auth-setup command
program
  .command('auth-setup')
  .description('Set up GitHub authentication for private repository access')
  .option('--token <token>', 'GitHub Personal Access Token')
  .action(authSetupCommand);

// Main batch command
program
  .command('batch')
  .description('Interactive batch repository analysis')
  .option('--org <org>', 'Specific organization to search')
  .action(batchCommand);

// Auto-batch command with interactive team/user selection
program
  .command('auto-batch')
  .description('Interactive team-based repository discovery and batch analysis')
  .option('--org <org>', 'Specific organization to search')
  .option('--pattern <pattern>', 'Repository name pattern (default: *)', '*')
  .option('--days <days>', 'Number of days to look back (default: 365)', '365')
  .option('--non-interactive', 'Run without interactive prompts (auto-select all teams and users)')
  .action(autoBatchCommand);

// Run program
program.parse();

// Authentication and configuration utilities
function getConfigPath() {
  return path.join(os.homedir(), '.config', 'agent-adr', 'config.json');
}

function loadConfig() {
  const configPath = getConfigPath();
  try {
    if (fs.existsSync(configPath)) {
      return JSON.parse(fs.readFileSync(configPath, 'utf8'));
    }
  } catch (error) {
    console.warn('Warning: Could not read config file');
  }
  return {};
}

function saveConfig(config) {
  const configPath = getConfigPath();
  fs.mkdirSync(path.dirname(configPath), { recursive: true });
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}

async function getGitHubToken() {
  // Priority: Environment variable > Config file
  const envToken = process.env.GITHUB_PAT;
  if (envToken) {
    return envToken;
  }
  
  const config = loadConfig();
  return config.githubToken;
}

async function validateGitHubToken(token) {
  try {
    const octokit = new Octokit({ auth: token });
    const { data } = await octokit.rest.user.get();
    return data.login;
  } catch (error) {
    throw new Error(`Invalid token: ${error.message}`);
  }
}

// Batch analysis command
async function batchCommand(options) {
  console.log('🔍 Discovering GitHub repositories...\n');
  
  // Get authentication token
  const token = await getGitHubToken();
  if (!token) {
    console.error('❌ No GitHub authentication found. Run "agent-adr auth-setup" first.');
    process.exit(1);
  }
  
  const octokit = new Octokit({ auth: token });
  const spinner = ora('Connecting to GitHub...').start();
  
  try {
    // Get authenticated user info
    const { data: user } = await octokit.rest.users.getAuthenticated();
    spinner.succeed(`Connected as: ${user.login}`);
    
    let organizations = [];
    
    if (options.org) {
      // Use specified organization
      try {
        const { data: org } = await octokit.rest.orgs.get({ org: options.org });
        organizations = [org];
      } catch (error) {
        spinner.fail(`Organization ${options.org} not found or not accessible`);
        throw error;
      }
    } else {
      // List user's organizations
      const { data: userOrgs } = await octokit.rest.orgs.listForAuthenticatedUser();
      organizations = userOrgs;
      
      // Add user's personal account as an "organization"
      organizations.unshift({
        login: user.login,
        description: 'Personal repositories'
      });
    }
    
    if (organizations.length === 0) {
      console.log('No organizations found.');
      return;
    }
    
    let selectedOrg;
    if (options.org) {
      selectedOrg = options.org;
      console.log(`📂 Using specified organization: ${selectedOrg}`);
    } else {
      // Let user select organization
      const { selectedOrg: userSelectedOrg } = await inquirer.prompt([
        {
          type: 'list',
          name: 'selectedOrg',
          message: 'Select organization:',
          choices: organizations.map(org => ({
            name: `${org.login} - ${org.description || 'No description'}`,
            value: org.login
          }))
        }
      ]);
      selectedOrg = userSelectedOrg;
    }
    
    // Get repositories for selected organization
    const repoSpinner = ora(`Fetching repositories from ${selectedOrg}...`).start();
    
    let repos = [];
    if (selectedOrg === user.login) {
      // Get user's repositories
      const { data: userRepos } = await octokit.rest.repos.listForAuthenticatedUser({
        type: 'all',
        per_page: 100
      });
      repos = userRepos;
    } else {
      // Get organization repositories
      const { data: orgRepos } = await octokit.rest.repos.listForOrg({
        org: selectedOrg,
        per_page: 100
      });
      repos = orgRepos;
    }
    
    repoSpinner.succeed(`Found ${repos.length} repositories`);
    
    if (repos.length === 0) {
      console.log('No repositories found in this organization.');
      return;
    }
    
    // Let user select repositories
    const { selectedRepos } = await inquirer.prompt([
      {
        type: 'checkbox',
        name: 'selectedRepos',
        message: 'Select repositories to analyze:',
        choices: repos.map(repo => ({
          name: `${repo.name} - ${repo.description || 'No description'} ${repo.private ? '(🔒 private)' : '(🌍 public)'}`,
          value: `${repo.owner.login}/${repo.name}`,
          checked: false
        })),
        validate: (input) => {
          if (input.length === 0) {
            return 'Please select at least one repository';
          }
          return true;
        }
      }
    ]);
    
    console.log(`\n✅ Selected ${selectedRepos.length} repositories:`);
    selectedRepos.forEach(repo => console.log(`  - ${repo}`));
    
    console.log('\n🚀 Starting batch analysis...');
    
    // Run batch analysis with selected repositories
    await runBatchAnalysis(selectedRepos);
    
  } catch (error) {
    spinner.fail('Failed to connect to GitHub');
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
  }
}

// Run batch analysis
async function runBatchAnalysis(selectedRepos) {
  const outputDir = '.agent-adr-cache';
  const model = 'gpt-5-mini';
  const timeout = 600;
  
  // Parse repository identifiers
  const parsedRepos = parseRepoIdentifiers(selectedRepos);
  
  // Get GitHub token
  const token = await getGitHubToken();
  
  // Run batch collection
  const collectionResults = await collectEvidenceBatch({ 
    repos: parsedRepos, 
    outputDir, 
    model, 
    timeout, 
    token 
  });
  
  // Generate summary JSON
  const summaryPath = path.join(outputDir, 'batch-summary.json');
  const summaryData = {
    timestamp: new Date().toISOString(),
    totalRepos: selectedRepos.length,
    successfulRepos: parsedRepos.filter(repo => collectionResults.results[repo.identifier]?.overallSuccess).length,
    failedRepos: parsedRepos.filter(repo => !collectionResults.results[repo.identifier]?.overallSuccess).length,
    repositories: selectedRepos,
    results: collectionResults.results
  };
  
  fs.writeFileSync(summaryPath, JSON.stringify(summaryData, null, 2));
  
  console.log(`\n✅ Batch analysis complete!`);
  console.log(`📊 Summary JSON created: ${summaryPath}`);
  console.log(`📈 Analyzed ${summaryData.successfulRepos}/${summaryData.totalRepos} repositories successfully`);
  
  if (summaryData.failedRepos > 0) {
    console.log(`⚠️  ${summaryData.failedRepos} repositories failed to analyze`);
  }
}

// Authentication setup command
async function authSetupCommand(options) {
  console.log('🔐 Setting up GitHub authentication for agent-adr\n');
  
  let token = options.token;
  
  if (!token) {
    const { inputToken } = await inquirer.prompt([
      {
        type: 'password',
        name: 'inputToken',
        message: 'Enter your GitHub Personal Access Token:',
        validate: (input) => {
          if (!input || input.length < 40) {
            return 'Please enter a valid GitHub Personal Access Token (typically 40+ characters)';
          }
          return true;
        }
      }
    ]);
    token = inputToken;
  }
  
  const spinner = ora('Validating token...').start();
  
  try {
    const username = await validateGitHubToken(token);
    spinner.succeed(`Token validated for user: ${username}`);
    
    // Save token to config
    const config = loadConfig();
    config.githubToken = token;
    saveConfig(config);
    
    console.log('✅ Authentication setup complete!');
    console.log(`Token stored in: ${getConfigPath()}`);
    console.log('You can now access private repositories.\n');
    
    console.log('💡 Tip: You can also use the GITHUB_PAT environment variable:');
    console.log('   export GITHUB_PAT="your_token_here"');
    
  } catch (error) {
    spinner.fail('Token validation failed');
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
  }
}

// Validate Node.js version
function validateNodeVersion() {
  const nodeVersion = process.version;
  const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
  
  if (majorVersion < 18) {
    console.error(`ERROR: Node.js version ${nodeVersion} is too old. Required: v18+`);
    process.exit(1);
  }
}

// Parse repository identifiers and validate format
function parseRepoIdentifiers(repos) {
  return repos.map(repo => {
    if (repo.startsWith('https://github.com/')) {
      // Full GitHub URL
      return {
        identifier: repo.replace('https://github.com/', '').replace('.git', ''),
        url: repo,
        isRemote: true
      };
    } else if (repo.includes('/') && !repo.startsWith('/')) {
      // owner/repo format
      return {
        identifier: repo,
        url: `https://github.com/${repo}`,
        isRemote: true
      };
    } else {
      // Local path
      return {
        identifier: repo,
        path: repo,
        isRemote: false
      };
    }
  });
}

// Get repository metadata using GitHub API
async function getRepoMetadata(repoIdentifiers, token) {
  const octokit = new Octokit({ auth: token });
  const metadata = [];
  
  for (const repo of repoIdentifiers) {
    if (!repo.isRemote) {
      // Local repo - just return path info
      metadata.push({
        identifier: repo.identifier,
        isRemote: false,
        localPath: repo.path
      });
      continue;
    }
    
    try {
      const [owner, name] = repo.identifier.split('/');
      const { data } = await octokit.rest.repos.get({ owner, repo: name });
      
      metadata.push({
        identifier: repo.identifier,
        name: data.name,
        fullName: data.full_name,
        description: data.description,
        language: data.language,
        isPrivate: data.private,
        defaultBranch: data.default_branch,
        cloneUrl: data.clone_url,
        isRemote: true
      });
    } catch (error) {
      throw new Error(`Failed to access repository ${repo.identifier}: ${error.message}`);
    }
  }
  
  return metadata;
}

// Validate repository access
async function validateRepoAccess(repos, token) {
  if (!repos.some(repo => repo.isRemote)) {
    return; // No remote repos to validate
  }
  
  const spinner = ora('Validating repository access...').start();
  
  try {
    const metadata = await getRepoMetadata(repos.filter(repo => repo.isRemote), token);
    spinner.succeed(`Access validated for ${metadata.length} remote repository(ies)`);
    return metadata;
  } catch (error) {
    spinner.fail('Repository validation failed');
    throw error;
  }
}

// Execute agentrc command with timeout and progress
async function executeAgentrc(command, args, cwd, timeout = 300000, commandName) {
  return new Promise((resolve, reject) => {
    const spinner = ora(`Running ${commandName}...`).start();
    const startTime = Date.now();
    
    const child = spawn(command, args, { cwd, stdio: 'pipe' });
    
    let stdout = '';
    let stderr = '';
    let lastProgressLine = '';
    
    child.stdout.on('data', (data) => {
      const output = data.toString();
      stdout += output;
      
      // Show real-time progress for batch commands
      if (commandName.includes('batch')) {
        const lines = output.split('\n');
        for (const line of lines) {
          if (line.trim()) {
            // Update spinner with progress info
            if (line.includes('Processing') || line.includes('Analyzing') || line.includes('Cloning') || line.includes('Generating')) {
              spinner.text = `${commandName}: ${line.trim()}`;
              lastProgressLine = line.trim();
            }
          }
        }
      }
    });
    
    child.stderr.on('data', (data) => {
      const output = data.toString();
      stderr += output;
      
      // Show important stderr messages for batch commands
      if (commandName.includes('batch')) {
        const lines = output.split('\n');
        for (const line of lines) {
          if (line.trim() && (line.includes('error') || line.includes('Error') || line.includes('WARNING'))) {
            console.log(`🔍 ${line.trim()}`);
          }
        }
      }
    });

    const progressInterval = setInterval(() => {
      const elapsed = Math.floor((Date.now() - startTime) / 1000);
      if (elapsed > timeout / 1000) {
        clearInterval(progressInterval);
        child.kill('SIGTERM');
        spinner.fail(`${commandName} timed out after ${timeout / 1000}s`);
        reject(new Error(`Command timed out after ${timeout / 1000}s`));
        return;
      }
      spinner.text = `Running ${commandName}... (${elapsed}s elapsed)`;
    }, 5000);

    child.on('close', async (code) => {
      clearInterval(progressInterval);
      
      // Prepare result summary
      const summary = {
        name: commandName,
        success: code === 0,
        exitCode: code,
        stdout: stdout,
        stderr: stderr,
        elapsed: Math.floor((Date.now() - startTime) / 1000)
      };
      
      if (code === 0) {
        spinner.succeed(`${commandName} completed successfully`);
        resolve(summary);
      } else {
        spinner.fail(`${commandName} failed (exit code: ${code})`);
        resolve({ ...summary, success: false });
      }
    });

    child.on('error', (error) => {
      clearInterval(progressInterval);
      spinner.fail(`${commandName} error: ${error.message}`);
      reject(error);
    });
  });
}


// Main collection function
async function collectEvidence(config) {
  const { repoPath, outputDir, model, timeout, isRemote, token } = config;
  
  console.log(`🚀 Starting collection for: ${repoPath}`);
  console.log(`📁 Output directory: ${outputDir}`);
  console.log(`⏱️  Timeout per command: ${timeout}s`);
  console.log(`🤖 Using model: ${model}`);
  console.log('');

  // Create output directory
  fs.mkdirSync(outputDir, { recursive: true });
  
  // Create subdirectories
  const dirs = ['logs', 'metadata', 'probes', 'generated', 'context'];
  dirs.forEach(dir => fs.mkdirSync(path.join(outputDir, dir), { recursive: true }));

  // Get agentrc path
  const agentrcPath = path.join(scriptDir, 'node_modules', '.bin', 'agentrc');
  
  if (!fs.existsSync(agentrcPath)) {
    throw new Error('agentrc not found. Please run: npm install');
  }

  // Build commands based on repo type
  const commands = [];
  
  if (isRemote) {
    // For remote repos, use batch command with single repo
    commands.push(
      { name: 'batch-analyze', args: ['batch', repoPath, '--output', path.join(outputDir, 'batch-analyze.json'), '--model', model] }
    );
  } else {
    // For local repos, use current working directory approach
    commands.push(
      { name: 'analyze', args: ['analyze', '--json', '--output', path.join(outputDir, 'analyze.json')] },
      { name: 'readiness', args: ['readiness', '--json', '--output', path.join(outputDir, 'readiness.json')] }
    );
  }

  const results = {};
  let overallSuccess = true;

  // Determine working directory
  const workingDir = isRemote ? process.cwd() : repoPath;

  if (isRemote) {
    // For remote repos, use step-by-step approach with temporary clone
    console.log(`🔍 Analyzing remote repository: ${repoPath}`);
    console.log(`📊 This will clone the repo temporarily and run analysis step by step...`);
    
    // Create temporary directory for cloning
    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'agent-adr-remote-'));
    console.log(`📁 Created temporary directory: ${tempDir}`);
    
    try {
      // Step 1: Clone the repository using git
      const cloneSpinner = ora('📥 Cloning remote repository...').start();
      const cloneStart = Date.now();
      
      try {
        const { execSync } = await import('child_process');
        const repoUrl = `https://github.com/${repoPath}.git`;
        execSync(`git clone "${repoUrl}" "${tempDir}"`, { stdio: 'pipe' });
        cloneSpinner.succeed(`Repository cloned (${Math.floor((Date.now() - cloneStart) / 1000)}s)`);
      } catch (error) {
        cloneSpinner.fail(`Failed to clone repository: ${error.message}`);
        throw new Error(`Clone failed: ${error.message}`);
      }
      
      // Step 2: Run analysis commands on cloned repo
      const analysisCommands = [
        { name: 'analyze', args: ['analyze', '--json', '--output', path.join(outputDir, 'analyze.json')] },
        { name: 'readiness', args: ['readiness', '--json', '--output', path.join(outputDir, 'readiness.json')] }
      ];
      
      for (const cmd of analysisCommands) {
        console.log(`🔍 Running ${cmd.name} on cloned repository...`);
        const result = await executeAgentrc(agentrcPath, cmd.args, tempDir, timeout * 1000, cmd.name, false);
        results[cmd.name] = result;
        if (!result.success) overallSuccess = false;
        console.log(`✅ ${cmd.name} completed (${result.elapsed}s)`);
      }
      
    } finally {
      // Clean up temporary directory
      console.log(`🧹 Cleaning up temporary directory...`);
      fs.rmSync(tempDir, { recursive: true, force: true });
      console.log(`✅ Cleanup completed`);
    }
  } else {
    // For local repos, run individual commands
    for (const cmd of commands) {
      console.log(`🔍 ${cmd.name}`);
      const result = await executeAgentrc(agentrcPath, cmd.args, workingDir, timeout * 1000, cmd.name, false);
      results[cmd.name] = result;
      if (!result.success) overallSuccess = false;
      console.log('');
    }
  }

  // Copy context files (only for local repos)
  let copiedCount = 0;
  if (!isRemote) {
    const contextSpinner = ora('Copying context files...').start();
    const contextFiles = ['README.md', 'package.json', 'tsconfig.json', '.github/copilot-instructions.md', 'AGENTS.md', 'CLAUDE.md', 'CONTRIBUTING.md', 'CODEOWNERS', 'SECURITY.md'];
    
    contextFiles.forEach(file => {
      const srcPath = path.join(repoPath, file);
      const destPath = path.join(outputDir, 'context', file);
      
      if (fs.existsSync(srcPath)) {
        fs.mkdirSync(path.dirname(destPath), { recursive: true });
        fs.copyFileSync(srcPath, destPath);
        copiedCount++;
      }
    });
    
    contextSpinner.succeed(`Copied ${copiedCount} context files`);
  } else {
    console.log('📄 Skipping context file copying for remote repository');
  }
  
  return { results, overallSuccess };
}

// Batch evidence collection for multiple repositories
async function collectEvidenceBatch(config) {
  const { repos, outputDir, model, timeout, token } = config;
  
  console.log(`🚀 Starting batch collection for ${repos.length} repositories`);
  console.log(`📁 Output directory: ${outputDir}`);
  console.log(`⏱️  Timeout per command: ${timeout}s`);
  console.log(`🤖 Using model: ${model}`);
  
  // Create output directory
  fs.mkdirSync(outputDir, { recursive: true });
  
  // Filter remote repos for batch processing
  const remoteRepos = repos.filter(repo => repo.isRemote);
  const localRepos = repos.filter(repo => !repo.isRemote);
  
  const results = {};
  let overallSuccess = true;
  
  if (remoteRepos.length > 0) {
    // Process remote repos individually
    console.log(`🔄 Processing ${remoteRepos.length} remote repositories sequentially...`);
    
    for (let i = 0; i < remoteRepos.length; i++) {
      const repo = remoteRepos[i];
      const repoOutputDir = path.join(outputDir, `remote-${i}-${repo.identifier.replace(/\//g, '-')}`);
      
      console.log(`\n📦 Processing repository ${i + 1}/${remoteRepos.length}: ${repo.identifier}`);
      
      try {
        const repoResult = await collectEvidence({
          repoPath: repo.identifier,
          outputDir: repoOutputDir,
          model,
          timeout,
          isRemote: true,
          token
        });
        
        results[repo.identifier] = repoResult;
        if (!repoResult.overallSuccess) overallSuccess = false;
        
        console.log(`✅ Completed ${repo.identifier}`);
      } catch (error) {
        console.error(`❌ Failed to process ${repo.identifier}: ${error.message}`);
        results[repo.identifier] = { success: false, error: error.message };
        overallSuccess = false;
      }
    }
  }
  
  if (localRepos.length > 0) {
    // Process local repos individually
    for (const repo of localRepos) {
      const localResult = await collectEvidence({
        ...config,
        repoPath: repo.path,
        outputDir: path.join(outputDir, `local-${repo.identifier.replace(/\//g, '-')}`)
      });
      results[repo.identifier] = localResult;
      if (!localResult.overallSuccess) overallSuccess = false;
    }
  }
  
  return { results, overallSuccess };
}

// Discovery functions for auto-batch workflow
async function getOrganizations(octokit, preselectedOrg = null) {
  if (preselectedOrg) {
    try {
      const { data: org } = await octokit.rest.orgs.get({ org: preselectedOrg });
      return [org];
    } catch (error) {
      throw new Error(`Organization ${preselectedOrg} not found or not accessible`);
    }
  }

  // Get user's organizations
  const { data: userOrgs } = await octokit.rest.orgs.listForAuthenticatedUser();
  const { data: user } = await octokit.rest.users.getAuthenticated();
  
  // Add personal account as organization option
  const organizations = [
    { login: user.login, description: 'Personal repositories' },
    ...userOrgs
  ];
  
  return organizations;
}

async function getTeams(octokit, org) {
  try {
    const { data: teams } = await octokit.rest.teams.list({
      org,
      per_page: 100
    });
    return teams;
  } catch (error) {
    console.warn(`Warning: Could not fetch teams for ${org}: ${error.message}`);
    return [];
  }
}

async function getTeamMembers(octokit, org, teamSlug) {
  try {
    const { data: members } = await octokit.rest.teams.listMembersInOrg({
      org,
      team_slug: teamSlug,
      per_page: 100
    });
    return members;
  } catch (error) {
    console.warn(`Warning: Could not fetch members for team ${teamSlug}: ${error.message}`);
    return [];
  }
}

async function getUserContributions(octokit, org, usernames, daysAgo = 365) {
  const sinceDate = new Date();
  sinceDate.setDate(sinceDate.getDate() - parseInt(daysAgo));
  
  // Get all repositories in the organization
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

  const contributions = new Map();
  
  for (const repo of repos) {
    const repoContributions = new Map();
    
    for (const username of usernames) {
      try {
        // Check commits by user
        const commits = await octokit.rest.repos.listCommits({
          owner: org,
          repo: repo.name,
          author: username,
          since: sinceDate.toISOString(),
          per_page: 1,
        });

        // Check pull requests by user
        const prs = await octokit.rest.pulls.list({
          owner: org,
          repo: repo.name,
          creator: username,
          state: 'all',
          since: sinceDate.toISOString(),
          per_page: 1,
        });

        // Check issues by user
        const issues = await octokit.rest.issues.listForRepo({
          owner: org,
          repo: repo.name,
          creator: username,
          state: 'all',
          since: sinceDate.toISOString(),
          per_page: 1,
        });

        const hasContribution = commits.data.length > 0 || prs.data.length > 0 || issues.data.length > 0;
        
        if (hasContribution) {
          repoContributions.set(username, {
            commits: commits.data.length,
            pullRequests: prs.data.length,
            issues: issues.data.length,
            lastCommit: commits.data.length > 0 ? commits.data[0].commit.author.date : null,
          });
        }

      } catch (error) {
        // Skip if user not found or no access
        continue;
      }
    }

    if (repoContributions.size > 0) {
      contributions.set(repo.full_name, {
        repository: repo.full_name,
        description: repo.description,
        language: repo.language,
        private: repo.private,
        contributions: Object.fromEntries(repoContributions),
        totalContributors: repoContributions.size,
      });
    }

    // Add small delay to avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  return Array.from(contributions.values());
}

// Auto-batch command implementation
async function autoBatchCommand(options) {
  console.log('🚀 Starting interactive team-based repository discovery...\n');
  
  // Get authentication token
  const token = await getGitHubToken();
  if (!token) {
    console.error('❌ No GitHub authentication found. Run "agent-adr auth-setup" first.');
    process.exit(1);
  }
  
  const octokit = new Octokit({ auth: token });
  const spinner = ora('Connecting to GitHub...').start();
  
  try {
    // Get authenticated user info
    const { data: user } = await octokit.rest.users.getAuthenticated();
    spinner.succeed(`Connected as: ${user.login}`);
    
    // Step 1: Organization selection
    const organizations = await getOrganizations(octokit, options.org);
    
    let selectedOrg;
    if (options.org) {
      selectedOrg = options.org;
      console.log(`📂 Using specified organization: ${selectedOrg}`);
    } else {
      const { organization } = await inquirer.prompt([
        {
          type: 'list',
          name: 'organization',
          message: 'Select organization:',
          choices: organizations.map(org => ({
            name: `${org.login} - ${org.description || 'No description'}`,
            value: org.login
          }))
        }
      ]);
      selectedOrg = organization;
    }
    
    // Step 2: Team discovery and selection
    console.log(`\n🔍 Discovering teams in ${selectedOrg}...`);
    const teams = await getTeams(octokit, selectedOrg);
    
    if (teams.length === 0) {
      console.log('No teams found in this organization.');
      return;
    }
    
    let selectedTeams;
    if (options.nonInteractive) {
      selectedTeams = teams.map(team => team.slug);
      console.log(`🤖 Auto-selected all ${teams.length} teams`);
    } else {
      const { selectedTeams: interactiveTeams } = await inquirer.prompt([
        {
          type: 'checkbox',
          name: 'selectedTeams',
          message: 'Select teams to analyze:',
          choices: teams.map(team => ({
            name: `${team.name} (${team.privacy || 'unknown'} privacy${team.members_count ? `, ${team.members_count} members` : ', member count hidden'})`,
            value: team.slug
          }))
        }
      ]);
      selectedTeams = interactiveTeams;
    }
    
    if (selectedTeams.length === 0) {
      console.log('No teams selected.');
      return;
    }
    
    // Step 3: User discovery from selected teams
    console.log(`\n👥 Discovering users from ${selectedTeams.length} teams...`);
    const allUsers = new Map();
    
    for (const teamSlug of selectedTeams) {
      const members = await getTeamMembers(octokit, selectedOrg, teamSlug);
      members.forEach(member => {
        if (!allUsers.has(member.login)) {
          allUsers.set(member.login, {
            login: member.login,
            name: member.name,
            teams: []
          });
        }
        allUsers.get(member.login).teams.push(teamSlug);
      });
    }
    
    if (allUsers.size === 0) {
      console.log('No users found in selected teams.');
      return;
    }
    
    // Step 4: User selection (pre-select all, allow deselection)
    let selectedUsers;
    if (options.nonInteractive) {
      selectedUsers = Array.from(allUsers.keys());
      console.log(`🤖 Auto-selected all ${selectedUsers.length} users`);
    } else {
      const { selectedUsers: interactiveUsers } = await inquirer.prompt([
        {
          type: 'checkbox',
          name: 'selectedUsers',
          message: 'Review users (deselect any you want to exclude):',
          choices: Array.from(allUsers.values()).map(user => ({
            name: `${user.login} ${user.name ? `(${user.name})` : ''} - Teams: ${user.teams.join(', ')}`,
            value: user.login,
            checked: true
          }))
        }
      ]);
      selectedUsers = interactiveUsers;
    }
    
    if (selectedUsers.length === 0) {
      console.log('No users selected.');
      return;
    }
    
    console.log(`\n✅ Selected ${selectedUsers.length} users from ${selectedTeams.length} teams`);
    
    // Step 5: Repository discovery
    console.log(`\n🔍 Finding repositories contributed by selected users in the last ${options.days} days...`);
    const contributions = await getUserContributions(octokit, selectedOrg, selectedUsers, options.days);
    
    // Step 6: Pattern filtering
    const pattern = options.pattern || '*';
    const regex = new RegExp(pattern.replace(/\*/g, '.*'), 'i');
    const filteredRepos = contributions.filter(repo => regex.test(repo.repository));
    
    console.log(`\n📊 Found ${contributions.length} repositories with user contributions`);
    if (pattern !== '*') {
      console.log(`🎯 Filtered to ${filteredRepos.length} repositories matching pattern "${pattern}"`);
    } else {
      console.log(`📋 Showing all ${filteredRepos.length} repositories`);
    }
    
    if (filteredRepos.length === 0) {
      console.log('No repositories found matching the pattern.');
      return;
    }
    
    // Step 7: Show discovered repositories and confirm
    console.log('\n📦 Discovered repositories:');
    filteredRepos.forEach(repo => {
      console.log(`  - ${repo.repository} (${repo.language || 'Unknown'}, ${repo.private ? 'Private' : 'Public'})`);
    });
    
    if (options.nonInteractive) {
      console.log(`\n🤖 Auto-proceeding with batch analysis on ${filteredRepos.length} repositories`);
    } else {
      const { confirmAnalysis } = await inquirer.prompt([
        {
          type: 'confirm',
          name: 'confirmAnalysis',
          message: `Run batch analysis on ${filteredRepos.length} repositories?`,
          default: true
        }
      ]);
      
      if (!confirmAnalysis) {
        console.log('Analysis cancelled.');
        return;
      }
    }
    
    // Step 8: Run batch analysis
    console.log('\n🚀 Starting batch analysis...');
    await runBatchAnalysis(filteredRepos.map(repo => repo.repository));
    
  } catch (error) {
    spinner.fail('Failed to complete auto-batch workflow');
    console.error('❌ Error:', error.message);
    if (error.status === 401) {
      console.error('Authentication failed. Please check your GitHub token.');
    } else if (error.status === 403) {
      console.error('Rate limit exceeded or insufficient permissions.');
    } else if (error.status === 404) {
      console.error('Organization or team not found or not accessible.');
    }
    process.exit(1);
  }
}
