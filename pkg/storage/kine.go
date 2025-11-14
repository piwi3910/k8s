package storage

import (
	"context"
	"fmt"
	"path/filepath"
	"time"

	"github.com/k3s-io/kine/pkg/drivers/generic"
	"github.com/k3s-io/kine/pkg/endpoint"
	"github.com/sirupsen/logrus"
)

// KineConfig holds Kine configuration
type KineConfig struct {
	DataDir     string
	SQLitePath  string
	ETCDServers []string
	Mode        string // "single" or "ha"
}

// KineServer wraps the Kine server
type KineServer struct {
	config   *KineConfig
	endpoint string
	ctx      context.Context
	cancel   context.CancelFunc
}

// NewKineServer creates a new Kine server instance
func NewKineServer(config *KineConfig) *KineServer {
	ctx, cancel := context.WithCancel(context.Background())

	return &KineServer{
		config: config,
		ctx:    ctx,
		cancel: cancel,
	}
}

// Start starts the Kine server with SQLite backend
func (k *KineServer) Start() error {
	if k.config.Mode == "ha" {
		logrus.Info("HA mode: skipping Kine, using external etcd")
		// In HA mode, we don't start Kine, just configure API server to use etcd directly
		if len(k.config.ETCDServers) > 0 {
			k.endpoint = k.config.ETCDServers[0]
		} else {
			k.endpoint = "http://127.0.0.1:2379"
		}
		return nil
	}

	// Single mode: Start Kine with SQLite
	logrus.Info("Starting Kine with SQLite backend...")

	// Construct SQLite connection string
	sqlitePath := k.config.SQLitePath
	if sqlitePath == "" {
		sqlitePath = filepath.Join(k.config.DataDir, "db", "state.db")
	}

	// Kine endpoint will be unix socket or TCP
	// For now, use a unix socket for local communication
	kineSocket := filepath.Join(k.config.DataDir, "kine.sock")
	k.endpoint = fmt.Sprintf("unix://%s", kineSocket)

	logrus.Infof("SQLite database: %s", sqlitePath)
	logrus.Infof("Kine endpoint: %s", k.endpoint)

	// Configure Kine with proper settings
	kineConfig := endpoint.Config{
		Listener: kineSocket,
		Endpoint: fmt.Sprintf("sqlite://%s?_journal=WAL&cache=shared", sqlitePath),
		// Connection pool settings for SQLite
		ConnectionPoolConfig: generic.ConnectionPoolConfig{
			MaxIdle:     2,
			MaxOpen:     0, // unlimited
			MaxLifetime: 0, // unlimited
		},
		// Watch progress notification interval
		NotifyInterval: 5 * time.Second,
		// Emulated etcd version for compatibility
		EmulatedETCDVersion: "3.5.13",
	}

	// Start Kine in a goroutine
	go func() {
		logrus.Info("Kine server starting...")
		etcdConfig, err := endpoint.Listen(k.ctx, kineConfig)
		if err != nil {
			logrus.Errorf("Failed to start Kine: %v", err)
			return
		}
		logrus.Infof("Kine started successfully: %+v", etcdConfig)
	}()

	logrus.Info("Kine server initialization complete")
	return nil
}

// Stop stops the Kine server
func (k *KineServer) Stop() error {
	logrus.Info("Stopping Kine server...")
	k.cancel()
	return nil
}

// Endpoint returns the etcd-compatible endpoint
func (k *KineServer) Endpoint() string {
	return k.endpoint
}
