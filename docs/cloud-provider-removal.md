# Cloud Provider Removal Strategy

## Overview

This document outlines the strategy for removing cloud provider code from Kubernetes to create a lightweight distribution suitable for edge computing and on-premises deployments.

## Cloud Providers to Remove

### In-Tree Cloud Providers (Legacy)

Kubernetes has deprecated in-tree cloud providers in favor of external cloud controller managers. We will remove:

1. **AWS** - `k8s.io/legacy-cloud-providers/aws`
2. **Azure** - `k8s.io/legacy-cloud-providers/azure`
3. **GCP** - `k8s.io/legacy-cloud-providers/gce`
4. **OpenStack** - `k8s.io/legacy-cloud-providers/openstack`
5. **vSphere** - `k8s.io/legacy-cloud-providers/vsphere`
6. **CloudStack** - Various cloud-specific code

### Build Tags Approach

Instead of patching Kubernetes source, we can leverage Go build tags to exclude cloud providers at compile time. Kubernetes already uses build tags for this purpose.

## Implementation Strategy

### Option 1: Build Tags (Recommended)

Use Go build tags to exclude cloud provider code during compilation:

```bash
go build -tags=nolegacyproviders,providerless
```

**Advantages:**
- No source code modifications required
- Cleaner approach
- Easier to maintain across K8s versions
- Official Kubernetes support

**Disadvantages:**
- May not remove all cloud-specific code
- Some references may remain

### Option 2: Source Code Removal

Remove cloud provider directories and update imports:

```bash
# Remove cloud provider directories
rm -rf vendor/k8s.io/legacy-cloud-providers/aws
rm -rf vendor/k8s.io/legacy-cloud-providers/azure
rm -rf vendor/k8s.io/legacy-cloud-providers/gce
# ... etc
```

**Advantages:**
- Complete removal
- Smaller binary size

**Disadvantages:**
- Requires maintaining patches
- May break with K8s updates
- More complex

### Option 3: Hybrid Approach (Our Choice)

1. Use build tags for most exclusions
2. Create minimal patches only where necessary
3. Focus on removing unnecessary dependencies from go.mod

## Components Affected

### kube-controller-manager

The controller manager has cloud-specific controllers that need to be disabled:

- `cloud-node-lifecycle`
- `route`
- `service` (cloud load balancer part)

Configuration approach:
```yaml
--cloud-provider=  # Set to empty or "external"
--controllers=-cloud-node-lifecycle,-route
```

### kube-apiserver

Minimal cloud provider integration, mostly configuration:

```yaml
--cloud-provider=  # Set to empty
```

### kubelet

Cloud provider integration for node registration:

```yaml
--cloud-provider=  # Set to empty or "external"
```

## In-Tree Storage Driver Removal

Similarly remove deprecated in-tree storage drivers:

- AWS EBS
- Azure Disk
- GCE PD
- Cinder (OpenStack)
- vSphere volumes

Keep only:
- CSI interface
- Local volumes
- Host path
- Empty dir

## Build Configuration

### Makefile Changes

Update our Makefile to build with appropriate tags:

```makefile
GO_BUILD_TAGS := -tags "providerless,nolegacyproviders"
GO_BUILD_FLAGS := $(GO_BUILD_TAGS) -ldflags "$(LDFLAGS)" -trimpath
```

### go.mod Optimization

Remove unnecessary cloud provider dependencies:

```bash
# After excluding cloud providers, clean up
go mod tidy
```

## Binary Size Impact

Expected reduction:
- Original K8s components: ~150-200 MB combined
- After cloud provider removal: ~100-130 MB combined
- Final single binary (with optimization): ~50-80 MB

## Testing Strategy

1. **Functional Tests**: Ensure core Kubernetes functionality works
2. **Integration Tests**: Test with SQLite and etcd backends
3. **Size Verification**: Confirm binary size reduction
4. **Compatibility Tests**: Ensure kubectl and kubeadm still work

## Migration Path

For users migrating from cloud providers:

1. Use external cloud controller managers (CCM) if needed
2. Migrate to CSI drivers for storage
3. Configure service type LoadBalancer with MetalLB or similar
4. Use external load balancer solutions

## Implementation Phases

### Phase 1: Build Tag Implementation (Current)
- Add build tags to exclude cloud providers
- Test compilation and functionality
- Document any issues

### Phase 2: Dependency Cleanup
- Remove unused cloud provider dependencies
- Optimize go.mod
- Measure binary size reduction

### Phase 3: Configuration Defaults
- Set cloud-provider flags to empty by default
- Disable cloud-specific controllers
- Update documentation

### Phase 4: Validation
- Comprehensive testing
- Performance benchmarks
- Size verification

## Documentation Updates

Update the following docs:
- README.md - Note cloud provider removal
- CLAUDE.md - Add build tag information
- User guide - Migration instructions

## References

- [Kubernetes Cloud Providers](https://kubernetes.io/docs/concepts/cluster-administration/cloud-providers/)
- [Cloud Provider Removal KEP](https://github.com/kubernetes/enhancements/tree/master/keps/sig-cloud-provider)
- [Providerless Build Tag](https://github.com/kubernetes/kubernetes/blob/master/staging/src/k8s.io/cloud-provider/go.mod)
