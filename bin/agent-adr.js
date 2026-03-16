#!/usr/bin/env node

/**
 * agent-adr: Repository AI Enablement ADR Synthesis Tool
 * 
 * Collects repository evidence with agentrc and builds synthesis prompts
 * for AI enablement architecture decision records.
 */

const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');

// Parse command line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  
  if (args.length < 3) {
    console.error(`
Usage:
  agent-adr <repo-path> --output <output-dir> [--education] [model] [timeout]

Arguments:
  repo-path           Local path or GitHub repository (owner/repo or full URL)
  --output OUTPUT     Output directory for collection artifacts and prompts
  --education         Use educational synthesis template with comprehensive framework
  model               AI model to use (default: gpt-5-mini)
  timeout             Timeout per command in seconds (default: 300)

Examples:
  agent-adr ./my-repo --output ../collections/my-repo
  agent-adr microsoft/vscode --output ../collections/vscode --education
  agent-adr https://github.com/microsoft/vscode --output ../collections/vscode
`);
    process.exit(1);
  }

  const result = {
    repoPath: args[0],
    outputDir: null,
    useEducation: false,
    model: 'gpt-5-mini',
    timeout: 300
  };

  // Parse --output flag
  const outputIndex = args.indexOf('--output');
  if (outputIndex === -1 || outputIndex + 1 >= args.length) {
    console.error('ERROR: --output flag is required');
    process.exit(1);
  }
  result.outputDir = args[outputIndex + 1];

  // Parse --education flag
  result.useEducation = args.includes('--education');

  // Parse model and timeout (remaining arguments after flags)
  const remainingArgs = args.filter(arg => 
    arg !== '--education' && 
    arg !== '--output' && 
    arg !== result.outputDir &&
    arg !== result.repoPath
  );

  if (remainingArgs.length > 0) {
    result.model = remainingArgs[0];
  }
  if (remainingArgs.length > 1) {
    result.timeout = parseInt(remainingArgs[1]);
  }

  return result;
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

// Handle remote repositories
async function handleRemoteRepo(repoPath, tempDir) {
  let repoUrl, repoIdentifier;
  
  if (repoPath.startsWith('https://github.com/')) {
    // Full GitHub URL
    repoUrl = repoPath;
    repoIdentifier = repoPath.replace('https://github.com/', '').replace('.git', '');
  } else if (repoPath.includes('/') && !repoPath.startsWith('/')) {
    // owner/repo format
    repoIdentifier = repoPath;
    repoUrl = `https://github.com/${repoPath}`;
  } else {
    return { localPath: repoPath, isRemote: false };
  }

  console.log(`🌐 Remote repository detected: ${repoIdentifier}`);
  console.log(`📥 Cloning to temporary directory...`);

  try {
    execSync(`git clone "${repoUrl}" "${tempDir}"`, { stdio: 'pipe' });
    console.log('✅ Repository cloned successfully');
    return { localPath: tempDir, isRemote: true, repoIdentifier, repoUrl };
  } catch (error) {
    console.error(`❌ Failed to clone repository: ${repoUrl}`);
    process.exit(1);
  }
}

// Execute agentrc command with timeout
async function executeAgentrc(command, args, cwd, timeout = 300000) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    const child = spawn(command, args, { cwd, stdio: 'pipe' });
    
    let stdout = '';
    let stderr = '';
    
    child.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    
    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    const progressInterval = setInterval(() => {
      const elapsed = Math.floor((Date.now() - startTime) / 1000);
      if (elapsed > timeout / 1000) {
        clearInterval(progressInterval);
        child.kill('SIGTERM');
        reject(new Error(`Command timed out after ${timeout / 1000}s`));
      }
      console.log(`⏳ Running... (${elapsed}s elapsed)`);
    }, 10000);

    child.on('close', (code) => {
      clearInterval(progressInterval);
      resolve({ code, stdout, stderr });
    });

    child.on('error', (error) => {
      clearInterval(progressInterval);
      reject(error);
    });
  });
}

