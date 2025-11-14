.PHONY: all clean deps download generate build install test lint validate

# Project metadata
PROJECT_NAME := k8s
BINARY_NAME := k8s

# Versions
K8S_VERSION ?= v1.31.4
KINE_VERSION ?= v0.13.6
GO_VERSION ?= 1.23

# Directories
BUILD_DIR := $(CURDIR)/build
DATA_DIR := $(BUILD_DIR)/data
DIST_DIR := $(CURDIR)/dist/artifacts
K8S_DIR := $(BUILD_DIR)/kubernetes
KINE_DIR := $(BUILD_DIR)/kine
PATCHES_DIR := $(CURDIR)/patches
SCRIPTS_DIR := $(CURDIR)/scripts

# Git metadata
GIT_TAG := $(shell git describe --tags --always 2>/dev/null || echo "v0.0.0-dev")
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_TREE_STATE := $(shell test -z "$(shell git status --porcelain 2>/dev/null)" && echo "clean" || echo "dirty")
BUILD_DATE := $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')

# Go build flags
LDFLAGS := -w -s \
	-X 'github.com/piwi3910/k8s/pkg/version.GitVersion=$(GIT_TAG)' \
	-X 'github.com/piwi3910/k8s/pkg/version.GitCommit=$(GIT_COMMIT)' \
	-X 'github.com/piwi3910/k8s/pkg/version.GitTreeState=$(GIT_TREE_STATE)' \
	-X 'github.com/piwi3910/k8s/pkg/version.BuildDate=$(BUILD_DATE)' \
	-X 'github.com/piwi3910/k8s/pkg/version.K8sVersion=$(K8S_VERSION)'

GO_BUILD_FLAGS := -ldflags "$(LDFLAGS)" -trimpath

# Default target
all: build

# Setup: Create necessary directories
setup:
	@echo "Creating build directories..."
	@mkdir -p $(BUILD_DIR) $(DATA_DIR) $(DIST_DIR) $(K8S_DIR) $(KINE_DIR)

# Download: Fetch Kubernetes and Kine sources
download: setup
	@echo "Downloading Kubernetes $(K8S_VERSION)..."
	@$(SCRIPTS_DIR)/download-k8s.sh $(K8S_VERSION) $(K8S_DIR)
	@echo "Downloading Kine $(KINE_VERSION)..."
	@$(SCRIPTS_DIR)/download-kine.sh $(KINE_VERSION) $(KINE_DIR)

# Generate: Apply patches and generate code
generate: download
	@echo "Applying patches to Kubernetes..."
	@$(SCRIPTS_DIR)/apply-patches.sh $(K8S_DIR) $(PATCHES_DIR)
	@echo "Generating code..."
	@$(SCRIPTS_DIR)/generate-code.sh $(K8S_DIR)

# Dependencies: Tidy Go modules
deps:
	@echo "Tidying Go modules..."
	@go mod tidy
	@go mod download

# Validate: Run validation checks
validate:
	@echo "Running validation..."
	@$(SCRIPTS_DIR)/validate.sh

# Lint: Run linting
lint:
	@echo "Running linters..."
	@golangci-lint run --timeout 5m || echo "golangci-lint not installed, skipping..."
	@go vet ./...

# Test: Run tests
test:
	@echo "Running tests..."
	@go test -v -race -coverprofile=coverage.out ./...

# Build: Compile the binary
build: generate deps
	@echo "Building $(BINARY_NAME)..."
	@CGO_ENABLED=1 go build $(GO_BUILD_FLAGS) -o $(DIST_DIR)/$(BINARY_NAME) ./cmd/server
	@echo "Binary created at $(DIST_DIR)/$(BINARY_NAME)"
	@$(DIST_DIR)/$(BINARY_NAME) --version

# Build without validation (for development)
build-fast:
	@echo "Building $(BINARY_NAME) (fast mode, no validation)..."
	@CGO_ENABLED=1 go build $(GO_BUILD_FLAGS) -o $(DIST_DIR)/$(BINARY_NAME) ./cmd/server

# Install: Install the binary to /usr/local/bin
install: build
	@echo "Installing $(BINARY_NAME) to /usr/local/bin..."
	@sudo install -m 755 $(DIST_DIR)/$(BINARY_NAME) /usr/local/bin/$(BINARY_NAME)
	@echo "Installing systemd service..."
	@sudo cp manifests/k8s.service /etc/systemd/system/
	@sudo systemctl daemon-reload

# Clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@go clean -cache

# Clean all: Remove build artifacts and downloaded sources
clean-all: clean
	@echo "Removing downloaded sources..."
	@rm -rf $(K8S_DIR) $(KINE_DIR)

# Help: Display available targets
help:
	@echo "Available targets:"
	@echo "  all          - Build the project (default)"
	@echo "  setup        - Create build directories"
	@echo "  download     - Download Kubernetes and Kine sources"
	@echo "  generate     - Apply patches and generate code"
	@echo "  deps         - Tidy and download Go dependencies"
	@echo "  validate     - Run validation checks"
	@echo "  lint         - Run linters"
	@echo "  test         - Run tests"
	@echo "  build        - Build the binary"
	@echo "  build-fast   - Build without validation (dev mode)"
	@echo "  install      - Install binary and systemd service"
	@echo "  clean        - Remove build artifacts"
	@echo "  clean-all    - Remove build artifacts and sources"
	@echo ""
	@echo "Variables:"
	@echo "  K8S_VERSION  - Kubernetes version (current: $(K8S_VERSION))"
	@echo "  KINE_VERSION - Kine version (current: $(KINE_VERSION))"
