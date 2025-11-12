# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a lightweight Kubernetes distribution similar to k3s, designed to run Kubernetes in resource-constrained environments. The project:

- Patches upstream Kubernetes to remove cloud providers and unnecessary components
- Uses SQLite (via Kine) for single-node deployments
- Retains etcd support for HA clusters
- Compiles everything into a single binary
- Runs as a systemd service

## Architecture

### Directory Structure

```
.
├── cmd/
│   └── server/          # Main application entry point
├── pkg/
│   ├── version/         # Version information
│   └── sqlite/          # SQLite backend integration (future)
├── scripts/             # Build and helper scripts
│   ├── download-k8s.sh      # Downloads Kubernetes sources
│   ├── download-kine.sh     # Downloads Kine (SQLite backend)
│   ├── apply-patches.sh     # Applies patches to K8s
│   ├── generate-code.sh     # Generates code from K8s
│   └── validate.sh          # Validation checks
├── patches/             # Kubernetes source patches
│   └── README.md            # Patch documentation
├── manifests/           # Systemd service files
│   ├── k8s.service          # Main service definition
│   └── k8s.env.example      # Environment variables
├── build/               # Build artifacts (gitignored)
│   ├── kubernetes/          # Downloaded K8s sources
│   ├── kine/                # Downloaded Kine sources
│   └── data/                # Generated data
└── dist/                # Distribution artifacts (gitignored)
    └── artifacts/           # Compiled binaries
```

### Build Process Flow

1. **Download Phase**: Fetch Kubernetes and Kine sources from GitHub
2. **Patch Phase**: Apply custom patches to remove cloud providers and add SQLite support
3. **Generate Phase**: Run Kubernetes code generation (if needed)
4. **Compile Phase**: Build the single binary with version information embedded

## Common Development Tasks

### Building the Project

```bash
# Full build (downloads, patches, compiles)
make

# Fast build (skip validation, for development)
make build-fast

# Clean and rebuild everything
make clean-all && make
```

### Working with Dependencies

```bash
# Update Go dependencies
make deps

# After modifying go.mod
go mod tidy
make deps
```

### Testing

```bash
# Run all tests
make test

# Run tests with coverage
go test -v -race -coverprofile=coverage.out ./...

# View coverage report
go tool cover -html=coverage.out
```

### Validation and Linting

```bash
# Run validation checks
make validate

# Run linters
make lint

# Type checking only
go vet ./...
```

### Working with Patches

```bash
# Download Kubernetes sources
make download

# Make changes in build/kubernetes/
cd build/kubernetes
# ... make your changes ...

# Create a patch
git diff > ../../patches/001-my-change.patch

# Apply all patches
make generate
```

### Installation

```bash
# Install binary and systemd service
sudo make install

# Start the service
sudo systemctl start k8s

# Enable on boot
sudo systemctl enable k8s

# Check status
sudo systemctl status k8s

# View logs
sudo journalctl -u k8s -f
```

## Build System Details

### Makefile Targets

- `make all` - Default target, builds the project
- `make setup` - Creates necessary build directories
- `make download` - Downloads Kubernetes and Kine sources
- `make generate` - Applies patches and generates code
- `make deps` - Tidies and downloads Go dependencies
- `make validate` - Runs validation checks
- `make lint` - Runs linters and static analysis
- `make test` - Runs the test suite
- `make build` - Builds the binary
- `make build-fast` - Builds without validation (dev mode)
- `make install` - Installs binary and systemd service
- `make clean` - Removes build artifacts
- `make clean-all` - Removes build artifacts and downloaded sources
- `make help` - Shows available targets

### Build Variables

Configure the build with these environment variables:

```bash
# Kubernetes version to use
K8S_VERSION=v1.31.4 make

# Kine version (SQLite backend)
KINE_VERSION=v0.13.6 make

# Skip validation for faster development builds
SKIP_VALIDATE=true make
```

### Version Information

Version information is embedded at build time using ldflags:

- `GitVersion` - Git tag or commit description
- `GitCommit` - Short commit hash
- `GitTreeState` - "clean" or "dirty"
- `BuildDate` - ISO 8601 timestamp
- `K8sVersion` - Kubernetes version being used

View version info:
```bash
./dist/artifacts/k8s --version
```

## Patch Management

Patches are stored in `patches/` and applied in alphabetical order. See `patches/README.md` for details.

### Current Patch Plans

1. **Kine Integration** - Add SQLite backend for single-node mode
2. **Remove Cloud Providers** - Strip AWS, Azure, GCP code
3. **Remove Storage Drivers** - Remove in-tree storage drivers
4. **Simplify Networking** - Remove unnecessary network plugins

## Server Modes

The binary supports two deployment modes:

### Single Mode (SQLite)
```bash
k8s --server-mode=single --data-dir=/var/lib/k8s
```
- Uses SQLite for storage via Kine
- Suitable for single-node deployments
- Lower resource requirements
- No external dependencies

### HA Mode (etcd)
```bash
k8s --server-mode=ha --data-dir=/var/lib/k8s
```
- Uses etcd for storage
- Suitable for multi-node clusters
- Higher availability
- Requires etcd cluster

## Development Guidelines

### Code Style

- Follow standard Go conventions
- Use `gofmt` and `goimports` for formatting
- Run `make lint` before committing
- Ensure `make validate` passes

### Git Workflow

- Create feature branches for new work
- Keep commits focused and atomic
- Write descriptive commit messages
- Reference issue numbers in commits

### Testing Requirements

- Write tests for new functionality
- Maintain test coverage above 80%
- Run full test suite before pushing
- Test both single and HA modes

## Troubleshooting

### Build Issues

**Problem**: Scripts fail with permission errors
```bash
# Solution: Make scripts executable
chmod +x scripts/*.sh
```

**Problem**: Kubernetes download fails
```bash
# Solution: Check network connectivity and version
curl -I https://github.com/kubernetes/kubernetes/releases/tag/v1.31.4
```

**Problem**: Patches fail to apply
```bash
# Solution: Clean and try again
make clean-all
make download
# Review patch compatibility with K8s version
```

### Runtime Issues

**Problem**: Binary won't start
```bash
# Check binary permissions
ls -la dist/artifacts/k8s

# Check dependencies
ldd dist/artifacts/k8s

# Run with verbose logging
./dist/artifacts/k8s --v=5
```

**Problem**: Systemd service fails
```bash
# Check service status
sudo systemctl status k8s

# View logs
sudo journalctl -u k8s --no-pager

# Test binary manually
sudo /usr/local/bin/k8s --version
```

## Key Dependencies

- **Kubernetes**: Core Kubernetes components
- **Kine**: SQLite backend adapter for Kubernetes
- **Go 1.23+**: Required for building
- **Git**: For source management
- **Make**: Build orchestration
- **systemd**: Service management (Linux)

## Next Steps

The build infrastructure is in place. Next tasks:

1. Create patches to integrate Kine SQLite backend
2. Create patches to remove cloud providers
3. Integrate Kubernetes API server into the binary
4. Add controller manager and scheduler
5. Implement kubelet and kube-proxy
6. Add comprehensive tests
7. Create installation documentation
8. Performance testing and optimization

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [k3s Project](https://github.com/k3s-io/k3s)
- [Kine Project](https://github.com/k3s-io/kine)
- [Kubernetes Development Guide](https://github.com/kubernetes/community/tree/master/contributors/devel)
