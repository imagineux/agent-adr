# Report Templates

This directory contains Mustache templates used by the `generate-report.mjs` script to create comprehensive AI readiness reports.

## Template Files

### `comprehensive-report.template.md`
Main template for the comprehensive AI readiness report. Uses Mustache syntax for dynamic content rendering.

## Template Variables

### Report Metadata
- `{{report.timestamp}}` - Report generation date (YYYY-MM-DD)
- `{{report.totalRepos}}` - Total number of repositories analyzed
- `{{report.successfulRepos}}` - Number of successfully analyzed repositories
- `{{report.failedRepos}}` - Number of failed analyses
- `{{report.successRate}}` - Success percentage
- `{{report.analysisDate}}` - Original analysis timestamp
- `{{report.generatedIso}}` - Full ISO timestamp
- `{{report.dataSource}}` - Path to batch summary file

### Repository Data
- `{{#repositories}}...{{/repositories}}` - Array iteration for repositories
- `{{name}}` - Repository name
- `{{status}}` - Success/failure status with emoji
- `{{analysisData}}` - Analysis data availability
- `{{readinessData}}` - Readiness data availability
- `{{languagesFormatted}}` - Comma-separated languages
- `{{frameworksFormatted}}` - Comma-separated frameworks
- `{{packageManager}}` - Package manager name
- `{{isMonorepo}}` - Boolean for monorepo status
- `{{overallScore}}` - Readiness score (0-100)
- `{{engineeringMaturity}}` - Maturity level
- `{{infrastructureReadiness}}` - Infrastructure readiness
- `{{documentationQuality}}` - Documentation quality
- `{{safetyGovernance}}` - Safety and governance status

### Conditional Sections
- `{{#hasLanguages}}...{{/hasLanguages}}` - Show if languages exist
- `{{#hasFrameworks}}...{{/hasFrameworks}}` - Show if frameworks exist
- `{{#hasPortfolioGuide}}...{{/hasPortfolioGuide}}` - Show portfolio guide section
- `{{#hasEducationalFramework}}...{{/hasEducationalFramework}}` - Show educational framework
- `{{#hasAdrTemplate}}...{{/hasAdrTemplate}}` - Show ADR template

### Synthesis Prompt
- `{{synthesisPrompt}}` - Pre-rendered synthesis prompt content

## Mustache Features Used

- **Variable substitution**: `{{variable}}`
- **Array iteration**: `{{#array}}...{{/array}}`
- **Conditionals**: `{{#condition}}...{{/condition}}`
- **Inverted conditionals**: `{{^condition}}...{{/condition}}`

## Template Customization

To modify the report structure:
1. Edit the template files in this directory
2. No code changes required for basic formatting changes
3. For new data fields, update the `prepareReportView()` function in `generate-report.mjs`

## Template Validation

Templates are validated during report generation. If a template file is missing or contains invalid Mustache syntax, the script will log a warning and continue with default content.
