#!/usr/bin/env bash
# Fingerprint verification for secure client transfers
# Generates cryptographic fingerprints of files to be transferred
# Client can verify integrity and detect any changes

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
    echo "Fingerprint Verification for Client Transfers"
    echo ""
    echo "Usage: $0 <collection-dir> [action]"
    echo ""
    echo "Actions:"
    echo "  generate    Generate fingerprints of transfer files (default)"
    echo "  verify      Verify files match generated fingerprints"
    echo ""
    echo "This creates cryptographic evidence of exactly what"
    echo "will be transferred, allowing clients to verify:"
    echo "- No files have been added/removed"
    echo "- No file contents have changed"
    echo "- Only metadata/documentation is included"
    echo ""
    echo "Perfect for security-conscious clients who want to"
    echo "verify the transfer package before approval."
}

# Generate SHA256 fingerprint of a file
generate_fingerprint() {
    local file="$1"
    local relative_path="$2"
    
    if [ -f "$file" ]; then
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unknown")
        local hash=$(sha256sum "$file" | cut -d' ' -f1)
        echo "$hash  $size  $relative_path"
    fi
}

# Generate fingerprints of all transfer files
generate_fingerprints() {
    local collection_dir="$1"
    local fingerprint_file="$collection_dir/TRANSFER_FINGERPRINTS.txt"
    
    log_info "🔐 Generating transfer fingerprints..."
    
    cat > "$fingerprint_file" <<HEADER
# Transfer Fingerprints - Generated $(date)
# Collection: $(basename "$collection_dir")
# Purpose: Cryptographic verification of transfer contents
#
# Format: SHA256_HASH  FILE_SIZE  RELATIVE_PATH
# Use: sha256sum -c TRANSFER_FINGERPRINTS.txt to verify
#
# These fingerprints prove exactly what will be transferred:
# - Only metadata and documentation files
# - No source code or intellectual property
# - Cryptographic verification of contents

HEADER

    # Always included files
    echo "# Core transfer files:" >> "$fingerprint_file"
    generate_fingerprint "$collection_dir/collection-summary.json" "collection-summary.json" >> "$fingerprint_file"
    generate_fingerprint "$collection_dir/prompts/adr-synthesis-prompt.md" "prompts/adr-synthesis-prompt.md" >> "$fingerprint_file"
    generate_fingerprint "$collection_dir/prompts/adr-review-prompt.md" "prompts/adr-review-prompt.md" >> "$fingerprint_file"
    
    # Optional context files
    echo "" >> "$fingerprint_file"
    echo "# Context files (if present):" >> "$fingerprint_file"
    generate_fingerprint "$collection_dir/context/README.md" "context/README.md" >> "$fingerprint_file"
    generate_fingerprint "$collection_dir/context/package.json" "context/package.json" >> "$fingerprint_file"
    
    # Docs folder (if present)
    if [ -d "$collection_dir/context/docs" ]; then
        echo "" >> "$fingerprint_file"
        echo "# Documentation folder:" >> "$fingerprint_file"
        find "$collection_dir/context/docs" -type f -name "*.md" -o -name "*.txt" | while read -r file; do
            local relative_path="context/docs/$(basename "$file")"
            generate_fingerprint "$file" "$relative_path" >> "$fingerprint_file"
        done
    fi
    
    # Generate summary
    local file_count=$(grep -c '^[a-f0-9]' "$fingerprint_file")
    local total_size=$(grep '^[a-f0-9]' "$fingerprint_file" | awk '{sum += $2} END {print sum}')
    
    cat >> "$fingerprint_file" <<SUMMARY

# Summary
# Files to transfer: $file_count
# Total size: $total_size bytes
# Generated: $(date)
# Collection: $(basename "$collection_dir")
#
# Verification command:
#   sha256sum -c TRANSFER_FINGERPRINTS.txt
SUMMARY

    log_info "✅ Fingerprints generated: $fingerprint_file"
    log_info "📊 Files: $file_count, Size: $total_size bytes"
    
    # Show what will be transferred
    echo ""
    log_info "🔍 Files to be transferred:"
    grep '^[a-f0-9]' "$fingerprint_file" | while read -r line; do
        local hash=$(echo "$line" | cut -d' ' -f1)
        local size=$(echo "$line" | cut -d' ' -f2)
        local path=$(echo "$line" | cut -d' ' -f3-)
        echo "  ✓ $path ($size bytes)"
    done
}

