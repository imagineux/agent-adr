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
  .description('Collect repository evidence and build AI enablement ADR synthesis prompts')
  .version('1.0.0');

// Check if discover command is being used
const args = process.argv.slice(2);
if (args[0] === 'discover') {
  // Create separate program for discover command
  const discoverProgram = new Command();
  discoverProgram
    .name('agent-adr')
    .description('Collect repository evidence and build AI enablement ADR synthesis prompts')
    .version('1.0.0');
  
  discoverProgram
    .command('discover')
    .description('Interactive repository discovery and selection')
    .option('--org <org>', 'Specific organization to search')
    .option('--name <pattern>', 'Filter repositories by name pattern (supports wildcards)')
    .option('--description <pattern>', 'Filter repositories by description pattern')
    .option('--language <language>', 'Filter repositories by primary language')
    .option('--private', 'Show only private repositories')
    .option('--public', 'Show only public repositories')
    .action(discoverCommand);
  
  discoverProgram.parse(process.argv);
} else {
  // Regular program with auth-setup and collect commands
  // Add auth-setup command first
  program
    .command('auth-setup')
    .description('Set up GitHub authentication for private repository access')
    .option('--token <token>', 'GitHub Personal Access Token')
    .action(authSetupCommand);

// Main collection command
program
  .command('collect')
  .alias('c')
  .argument('[repos...]', 'One or more repositories (local paths or owner/repo)')
  .requiredOption('-o, --output <output-dir>', 'Output directory for collection artifacts and prompts')
  .option('-e, --education', 'Use educational synthesis template with comprehensive framework')
  .option('-m, --model <model>', 'AI model to use', 'gpt-5-mini')
  .option('-t, --timeout <timeout>', 'Timeout per command in seconds', '300')
  .option('-i, --interactive', 'Interactive mode - review and confirm each step')
  .option('--batch', 'Process multiple repositories using agentrc batch command')
  .action(async (repos, options) => {
    try {
      await main({ repos, outputDir: options.output, useEducation: options.education, model: options.model, timeout: parseInt(options.timeout), interactive: options.interactive, batch: options.batch });
    } catch (error) {
      console.error(`❌ Fatal error: ${error.message}`);
      process.exit(1);
    }
  });

// Default action for backward compatibility - treat as collect command
program
  .argument('[repos...]', 'One or more repositories (local paths or owner/repo)')
  .requiredOption('-o, --output <output-dir>', 'Output directory for collection artifacts and prompts')
  .option('-e, --education', 'Use educational synthesis template with comprehensive framework')
  .option('-m, --model <model>', 'AI model to use', 'gpt-5-mini')
  .option('-t, --timeout <timeout>', 'Timeout per command in seconds', '300')
  .option('-i, --interactive', 'Interactive mode - review and confirm each step')
  .option('--batch', 'Process multiple repositories using agentrc batch command')
  .action(async (repos, options) => {
    try {
      await main({ repos, outputDir: options.output, useEducation: options.education, model: options.model, timeout: parseInt(options.timeout), interactive: options.interactive, batch: options.batch });
    } catch (error) {
      console.error(`❌ Fatal error: ${error.message}`);
      process.exit(1);
    }
  });

  // Run program for non-discover commands
  program.parse();
}

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

