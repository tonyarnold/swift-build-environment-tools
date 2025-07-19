#!/bin/bash

# Swift Build Environment Tools SPM Artifact Bundle Generator
# Creates Swift Package Manager compatible artifact bundles with multi-platform binaries
# Usage: ./spm-artifact-bundle.sh <version>

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly BUNDLE_PREFIX="swift-build-environment-tools"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

log_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

# Utility functions
calculate_checksum() {
    local file="$1"
    
    if command -v shasum >/dev/null 2>&1; then
        # macOS/BSD systems
        shasum -a 256 "$file" | cut -d' ' -f1
    elif command -v sha256sum >/dev/null 2>&1; then
        # Linux/GNU systems
        sha256sum "$file" | cut -d' ' -f1
    else
        log_error "No checksum tool available (shasum or sha256sum)"
        return 1
    fi
}

# Validation functions
validate_version() {
    local version="$1"

    # Remove 'v' prefix if present for internal processing
    version="${version#v}"

    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-.*)?$ ]]; then
        log_error "Invalid version format: $version"
        log_error "Expected format: 1.0.0 or 1.0.0-beta.1"
        return 1
    fi

    return 0
}

validate_binary() {
    local binary_path="$1"
    local platform="$2"
    local tool_name="$3"

    if [[ ! -f "$binary_path" ]]; then
        log_error "$platform $tool_name binary not found: $binary_path"
        return 1
    fi

    if [[ ! -x "$binary_path" ]]; then
        log_error "$platform $tool_name binary is not executable: $binary_path"
        return 1
    fi

    # Get binary size for reporting
    local size
    if size=$(du -h "$binary_path" 2>/dev/null | cut -f1); then
        log_info "$platform $tool_name binary found: $binary_path ($size)"
    else
        log_info "$platform $tool_name binary found: $binary_path"
    fi

    return 0
}

# Function to create platform-specific directory and copy binary
create_platform_binary() {
    local platform="$1"
    local binary_path="$2"
    local tool_name="$3"
    local bundle_name="$4"
    local version="$5"

    local platform_dir="$bundle_name/${tool_name}-$platform"

    log_info "Creating $platform $tool_name binary entry..."

    # Validate binary exists and is executable
    if ! validate_binary "$binary_path" "$platform" "$tool_name"; then
        log_error "Validation failed for $platform $tool_name binary: $binary_path"
        return 1
    fi

    # Create directory structure
    if ! mkdir -p "$platform_dir"; then
        log_error "Failed to create directory: $platform_dir"
        return 1
    fi

    # Copy binary
    if ! cp "$binary_path" "$platform_dir/$tool_name"; then
        log_error "Failed to copy binary from $binary_path to $platform_dir/$tool_name"
        return 1
    fi

    if ! chmod +x "$platform_dir/$tool_name"; then
        log_error "Failed to make binary executable: $platform_dir/$tool_name"
        return 1
    fi

    # Verify the copy
    if [[ ! -f "$platform_dir/$tool_name" ]]; then
        log_error "Failed to copy $platform $tool_name binary to $platform_dir/$tool_name"
        return 1
    fi

    local copied_size=$(du -h "$platform_dir/$tool_name" | cut -f1)
    log_success "$platform $tool_name binary created: $platform_dir/$tool_name ($copied_size)"

    return 0
}

