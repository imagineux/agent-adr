#!/usr/bin/env bash
# Clipboard transfer for private Gist creation
# Collects evidence and copies everything to clipboard for easy Gist pasting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Usage info
usage() {
    echo "Clipboard Transfer for Private Gist Creation"
    echo ""
    echo "Usage: $0 <collection-dir>"
    echo ""
    echo "This script:"
    echo "1. Creates minimal transfer package (metadata only)"
    echo "2. Generates cryptographic fingerprints"
    echo "3. Formats everything for Gist pasting"
    echo "4. Copies formatted content to clipboard"
    echo "5. Provides instructions for private Gist creation"
    echo ""
    echo "Perfect for creating private Gists with evidence content."
}

# Check clipboard command
check_clipboard() {
    if command -v pbcopy >/dev/null 2>&1; then
        CLIPBOARD_CMD="pbcopy"
        log_info "✅ Using pbcopy (macOS)"
    elif command -v xclip >/dev/null 2>&1; then
        CLIPBOARD_CMD="xclip -selection clipboard"
        log_info "✅ Using xclip (Linux)"
    elif command -v clip.exe >/dev/null 2>&1; then
        CLIPBOARD_CMD="clip.exe"
        log_info "✅ Using clip.exe (Windows)"
    else
        log_error "❌ No clipboard command found"
        echo "Install clipboard tool:"
        echo "  macOS: pbcopy (built-in)"
        echo "  Linux: sudo apt install xclip"
        echo "  Windows: clip.exe (built-in)"
        exit 1
    fi
}

# Create transfer package
create_transfer_package() {
    local collection_dir="$1"
    local transfer_name="clipboard-transfer-$(basename "$collection_dir")"
    
    log_info "📦 Creating transfer package..."
    
    # Create transfer directory
    mkdir -p "$transfer_name"
    
    # Copy essential files
    cp "$collection_dir/collection-summary.json" "$transfer_name/"
    cp "$collection_dir/prompts/adr-synthesis-prompt.md" "$transfer_name/"
    cp "$collection_dir/prompts/adr-review-prompt.md" "$transfer_name/"
    
    # Copy context files if they exist
    [ -f "$collection_dir/context/README.md" ] && cp "$collection_dir/context/README.md" "$transfer_name/"
    [ -f "$collection_dir/context/package.json" ] && cp "$collection_dir/context/package.json" "$transfer_name/"
    
    # Copy docs folder if it exists
    if [ -d "$collection_dir/context/docs" ]; then
        cp -r "$collection_dir/context/docs" "$transfer_name/"
    fi
    
    # Generate fingerprints
    log_info "🔐 Generating cryptographic fingerprints..."
    "$SCRIPT_DIR/fingerprint-verify.sh" "$collection_dir" generate
    
    # Copy fingerprint files
    [ -f "$collection_dir/TRANSFER_FINGERPRINTS.txt" ] && cp "$collection_dir/TRANSFER_FINGERPRINTS.txt" "$transfer_name/"
    
    echo "$transfer_name"
}