// Interactive repository discovery
async function discoverCommand(options) {
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
    
    // Apply filters
    const filteredRepos = repos.filter(repo => {
      // Name pattern filter
      if (options.name) {
        const pattern = options.name.replace(/\*/g, '.*');
        const regex = new RegExp(pattern, 'i');
        if (!regex.test(repo.name)) return false;
      }
      
      // Description pattern filter
      if (options.description && repo.description) {
        const pattern = options.description.replace(/\*/g, '.*');
        const regex = new RegExp(pattern, 'i');
        if (!regex.test(repo.description)) return false;
      }
      
      // Language filter
      if (options.language && repo.language !== options.language) {
        return false;
      }
      
      // Privacy filter
      if (options.private && !repo.private) return false;
      if (options.public && repo.private) return false;
      
      return true;
    });
    
    console.log(`🔍 Applied filters: ${filteredRepos.length} repositories match criteria`);
    
    if (filteredRepos.length === 0) {
      console.log('No repositories match the specified filters.');
      return;
    }
    
    // Let user select repositories
    const { selectedRepos } = await inquirer.prompt([
      {
        type: 'checkbox',
        name: 'selectedRepos',
        message: 'Select repositories to analyze:',
        choices: filteredRepos.map(repo => ({
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
    
    // Ask for output directory
    const { outputDir } = await inquirer.prompt([
      {
        type: 'input',
        name: 'outputDir',
        message: 'Output directory for collection:',
        default: `../collections/${selectedOrg}-analysis`,
        validate: (input) => {
          if (!input.trim()) {
            return 'Output directory is required';
          }
          return true;
        }
      }
    ]);
    
    // Ask for batch processing
    const { useBatch } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'useBatch',
        message: 'Use batch processing for better performance?',
        default: selectedRepos.length > 1
      }
    ]);
    
    console.log('\n🚀 Starting analysis...');
    
    // Run analysis with selected repositories
    await main({
      repos: selectedRepos,
      outputDir,
      useEducation: false,
      model: 'gpt-5-mini',
      timeout: 600,
      interactive: false,
      batch: useBatch
    });
    
  } catch (error) {
    spinner.fail('Failed to connect to GitHub');
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
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
async function executeAgentrc(command, args, cwd, timeout = 300000, commandName, interactive = false) {
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
        
        // Show preview and ask for confirmation if interactive mode
        if (interactive) {
          await showStepSummaryAndConfirm(summary);
        }
        resolve(summary);
      } else {
        spinner.fail(`${commandName} failed (exit code: ${code})`);
        
        // Show error details and ask if user wants to continue if interactive mode
        if (interactive) {
          const shouldContinue = await showErrorAndAskContinue(summary);
          if (shouldContinue) {
            resolve({ ...summary, success: false });
          } else {
            reject(new Error(`User chose to stop after ${commandName} failed`));
          }
        } else {
          resolve({ ...summary, success: false });
        }
      }
    });

    child.on('error', (error) => {
      clearInterval(progressInterval);
      spinner.fail(`${commandName} error: ${error.message}`);
      reject(error);
    });
  });
}

// Show step summary and ask for confirmation
async function showStepSummaryAndConfirm(step) {
  console.log(`\n📋 ${step.name} Summary:`);
  console.log(`⏱️  Time: ${step.elapsed}s`);
  console.log(`✅ Status: Success`);
  
  // Show preview of output (first few lines)
  if (step.stdout) {
    const preview = step.stdout.split('\n').slice(0, 5).join('\n');
    console.log(`📄 Output Preview:`);
    console.log('```');
    console.log(preview);
    console.log('```');
    
    if (step.stdout.split('\n').length > 5) {
      console.log(`... (${step.stdout.split('\n').length - 5} more lines)`);
    }
  }
  
  // Ask for user context/comments
  const { shouldContinue, userComments } = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'shouldContinue',
      message: `Continue with next step?`,
      default: true
    },
    {
      type: 'editor',
      name: 'userComments',
      message: 'Add any context, notes, or observations about this step:',
      when: () => true,
      default: ''
    }
  ]);
  
  // Store user comments if provided
  if (userComments && userComments.trim()) {
    step.userComments = userComments.trim();
    console.log(`📝 Notes added: ${userComments.trim().split('\n')[0]}${userComments.trim().split('\n').length > 1 ? '...' : ''}`);
  }
  
  if (!shouldContinue) {
    throw new Error('User chose to stop the process');
  }
}

