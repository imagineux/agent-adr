#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

function parseArgs(argv) {
  const args = { collection: '', template: '', out: '' };
  for (let i = 2; i < argv.length; i += 1) {
    const key = argv[i];
    const value = argv[i + 1];
    if (!value || value.startsWith('--')) {
      throw new Error(`Missing value for ${key}`);
    }
    if (key === '--collection') args.collection = value;
    else if (key === '--template') args.template = value;
    else if (key === '--out') args.out = value;
    else throw new Error(`Unknown argument: ${key}`);
    i += 1;
  }
  if (!args.collection || !args.template || !args.out) {
    throw new Error('Usage: node scripts/build-adr-prompt.mjs --collection <dir> --template <file> --out <file>');
  }
  return args;
}

function readUtf8IfExists(filePath) {
  if (!fs.existsSync(filePath)) {
    return { exists: false, content: '' };
  }
  return { exists: true, content: fs.readFileSync(filePath, 'utf8') };
}

function readJsonPretty(filePath, label) {
  const loaded = readUtf8IfExists(filePath);
  if (!loaded.exists) {
    return `MISSING: ${label} not found at ${filePath}`;
  }
  try {
    const parsed = JSON.parse(loaded.content);
    return JSON.stringify(parsed, null, 2);
  } catch (err) {
    return `INVALID JSON in ${filePath}\n${loaded.content}`;
  }
}

function readDirRecursive(baseDir, relativeDir) {
  const root = path.join(baseDir, relativeDir);
  if (!fs.existsSync(root)) return [];

  const files = [];
  const stack = [root];

  while (stack.length > 0) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name));
    for (const entry of entries) {
      const absolute = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(absolute);
      } else if (entry.isFile()) {
        const relFromCollection = path.relative(baseDir, absolute).split(path.sep).join('/');
        files.push(relFromCollection);
      }
    }
  }

  return files.sort();
}

function formatContextSection(collectionDir) {
  const contextFiles = readDirRecursive(collectionDir, 'context');
  if (contextFiles.length === 0) {
    return 'MISSING: no copied context files under context/.';
  }

  const blocks = [];
  for (const relPath of contextFiles) {
    const abs = path.join(collectionDir, relPath);
    const content = fs.readFileSync(abs, 'utf8');
    blocks.push(`### ${relPath}\n\n\`\`\`markdown\n${content}\n\`\`\``);
  }

  return blocks.join('\n\n');
}

function formatOptionalMarkdown(filePath, missingMessage) {
  const loaded = readUtf8IfExists(filePath);
  if (!loaded.exists) return `MISSING: ${missingMessage}`;
  if (!loaded.content.trim()) return `MISSING: ${path.basename(filePath)} exists but is empty.`;
  return loaded.content;
}

function applyTemplate(template, data) {
  return template
    .replaceAll('{{COLLECTION_SUMMARY_JSON}}', data.collectionSummaryJson)
    .replaceAll('{{ANALYZE_JSON}}', data.analyzeJson)
    .replaceAll('{{READINESS_JSON}}', data.readinessJson)
    .replaceAll('{{INSTRUCTIONS_STATUS_JSON}}', data.instructionsStatusJson)
    .replaceAll('{{GENERATED_INSTRUCTIONS_MD}}', data.generatedInstructionsMd)
    .replaceAll('{{COPIED_CONTEXT_FILES_MD}}', data.copiedContextFilesMd)
    .replaceAll('{{EVALUATOR_NOTES_MD}}', data.evaluatorNotesMd)
    .replaceAll('{{ADR_TEMPLATE_MD}}', data.adrTemplateMd);
}

function main() {
  const args = parseArgs(process.argv);
  const collectionDir = path.resolve(args.collection);
  const templatePath = path.resolve(args.template);
  const outPath = path.resolve(args.out);

  if (!fs.existsSync(collectionDir) || !fs.statSync(collectionDir).isDirectory()) {
    throw new Error(`Collection directory not found: ${collectionDir}`);
  }

  if (!fs.existsSync(templatePath)) {
    throw new Error(`Template file not found: ${templatePath}`);
  }

  const template = fs.readFileSync(templatePath, 'utf8');

  const data = {
    collectionSummaryJson: readJsonPretty(path.join(collectionDir, 'collection-summary.json'), 'collection-summary.json'),
    analyzeJson: readJsonPretty(path.join(collectionDir, 'analyze.json'), 'analyze.json'),
    readinessJson: readJsonPretty(path.join(collectionDir, 'readiness.json'), 'readiness.json'),
    instructionsStatusJson: readJsonPretty(path.join(collectionDir, 'instructions-status.json'), 'instructions-status.json'),
    generatedInstructionsMd: formatOptionalMarkdown(
      path.join(collectionDir, 'copilot-instructions.generated.md'),
      'copilot-instructions.generated.md not found.'
    ),
    copiedContextFilesMd: formatContextSection(collectionDir),
    evaluatorNotesMd: formatOptionalMarkdown(path.join(collectionDir, 'notes.md'), 'notes.md not found.'),
    adrTemplateMd: formatOptionalMarkdown(
      path.resolve('templates/ai-enablement-adr-template.md'),
      'templates/ai-enablement-adr-template.md not found in this repo.'
    )
  };

  const rendered = applyTemplate(template, data);

  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, rendered, 'utf8');

  console.log(`[info] Wrote ADR synthesis prompt to: ${outPath}`);
}

main();
