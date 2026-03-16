#!/usr/bin/env node
import fs from 'fs';
import path from 'path';

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i += 1) {
    const k = argv[i];
    const v = argv[i + 1];
    if (k.startsWith('--')) {
      args[k.slice(2)] = v;
      i += 1;
    }
  }
  return args;
}

function readText(file) {
  try {
    return fs.readFileSync(file, 'utf8');
  } catch {
    return null;
  }
}

function readJson(file) {
  const txt = readText(file);
  if (!txt) return { missing: true, raw: null, value: null };
  try {
    return { missing: false, raw: txt, value: JSON.parse(txt) };
  } catch {
    return { missing: false, raw: txt, value: null, parseError: true };
  }
}

function sectionForJson(title, file) {
  const data = readJson(file);
  if (data.missing) return `## ${title}\nMissing: ${file}\n`;
  if (!data.value) return `## ${title}\nPresent but invalid JSON: ${file}\n\n\
\`\`\`json\n${data.raw}\n\`\`\`\n`;
  return `## ${title}\nSource: ${file}\n\n\`\`\`json\n${JSON.stringify(data.value, null, 2)}\n\`\`\`\n`;
}

function tail(text, n = 1200) {
  if (!text) return '';
  return text.length <= n ? text : text.slice(-n);
}

function gatherFailureStderr(collectionDir) {
  const files = [
    'probes/flat-root/stderr.log',
    'probes/flat-areas/stderr.log',
    'probes/nested-root/stderr.log',
    'probes/nested-areas/stderr.log',
    'generated/flat-root/stderr.log',
    'generated/nested-root/stderr.log'
  ];

  const chunks = [];
  for (const rel of files) {
    const full = path.join(collectionDir, rel);
    const content = readText(full);
    if (content && content.trim()) {
      chunks.push(`### ${rel}\n\n\`\`\`text\n${tail(content)}\n\`\`\``);
    } else {
      chunks.push(`### ${rel}\nMissing or empty.`);
    }
  }
  return chunks.join('\n\n');
}

function contextDump(collectionDir) {
  const root = path.join(collectionDir, 'context');
  if (!fs.existsSync(root)) return 'Context directory missing.';

  const files = [];
  const walk = (dir) => {
    for (const name of fs.readdirSync(dir)) {
      const full = path.join(dir, name);
      const rel = path.relative(collectionDir, full);
      const stat = fs.statSync(full);
      if (stat.isDirectory()) walk(full);
      else files.push(rel);
    }
  };
  walk(root);
  if (!files.length) return 'No context files copied.';

  const chunks = files.sort().map((rel) => {
    const content = readText(path.join(collectionDir, rel));
    return `### ${rel}\n\n\`\`\`text\n${tail(content || '')}\n\`\`\``;
  });
  return chunks.join('\n\n');
}

function generatedDrafts(collectionDir) {
  const candidates = [
    'generated/flat-root/copilot-instructions.generated.md',
    'generated/nested-root/AGENTS.generated.md'
  ];
  const parts = [];
  for (const rel of candidates) {
    const txt = readText(path.join(collectionDir, rel));
    if (txt) {
      parts.push(`### ${rel}\n\n\`\`\`markdown\n${txt}\n\`\`\``);
    } else {
      parts.push(`### ${rel}\nMissing.`);
    }
  }
  return parts.join('\n\n');
}

function loadTemplate(localName) {
  return readText(path.join(process.cwd(), 'templates', localName)) || `(Missing template: ${localName})`;
}

const args = parseArgs(process.argv);
const collection = args.collection;
const outDir = args.out;
if (!collection || !outDir) {
  console.error('Usage: node scripts/build-strong-model-prompt.mjs --collection <dir> --out <dir>');
  process.exit(1);
}

fs.mkdirSync(outDir, { recursive: true });

const synthesisTemplate = loadTemplate('strong-model-synthesis-template.md');
const reviewTemplate = loadTemplate('strong-model-review-template.md');

const synthesisPrompt = `# ADR Synthesis Prompt Bundle\n
${synthesisTemplate}\n
## Collection Summary\n${sectionForJson('collection-summary.json', path.join(collection, 'collection-summary.json'))}
${sectionForJson('metadata/run.json', path.join(collection, 'metadata/run.json'))}
${sectionForJson('metadata/environment.json', path.join(collection, 'metadata/environment.json'))}
${sectionForJson('metadata/commands.json', path.join(collection, 'metadata/commands.json'))}
${sectionForJson('metadata/analyze-status.json', path.join(collection, 'metadata/analyze-status.json'))}
${sectionForJson('metadata/readiness-status.json', path.join(collection, 'metadata/readiness-status.json'))}
${sectionForJson('Analyze Artifact', path.join(collection, 'analyze.json'))}
${sectionForJson('Readiness Artifact', path.join(collection, 'readiness.json'))}
${sectionForJson('Probe flat-root', path.join(collection, 'probes/flat-root/probe.json'))}
${sectionForJson('Probe flat-areas', path.join(collection, 'probes/flat-areas/probe.json'))}
${sectionForJson('Probe nested-root', path.join(collection, 'probes/nested-root/probe.json'))}
${sectionForJson('Probe nested-areas', path.join(collection, 'probes/nested-areas/probe.json'))}
${sectionForJson('Probe status flat-root', path.join(collection, 'probes/flat-root/status.json'))}
${sectionForJson('Probe status flat-areas', path.join(collection, 'probes/flat-areas/status.json'))}
${sectionForJson('Probe status nested-root', path.join(collection, 'probes/nested-root/status.json'))}
${sectionForJson('Probe status nested-areas', path.join(collection, 'probes/nested-areas/status.json'))}
${sectionForJson('Generation status flat-root', path.join(collection, 'generated/flat-root/status.json'))}
${sectionForJson('Generation status nested-root', path.join(collection, 'generated/nested-root/status.json'))}

## Failed Step stderr snippets (never ignore these)\n${gatherFailureStderr(collection)}

## Generated Instruction Drafts (candidate artifacts only)\n${generatedDrafts(collection)}

## Copied Context Files\n${contextDump(collection)}
`;

const reviewPrompt = `# ADR Review Prompt Bundle\n
${reviewTemplate}\n
## First-pass inputs\n- Paste the first-pass ADR below this line before running review.\n- Treat failed probe/generation diagnostics as process-risk evidence.\n
## Collection diagnostics\n${sectionForJson('collection-summary.json', path.join(collection, 'collection-summary.json'))}
${sectionForJson('Generation status flat-root', path.join(collection, 'generated/flat-root/status.json'))}
${sectionForJson('Generation status nested-root', path.join(collection, 'generated/nested-root/status.json'))}

## Failure stderr snippets\n${gatherFailureStderr(collection)}

## Candidate generated instruction drafts\n${generatedDrafts(collection)}
`;

fs.writeFileSync(path.join(outDir, 'adr-synthesis-prompt.md'), synthesisPrompt);
fs.writeFileSync(path.join(outDir, 'adr-review-prompt.md'), reviewPrompt);

console.log(`Wrote prompts to ${outDir}`);