// Show error details and ask if user wants to continue
async function showErrorAndAskContinue(step) {
  console.log(`\n❌ ${step.name} Error Details:`);
  console.log(`⏱️  Time: ${step.elapsed}s`);
  console.log(`🔴 Exit Code: ${step.exitCode}`);
  
  // Show error output
  if (step.stderr) {
    console.log(`📄 Error Output:`);
    console.log('```');
    console.log(step.stderr);
    console.log('```');
  }
  
  // Show stdout if available
  if (step.stdout) {
    const preview = step.stdout.split('\n').slice(0, 3).join('\n');
    console.log(`📄 Partial Output:`);
    console.log('```');
    console.log(preview);
    console.log('```');
  }
  
  // Ask for user context/comments even on errors
  const { shouldContinue, userComments } = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'shouldContinue',
      message: `${step.name} failed. Continue anyway? (Some data may be incomplete)`,
      default: true
    },
    {
      type: 'editor',
      name: 'userComments',
      message: 'Add context about this failure or workarounds:',
      when: () => true,
      default: ''
    }
  ]);
  
  // Store user comments if provided
  if (userComments && userComments.trim()) {
    step.userComments = userComments.trim();
    console.log(`📝 Notes added: ${userComments.trim().split('\n')[0]}${userComments.trim().split('\n').length > 1 ? '...' : ''}`);
  }
  
  return shouldContinue;
}

// Main collection function
async function collectEvidence(config) {
  const { repoPath, outputDir, model, timeout, interactive, isRemote, token } = config;
  
  console.log(`🚀 Starting collection for: ${repoPath}`);
  console.log(`📁 Output directory: ${outputDir}`);
  console.log(`⏱️  Timeout per command: ${timeout}s`);
  console.log(`🤖 Using model: ${model}`);
  if (interactive) {
    console.log(`🎮 Interactive mode: You'll review and confirm each step`);
  }
  console.log('');

  // Create output directory
  fs.mkdirSync(outputDir, { recursive: true });
  
  // Create subdirectories
  const dirs = ['logs', 'metadata', 'probes', 'generated', 'context', 'prompts'];
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
      { name: 'readiness', args: ['readiness', '--json', '--output', path.join(outputDir, 'readiness.json')] },
      { name: 'probe-flat-root', args: ['instructions', '--dry-run', '--json', '--model', model] },
      { name: 'probe-flat-areas', args: ['instructions', '--dry-run', '--json', '--areas', '--model', model] },
      { name: 'probe-nested-root', args: ['instructions', '--dry-run', '--json', '--strategy', 'nested', '--model', model] },
      { name: 'probe-nested-areas', args: ['instructions', '--dry-run', '--json', '--strategy', 'nested', '--areas', '--model', model] },
      { name: 'generate-flat', args: ['instructions', '--output', path.join(outputDir, 'generated', 'flat-root', 'copilot-instructions.generated.md'), '--model', model, '--force'] },
      { name: 'generate-nested', args: ['instructions', '--strategy', 'nested', '--output', path.join(outputDir, 'generated', 'nested-root', 'AGENTS.generated.md'), '--model', model, '--force'] }
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
        const result = await executeAgentrc(agentrcPath, cmd.args, tempDir, timeout * 1000, cmd.name, interactive);
        results[cmd.name] = result;
        if (!result.success) overallSuccess = false;
        console.log(`✅ ${cmd.name} completed (${result.elapsed}s)`);
      }
      
      // Step 3: Skip instruction generation probes (requires Copilot CLI)
      // For ADR synthesis, analyze + readiness data is sufficient
      console.log(`⏭️  Skipping instruction generation probes (requires Copilot CLI)`);
      console.log(`� Analysis and readiness data is sufficient for ADR synthesis`);
      
      // Add placeholder results for probes
      results['probe-flat-root'] = { success: true, skipped: true, reason: 'Copilot CLI not required for ADR synthesis' };
      results['probe-nested-root'] = { success: true, skipped: true, reason: 'Copilot CLI not required for ADR synthesis' };
      
    } finally {
      // Clean up temporary directory
      console.log(`🧹 Cleaning up temporary directory...`);
      fs.rmSync(tempDir, { recursive: true, force: true });
      console.log(`✅ Cleanup completed`);
    }
  } else {
    // For local repos, run individual commands
    // Run analysis commands first
    const analysisCommands = commands.filter(cmd => cmd.name === 'analyze' || cmd.name === 'readiness');
    for (const cmd of analysisCommands) {
      console.log(`🔍 ${cmd.name}`);
      const result = await executeAgentrc(agentrcPath, cmd.args, workingDir, timeout * 1000, cmd.name, interactive);
      results[cmd.name] = result;
      if (!result.success) overallSuccess = false;
      console.log('');
    }

    // Run probe commands
    console.log('🔍 Running probes (dry-run instruction generation)...');
    const probeCommands = commands.filter(cmd => cmd.name.startsWith('probe-'));
    for (const cmd of probeCommands) {
      const result = await executeAgentrc(agentrcPath, cmd.args, workingDir, timeout * 1000, cmd.name, interactive);
      results[cmd.name] = result;
      if (!result.success) overallSuccess = false;
    }
    console.log('');

    // Run generation commands
    console.log('🔧 Running real instruction generation...');
    const genCommands = commands.filter(cmd => cmd.name.startsWith('generate-'));
    for (const cmd of genCommands) {
      const result = await executeAgentrc(agentrcPath, cmd.args, workingDir, timeout * 1000, cmd.name, interactive);
      results[cmd.name] = result;
      if (!result.success) overallSuccess = false;
    }
    console.log('');
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
  
  // Save user comments if interactive mode
  if (interactive) {
    const commentsSpinner = ora('Saving user comments...').start();
    const userComments = {};
    
    // Collect all user comments from results
    Object.entries(results).forEach(([stepName, result]) => {
      if (result.userComments) {
        userComments[stepName] = {
          comments: result.userComments,
          success: result.success,
          exitCode: result.exitCode,
          elapsed: result.elapsed
        };
      }
    });
    
    // Save comments to JSON file
    if (Object.keys(userComments).length > 0) {
      fs.writeFileSync(
        path.join(outputDir, 'user-comments.json'),
        JSON.stringify(userComments, null, 2)
      );
      commentsSpinner.succeed(`Saved ${Object.keys(userComments).length} user comment sections`);
    } else {
      commentsSpinner.succeed('No user comments to save');
    }
  }
  
  return { results, overallSuccess, userComments: interactive ? results : null };
}

