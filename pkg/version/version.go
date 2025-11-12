package version

import (
	"fmt"
	"runtime"
)

var (
	// GitVersion is the semantic version (added at build time)
	GitVersion = "v0.0.0-dev"
	// GitCommit is the git commit hash (added at build time)
	GitCommit = "unknown"
	// GitTreeState indicates if the git tree was clean or dirty (added at build time)
	GitTreeState = "unknown"
	// BuildDate is the date of the build (added at build time)
	BuildDate = "unknown"
	// K8sVersion is the Kubernetes version this binary is based on
	K8sVersion = "unknown"
)

// Info contains version information
type Info struct {
	GitVersion   string `json:"gitVersion"`
	GitCommit    string `json:"gitCommit"`
	GitTreeState string `json:"gitTreeState"`
	BuildDate    string `json:"buildDate"`
	K8sVersion   string `json:"k8sVersion"`
	GoVersion    string `json:"goVersion"`
	Compiler     string `json:"compiler"`
	Platform     string `json:"platform"`
}

// Get returns version information
func Get() Info {
	return Info{
		GitVersion:   GitVersion,
		GitCommit:    GitCommit,
		GitTreeState: GitTreeState,
		BuildDate:    BuildDate,
		K8sVersion:   K8sVersion,
		GoVersion:    runtime.Version(),
		Compiler:     runtime.Compiler,
		Platform:     fmt.Sprintf("%s/%s", runtime.GOOS, runtime.GOARCH),
	}
}

// String returns a formatted version string
func (i Info) String() string {
	return fmt.Sprintf(`Version:      %s
Git Commit:   %s
Git State:    %s
Build Date:   %s
K8s Version:  %s
Go Version:   %s
Compiler:     %s
Platform:     %s`,
		i.GitVersion,
		i.GitCommit,
		i.GitTreeState,
		i.BuildDate,
		i.K8sVersion,
		i.GoVersion,
		i.Compiler,
		i.Platform,
	)
}
