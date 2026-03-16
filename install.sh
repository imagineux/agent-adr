#!/usr/bin/env bash
# Quick installer for agent-adr tools
# Usage: curl -sSL https://raw.githubusercontent.com/imagineux/agent-adr/main/install.sh | bash

set -euo pipefail

REPO="imagineux/agent-adr"
BRANCH="main"
TOOLS_DIR="tools"

echo "🚀 Installing agent-adr tools..."

# Check if we're in a git repo
if [ ! -d ".git" ]; then
  echo "⚠️  Warning: Not in a git repository. Continuing anyway..."
fi

# Create tools directory
mkdir -p "$TOOLS_DIR"

# Download essential files
echo "📥 Downloading core files..."

# Scripts
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/scripts/collect-agentrc.sh" -o "$TOOLS_DIR/collect-agentrc.sh"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/scripts/build-strong-model-prompt.mjs" -o "$TOOLS_DIR/build-strong-model-prompt.mjs"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/scripts/gist-transfer.sh" -o "$TOOLS_DIR/gist-transfer.sh"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/scripts/clipboard-transfer.sh" -o "$TOOLS_DIR/clipboard-transfer.sh"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/scripts/fingerprint-verify.sh" -o "$TOOLS_DIR/fingerprint-verify.sh"
chmod +x "$TOOLS_DIR/collect-agentrc.sh"
chmod +x "$TOOLS_DIR/gist-transfer.sh"
chmod +x "$TOOLS_DIR/clipboard-transfer.sh"
chmod +x "$TOOLS_DIR/fingerprint-verify.sh"

# Templates
mkdir -p "$TOOLS_DIR/templates"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/templates/ai-enablement-adr-template.md" -o "$TOOLS_DIR/templates/ai-enablement-adr-template.md"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/templates/strong-model-synthesis-template.md" -o "$TOOLS_DIR/templates/strong-model-synthesis-template.md"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/templates/strong-model-review-template.md" -o "$TOOLS_DIR/templates/strong-model-review-template.md"

# Skills
mkdir -p "$TOOLS_DIR/skills"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/skills/compose-ai-enablement-adr.md" -o "$TOOLS_DIR/skills/compose-ai-enablement-adr.md"

# Tests (optional but useful for verification)
mkdir -p "$TOOLS_DIR/tests"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/tests/fake-agentrc.sh" -o "$TOOLS_DIR/tests/fake-agentrc.sh"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/tests/test-utils.sh" -o "$TOOLS_DIR/tests/test-utils.sh"
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/tests/smoke-test-confidence.sh" -o "$TOOLS_DIR/tests/smoke-test-confidence.sh"
chmod +x "$TOOLS_DIR/tests/fake-agentrc.sh"
chmod +x "$TOOLS_DIR/tests/smoke-test-confidence.sh"

# Makefile
curl -sSL "https://raw.githubusercontent.com/$REPO/$BRANCH/Makefile" -o "$TOOLS_DIR/Makefile"

# Add to .gitignore if not already there
if [ -f ".gitignore" ]; then
  if ! grep -q "^tools/$" .gitignore; then
    echo "tools/" >> .gitignore
    echo "✅ Added tools/ to .gitignore"
  fi
else
  echo "tools/" > .gitignore
  echo "✅ Created .gitignore with tools/"
fi

# Verify installation
echo "🧪 Verifying installation..."
cd "$TOOLS_DIR"

if command -v make >/dev/null 2>&1; then
  if make test >/dev/null 2>&1; then
    echo "✅ Installation verified - tests pass!"
  else
    echo "⚠️  Installation completed but tests failed. Check Node.js and dependencies."
  fi
else
  echo "⚠️  make not found. Install make to run tests: cd tools && make test"
fi

cd ..

echo ""
echo "🎉 Installation complete!"
echo ""
echo "📋 Next steps:"
echo "   cd tools && make test                    # Verify everything works"
echo "   ./scripts/collect-agentrc.sh . ../collections/\$(basename \"\$PWD\")  # Collect evidence"
echo "   ./scripts/clipboard-transfer.sh ./collections/\$(basename \"\$PWD\")      # Copy to clipboard (recommended)"
echo "   ./scripts/gist-transfer.sh ./collections/\$(basename \"\$PWD\")           # Create Gist automatically"
echo ""
echo "📚 For full documentation: https://github.com/$REPO#$BRANCH"
