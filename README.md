# Lightweight Kubernetes Distribution

A minimal Kubernetes distribution inspired by k3s, designed for resource-constrained environments and edge computing.

## Features

- **Single Binary**: Everything compiled into one executable
- **SQLite Backend**: Uses Kine for single-node deployments (no etcd required)
- **HA Support**: Retains etcd support for multi-node clusters
- **Minimal Footprint**: Cloud providers and unnecessary components removed
- **Systemd Integration**: Native Linux service management
- **Easy Installation**: Simple build and install process

## Quick Start

### Prerequisites

- Go 1.23 or higher
- Git
- Make
- Linux (for systemd integration)

### Building

```bash
# Clone the repository
git clone https://github.com/piwi3910/k8s.git
cd k8s

# Build the binary
make

# Install (requires sudo)
sudo make install
```

### Running

#### Single-Node Mode (SQLite)

```bash
# Start the service
sudo systemctl start k8s

# Check status
sudo systemctl status k8s

# View logs
sudo journalctl -u k8s -f
```

#### High-Availability Mode (etcd)

```bash
# Configure for HA mode
sudo bash -c 'echo "SERVER_MODE=ha" > /etc/systemd/system/k8s.service.env'

# Start the service
sudo systemctl start k8s
```

## Architecture

This project takes upstream Kubernetes and applies minimal patches to:

1. **Integrate Kine** - Adds SQLite support for single-node deployments
2. **Remove Cloud Providers** - Strips AWS, Azure, GCP, and other cloud-specific code
3. **Remove Storage Drivers** - Removes in-tree storage drivers (CSI remains)
4. **Simplify Components** - Removes unnecessary features for edge deployments

The result is a single binary that includes:
- Kubernetes API Server
- Controller Manager
- Scheduler
- Kubelet
- Kube-proxy
- Storage backend (SQLite or etcd)

## Build System

The build system is organized in phases:

```
make download  →  make generate  →  make build
     ↓                 ↓                ↓
  Download          Apply            Compile
  K8s sources       patches          binary
```

### Available Make Targets

```bash
make              # Full build
make build-fast   # Build without validation (dev)
make test         # Run tests
make lint         # Run linters
make validate     # Run validation checks
make clean        # Clean build artifacts
make clean-all    # Clean everything including sources
make install      # Install binary and systemd service
make help         # Show all targets
```

### Customizing the Build

```bash
# Use different Kubernetes version
K8S_VERSION=v1.32.0 make

# Use different Kine version
KINE_VERSION=v0.14.0 make

# Skip validation (faster builds)
SKIP_VALIDATE=true make
```

## Development

### Project Structure

```
cmd/server/         Main application entry point
pkg/                Shared libraries and packages
scripts/            Build and helper scripts
patches/            Kubernetes source patches
manifests/          Systemd service files
build/              Build artifacts (gitignored)
dist/               Distribution artifacts (gitignored)
```

### Creating Patches

```bash
# Download Kubernetes sources
make download

# Make your changes
cd build/kubernetes
# ... edit files ...

# Create a patch
git diff > ../../patches/001-my-feature.patch

# Test the patch
make clean
make generate
```

### Running Tests

```bash
# Run all tests
make test

# Run specific package tests
go test -v ./pkg/version/...

# Run with coverage
go test -v -race -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Configuration

### Server Modes

**Single Mode** - Uses SQLite for storage (default)
- Suitable for: Development, edge devices, single-node clusters
- No external dependencies
- Lower resource usage

**HA Mode** - Uses etcd for storage
- Suitable for: Production, multi-node clusters
- Requires: External etcd cluster
- Higher availability

### Environment Variables

Configure via `/etc/systemd/system/k8s.service.env`:

```bash
SERVER_MODE=single          # Server mode: single or ha
DATA_DIR=/var/lib/k8s       # Data directory
CONFIG_FILE=/etc/k8s/config.yaml  # Configuration file
```

## Comparison with k3s

| Feature | This Project | k3s |
|---------|--------------|-----|
| Single Binary | ✅ | ✅ |
| SQLite Backend | ✅ | ✅ |
| Cloud Providers | Removed | Removed |
| Embedded Components | Planned | ✅ |
| Container Runtime | Planned | containerd |
| Network Plugin | Planned | Flannel |
| Service Proxy | Planned | kube-proxy |
| Ingress | Planned | Traefik |

## Current Status

⚠️ **Early Development** - Build infrastructure is complete, but core Kubernetes integration is in progress.

### Completed
- ✅ Build system and Makefile
- ✅ Source download and caching
- ✅ Patch management system
- ✅ Version information
- ✅ Systemd integration
- ✅ Project structure

### In Progress
- 🔄 Kine SQLite integration
- 🔄 Cloud provider removal patches
- 🔄 Kubernetes component integration

### Planned
- ⏳ API server integration
- ⏳ Controller manager
- ⏳ Scheduler
- ⏳ Kubelet
- ⏳ Kube-proxy
- ⏳ CNI networking
- ⏳ Container runtime integration

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and validation
5. Submit a pull request

## Documentation

- [CLAUDE.md](CLAUDE.md) - Detailed development guide
- [patches/README.md](patches/README.md) - Patch management guide

## License

This project packages and modifies Kubernetes, which is licensed under Apache License 2.0.

## Acknowledgments

- [Kubernetes](https://kubernetes.io/) - The container orchestration platform
- [k3s](https://k3s.io/) - Inspiration for this project
- [Kine](https://github.com/k3s-io/kine) - SQLite backend for Kubernetes

## Support

For issues, questions, or contributions, please open an issue on GitHub.

---

**Note**: This is an educational and experimental project. For production use, consider [k3s](https://k3s.io/) or official Kubernetes distributions.
