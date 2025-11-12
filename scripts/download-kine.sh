#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v0.13.6}"
TARGET_DIR="${2:-./build/kine}"

echo "Downloading Kine ${VERSION}..."

# Create target directory
mkdir -p "${TARGET_DIR}"

# Check if already downloaded
if [ -d "${TARGET_DIR}/.git" ]; then
    echo "Kine sources already exist, checking version..."
    cd "${TARGET_DIR}"
    CURRENT_VERSION=$(git describe --tags --exact-match 2>/dev/null || echo "unknown")
    if [ "${CURRENT_VERSION}" = "${VERSION}" ]; then
        echo "Kine ${VERSION} already downloaded."
        exit 0
    fi
    echo "Different version found, re-downloading..."
    cd -
    rm -rf "${TARGET_DIR}"
    mkdir -p "${TARGET_DIR}"
fi

# Clone Kine at specific version
echo "Cloning Kine repository..."
git clone --depth 1 --branch "${VERSION}" https://github.com/k3s-io/kine.git "${TARGET_DIR}"

echo "Kine ${VERSION} downloaded successfully to ${TARGET_DIR}"

# Display commit info
cd "${TARGET_DIR}"
echo "Commit: $(git rev-parse HEAD)"
echo "Date: $(git log -1 --format=%ci)"
