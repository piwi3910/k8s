#!/usr/bin/env bash
set -euo pipefail

K8S_DIR="${1:-./build/kubernetes}"
PATCHES_DIR="${2:-./patches}"

echo "Applying patches to Kubernetes..."

if [ ! -d "${K8S_DIR}" ]; then
    echo "Error: Kubernetes directory not found at ${K8S_DIR}"
    exit 1
fi

if [ ! -d "${PATCHES_DIR}" ]; then
    echo "No patches directory found at ${PATCHES_DIR}, skipping patches."
    exit 0
fi

# Check if patches exist
PATCH_COUNT=$(find "${PATCHES_DIR}" -name "*.patch" 2>/dev/null | wc -l)
if [ "${PATCH_COUNT}" -eq 0 ]; then
    echo "No patches found in ${PATCHES_DIR}, skipping."
    exit 0
fi

# Apply patches in order
cd "${K8S_DIR}"

echo "Found ${PATCH_COUNT} patch(es) to apply..."

for patch in $(find "${PATCHES_DIR}" -name "*.patch" | sort); do
    echo "Applying patch: $(basename ${patch})"

    # Check if patch has already been applied
    if git apply --check --reverse "${patch}" 2>/dev/null; then
        echo "  Patch already applied, skipping..."
        continue
    fi

    # Apply the patch
    if git apply --whitespace=fix "${patch}"; then
        echo "  Patch applied successfully"
    else
        echo "  Error: Failed to apply patch ${patch}"
        exit 1
    fi
done

echo "All patches applied successfully"
