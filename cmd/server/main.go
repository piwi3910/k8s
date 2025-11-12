package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"github.com/piwi3910/k8s/pkg/server"
	"github.com/piwi3910/k8s/pkg/version"
	"github.com/sirupsen/logrus"
)

var (
	showVersion = flag.Bool("version", false, "Show version information and exit")
	configFile  = flag.String("config", "/etc/k8s/config.yaml", "Path to configuration file")
	dataDir     = flag.String("data-dir", "/var/lib/k8s", "Path to data directory")
	serverMode  = flag.String("server-mode", "single", "Server mode: single (SQLite) or ha (etcd)")
	logLevel    = flag.String("log-level", "info", "Log level (debug, info, warn, error)")
)

func main() {
	flag.Parse()

	// Configure logging
	level, err := logrus.ParseLevel(*logLevel)
	if err != nil {
		logrus.Warnf("Invalid log level '%s', defaulting to info", *logLevel)
		level = logrus.InfoLevel
	}
	logrus.SetLevel(level)
	logrus.SetFormatter(&logrus.TextFormatter{
		FullTimestamp: true,
	})

	// Show version and exit if requested
	if *showVersion {
		info := version.Get()
		fmt.Println(info.String())
		os.Exit(0)
	}

	// Print banner
	printBanner()

	// Validate server mode
	mode := server.ServerMode(*serverMode)
	if mode != server.ModeSingle && mode != server.ModeHA {
		logrus.Fatalf("Invalid server mode '%s'. Must be 'single' or 'ha'", *serverMode)
	}

	// Create data directory if it doesn't exist
	if err := os.MkdirAll(*dataDir, 0755); err != nil {
		logrus.Fatalf("Failed to create data directory: %v", err)
	}

	// Build server configuration
	config := &server.Config{
		Mode:       mode,
		DataDir:    *dataDir,
		ConfigFile: *configFile,
	}

	// Set storage endpoint based on mode
	if mode == server.ModeSingle {
		// SQLite database path
		config.StorageEndpoint = fmt.Sprintf("sqlite://%s/db/state.db", *dataDir)
		// Ensure db directory exists
		dbDir := filepath.Join(*dataDir, "db")
		if err := os.MkdirAll(dbDir, 0755); err != nil {
			logrus.Fatalf("Failed to create database directory: %v", err)
		}
	} else {
		// etcd endpoint (default to localhost, can be overridden via config)
		config.StorageEndpoint = "http://127.0.0.1:2379"
	}

	// Create and run server
	srv, err := server.New(config)
	if err != nil {
		logrus.Fatalf("Failed to create server: %v", err)
	}

	logrus.Info("Lightweight Kubernetes Distribution")
	logrus.Infof("Version: %s", version.GitVersion)
	logrus.Infof("Kubernetes: %s", version.K8sVersion)
	logrus.Infof("Mode: %s", mode)

	if err := srv.Run(); err != nil {
		logrus.Fatalf("Server error: %v", err)
	}
}

func printBanner() {
	banner := `
╔═══════════════════════════════════════════════════════════════╗
║   Lightweight Kubernetes Distribution                        ║
║   Minimal K8s for Edge Computing                             ║
╚═══════════════════════════════════════════════════════════════╝
`
	fmt.Println(banner)
}
