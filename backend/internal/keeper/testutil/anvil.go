package testutil

import (
	"context"
	"fmt"
	"net"
	"os/exec"
	"time"

	"github.com/ethereum/go-ethereum/ethclient"
)

// AnvilProcess represents a running Anvil instance
type AnvilProcess struct {
	Cmd    *exec.Cmd
	Port   int
	ctx    context.Context
	cancel context.CancelFunc
}

// StartAnvil starts an Anvil instance on the default port (8545)
// It returns an AnvilProcess that can be used to stop the instance
func StartAnvil(ctx context.Context) (*AnvilProcess, error) {
	return StartAnvilOnPort(ctx, 8545)
}

// StartAnvilOnPort starts an Anvil instance on the specified port
func StartAnvilOnPort(ctx context.Context, port int) (*AnvilProcess, error) {
	// Check if port is already in use
	if isPortInUse(port) {
		return nil, fmt.Errorf("port %d is already in use", port)
	}

	anvilCtx, cancel := context.WithCancel(ctx)

	cmd := exec.CommandContext(anvilCtx, "anvil", "--port", fmt.Sprintf("%d", port))

	if err := cmd.Start(); err != nil {
		cancel()
		return nil, fmt.Errorf("failed to start anvil: %w", err)
	}

	// Wait for Anvil to be ready
	rpcURL := fmt.Sprintf("http://localhost:%d", port)
	if err := waitForAnvilReady(rpcURL, 10*time.Second); err != nil {
		cmd.Process.Kill()
		cancel()
		return nil, fmt.Errorf("anvil failed to start: %w", err)
	}

	return &AnvilProcess{
		Cmd:    cmd,
		Port:   port,
		ctx:    anvilCtx,
		cancel: cancel,
	}, nil
}

// Stop stops the Anvil instance
func (ap *AnvilProcess) Stop() error {
	if ap == nil || ap.Cmd == nil || ap.Cmd.Process == nil {
		return nil
	}

	ap.cancel()

	// Give it a moment to shut down gracefully
	time.Sleep(500 * time.Millisecond)

	// Force kill if still running
	if err := ap.Cmd.Process.Kill(); err != nil {
		// Process may have already exited, that's okay
		return nil
	}

	return nil
}

// GetClient returns an ethclient connected to this Anvil instance
func (ap *AnvilProcess) GetClient() (*ethclient.Client, error) {
	return GetAnvilClient(ap.Port)
}

// GetAnvilClient returns an ethclient connected to Anvil on the specified port
func GetAnvilClient(port int) (*ethclient.Client, error) {
	rpcURL := fmt.Sprintf("http://localhost:%d", port)
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to anvil at %s: %w", rpcURL, err)
	}
	return client, nil
}

// IsAnvilRunning checks if Anvil is running on the specified port
func IsAnvilRunning(port int) bool {
	return isPortInUse(port)
}

// isPortInUse checks if a TCP port is in use
func isPortInUse(port int) bool {
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("localhost:%d", port), 1*time.Second)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

// waitForAnvilReady waits for Anvil to be ready by attempting to connect to the RPC endpoint
func waitForAnvilReady(rpcURL string, timeout time.Duration) error {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return fmt.Errorf("timeout waiting for anvil to be ready")
		case <-ticker.C:
			client, err := ethclient.Dial(rpcURL)
			if err == nil {
				// Try to get chain ID to verify it's responding
				_, err := client.ChainID(context.Background())
				client.Close()
				if err == nil {
					return nil
				}
			}
		}
	}
}
