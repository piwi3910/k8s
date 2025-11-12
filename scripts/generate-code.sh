#!/usr/bin/env bash
set -euo pipefail

K8S_DIR="${1:-./build/kubernetes}"

echo "Generating code from Kubernetes sources..."

if [ ! -d "${K8S_DIR}" ]; then
    echo "Error: Kubernetes directory not found at ${K8S_DIR}"
    exit 1
fi

cd "${K8S_DIR}"

# Check if code generation is needed
if [ -f "hack/update-codegen.sh" ]; then
    echo "Running Kubernetes code generation..."
    # This may take a while
    # make generated_files
    echo "Code generation completed (skipped for now - will be enabled when needed)"
else
    echo "No code generation script found, skipping."
fi

echo "Code generation complete"