# Format content for Gist
format_for_gist() {
    local transfer_dir="$1"
    local repo_name="$(basename "$transfer_dir" | sed 's/^clipboard-transfer-//')"
    
    log_info "📝 Formatting content for Gist..."
    
    # Create Gist content
    local gist_content="# AI Enablement Evidence - $repo_name

**Date:** $(date +%Y-%m-%d)  
**Purpose:** Repository evidence collection for AI enablement analysis  
**Verification:** Cryptographic fingerprints included  

---

## 📋 Contents

This Gist contains ONLY metadata and prompts - **no source code**:

"

    # Add each file content
    for file in "$transfer_dir"/*; do
        if [ -f "$file" ]; then
            local filename="$(basename "$file")"
            local extension="${filename##*.}"
            
            gist_content+="---

### 📄 $filename

"
            
            # Add file content with appropriate syntax highlighting
            case "$extension" in
                "md")
                    gist_content+="\`\`\`markdown
$(cat "$file")
\`\`\`
"
                    ;;
                "json")
                    gist_content+="\`\`\`json
$(cat "$file")
\`\`\`
"
                    ;;
                *)
                    gist_content+="\`\`\`
$(cat "$file")
\`\`\`
"
                    ;;
            esac
        fi
    done
    
    # Add docs folder if present
    if [ -d "$transfer_dir/docs" ]; then
        gist_content+="

---

### 📁 docs/ folder

"
        find "$transfer_dir/docs" -type f -name "*.md" | while read -r file; do
            local doc_name="$(basename "$file")"
            gist_content+="#### $doc_name

\`\`\`markdown
$(cat "$file")
\`\`\`

"
        done
    fi
    
    # Add fingerprint verification section
    if [ -f "$transfer_dir/TRANSFER_FINGERPRINTS.txt" ]; then
        gist_content+="

---

### 🔐 Cryptographic Verification

**Fingerprint file:** \`TRANSFER_FINGERPRINTS.txt\`

**To verify integrity:**
\`\`\`bash
# Copy this Gist content to local files
sha256sum -c TRANSFER_FINGERPRINTS.txt
\`\`\`

**Fingerprints:**
\`\`\`
$(cat "$transfer_dir/TRANSFER_FINGERPRINTS.txt")
\`\`\`

This proves:
- ✅ Exact file list (no additional files)
- ✅ File integrity (no modifications)
- ✅ Metadata only (no source code)
- ✅ Tamper-evident (any changes detected)
"
    fi
    
    # Add footer
    gist_content+="

---

## 📞 Usage

1. **Review contents** - Verify only metadata is included
2. **Copy to local files** - Save each section to appropriate files
3. **Verify integrity** - Run \`sha256sum -c TRANSFER_FINGERPRINTS.txt\`
4. **Use prompts** - Copy \`adr-synthesis-prompt.md\` to AI models
5. **Generate ADR** - Use AI analysis for recommendations

---

*Generated with cryptographic verification for secure transfer*"

    echo "$gist_content"
}

# Copy to clipboard
copy_to_clipboard() {
    local content="$1"
    
    log_info "📋 Copying formatted content to clipboard..."
    
    if echo "$content" | $CLIPBOARD_CMD; then
        log_info "✅ Content copied to clipboard successfully!"
    else
        log_error "❌ Failed to copy to clipboard"
        exit 1
    fi
}

# Show instructions
show_instructions() {
    local repo_name="$(basename "$1" | sed 's/^clipboard-transfer-//')"
    
    echo ""
    log_info "🎉 CLIPBOARD TRANSFER READY!"
    echo ""
    echo "📋 NEXT STEPS:"
    echo "1. Open GitHub Gist: https://gist.github.com/"
    echo "2. Click 'Create a new gist'"
    echo "3. Set visibility to 'Private'"
    echo "4. Paste clipboard content (Ctrl+V / Cmd+V)"
    echo "5. Title: \"AI Enablement Evidence - $repo_name\""
    echo "6. Create private Gist"
    echo "7. Copy Gist URL for analysis"
    echo ""
    echo "📊 Transfer Summary:"
    echo "  Repository: $repo_name"
    echo "  Files: $(find "$1" -type f ! -name 'TRANSFER_FINGERPRINTS.txt' | wc -l)"
    echo "  Size: $(du -sh "$1" | cut -f1)"
    echo "  Verification: Cryptographic fingerprints included"
    echo ""
    log_info "🔒 Content is ready for private Gist creation!"
    log_info "🗑️  Remember to delete Gist after analysis if needed"
}

# Main execution
main() {
    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi
    
    local collection_dir="$1"
    
    if [ ! -d "$collection_dir" ]; then
        log_error "❌ Collection directory not found: $collection_dir"
        exit 1
    fi
    
    # Check clipboard command
    check_clipboard || exit 1
    
    log_info "🚀 Starting clipboard transfer for private Gist..."
    log_info "📁 Collection: $collection_dir"
    
    # Create transfer package
    local transfer_dir
    transfer_dir=$(create_transfer_package "$collection_dir")
    
    # Format content for Gist
    local gist_content
    gist_content=$(format_for_gist "$transfer_dir")
    
    # Copy to clipboard
    copy_to_clipboard "$gist_content"
    
    # Show instructions
    show_instructions "$transfer_dir"
    
    # Cleanup
    rm -rf "$transfer_dir"
    
    log_info "✅ Clipboard transfer completed successfully!"
    log_info "📋 Content is ready for pasting into private Gist!"
}

# Run main function
main "$@"
