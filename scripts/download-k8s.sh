#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v1.31.4}"
TARGET_DIR="${2:-./build/kubernetes}"

echo "Downloading Kubernetes ${VERSION}..."

# Create target directory
mkdir -p "${TARGET_DIR}"

# Check if already downloaded
if [ -d "${TARGET_DIR}/.git" ]; then
    echo "Kubernetes sources already exist, checking version..."
    cd "${TARGET_DIR}"
    CURRENT_VERSION=$(git describe --tags --exact-match 2>/dev/null || echo "unknown")
    if [ "${CURRENT_VERSION}" = "${VERSION}" ]; then
        echo "Kubernetes ${VERSION} already downloaded."
        exit 0
    fi
    echo "Different version found, re-downloading..."
    cd -
    rm -rf "${TARGET_DIR}"
    mkdir -p "${TARGET_DIR}"
fi

# Clone Kubernetes at specific version
echo "Cloning Kubernetes repository..."
git clone --depth 1 --branch "${VERSION}" https://github.com/kubernetes/kubernetes.git "${TARGET_DIR}"

echo "Kubernetes ${VERSION} downloaded successfully to ${TARGET_DIR}"

# Display commit info
cd "${TARGET_DIR}"
echo "Commit: $(git rev-parse HEAD)"
echo "Date: $(git log -1 --format=%ci)"
