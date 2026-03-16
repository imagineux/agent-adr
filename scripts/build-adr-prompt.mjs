#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

function usage() {
  console.log(`Usage:
  node scripts/build-adr-prompt.mjs --collection <dir> --template <template-file> --out <output-file>`);
}

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (!key.startsWith('--') || value === undefined) {
      throw new Error(`Invalid argument near: ${key ?? '<missing>'}`);
    }
    args[key.slice(2)] = value;
    i += 1;
  }
  return args;
}

function readIfExists(filePath) {
  if (!fs.existsSync(filePath)) {
    return null;
  }
  return fs.readFileSync(filePath, 'utf8');
}

function readJsonIfExists(filePath) {
  const raw = readIfExists(filePath);
  if (raw === null) return { exists: false, text: null, value: null, parseError: null };
  try {
    return { exists: true, text: raw, value: JSON.parse(raw), parseError: null };
  } catch (err) {
    return { exists: true, text: raw, value: null, parseError: String(err) };
  }
}

function fenced(lang, content) {
  return `\`\`\`${lang}\n${content}\n\`\`\``;
}

function renderJsonSection(title, result) {
  if (!result.exists) {
    return `### ${title}\nMISSING: artifact not found.`;
  }
  if (result.parseError) {
    return `### ${title}\nPRESENT BUT INVALID JSON (${result.parseError})\n${fenced('text', result.text ?? '')}`;
  }
  return `### ${title}\n${fenced('json', JSON.stringify(result.value, null, 2))}`;
}

function renderMarkdownSection(title, content, missingLabel = 'MISSING: artifact not found.') {
  if (content === null) {
    return `### ${title}\n${missingLabel}`;
  }
  return `### ${title}\n${fenced('markdown', content)}`;
}

function gatherContext(contextDir) {
  if (!fs.existsSync(contextDir)) {
    return [];
  }

  const files = [];
  function walk(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    entries.sort((a, b) => a.name.localeCompare(b.name));
    for (const entry of entries) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(full);
      } else if (entry.isFile()) {
        files.push(full);
      }
    }
  }

  walk(contextDir);
  files.sort();
  return files.map((full) => {
    const rel = path.relative(contextDir, full).split(path.sep).join('/');
    const text = fs.readFileSync(full, 'utf8');
    return { rel, text };
  });
}

function renderContextSections(contextItems) {
  if (contextItems.length === 0) {
    return '### Copied Repo Context Files\nMISSING: no context files were copied into collection/context.';
  }

  const parts = ['### Copied Repo Context Files'];
  for (const item of contextItems) {
    parts.push(`#### context/${item.rel}`);
    parts.push(fenced('markdown', item.text));
  }
  return parts.join('\n\n');
}

function applyTemplate(template, map) {
  return template.replace(/\{\{\s*([A-Z0-9_]+)\s*\}\}/g, (match, key) => {
    if (Object.prototype.hasOwnProperty.call(map, key)) {
      return map[key];
    }
    return `[[UNRESOLVED_PLACEHOLDER:${key}]]`;
  });
}

function main() {
  let args;
  try {
    args = parseArgs(process.argv);
  } catch (err) {
    console.error(`Error: ${err.message}`);
    usage();
    process.exit(1);
  }

  const collection = args.collection;
  const templatePath = args.template;
  const outPath = args.out;

  if (!collection || !templatePath || !outPath) {
    usage();
    process.exit(1);
  }

  if (!fs.existsSync(collection) || !fs.statSync(collection).isDirectory()) {
    console.error(`Error: collection directory not found: ${collection}`);
    process.exit(1);
  }

  if (!fs.existsSync(templatePath)) {
    console.error(`Error: template file not found: ${templatePath}`);
    process.exit(1);
  }

  const analyze = readJsonIfExists(path.join(collection, 'analyze.json'));
  const readiness = readJsonIfExists(path.join(collection, 'readiness.json'));
  const instructionsStatus = readJsonIfExists(path.join(collection, 'instructions-status.json'));
  const collectionSummary = readJsonIfExists(path.join(collection, 'collection-summary.json'));

  const generatedInstructions = readIfExists(path.join(collection, 'copilot-instructions.generated.md'));
  const notes = readIfExists(path.join(collection, 'notes.md'));
  const contextItems = gatherContext(path.join(collection, 'context'));
  const adrTemplate = readIfExists(path.join('templates', 'ai-enablement-adr-template.md'));

  const sections = {
    COLLECTION_SUMMARY: renderJsonSection('Collection Summary', collectionSummary),
    ANALYZE_JSON: renderJsonSection('analyze.json', analyze),
    READINESS_JSON: renderJsonSection('readiness.json', readiness),
    INSTRUCTIONS_STATUS: renderJsonSection('instructions-status.json', instructionsStatus),
    GENERATED_INSTRUCTIONS: renderMarkdownSection(
      'Generated Instructions (copilot-instructions.generated.md)',
      generatedInstructions,
      'MISSING: instructions output was not generated or empty.'
    ),
    COPIED_CONTEXT_FILES: renderContextSections(contextItems),
    EVALUATOR_NOTES: renderMarkdownSection('Evaluator Notes (notes.md)', notes),
    ADR_TEMPLATE: renderMarkdownSection(
      'ADR Template (templates/ai-enablement-adr-template.md)',
      adrTemplate,
      'MISSING: ADR template not found at templates/ai-enablement-adr-template.md.'
    )
  };

  const template = fs.readFileSync(templatePath, 'utf8');
  const output = applyTemplate(template, sections);

  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, output, 'utf8');

  console.log(`Wrote synthesis prompt to: ${outPath}`);
}

main();
