package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/piwi3910/k8s/pkg/version"
)

var (
	showVersion = flag.Bool("version", false, "Show version information and exit")
	configFile  = flag.String("config", "/etc/k8s/config.yaml", "Path to configuration file")
	dataDir     = flag.String("data-dir", "/var/lib/k8s", "Path to data directory")
	serverMode  = flag.String("server-mode", "single", "Server mode: single (SQLite) or ha (etcd)")
)

func main() {
	flag.Parse()

	// Show version and exit if requested
	if *showVersion {
		info := version.Get()
		fmt.Println(info.String())
		os.Exit(0)
	}

	// Validate server mode
	if *serverMode != "single" && *serverMode != "ha" {
		fmt.Fprintf(os.Stderr, "Error: invalid server mode '%s'. Must be 'single' or 'ha'\n", *serverMode)
		os.Exit(1)
	}

	fmt.Printf("Starting Lightweight Kubernetes Distribution\n")
	fmt.Printf("Version: %s\n", version.GitVersion)
	fmt.Printf("Mode: %s\n", *serverMode)
	fmt.Printf("Data Directory: %s\n", *dataDir)
	fmt.Printf("Config File: %s\n", *configFile)
	fmt.Println()

	// TODO: Initialize server components
	// This is where we'll integrate:
	// - Kine (SQLite backend for single mode)
	// - etcd client (for HA mode)
	// - Kubernetes API server
	// - Controller manager
	// - Scheduler
	// - Kubelet
	// - Kube-proxy

	fmt.Println("Server initialization not yet implemented.")
	fmt.Println("Next steps:")
	fmt.Println("  1. Integrate Kine for SQLite backend")
	fmt.Println("  2. Set up Kubernetes API server")
	fmt.Println("  3. Configure controller manager and scheduler")
	fmt.Println("  4. Implement kubelet and kube-proxy")
	fmt.Println("  5. Add service orchestration")
}