// Build synthesis prompt
function buildPrompt(config, collectionResults) {
  const promptSpinner = ora('Building synthesis prompt...').start();
  
  const { outputDir, useEducation } = config;
  
  try {
    // Load templates
    const templateFile = useEducation ? 
      'adr-synthesis-with-education-template.md' : 
      'adr-synthesis-template.md';
    
    let templateContent = fs.readFileSync(path.join(scriptDir, 'templates', templateFile), 'utf8');
    const adrTemplate = fs.readFileSync(path.join(scriptDir, 'templates', 'ai-enablement-adr-template.md'), 'utf8');
    
    // For educational template, compose with standard template
    if (useEducation && templateContent.includes('{{STANDARD_SYNTHESIS_TEMPLATE}}')) {
      const standardTemplate = fs.readFileSync(path.join(scriptDir, 'templates', 'adr-synthesis-template.md'), 'utf8');
      templateContent = templateContent.replace('{{STANDARD_SYNTHESIS_TEMPLATE}}', standardTemplate);
    }
    
    // Read collection data
    const analyzePath = path.join(outputDir, 'analyze.json');
    const readinessPath = path.join(outputDir, 'readiness.json');
    const userCommentsPath = path.join(outputDir, 'user-comments.json');
    
    let analyzeData = '{}';
    let readinessData = '{}';
    let userCommentsData = '{}';
    
    try {
      if (fs.existsSync(analyzePath)) {
        analyzeData = fs.readFileSync(analyzePath, 'utf8');
      }
      if (fs.existsSync(readinessPath)) {
        readinessData = fs.readFileSync(readinessPath, 'utf8');
      }
      if (fs.existsSync(userCommentsPath)) {
        userCommentsData = fs.readFileSync(userCommentsPath, 'utf8');
      }
    } catch (error) {
      promptSpinner.warn('Could not read some collection data');
    }
    
    // Format user comments for inclusion in prompt
    let userCommentsSection = '';
    if (userCommentsData !== '{}') {
      const comments = JSON.parse(userCommentsData);
      userCommentsSection = '\n## [SECTION] User Comments & Context\n\n';
      
      Object.entries(comments).forEach(([stepName, stepData]) => {
        userCommentsSection += `### ${stepName}\n\n`;
        userCommentsSection += `**Status:** ${stepData.success ? '✅ Success' : '❌ Failed'} (${stepData.elapsed}s)\n\n`;
        userCommentsSection += `**User Context:**\n`;
        userCommentsSection += stepData.comments;
        userCommentsSection += '\n\n---\n\n';
      });
    }
    
    // Replace placeholders
    const synthesis = templateContent
      .replace('{{ANALYZE_JSON}}', analyzeData)
      .replace('{{READINESS_JSON}}', readinessData)
      .replace('{{USER_COMMENTS_MD}}', userCommentsSection)
      .replace('{{ADR_TEMPLATE_MD}}', adrTemplate);
    
    // Write prompt to file
    const promptsDir = path.join(outputDir, 'prompts');
    const promptFile = path.join(promptsDir, 'adr-synthesis-prompt.md');
    
    fs.writeFileSync(promptFile, synthesis);
    
    promptSpinner.succeed(`Synthesis prompt built (${synthesis.length} characters)`);
    
    return promptFile;
  } catch (error) {
    promptSpinner.fail(`Failed to build prompt: ${error.message}`);
    throw error;
  }
}

