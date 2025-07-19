#!/bin/bash

# Update Package.swift with binary target URLs for release using production template
# Usage: update-artifact-bundle.sh <version>

set -euo pipefail

VERSION="$1"
CLEAN_VERSION="$VERSION"
PACKAGE_FILE="Package.swift"
TEMPLATE_FILE="Templates/Package-production.swift"
REPO_URL="https://github.com/tonyarnold/swift-build-environment-tools"

echo "Updating Package.swift with binary targets for version $VERSION"

# Check if template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: Template file $TEMPLATE_FILE not found"
    exit 1
fi

# Backup original Package.swift
cp "$PACKAGE_FILE" "${PACKAGE_FILE}.backup"

# Calculate checksums of the artifact bundles
if [[ ! -f "BuildEnvironmentExtractor.artifactbundle.zip" ]]; then
    echo "Error: BuildEnvironmentExtractor artifact bundle not found. Make sure spm-artifact-bundle.sh has been run first."
    exit 1
fi

if [[ ! -f "GitInfoExtractor.artifactbundle.zip" ]]; then
    echo "Error: GitInfoExtractor artifact bundle not found. Make sure smp-artifact-bundle.sh has been run first."
    exit 1
fi

# Calculate checksums using portable approach
if command -v shasum >/dev/null 2>&1; then
    # macOS/BSD systems
    BUILD_ENV_CHECKSUM=$(shasum -a 256 BuildEnvironmentExtractor.artifactbundle.zip | cut -d' ' -f1)
    GIT_INFO_CHECKSUM=$(shasum -a 256 GitInfoExtractor.artifactbundle.zip | cut -d' ' -f1)
elif command -v sha256sum >/dev/null 2>&1; then
    # Linux/GNU systems
    BUILD_ENV_CHECKSUM=$(sha256sum BuildEnvironmentExtractor.artifactbundle.zip | cut -d' ' -f1)
    GIT_INFO_CHECKSUM=$(sha256sum GitInfoExtractor.artifactbundle.zip | cut -d' ' -f1)
else
    echo "Error: No checksum tool available (shasum or sha256sum)"
    exit 1
fi

BUILD_ENV_URL="${REPO_URL}/releases/download/${VERSION}/BuildEnvironmentExtractor.artifactbundle.zip"
GIT_INFO_URL="${REPO_URL}/releases/download/${VERSION}/GitInfoExtractor.artifactbundle.zip"

echo "BuildEnvironmentExtractor URL: $BUILD_ENV_URL"
echo "BuildEnvironmentExtractor Checksum: $BUILD_ENV_CHECKSUM"
echo "GitInfoExtractor URL: $GIT_INFO_URL"
echo "GitInfoExtractor Checksum: $GIT_INFO_CHECKSUM"

# Create new Package.swift from template, replacing placeholders
sed -e "s|VERSION_PLACEHOLDER|${VERSION}|g" \
    -e "s|BUILD_ENV_CHECKSUM_PLACEHOLDER|${BUILD_ENV_CHECKSUM}|g" \
    -e "s|GIT_INFO_CHECKSUM_PLACEHOLDER|${GIT_INFO_CHECKSUM}|g" \
    "$TEMPLATE_FILE" > "$PACKAGE_FILE"

echo "Package.swift updated from template with binary targets"
echo "Original Package.swift backed up as ${PACKAGE_FILE}.backup"

# Validate the generated Package.swift
if ! grep -q "checksum: \"$BUILD_ENV_CHECKSUM\"" "$PACKAGE_FILE"; then
    echo "Warning: BuildEnvironmentExtractor checksum not found in generated Package.swift"
fi

if ! grep -q "checksum: \"$GIT_INFO_CHECKSUM\"" "$PACKAGE_FILE"; then
    echo "Warning: GitInfoExtractor checksum not found in generated Package.swift"
fi

if ! grep -q "download/${VERSION}/" "$PACKAGE_FILE"; then
    echo "Warning: Version not found in generated Package.swift"
fi

echo "Package.swift validation completed"