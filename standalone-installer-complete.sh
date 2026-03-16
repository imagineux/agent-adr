#!/usr/bin/env bash
# Standalone agent-adr installer - completely self-contained
# Generated: $(date)
# Usage: curl -sSL https://raw.githubusercontent.com/imagineux/agent-adr/main/standalone-installer-complete.sh | bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TOOLS_DIR="tools"

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Embedded files (base64 encoded)
collect_agentrc="$(base64 -w 0 < "$SCRIPT_DIR/scripts/collect-agentrc.sh")"
build_prompt="$(base64 -w 0 < "$SCRIPT_DIR/scripts/build-strong-model-prompt.mjs")"
secure_transfer="$(base64 -w 0 < "$SCRIPT_DIR/scripts/secure-transfer.sh")"
ai_adr_template="$(base64 -w 0 < "$SCRIPT_DIR/templates/ai-enablement-adr-template.md")"
synthesis_template="$(base64 -w 0 < "$SCRIPT_DIR/templates/strong-model-synthesis-template.md")"
review_template="$(base64 -w 0 < "$SCRIPT_DIR/templates/strong-model-review-template.md")"
compose_skill="$(base64 -w 0 < "$SCRIPT_DIR/skills/compose-ai-enablement-adr.md")"
fake_agentrc="$(base64 -w 0 < "$SCRIPT_DIR/tests/fake-agentrc.sh")"
test_utils="$(base64 -w 0 < "$SCRIPT_DIR/tests/test-utils.sh")"
smoke_test="$(base64 -w 0 < "$SCRIPT_DIR/tests/smoke-test-confidence.sh")"
makefile="$(base64 -w 0 < "$SCRIPT_DIR/Makefile")"

# Add each file as base64 (using simple variables instead of associative arrays)
cat >> "$OUTPUT_FILE" <<'FOOTER'
)

# Function to decode and write file
decode_and_write() {
    local filename="$1"
    local var_name="$2"
    local b64_data
    
    case "$var_name" in
        "collect_agentrc") b64_data="$collect_agentrc" ;;
        "build_prompt") b64_data="$build_prompt" ;;
        "secure_transfer") b64_data="$secure_transfer" ;;
        "ai_adr_template") b64_data="$ai_adr_template" ;;
        "synthesis_template") b64_data="$synthesis_template" ;;
        "review_template") b64_data="$review_template" ;;
        "compose_skill") b64_data="$compose_skill" ;;
        "fake_agentrc") b64_data="$fake_agentrc" ;;
        "test_utils") b64_data="$test_utils" ;;
        "smoke_test") b64_data="$smoke_test" ;;
        "makefile") b64_data="$makefile" ;;
        *) log_error "Unknown file: $var_name"; return 1 ;;
    esac
    
    if [ -z "$b64_data" ]; then
        log_error "Embedded file not found: $var_name"
        return 1
    fi
    
    echo "📝 Creating $filename..."
    echo "$b64_data" | base64 -d > "$filename"
}

# Main installation
main() {
    echo "🚀 Installing agent-adr tools (standalone, self-contained)..."
    
    # Check if we're in a git repo
    if [ ! -d ".git" ]; then
        log_warn "Warning: Not in a git repository. Continuing anyway..."
    fi

    # Create tools directory
    mkdir -p "$TOOLS_DIR"
    cd "$TOOLS_DIR"

    # Create subdirectories
    mkdir -p templates tests skills

    # Decode and write all files
    decode_and_write "collect-agentrc.sh" "collect_agentrc"
    decode_and_write "build-strong-model-prompt.mjs" "build_prompt"
    decode_and_write "secure-transfer.sh" "secure_transfer"
    
    decode_and_write "templates/ai-enablement-adr-template.md" "ai_adr_template"
    decode_and_write "templates/strong-model-synthesis-template.md" "synthesis_template"
    decode_and_write "templates/strong-model-review-template.md" "review_template"
    
    decode_and_write "skills/compose-ai-enablement-adr.md" "compose_skill"
    
    decode_and_write "tests/fake-agentrc.sh" "fake_agentrc"
    decode_and_write "tests/test-utils.sh" "test_utils"
    decode_and_write "tests/smoke-test-confidence.sh" "smoke_test"
    
    decode_and_write "Makefile" "makefile"

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
    echo "📚 For full documentation: https://github.com/imagineux/agent-adr#main"
    echo ""
    log_info "🔒 Ready for secure client deployment!"
    log_info "📦 This installer was completely self-contained - no network calls needed!"
}

# Run main function
main "$@"
FOOTER

# Make it executable
chmod +x "$OUTPUT_FILE"

# Show file size
echo "✅ Standalone installer created: $OUTPUT_FILE"
echo "📏 Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo "📦 Contains all files - no network calls needed during installation!"

# Test it (optional)
echo ""
echo "🧪 Quick test (optional)..."
echo "Run: $OUTPUT_FILE"
echo "Or: curl -sSL https://raw.githubusercontent.com/imagineux/agent-adr/main/standalone-installer-complete.sh | bash"
