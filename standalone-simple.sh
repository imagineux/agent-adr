#!/usr/bin/env bash
# Ultra-simple standalone installer - no base64, just curl fallback
# Perfect for locked-down clients

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TOOLS_DIR="tools"
REPO="imagineux/agent-adr"
BRANCH="main"

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Fallback function if curl fails
fallback_manual() {
    echo ""
    log_error "❌ Network installation failed!"
    echo ""
    echo "🔧 Manual installation steps:"
    echo "1. Download https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
    echo "2. Unzip and copy files to ./tools/"
    echo "3. Run: cd tools && make test"
    echo ""
    echo "📁 Files needed:"
    echo "   - scripts/collect-agentrc.sh"
    echo "   - scripts/build-strong-model-prompt.mjs" 
    echo "   - scripts/secure-transfer.sh"
    echo "   - templates/*.md"
    echo "   - skills/*.md"
    echo "   - tests/*.sh"
    echo "   - Makefile"
}

# Main installation
main() {
    echo "🚀 Installing agent-adr tools..."
    
    # Check if we're in a git repo
    if [ ! -d ".git" ]; then
        log_warn "Warning: Not in a git repository. Continuing anyway..."
    fi

    # Create tools directory
    mkdir -p "$TOOLS_DIR"
    cd "$TOOLS_DIR"

    log_info "📥 Downloading core files..."

    # Try to download files with error handling
    download_success=true

    # Scripts
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/scripts/collect-agentrc.sh" -o "collect-agentrc.sh"; then
        download_success=false
    fi
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/scripts/build-strong-model-prompt.mjs" -o "build-strong-model-prompt.mjs"; then
        download_success=false
    fi
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/scripts/secure-transfer.sh" -o "secure-transfer.sh"; then
        download_success=false
    fi

    # Templates
    mkdir -p templates
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/templates/ai-enablement-adr-template.md" -o "templates/ai-enablement-adr-template.md"; then
        download_success=false
    fi
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/templates/strong-model-synthesis-template.md" -o "templates/strong-model-synthesis-template.md"; then
        download_success=false
    fi
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/templates/strong-model-review-template.md" -o "templates/strong-model-review-template.md"; then
        download_success=false
    fi

    # Skills
    mkdir -p skills
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/skills/compose-ai-enablement-adr.md" -o "skills/compose-ai-enablement-adr.md"; then
        download_success=false
    fi

    # Tests (for verification)
    mkdir -p tests
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/tests/fake-agentrc.sh" -o "tests/fake-agentrc.sh"; then
        download_success=false
    fi
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/tests/test-utils.sh" -o "tests/test-utils.sh"; then
        download_success=false
    fi
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/tests/smoke-test-confidence.sh" -o "tests/smoke-test-confidence.sh"; then
        download_success=false
    fi

    # Makefile
    if ! curl -sSL --fail "https://raw.githubusercontent.com/$REPO/$BRANCH/Makefile" -o "Makefile"; then
        download_success=false
    fi

    # Check if downloads succeeded
    if [ "$download_success" = false ]; then
        fallback_manual
        exit 1
    fi

    # Make scripts executable
    chmod +x collect-agentrc.sh secure-transfer.sh
    chmod +x tests/fake-agentrc.sh tests/smoke-test-confidence.sh

    # Add to .gitignore if not already there
    cd ..
    if [ -f ".gitignore" ]; then
        if ! grep -q "^tools/$" .gitignore; then
            echo "tools/" >> .gitignore
            log_info "✅ Added tools/ to .gitignore"
        fi
    else
        echo "tools/" > .gitignore
        log_info "✅ Created .gitignore with tools/"
    fi

    # Verify installation
    log_info "🧪 Verifying installation..."
    cd "$TOOLS_DIR"

    if command -v make >/dev/null 2>&1; then
        if make test >/dev/null 2>&1; then
            log_info "✅ Installation verified - tests pass!"
        else
            log_warn "⚠️ Installation completed but tests failed. Check Node.js and dependencies."
        fi
    else
        log_warn "⚠️ make not found. Install make to run tests: cd tools && make test"
    fi

    cd ..

    echo ""
    echo "🎉 Installation complete!"
    echo ""
    echo "📋 Quick Start:"
    echo "   cd tools && make test                    # Verify everything works"
    echo "   ./scripts/collect-agentrc.sh . ../collections/\$(basename \"\$PWD\")  # Collect evidence"
    echo "   ./scripts/secure-transfer.sh .           # Secure transfer for locked-down clients"
    echo ""
    echo "📚 For full documentation: https://github.com/$REPO#$BRANCH"
    echo ""
    log_info "🔒 Ready for secure client deployment!"
}

# Run main function
main "$@"
