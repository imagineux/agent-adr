# Quick Usage Guide

Get agent-adr running in a repository in 30 seconds.

## 🚀 Quick Start

### Step 1: Install Tools (Choose Method)

**Option A: Simple Standalone (Recommended)**
```bash
curl -sSL https://raw.githubusercontent.com/imagineux/agent-adr/main/standalone-simple.sh | bash
```

**Option B: Full Installer (More Features)**
```bash
curl -sSL https://raw.githubusercontent.com/imagineux/agent-adr/main/install.sh | bash
```

**Option C: Ultra-Standalone (No Network)**
```bash
# Download the standalone file first
curl -sSL https://raw.githubusercontent.com/imagineux/agent-adr/main/standalone-installer-complete.sh > install.sh
chmod +x install.sh
./install.sh
```

That's it! The tools are now in `./tools/` and ready to use.

### Step 2: Verify It Works
```bash
cd tools
make test
cd ..
```

### Step 3: Collect Evidence
```bash
# Run collection on the repository
./tools/scripts/collect-agentrc.sh . ./collections/$(basename "$PWD")

# Example output:
# Collection completed successfully: ./collections/my-project
```

### Step 4: Build Prompts
```bash
# Generate analysis prompts
node ./tools/scripts/build-strong-model-prompt.mjs \
  --collection ./collections/$(basename "$PWD") \
  --out ./collections/$(basename "$PWD")/prompts
```

### Step 5: Review Results
```bash
# See what was collected
ls -la ./collections/$(basename "$PWD")/

# Check the summary
cat ./collections/$(basename "$PWD")/collection-summary.json

# View the prompts
cat ./collections/$(basename "$PWD")/prompts/adr-synthesis-prompt.md
```

## 📁 What You Get

```
collections/my-project/
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
curl -sSL https://raw.githubusercontent.com/imagineux/agent-adr/main/install.sh | bash && \
cd tools && make test && cd .. && \
./tools/scripts/collect-agentrc.sh . ./collections/$(basename "$PWD") && \
node ./tools/scripts/build-strong-model-prompt.mjs --collection ./collections/$(basename "$PWD") --out ./collections/$(basename "$PWD")/prompts && \
echo "✅ Ready! Check ./collections/$(basename "$PWD")/prompts/"
```

## 🔧 Common Issues

**"output root is inside the client repo"**
```bash
# ❌ This doesn't work
./tools/scripts/collect-agentrc.sh . ./collections/my-project

# ✅ This works (output outside repo)
./tools/scripts/collect-agentrc.sh . ../collections/my-project
```

**"node: command not found"**
```bash
# Install Node.js (version 16+)
# On Mac: brew install node
# On Ubuntu: sudo apt install nodejs npm
```

**"curl: command not found"**
```bash
# Install curl
# On Mac: brew install curl
# On Ubuntu: sudo apt install curl
```

**"Permission denied"**
```bash
# Make scripts executable
chmod +x ./tools/scripts/collect-agentrc.sh
```

## 🔒 Transfer Options

### Option A: Clipboard Transfer (Recommended)
```bash
./tools/scripts/clipboard-transfer.sh ./collections/repo-name
```

This automatically:
1. ✅ Creates minimal transfer package (metadata only)
2. ✅ Generates cryptographic fingerprints
3. ✅ Formats everything for Gist pasting
4. ✅ Copies formatted content to clipboard
5. ✅ Provides instructions for private Gist creation

**Workflow:**
1. Run the command
2. Open https://gist.github.com/
3. Create new private Gist
4. Paste clipboard content (Cmd+V / Ctrl+V)
5. Copy Gist URL for analysis
6. Delete Gist immediately after use

**Perfect for:**
- Personal GitHub account usage
- No CLI authentication required
- Immediate creation and deletion
- Complete control over Gist lifecycle

### Option B: Gist Transfer (Automatic - Public)
```bash
./tools/scripts/gist-transfer.sh ./collections/repo-name
```

This automatically creates a public Gist with all files using GitHub CLI.

### What Gets Transferred
- ✅ `collection-summary.json` - Repository metadata
- ✅ `adr-synthesis-prompt.md` - AI analysis prompt
- ✅ `adr-review-prompt.md` - AI review prompt  
- ✅ `README.md` - Project documentation (if present)
- ✅ `package.json` - Package metadata (if present)
- ✅ `docs/` folder - Repository documentation, ADRs, API docs (if present)
- ✅ `TRANSFER_FINGERPRINTS.txt` - Cryptographic verification

### What Does NOT Get Transferred
- ❌ Source code files
- ❌ Business logic or algorithms
- ❌ Sensitive configuration
- ❌ Intellectual property

### Requirements

**For Clipboard Transfer:**
- pbcopy (macOS, built-in)
- xclip (Linux: `sudo apt install xclip`)
- clip.exe (Windows, built-in)
- Personal GitHub account for private Gist

**For Gist Transfer (Optional):**
- GitHub CLI installed: `brew install gh`
- Authenticated: `gh auth login`
- Or GITHUB_TOKEN environment variable

### 🔐 Cryptographic Verification

**Fingerprints prove:**
- ✅ **Exact file list** - No additional files added
- ✅ **File integrity** - No contents modified  
- ✅ **Metadata only** - No source code included
- ✅ **Tamper-evident** - Any changes detected

**Verification:**
```bash
# After downloading from Gist
sha256sum -c TRANSFER_FINGERPRINTS.txt
# Shows: PASSED/FAILED for each file
```

**Fingerprint format:**
```
SHA256_HASH  FILE_SIZE  RELATIVE_PATH
a1b2c3d4...  1234      collection-summary.json
e5f6g7h8...  5678      prompts/adr-synthesis-prompt.md
```

### 🚀 Complete Workflow

```bash
# 1. Install tools
curl -sSL https://raw.githubusercontent.com/imagineux/agent-adr/main/install.sh | bash

# 2. Collect evidence
./tools/scripts/collect-agentrc.sh . ./collections/repo-name

# 3. Copy to clipboard for private Gist (recommended)
./tools/scripts/clipboard-transfer.sh ./collections/repo-name

# 4. Create private Gist and paste content
# 5. Use prompts for AI analysis
# 6. Delete Gist immediately after use
```

This gives cryptographic proof that exactly the approved files are being transferred, with no source code or intellectual property included.

## �� Need Help?

- **Full documentation**: See README.md for comprehensive guide
- **Testing**: Run `cd tools && make test` to verify everything works
- **Issues**: Check the troubleshooting section in README.md

## 🎉 Success!

You now have:
- ✅ Evidence collected from the actual client codebase
- ✅ Prompts ready for strong AI models
- ✅ Concrete examples to discuss with client
- ✅ Failed generations marked as "(missing)" for transparency

Ready to deliver evidence-based AI enablement recommendations!
