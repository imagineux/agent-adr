#!/usr/bin/env node

/**
 * Generate comprehensive report from batch analysis and documentation
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { Command } from 'commander';
import ora from 'ora';
import mustache from 'mustache';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const scriptDir = path.dirname(__dirname);

const program = new Command();

// Program configuration
program
  .name('generate-ai-report')
  .description('Generate comprehensive AI readiness report from batch analysis and documentation')
  .version('1.0.0');

program
  .argument('[summary-path]', 'Path to batch-summary.json', '.agent-adr-cache/batch-summary.json')
  .argument('[output-path]', 'Output path for report', '.agent-adr-cache/reports/comprehensive-ai-readiness-report.md')
  .action(async (summaryPath, outputPath) => {
    try {
      await generateReport(summaryPath, outputPath);
    } catch (error) {
      console.error(`❌ Report generation failed: ${error.message}`);
      process.exit(1);
    }
  });

// Parse command line arguments
program.parse();

// Export for use by main CLI
export async function generateReport(summaryPath, outputPath) {
  const spinner = ora('Generating comprehensive AI readiness report...').start();
  
  try {
    // Ensure output directory exists
    const outputDir = path.dirname(outputPath);
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
      spinner.info(`Created reports directory: ${outputDir}`);
    }

    // Read batch summary
    let batchSummary = {};
    try {
      const summaryContent = fs.readFileSync(summaryPath, 'utf8');
      batchSummary = JSON.parse(summaryContent);
      spinner.succeed(`Loaded batch summary: ${batchSummary.totalRepos} repositories analyzed`);
    } catch (error) {
      spinner.fail(`Failed to read batch summary from ${summaryPath}`);
      throw error;
    }

    // Start documentation loading
    const docsSpinner = ora('Loading documentation files...').start();

    // Read documentation files
    const docsDir = path.join(scriptDir, 'docs');
    const templatesDir = path.join(scriptDir, 'templates');
    
    const docFiles = {
      adrTemplate: path.join(docsDir, 'adr-template.md'),
      educationalFramework: path.join(docsDir, 'educational-framework.md'),
      portfolioGuide: path.join(docsDir, 'portfolio-analysis-guide.md'),
      synthesisPrompt: path.join(docsDir, 'synthesis-prompt-template.md'),
      comprehensiveReport: path.join(templatesDir, 'comprehensive-report.template.md')
    };

    let docContents = {};
    for (const [key, filePath] of Object.entries(docFiles)) {
      try {
        docContents[key] = fs.readFileSync(filePath, 'utf8');
      } catch (error) {
        docsSpinner.warn(`Could not read ${filePath}: ${error.message}`);
        docContents[key] = '';
      }
    }

    docsSpinner.succeed('Documentation files loaded');

    // Generate report
    const reportSpinner = ora('Generating comprehensive report...').start();
    const report = generateReportContent(batchSummary, docContents, summaryPath);
    reportSpinner.succeed('Report content generated');

    // Write report
    const writeSpinner = ora('Writing report file...').start();
    fs.writeFileSync(outputPath, report);
    writeSpinner.succeed(`Report generated: ${path.basename(outputPath)}`);

    console.log(`📄 Report length: ${report.length.toLocaleString()} characters`);
    console.log(`📁 Saved to: ${outputPath}`);
    console.log('\n🎉 Report generation completed successfully!');

  } catch (error) {
    spinner.fail(`Report generation failed: ${error.message}`);
    throw error;
  }
}

function generateSynthesisPrompt(batchSummary, docContents) {
  const timestamp = new Date().toISOString().split('T')[0];
  const successRate = Math.round((batchSummary.successfulRepos / batchSummary.totalRepos) * 100);

  // Extract repository data for the prompt
  const repoData = Object.entries(batchSummary.results || {}).map(([repo, result]) => {
    if (!result || !result.results) return null;
    
    let analysisData = {};
    let readinessData = {};
    
    // Extract analyze data
    if (result.results.analyze && result.results.analyze.stdout) {
      try {
        analysisData = JSON.parse(result.results.analyze.stdout);
      } catch (e) {
        // Skip invalid data
      }
    }
    
    // Extract readiness data
    if (result.results.readiness && result.results.readiness.stdout) {
      try {
        readinessData = JSON.parse(result.results.readiness.stdout);
      } catch (e) {
        // Skip invalid data
      }
    }
    
    return {
      repository: repo,
      languages: analysisData.data?.languages || [],
      frameworks: analysisData.data?.frameworks || [],
      packageManager: analysisData.data?.packageManager || 'Unknown',
      isMonorepo: analysisData.data?.isMonorepo || false,
      overallScore: readinessData.data?.overall_score || 0,
      engineeringMaturity: readinessData.data?.engineering_maturity || 'Unknown',
      infrastructureReadiness: readinessData.data?.infrastructure_readiness || 'Unknown',
      documentationQuality: readinessData.data?.documentation_quality || 'Unknown',
      safetyGovernance: readinessData.data?.safety_governance || 'Unknown'
    };
  }).filter(Boolean);

  const repositoriesSummary = JSON.stringify(repoData, null, 2);
  
  // Generate overview table
  const overviewTable = repoData.map(repo => 
    `| ${repo.repository} | ${repo.languages.join(', ') || 'Unknown'} | ${repo.engineeringMaturity} | ${repo.overallScore}/100 |`
  ).join('\n');

  // Count maturity levels
  const totalRepos = repoData.length;
  const highReadiness = repoData.filter(r => r.overallScore >= 80).length;
  const mediumReadiness = repoData.filter(r => r.overallScore >= 60 && r.overallScore < 80).length;
  const lowReadiness = repoData.filter(r => r.overallScore < 60).length;

  // Generate variance analysis
  const languages = [...new Set(repoData.flatMap(r => r.languages))];
  const maturityLevels = [...new Set(repoData.map(r => r.engineeringMaturity))];

  // Prepare view object for Mustache
  const view = {
    timestamp,
    totalRepos,
    successRate,
    repoOverviewTable: overviewTable,
    repositoriesSummary,
    highReadiness,
    mediumReadiness,
    lowReadiness,
    languages: languages.join(', '),
    maturityLevels: maturityLevels.join(', ')
  };

  // Render with Mustache
  return mustache.render(docContents.synthesisPrompt || '', view);
}

function prepareReportView(batchSummary, docContents, summaryPath) {
  const timestamp = new Date().toISOString().split('T')[0];
  const successRate = Math.round((batchSummary.successfulRepos / batchSummary.totalRepos) * 100);

  // Extract repository data for the report
  const repositories = Object.entries(batchSummary.results || {}).map(([repo, result]) => {
    if (!result || !result.results) return null;
    
    let analysisData = {};
    let readinessData = {};
    
    // Extract analyze data
    if (result.results.analyze && result.results.analyze.stdout) {
      try {
        analysisData = JSON.parse(result.results.analyze.stdout);
      } catch (e) {
        // Skip invalid data
      }
    }
    
    // Extract readiness data
    if (result.results.readiness && result.results.readiness.stdout) {
      try {
        readinessData = JSON.parse(result.results.readiness.stdout);
      } catch (e) {
        // Skip invalid data
      }
    }
    
    const languages = analysisData.data?.languages || [];
    const frameworks = analysisData.data?.frameworks || [];
    
    return {
      name: repo,
      status: result?.overallSuccess ? '✅ Success' : '❌ Failed',
      analysisData: result?.results?.analyze?.success ? '✅ Available' : '❌ Missing',
      readinessData: result?.results?.readiness?.success ? '✅ Available' : '❌ Missing',
      languages,
      frameworks,
      languagesFormatted: languages.join(', ') || 'Unknown',
      frameworksFormatted: frameworks.join(', ') || 'None detected',
      packageManager: analysisData.data?.packageManager || 'Unknown',
      isMonorepo: analysisData.data?.isMonorepo || false,
      overallScore: readinessData.data?.overall_score || 0,
      engineeringMaturity: readinessData.data?.engineering_maturity || 'Unknown',
      infrastructureReadiness: readinessData.data?.infrastructure_readiness || 'Unknown',
      documentationQuality: readinessData.data?.documentation_quality || 'Unknown',
      safetyGovernance: readinessData.data?.safety_governance || 'Unknown',
      hasLanguages: languages.length > 0,
      hasFrameworks: frameworks.length > 0
    };
  }).filter(Boolean);

  return {
    report: {
      timestamp,
      totalRepos: batchSummary.totalRepos,
      successfulRepos: batchSummary.successfulRepos,
      failedRepos: batchSummary.failedRepos,
      successRate,
      analysisDate: batchSummary.timestamp || 'Unknown',
      generatedIso: new Date().toISOString(),
      dataSource: summaryPath
    },
    repositories,
    synthesisPrompt: generateSynthesisPrompt(batchSummary, docContents),
    hasPortfolioGuide: Boolean(docContents.portfolioGuide),
    hasEducationalFramework: Boolean(docContents.educationalFramework),
    hasAdrTemplate: Boolean(docContents.adrTemplate),
    portfolioGuide: docContents.portfolioGuide,
    educationalFramework: docContents.educationalFramework,
    adrTemplate: docContents.adrTemplate
  };
}

function generateReportContent(batchSummary, docContents, summaryPath) {
  const view = prepareReportView(batchSummary, docContents, summaryPath);
  return mustache.render(docContents.comprehensiveReport || '', view);
}
