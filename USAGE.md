# Quick Usage Guide

Get agent-adr running in a repository in 3 simple steps.

## 🚀 Quick Start

### Step 1: Clone and Setup
```bash
git clone https://github.com/imagineux/agent-adr.git
cd agent-adr
nvm install lts-* && nvm use
```

### Step 2: Run Collection
```bash
./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-name
```

### Step 3: Get Results
```bash
cat ./collections/client-name/prompts/adr-synthesis-prompt.md
```

That's it! Your analysis prompt is ready for a strong AI model.

## 📁 What You Get

```
collections/client-name/
├── collection-summary.json      # Overall results summary
├── instructions-overview.md     # Human-readable overview
├── context/                     # Copied context files
│   ├── README.md
│   ├── package.json
│   └── .github/copilot-instructions.md
├── generated/                   # Generated AI instructions
│   ├── flat-root/copilot-instructions.generated.md
│   └── nested-root/AGENTS.generated.md
└── prompts/                     # Ready for AI models
    ├── adr-synthesis-prompt.md
    └── adr-review-prompt.md
```

## 🎯 What to Do Next

1. **Copy `adr-synthesis-prompt.md`** into Kimi K2.5, GPT-5.4 Pro, or SWE-1.5
2. **Get first ADR** from the strong model
3. **Copy `adr-review-prompt.md`** to review and improve the ADR
4. **Deliver final ADR** to client with evidence-based recommendations

## ⚡ Complete One-Liner

```bash
git clone https://github.com/imagineux/agent-adr.git && \
cd agent-adr && nvm install lts-* && nvm use && \
./scripts/collect-agentrc.sh /path/to/client/repo ./collections/client-name && \
echo "✅ Ready! Check ./collections/client-name/prompts/adr-synthesis-prompt.md"
```

## 🔧 Installation in Restricted Environments

If you're in a corporate environment with certificate issues or network restrictions:

**The git clone method works reliably where curl fails:**
```bash
git clone https://github.com/imagineux/agent-adr.git
cd agent-adr
nvm install lts-* && nvm use
```

**Why this works:**
- No external downloads during setup
- All files are local after cloning
- Works with self-signed certificates
- No network dependencies after initial clone

## 🔧 Common Issues

**"output root is inside the client repo"**
```bash
# ❌ This doesn't work
./scripts/collect-agentrc.sh . ./collections/my-project

# ✅ This works (output outside repo)
./scripts/collect-agentrc.sh . ../collections/my-project
```

**"node: command not found"**
```bash
# Install Node.js using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install lts-* && nvm use
```

**"npx: command not found"**
```bash
# npx comes with Node.js/npm - just ensure Node.js is properly installed
nvm install lts-* && nvm use
```

**"Permission denied"**
```bash
# Make scripts executable
chmod +x ./scripts/collect-agentrc.sh
```

## 🔒 Transfer Options

### Option A: Clipboard Transfer (Recommended)
```bash
# Copy prompts to clipboard for manual Gist creation
cat ./collections/client-name/prompts/adr-synthesis-prompt.md | pbcopy
```

### Option B: Gist Transfer (Automatic - Public)
```bash
# Requires GitHub CLI setup
./scripts/gist-transfer.sh ./collections/client-name
```

### What Gets Transferred
- ✅ `collection-summary.json` - Repository metadata
- ✅ `adr-synthesis-prompt.md` - AI analysis prompt
- ✅ `adr-review-prompt.md` - AI review prompt  
- ✅ Context files (README.md, package.json, docs/)
- ✅ No source code or intellectual property

## 🎉 Success!

You now have:
- ✅ Evidence collected from the actual client codebase
- ✅ Prompts ready for strong AI models
- ✅ Concrete examples to discuss with client
- ✅ Failed generations marked as "(missing)" for transparency

Ready to deliver evidence-based AI enablement recommendations!
