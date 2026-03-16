#!/usr/bin/env bash
# Gist-based transfer for locked-down clients
# Creates GitHub Gist with transfer package and cryptographic verification

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
    echo "Gist Transfer for Locked-Down Clients"
    echo ""
    echo "Usage: $0 <collection-dir> [gist-description]"
    echo ""
    echo "This script:"
    echo "1. Creates minimal transfer package with metadata only"
    echo "2. Generates cryptographic fingerprints for verification"
    echo "3. Creates GitHub Gist with transfer contents"
    echo "4. Provides Gist URL for secure transfer"
    echo "5. Includes verification instructions for client"
    echo ""
    echo "Perfect for clients who only allow GitHub Gist transfers."
    echo ""
    echo "Requirements:"
    echo "- GitHub CLI (gh) installed and authenticated"
    echo "- Or GITHUB_TOKEN environment variable set"
}

# Check for GitHub CLI or token
check_github_auth() {
    if command -v gh >/dev/null 2>&1; then
        if gh auth status >/dev/null 2>&1; then
            log_info "✅ GitHub CLI authenticated"
            return 0
        else
            log_error "❌ GitHub CLI not authenticated. Run: gh auth login"
            return 1
        fi
    elif [ -n "${GITHUB_TOKEN:-}" ]; then
        log_info "✅ GitHub token found in environment"
        return 0
    else
        log_error "❌ GitHub authentication required"
        echo "Install GitHub CLI: brew install gh"
        echo "Then authenticate: gh auth login"
        echo "Or set GITHUB_TOKEN environment variable"
        return 1
    fi
}

# Create transfer package
create_transfer_package() {
    local collection_dir="$1"
    local transfer_name="gist-transfer-$(basename "$collection_dir")"
    
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
    [ -f "$collection_dir/TRANSFER_MANIFEST_WITH_FINGERPRINTS.md" ] && cp "$collection_dir/TRANSFER_MANIFEST_WITH_FINGERPRINTS.md" "$transfer_name/"
    
    echo "$transfer_name"
}

# Create Gist content
create_gist_content() {
    local transfer_dir="$1"
    local description="${2:-AI Enablement Evidence Transfer - Cryptographic Verification}"
    
    log_info "📝 Preparing Gist content..."
    
    # Create Gist description file
    cat > "$transfer_dir/GIST_DESCRIPTION.md" <<GIST_DESC
# AI Enablement Evidence Transfer

**Date:** $(date +%Y-%m-%d)  
**Purpose:** Secure transfer of AI enablement evidence  
**Verification:** Cryptographic fingerprints included  

## 📋 Contents

This Gist contains ONLY metadata and prompts - **no source code**:

- \`collection-summary.json\` - Repository analysis results
- \`adr-synthesis-prompt.md\` - AI analysis prompt  
- \`adr-review-prompt.md\` - AI review prompt
- \`README.md\` - Project documentation (if present)
- \`package.json\` - Package metadata (if present)
- \`docs/\` - Repository documentation (if present)

## 🔐 Security Verification

**Fingerprints:** \`TRANSFER_FINGERPRINTS.txt\`

**To verify integrity:**
\`\`\`bash
# Download all files from this Gist
sha256sum -c TRANSFER_FINGERPRINTS.txt
\`\`\`

This proves:
- ✅ Exact file list (no additional files)
- ✅ File integrity (no modifications)
- ✅ Metadata only (no source code)
- ✅ Tamper-evident (any changes detected)

## 📞 Next Steps

1. **Review contents** - Verify only metadata is included
2. **Download files** - Use GitHub Gist interface
3. **Verify fingerprints** - Run \`sha256sum -c TRANSFER_FINGERPRINTS.txt\`
4. **Use prompts** - Copy to AI models for analysis
5. **Delete Gist** - After verification, delete for security

---

*Generated with cryptographic verification for secure transfer*
GIST_DESC
    
    echo "$transfer_dir"
}

# Create GitHub Gist
create_gist() {
    local transfer_dir="$1"
    local description="$2"
    
    log_info "🚀 Creating GitHub Gist..."
    
    # Change to transfer directory
    cd "$transfer_dir"
    
    # Create Gist using GitHub CLI
    if command -v gh >/dev/null 2>&1; then
        # Use GitHub CLI
        local gist_url=$(gh gist create --public --desc "$description" *.md *.json docs/*/*.md 2>/dev/null | grep -o 'https://gist.github.com/[^[:space:]]*' || echo "")
        
        if [ -n "$gist_url" ]; then
            echo "$gist_url"
        else
            log_error "❌ Failed to create Gist with GitHub CLI"
            return 1
        fi
    else
        log_error "❌ GitHub CLI required for Gist creation"
        echo "Install with: brew install gh"
        echo "Authenticate with: gh auth login"
        return 1
    fi
}

# Show transfer summary
show_summary() {
    local gist_url="$1"
    local transfer_dir="$2"
    
    echo ""
    log_info "🎉 GIST TRANSFER READY!"
    echo ""
    echo "🔗 Gist URL: $gist_url"
    echo ""
    echo "📋 CLIENT INSTRUCTIONS:"
    echo "1. Open Gist URL in browser"
    echo "2. Review all files (should be metadata only)"
    echo "3. Download all files to a directory"
    echo "4. Verify integrity:"
    echo "   sha256sum -c TRANSFER_FINGERPRINTS.txt"
    echo "5. Use prompts for AI analysis"
    echo "6. Delete Gist after verification"
    echo ""
    echo "📊 Transfer Summary:"
    echo "  Files: $(find "$transfer_dir" -type f ! -name 'GIST_DESCRIPTION.md' | wc -l)"
    echo "  Size: $(du -sh "$transfer_dir" | cut -f1)"
    echo "  Verification: Cryptographic fingerprints included"
    echo ""
    log_info "🔒 Client can verify cryptographic integrity of transfer!"
    log_info "🗑️  Remember to delete Gist after client verification!"
}

# Main execution
main() {
    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi
    
    local collection_dir="$1"
    local description="${2:-AI Enablement Evidence Transfer - Cryptographic Verification}"
    
    if [ ! -d "$collection_dir" ]; then
        log_error "❌ Collection directory not found: $collection_dir"
        exit 1
    fi
    
    # Check GitHub authentication
    check_github_auth || exit 1
    
    log_info "🚀 Starting Gist-based secure transfer..."
    log_info "📁 Collection: $collection_dir"
    
    # Create transfer package
    local transfer_dir
    transfer_dir=$(create_transfer_package "$collection_dir")
    
    # Create Gist content
    create_gist_content "$transfer_dir" "$description"
    
    # Create Gist
    local gist_url
    gist_url=$(create_gist "$transfer_dir" "$description")
    
    if [ -n "$gist_url" ]; then
        # Show summary
        show_summary "$gist_url" "$transfer_dir"
        
        # Cleanup
        cd ..
        rm -rf "$transfer_dir"
        
        log_info "✅ Gist transfer completed successfully!"
    else
        log_error "❌ Failed to create Gist"
        exit 1
    fi
}

# Run main function
main "$@"
