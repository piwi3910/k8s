#!/usr/bin/env bash
set -euo pipefail

echo "Running validation checks..."

# Check Go version
echo "Checking Go version..."
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
echo "  Go version: ${GO_VERSION}"

# Check if git repo is clean
if [ -d .git ]; then
    echo "Checking git status..."
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "  Warning: Git working tree is dirty"
    else
        echo "  Git working tree is clean"
    fi
fi

# Check required directories
echo "Checking required directories..."
for dir in cmd pkg scripts patches manifests; do
    if [ -d "${dir}" ]; then
        echo "  ✓ ${dir}"
    else
        echo "  ✗ ${dir} (missing)"
    fi
done

# Check Go mod
echo "Checking Go modules..."
if go mod verify; then
    echo "  ✓ Go modules verified"
else
    echo "  ✗ Go modules verification failed"
    exit 1
fi

echo "Validation complete"
