# Quick Usage Guide

Get agent-adr running in a client repository in 30 seconds.

## 🚀 Quick Start

### Step 1: Install Tools (One Command)

```bash
curl -sSL https://raw.githubusercontent.com/imagineux/agent-adr/main/install.sh | bash
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
# Run collection on the client repo
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

## � Secure Transfer (Locked-Down Clients)

For clients who don't want data leaving their system:

### One-Command Secure Workflow
```bash
./tools/scripts/secure-transfer.sh /path/to/client/repo
```

This automatically:
1. ✅ Collects evidence from client repo
2. ✅ Builds AI prompts  
3. ✅ Creates minimal transfer package (metadata only)
4. ✅ Shows exactly what will be transferred
5. ✅ Prepares compressed package with checksum

### What Gets Transferred
- ✅ `collection-summary.json` - Repository metadata
- ✅ `adr-synthesis-prompt.md` - AI analysis prompt
- ✅ `adr-review-prompt.md` - AI review prompt  
- ✅ `README.md` - Project documentation (if present)
- ✅ `package.json` - Package metadata (if present)

### What Does NOT Get Transferred
- ❌ Source code files
- ❌ Business logic or algorithms
- ❌ Sensitive configuration
- ❌ Intellectual property

### Transfer Methods
```bash
# After secure-transfer.sh runs, you get:
secure-transfer-client-name-20240315.tar.gz
secure-transfer-client-name-20240315.tar.gz.sha256

# Transfer via client-approved method:
# - USB drive (most secure)
# - Internal GitLab/GitHub Enterprise  
# - Client-approved cloud storage

# Verify integrity on your machine:
sha256sum -c secure-transfer-client-name-20240315.tar.gz.sha256
tar -xzf secure-transfer-client-name-20240315.tar.gz
```

## �📞 Need Help?

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