// Batch evidence collection using agentrc batch command
async function collectEvidenceBatch(config) {
  const { repos, outputDir, model, timeout, token } = config;
  
  console.log(`🚀 Starting batch collection for ${repos.length} repositories`);
  console.log(`📁 Output directory: ${outputDir}`);
  console.log(`⏱️  Timeout per command: ${timeout}s`);
  console.log(`🤖 Using model: ${model}`);
  
  // Create output directory
  fs.mkdirSync(outputDir, { recursive: true });
  
  // Get agentrc path
  const agentrcPath = path.join(scriptDir, 'node_modules', '.bin', 'agentrc');
  
  if (!fs.existsSync(agentrcPath)) {
    throw new Error('agentrc not found. Please run: npm install');
  }
  
  // Filter remote repos for batch processing
  const remoteRepos = repos.filter(repo => repo.isRemote);
  const localRepos = repos.filter(repo => !repo.isRemote);
  
  const results = {};
  let overallSuccess = true;
  
  if (remoteRepos.length > 0) {
    // Process remote repos individually with step-by-step approach
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
          interactive: false,
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
    
    // Create consolidated batch summary
    const batchSummary = {
      totalRepos: remoteRepos.length,
      successfulRepos: remoteRepos.filter(repo => results[repo.identifier]?.overallSuccess).length,
      failedRepos: remoteRepos.filter(repo => !results[repo.identifier]?.overallSuccess).length,
      results: results
    };
    
    fs.writeFileSync(path.join(outputDir, 'batch-summary.json'), JSON.stringify(batchSummary, null, 2));
    console.log(`\n📊 Batch Summary: ${batchSummary.successfulRepos}/${batchSummary.totalRepos} successful`);
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

// Build batch synthesis prompt
function buildPromptBatch(config, collectionResults) {
  const promptSpinner = ora('Building batch synthesis prompt...').start();
  
  const { outputDir, useEducation } = config;
  
  try {
    // Load templates
    const templateFile = useEducation ? 
      'adr-synthesis-with-education-template.md' : 
      'adr-synthesis-template.md';
    
    let templateContent = fs.readFileSync(path.join(scriptDir, 'templates', templateFile), 'utf8');
    const adrTemplate = fs.readFileSync(path.join(scriptDir, 'templates', 'ai-enablement-adr-template.md'), 'utf8');
    
    // For educational template, compose with standard template
    if (useEducation && templateContent.includes('{{STANDARD_SYNTHESIS_TEMPLATE}}')) {
      const standardTemplate = fs.readFileSync(path.join(scriptDir, 'templates', 'adr-synthesis-template.md'), 'utf8');
      templateContent = templateContent.replace('{{STANDARD_SYNTHESIS_TEMPLATE}}', standardTemplate);
    }
    
    // Read batch results
    let batchData = '{}';
    if (collectionResults.results.batchData) {
      batchData = JSON.stringify(collectionResults.results.batchData, null, 2);
    }
    
    // Replace placeholders
    const synthesis = templateContent
      .replace('{{ANALYZE_JSON}}', batchData)
      .replace('{{READINESS_JSON}}', '{}')
      .replace('{{USER_COMMENTS_MD}}', '')
      .replace('{{ADR_TEMPLATE_MD}}', adrTemplate);
    
    // Write prompt to file
    const promptsDir = path.join(outputDir, 'prompts');
    fs.mkdirSync(promptsDir, { recursive: true });
    const promptFile = path.join(promptsDir, 'batch-adr-synthesis-prompt.md');
    
    fs.writeFileSync(promptFile, synthesis);
    
    promptSpinner.succeed(`Batch synthesis prompt built (${synthesis.length} characters)`);
    
    return promptFile;
  } catch (error) {
    promptSpinner.fail(`Failed to build batch prompt: ${error.message}`);
    throw error;
  }
}

// Main execution
async function main(config) {
  validateNodeVersion();
  
  // Handle backward compatibility for single repo
  if (typeof config.repos === 'string') {
    config.repos = [config.repos];
  }
  
  if (!config.repos || config.repos.length === 0) {
    throw new Error('At least one repository must be specified');
  }
  
  // Parse repository identifiers
  const parsedRepos = parseRepoIdentifiers(config.repos);
  
  // Get GitHub token for remote repos
  let token = null;
  if (parsedRepos.some(repo => repo.isRemote)) {
    token = await getGitHubToken();
    if (!token) {
      throw new Error('GitHub authentication required for remote repositories. Run "agent-adr auth-setup" to configure.');
    }
    
    // Validate repository access
    await validateRepoAccess(parsedRepos, token);
  }
  
  // Choose processing strategy
  if (config.batch && parsedRepos.length > 1) {
    // Use agentrc batch command for multiple repos
    const collectionResults = await collectEvidenceBatch({ ...config, repos: parsedRepos, token });
    const promptFile = buildPromptBatch(config, collectionResults);
    
    console.log('');
    console.log(`🎯 Ready for advanced AI model`);
    console.log(`📄 Prompt file: ${promptFile}`);
    console.log(`📁 Collection artifacts: ${config.outputDir}`);
    
    if (collectionResults.overallSuccess) {
      console.log('✅ Batch collection completed successfully');
    } else {
      console.log('⚠️  Batch collection completed with some failures');
    }
  } else {
    // Process repos individually (backward compatibility)
    for (let i = 0; i < parsedRepos.length; i++) {
      const repo = parsedRepos[i];
      const repoSuffix = parsedRepos.length > 1 ? `-${repo.identifier.replace(/\//g, '-')}` : '';
      const repoOutputDir = path.join(config.outputDir, `repo${i}${repoSuffix}`);
      
      console.log(`\n📦 Processing repository ${i + 1}/${parsedRepos.length}: ${repo.identifier}`);
      
      let localRepoPath = repo.path || repo.identifier;
      
      // For remote repos, we'll use agentrc's built-in remote handling
      if (repo.isRemote) {
        localRepoPath = repo.identifier; // Pass as owner/repo to agentrc
      }
      
      const collectionResults = await collectEvidence({ 
        ...config, 
        repoPath: localRepoPath, 
        outputDir: repoOutputDir,
        isRemote: repo.isRemote,
        token
      });
      
      const promptFile = buildPrompt({ ...config, outputDir: repoOutputDir }, collectionResults);
      
      console.log(`✅ Completed ${repo.identifier}`);
      console.log(`📄 Prompt: ${promptFile}`);
    }
    
    console.log('');
    console.log(`🎯 Ready for advanced AI model`);
    console.log(`📁 Collection artifacts: ${config.outputDir}`);
  }
}