// Main collection function
async function collectEvidence(config) {
  const { repoPath, outputDir, model, timeout } = config;
  
  console.log(`🚀 Starting collection for: ${repoPath}`);
  console.log(`📁 Output directory: ${outputDir}`);
  console.log(`⏱️  Timeout per command: ${timeout / 1000}s`);
  console.log(`🤖 Using model: ${model}`);

  // Create output directory
  fs.mkdirSync(outputDir, { recursive: true });
  
  // Create subdirectories
  const dirs = ['logs', 'metadata', 'probes', 'generated', 'context', 'prompts'];
  dirs.forEach(dir => fs.mkdirSync(path.join(outputDir, dir), { recursive: true }));

  // Get agentrc path
  const scriptDir = path.dirname(__dirname);
  const agentrcPath = path.join(scriptDir, 'node_modules', '.bin', 'agentrc');
  
  if (!fs.existsSync(agentrcPath)) {
    console.error('ERROR: agentrc not found. Please run: npm install');
    process.exit(1);
  }

  const commands = [
    { name: 'analyze', args: ['analyze', '--json', '--output', path.join(outputDir, 'analyze.json')] },
    { name: 'readiness', args: ['readiness', '--json', '--output', path.join(outputDir, 'readiness.json')] },
    { name: 'probe-flat-root', args: ['instructions', '--dry-run', '--json', '--model', model] },
    { name: 'probe-flat-areas', args: ['instructions', '--dry-run', '--json', '--areas', '--model', model] },
    { name: 'probe-nested-root', args: ['instructions', '--dry-run', '--json', '--strategy', 'nested', '--model', model] },
    { name: 'probe-nested-areas', args: ['instructions', '--dry-run', '--json', '--strategy', 'nested', '--areas', '--model', model] },
    { name: 'generate-flat', args: ['instructions', '--output', path.join(outputDir, 'generated', 'flat-root', 'copilot-instructions.generated.md'), '--model', model, '--force'] },
    { name: 'generate-nested', args: ['instructions', '--strategy', 'nested', '--output', path.join(outputDir, 'generated', 'nested-root', 'AGENTS.generated.md'), '--model', model, '--force'] }
  ];

  const results = {};
  let overallSuccess = true;

  for (const cmd of commands) {
    console.log(`🔍 Running: ${cmd.name}`);
    console.log(`   Command: agentrc ${cmd.args.join(' ')}`);
    
    try {
      const result = await executeAgentrc(agentrcPath, cmd.args, repoPath, timeout);
      
      if (result.code === 0) {
        console.log(`✅ ${cmd.name}: SUCCESS`);
        results[cmd.name] = { success: true, ...result };
      } else {
        console.log(`❌ ${cmd.name}: FAILED (exit code: ${result.code})`);
        results[cmd.name] = { success: false, ...result };
        overallSuccess = false;
      }
    } catch (error) {
      console.log(`❌ ${cmd.name}: ERROR - ${error.message}`);
      results[cmd.name] = { success: false, error: error.message };
      overallSuccess = false;
    }
    
    console.log(''); // Add spacing between commands
  }

  // Copy context files
  console.log('📋 Copying context files...');
  const contextFiles = ['README.md', 'package.json', 'tsconfig.json', '.github/copilot-instructions.md', 'AGENTS.md', 'CLAUDE.md', 'CONTRIBUTING.md', 'CODEOWNERS', 'SECURITY.md'];
  
  contextFiles.forEach(file => {
    const srcPath = path.join(repoPath, file);
    const destPath = path.join(outputDir, 'context', file);
    
    if (fs.existsSync(srcPath)) {
      fs.mkdirSync(path.dirname(destPath), { recursive: true });
      fs.copyFileSync(srcPath, destPath);
    }
  });
  
  console.log('✅ Context files copied');
  
  return { results, overallSuccess };
}

// Build synthesis prompt
function buildPrompt(config, collectionResults) {
  console.log('Building synthesis prompt in memory...');
  
  const { outputDir, useEducation } = config;
  const scriptDir = path.dirname(__dirname);
  
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
  
  console.log(`📚 Using template: ${templateFile}`);
  
  // Read collection data
  const analyzePath = path.join(outputDir, 'analyze.json');
  const readinessPath = path.join(outputDir, 'readiness.json');
  
  let analyzeData = '{}';
  let readinessData = '{}';
  
  try {
    if (fs.existsSync(analyzePath)) {
      analyzeData = fs.readFileSync(analyzePath, 'utf8');
    }
    if (fs.existsSync(readinessPath)) {
      readinessData = fs.readFileSync(readinessPath, 'utf8');
    }
  } catch (error) {
    console.warn('Warning: Could not read some collection data');
  }
  
  // Replace placeholders
  const synthesis = templateContent
    .replace('{{ANALYZE_JSON}}', analyzeData)
    .replace('{{READINESS_JSON}}', readinessData)
    .replace('{{ADR_TEMPLATE_MD}}', adrTemplate);
  
  // Write prompt to file
  const promptsDir = path.join(outputDir, 'prompts');
  const promptFile = path.join(promptsDir, 'adr-synthesis-prompt.md');
  
  fs.writeFileSync(promptFile, synthesis);
  
  console.log(`✅ Synthesis prompt built: ${promptFile}`);
  console.log(`📋 Prompt length: ${synthesis.length} characters`);
  
  return promptFile;
}

// Main execution
async function main() {
  try {
    validateNodeVersion();
    const config = parseArgs();
    
    // Handle remote repositories
    let tempDir = null;
    let localRepoPath = config.repoPath;
    let cleanup = () => {};
    
    if (config.repoPath.startsWith('https://') || (config.repoPath.includes('/') && !config.repoPath.startsWith('/'))) {
      tempDir = fs.mkdtempSync(path.join(require('os').tmpdir(), 'agent-adr-'));
      const remoteInfo = await handleRemoteRepo(config.repoPath, tempDir);
      localRepoPath = remoteInfo.localPath;
      cleanup = () => {
        console.log('🧹 Cleaning up temporary directory');
        fs.rmSync(tempDir, { recursive: true, force: true });
      };
    }
    
    // Set up cleanup on exit
    process.on('exit', cleanup);
    process.on('SIGINT', () => { cleanup(); process.exit(1); });
    process.on('SIGTERM', () => { cleanup(); process.exit(1); });
    
    // Collect evidence
    const collectionResults = await collectEvidence({ ...config, repoPath: localRepoPath });
    
    // Build prompt
    const promptFile = buildPrompt(config, collectionResults);
    
    console.log(`🎯 Ready for advanced AI model (paste from: ${promptFile})`);
    console.log(`📁 Collection artifacts: ${config.outputDir}`);
    
    if (collectionResults.overallSuccess) {
      console.log('✅ Collection completed successfully');
      process.exit(0);
    } else {
      console.log('⚠️  Collection completed with some failures (check logs)');
      process.exit(1);
    }
    
  } catch (error) {
    console.error(`❌ Fatal error: ${error.message}`);
    process.exit(1);
  }
}

// Run main function
if (require.main === module) {
  main();
}