# Function to create an artifact bundle for a specific tool
create_bundle() {
    local tool_name="$1"
    local version="$2"
    local bundle_name="${tool_name}.artifactbundle"
    
    log_info "Creating artifact bundle for $tool_name version $version"
    
    # Clean up any existing bundle
    if [[ -d "$bundle_name" ]]; then
        log_info "Removing existing bundle directory..."
        rm -rf "$bundle_name"
    fi

    if [[ -f "$bundle_name.zip" ]]; then
        log_info "Removing existing bundle archive..."
        rm -f "$bundle_name.zip"
    fi
    
    # Create bundle directory structure
    mkdir -p "$bundle_name"
    
    # Track successful binary creations
    local binaries_created=0

    # Create macOS universal binary
    local macos_path=".build/apple/Products/Release/$tool_name"
    if [[ -f "$macos_path" ]]; then
        if create_platform_binary "macos" "$macos_path" "$tool_name" "$bundle_name" "$version"; then
            binaries_created=$((binaries_created + 1))
        else
            log_warning "Failed to create macOS $tool_name binary bundle"
        fi
    else
        log_warning "macOS $tool_name binary not found: $macos_path"
    fi

    # Create Linux x86_64 binary
    local linux_x86_path=".build/x86_64-unknown-linux-gnu/release/$tool_name"
    if [[ -f "$linux_x86_path" ]]; then
        if create_platform_binary "x86_64-unknown-linux-gnu" "$linux_x86_path" "$tool_name" "$bundle_name" "$version"; then
            binaries_created=$((binaries_created + 1))
        else
            log_warning "Failed to create Linux x86_64 $tool_name binary bundle"
        fi
    else
        log_warning "Linux x86_64 $tool_name binary not found: $linux_x86_path"
    fi

    # Create Linux ARM64 binary
    local linux_arm_path=".build/aarch64-unknown-linux-gnu/release/$tool_name"
    if [[ -f "$linux_arm_path" ]]; then
        if create_platform_binary "aarch64-unknown-linux-gnu" "$linux_arm_path" "$tool_name" "$bundle_name" "$version"; then
            binaries_created=$((binaries_created + 1))
        else
            log_warning "Failed to create Linux aarch64 $tool_name binary bundle"
        fi
    else
        log_warning "Linux ARM64 $tool_name binary not found: $linux_arm_path"
    fi

    # Verify we have at least one binary
    if [[ $binaries_created -eq 0 ]]; then
        log_error "No binaries were successfully created for $tool_name"
        return 1
    fi

    log_info "Successfully created $binaries_created platform binary/binaries for $tool_name"
    
    # Create info.json with artifact bundle metadata
    cat > "$bundle_name/info.json" << EOF
{
  "schemaVersion": "1.0",
  "artifacts": {
    "${tool_name}Binary": {
      "type": "executable",
      "version": "$version",
      "variants": [
        {
          "path": "${tool_name}-macos/${tool_name}",
          "supportedTriples": ["arm64-apple-macosx", "x86_64-apple-macosx"]
        },
        {
          "path": "${tool_name}-x86_64-unknown-linux-gnu/${tool_name}",
          "supportedTriples": ["x86_64-unknown-linux-gnu"]
        },
        {
          "path": "${tool_name}-aarch64-unknown-linux-gnu/${tool_name}",
          "supportedTriples": ["aarch64-unknown-linux-gnu"]
        }
      ]
    }
  }
}
EOF

    if [[ ! -f "$bundle_name/info.json" ]]; then
        log_error "Failed to generate info.json for $tool_name"
        return 1
    fi

    log_success "Generated info.json for $tool_name version $version"

    # Copy license if available
    if [[ -f "LICENSE" ]]; then
        cp LICENSE "$bundle_name/"
        log_success "Added LICENSE to $tool_name bundle"
    else
        log_warning "LICENSE file not found, skipping for $tool_name"
    fi

    # Create ZIP archive
    local zip_name="$bundle_name.zip"
    log_info "Creating ZIP archive: $zip_name"

    if command -v 7z >/dev/null 2>&1; then
        # Use 7z if available (better compression)
        log_info "Using 7zip for compression..."
        7z a -tzip -mx=9 "$zip_name" "$bundle_name/" >/dev/null
    else
        # Fallback to system zip
        log_info "Using system zip for compression..."
        zip -r -9 "$zip_name" "$bundle_name/" >/dev/null
    fi

    # Verify ZIP was created
    if [[ ! -f "$zip_name" ]]; then
        log_error "Failed to create ZIP archive for $tool_name"
        return 1
    fi

    # Calculate checksum
    local checksum=$(calculate_checksum "$zip_name")
    local zip_size=$(du -h "$zip_name" | cut -f1)

    # Save checksum to file for CI
    echo "$checksum" > "$zip_name.checksum"

    # Display results
    log_success "🎉 Artifact bundle created successfully for $tool_name!"
    log_info "📦 Bundle: $zip_name ($zip_size)"
    log_info "🔐 SHA256: $checksum"
    log_info "📋 Checksum file: $zip_name.checksum"

    # Clean up bundle directory
    rm -rf "$bundle_name"
    log_info "Cleaned up temporary bundle directory for $tool_name"

    return 0
}

# Main script
main() {
    # Parse arguments
    local version
    if [[ $# -eq 1 ]]; then
        version="$1"
    else
        # Try to get version from git if no argument provided
        if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
            version="$(git describe --tags --always)"
            log_info "Using git version: $version"
        else
            log_error "Usage: $SCRIPT_NAME <version>"
            log_error "Example: $SCRIPT_NAME 1.0.0"
            exit 1
        fi
    fi

    # Clean VERSION to remove any 'v' prefix for internal processing
    local clean_version="${version#v}"

    # Validate version format
    if ! validate_version "$clean_version"; then
        exit 1
    fi

    log_info "Creating artifact bundles for $BUNDLE_PREFIX version $clean_version"

    # Create artifact bundles for each tool
    local tools_created=0
    
    if create_bundle "BuildEnvironmentExtractor" "$clean_version"; then
        tools_created=$((tools_created + 1))
    fi
    
    if create_bundle "GitInfoExtractor" "$clean_version"; then
        tools_created=$((tools_created + 1))
    fi

    if [[ $tools_created -eq 0 ]]; then
        log_error "Failed to create any artifact bundles"
        exit 1
    fi

    # Combine checksums into a single file
    if ls *.artifactbundle.zip.checksum >/dev/null 2>&1; then
        cat *.artifactbundle.zip.checksum > checksums.txt
        log_success "Combined checksums written to checksums.txt"
    fi

    echo ""
    log_success "🎉 All artifact bundle generation completed!"
    log_info "Created $tools_created artifact bundles:"
    log_info "- BuildEnvironmentExtractor.artifactbundle.zip"
    log_info "- GitInfoExtractor.artifactbundle.zip"
    echo ""
}

# Run main function with all arguments
main "$@"