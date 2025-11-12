# Kubernetes Patches

This directory contains patches that are applied to the Kubernetes source code during the build process.

## Patch Naming Convention

Patches should be named with a numeric prefix to ensure they are applied in the correct order:

```
001-description.patch
002-another-change.patch
```

## Creating Patches

To create a patch:

1. Download Kubernetes sources: `make download`
2. Navigate to the Kubernetes directory: `cd build/kubernetes`
3. Make your changes to the source code
4. Create a patch: `git diff > ../../patches/XXX-description.patch`

## Planned Patches

The following patches need to be created:

### 1. SQLite Backend Integration (001-kine-integration.patch)
- Integrate Kine as the storage backend option
- Add SQLite support for single-node deployments
- Maintain etcd compatibility for HA setups

### 2. Remove Cloud Providers (002-remove-cloud-providers.patch)
- Remove AWS cloud provider
- Remove Azure cloud provider
- Remove GCP cloud provider
- Remove other cloud-specific code
- Keep the core Kubernetes functionality

### 3. Storage Driver Removal (003-remove-storage-drivers.patch)
- Remove in-tree storage drivers
- Keep CSI interface
- Remove deprecated volume plugins

### 4. Simplify Networking (004-simplify-networking.patch)
- Remove unnecessary network plugins
- Keep CNI interface
- Simplify default networking setup

## Applying Patches

Patches are automatically applied during the build process via:

```bash
make generate
```

Or manually:

```bash
./scripts/apply-patches.sh
```

## Patch Guidelines

- Keep patches small and focused
- Document the purpose of each patch
- Test patches against the target Kubernetes version
- Ensure patches can be cleanly applied
- Update patches when Kubernetes version changes
