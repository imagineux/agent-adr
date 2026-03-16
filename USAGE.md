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

## 📞 Need Help?

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