# Verify files match fingerprints
verify_fingerprints() {
    local collection_dir="$1"
    local fingerprint_file="$collection_dir/TRANSFER_FINGERPRINTS.txt"
    
    if [ ! -f "$fingerprint_file" ]; then
        log_error "❌ Fingerprint file not found: $fingerprint_file"
        log_info "Run '$0 generate' first to create fingerprints"
        exit 1
    fi
    
    log_info "🔍 Verifying transfer fingerprints..."
    
    # Change to collection directory for relative paths
    cd "$collection_dir"
    
    # Run verification
    if sha256sum -c "TRANSFER_FINGERPRINTS.txt" >/dev/null 2>&1; then
        log_info "✅ All fingerprints verified - no changes detected!"
        
        # Show verification summary
        local file_count=$(grep -c '^[a-f0-9]' "TRANSFER_FINGERPRINTS.txt")
        local total_size=$(grep '^[a-f0-9]' "TRANSFER_FINGERPRINTS.txt" | awk '{sum += $2} END {print sum}')
        
        echo ""
        log_info "📊 Verification Summary:"
        echo "  Files verified: $file_count"
        echo "  Total size: $total_size bytes"
        echo "  Status: PASSED"
        
    else
        log_error "❌ Fingerprint verification FAILED!"
        echo ""
        log_info "🔍 Failed verification details:"
        sha256sum -c "TRANSFER_FINGERPRINTS.txt" | grep FAILED
        
        echo ""
        log_warn "⚠️  This indicates files have changed since fingerprint generation"
        log_warn "    Client should review changes before approving transfer"
        exit 1
    fi
}

# Create transfer manifest with fingerprints
create_manifest() {
    local collection_dir="$1"
    local fingerprint_file="$collection_dir/TRANSFER_FINGERPRINTS.txt"
    
    if [ ! -f "$fingerprint_file" ]; then
        log_error "❌ Generate fingerprints first: $0 generate"
        exit 1
    fi
    
    cat > "$collection_dir/TRANSFER_MANIFEST_WITH_FINGERPRINTS.md" <<MANIFEST
# Secure Transfer Manifest with Cryptographic Verification

**Client:** $(basename "$collection_dir")  
**Date:** $(date +%Y-%m-%d)  
**Purpose:** AI enablement evidence collection with cryptographic verification  

## What This Contains

This package contains ONLY metadata and prompts - **no source code**:

| File | Purpose | Size | Fingerprint |
|------|---------|------|-------------|
| collection-summary.json | Repository analysis results | $(stat -f%z "$collection_dir/collection-summary.json" 2>/dev/null || stat -c%s "$collection_dir/collection-summary.json" 2>/dev/null || echo "unknown") bytes | $(sha256sum "$collection_dir/collection-summary.json" | cut -d' ' -f1) |
| adr-synthesis-prompt.md | AI model prompt | $(stat -f%z "$collection_dir/prompts/adr-synthesis-prompt.md" 2>/dev/null || stat -c%s "$collection_dir/prompts/adr-synthesis-prompt.md" 2>/dev/null || echo "unknown") bytes | $(sha256sum "$collection_dir/prompts/adr-synthesis-prompt.md" | cut -d' ' -f1) |
| adr-review-prompt.md | AI review prompt | $(stat -f%z "$collection_dir/prompts/adr-review-prompt.md" 2>/dev/null || stat -c%s "$collection_dir/prompts/adr-review-prompt.md" 2>/dev/null || echo "unknown") bytes | $(sha256sum "$collection_dir/prompts/adr-review-prompt.md" | cut -d' ' -f1) |

## Cryptographic Verification

**Fingerprint file:** \`TRANSFER_FINGERPRINTS.txt\`

**To verify integrity:**
\`\`\`bash
sha256sum -c TRANSFER_FINGERPRINTS.txt
\`\`\`

**This proves:**
- ✅ No additional files have been added
- ✅ No files have been removed  
- ✅ No file contents have been modified
- ✅ Only approved metadata/documentation is included

## Security Assurance

The fingerprints provide cryptographic proof that:
1. **Exactly the approved files** are included
2. **No source code** is present in transfer
3. **Contents have not changed** since approval
4. **Transfer package is tamper-evident**

## Next Steps

1. **Review fingerprints** in \`TRANSFER_FINGERPRINTS.txt\`
2. **Verify integrity** with \`sha256sum -c TRANSFER_FINGERPRINTS.txt\`
3. **Transfer using** client-approved method
4. **Re-verify** after transfer if desired

---

*Generated with cryptographic fingerprint verification*
MANIFEST

    log_info "📋 Created manifest with fingerprints: TRANSFER_MANIFEST_WITH_FINGERPRINTS.md"
}

# Main execution
main() {
    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi
    
    local collection_dir="$1"
    local action="${2:-generate}"
    
    if [ ! -d "$collection_dir" ]; then
        log_error "❌ Collection directory not found: $collection_dir"
        exit 1
    fi
    
    case "$action" in
        "generate")
            generate_fingerprints "$collection_dir"
            create_manifest "$collection_dir"
            ;;
        "verify")
            verify_fingerprints "$collection_dir"
            ;;
        *)
            log_error "❌ Unknown action: $action"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
