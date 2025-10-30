package keeper

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestScheduler_NewScheduler tests scheduler creation
func TestScheduler_NewScheduler(t *testing.T) {
	t.Run("creates scheduler successfully", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)
		defer keeper.Shutdown(context.Background())

		scheduler := NewScheduler(keeper)
		assert.NotNil(t, scheduler)
		assert.NotNil(t, scheduler.keeper)
		assert.NotNil(t, scheduler.tasks)
	})
}

// TestScheduler_RegisterTask tests task registration
func TestScheduler_RegisterTask(t *testing.T) {
	t.Run("registers task successfully", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)
		defer keeper.Shutdown(context.Background())

		scheduler := NewScheduler(keeper)

		// Register lock task
		lockTask := NewLockTask(keeper)
		scheduler.RegisterTask("lock", lockTask, time.Duration(cfg.TaskInterval)*time.Second)

		assert.Len(t, scheduler.tasks, 1)
		assert.Contains(t, scheduler.tasks, "lock")
	})

	t.Run("overwrites existing task", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)
		defer keeper.Shutdown(context.Background())

		scheduler := NewScheduler(keeper)

		// Register same task twice with different intervals
		lockTask1 := NewLockTask(keeper)
		scheduler.RegisterTask("lock", lockTask1, 30*time.Second)

		lockTask2 := NewLockTask(keeper)
		scheduler.RegisterTask("lock", lockTask2, 60*time.Second)

		assert.Len(t, scheduler.tasks, 1)
		assert.Equal(t, 60*time.Second, scheduler.tasks["lock"].Interval)
	})
}

// TestScheduler_Start tests scheduler start and stop
func TestScheduler_Start(t *testing.T) {
	t.Run("starts and stops gracefully", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     1, // 1 second for faster testing
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)
		defer keeper.Shutdown(context.Background())

		scheduler := NewScheduler(keeper)

		// Register a task
		lockTask := NewLockTask(keeper)
		scheduler.RegisterTask("lock", lockTask, 1*time.Second)

		// Start scheduler in background
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()

		errChan := make(chan error, 1)
		go func() {
			errChan <- scheduler.Start(ctx)
		}()

		// Wait for scheduler to run a few cycles
		time.Sleep(2 * time.Second)

		// Cancel context to stop scheduler
		cancel()

		// Wait for shutdown
		select {
		case err := <-errChan:
			assert.NoError(t, err, "Scheduler should shutdown gracefully")
		case <-time.After(5 * time.Second):
			t.Fatal("Scheduler shutdown timeout")
		}
	})

	t.Run("handles task execution errors", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     1,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)
		defer keeper.Shutdown(context.Background())

		scheduler := NewScheduler(keeper)

		// Register lock task (will have empty database, no errors expected)
		lockTask := NewLockTask(keeper)
		scheduler.RegisterTask("lock", lockTask, 1*time.Second)

		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		err = scheduler.Start(ctx)
		assert.NoError(t, err, "Scheduler should handle task errors gracefully")
	})
}

// TestScheduler_Stop tests scheduler stop
func TestScheduler_Stop(t *testing.T) {
	t.Run("stops all running tasks", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     1,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)
		defer keeper.Shutdown(context.Background())

		scheduler := NewScheduler(keeper)

		// Register task
		lockTask := NewLockTask(keeper)
		scheduler.RegisterTask("lock", lockTask, 1*time.Second)

		// Start scheduler
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()

		errChan := make(chan error, 1)
		go func() {
			errChan <- scheduler.Start(ctx)
		}()

		// Wait a bit for scheduler to start
		time.Sleep(500 * time.Millisecond)

		// Cancel context to stop scheduler
		cancel()

		// Should stop gracefully
		select {
		case err := <-errChan:
			assert.NoError(t, err)
		case <-time.After(3 * time.Second):
			t.Fatal("Scheduler stop timeout")
		}
	})
}

// TestScheduler_GetTaskStatus tests task status retrieval
func TestScheduler_GetTaskStatus(t *testing.T) {
	t.Run("returns task status", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)
		defer keeper.Shutdown(context.Background())

		scheduler := NewScheduler(keeper)

		// Register a task
		lockTask := NewLockTask(keeper)
		scheduler.RegisterTask("lock", lockTask, time.Hour)

		// Get task status
		status, err := scheduler.GetTaskStatus("lock")
		require.NoError(t, err)
		assert.NotNil(t, status)
		assert.Equal(t, "lock", status["name"])
		assert.False(t, status["running"].(bool))

		// Get non-existent task status
		status, err = scheduler.GetTaskStatus("non-existent")
		assert.Error(t, err)
		assert.Nil(t, status)
	})
}

// TestScheduler_ListTasks tests task listing
func TestScheduler_ListTasks(t *testing.T) {
	t.Run("lists all registered tasks", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)
		defer keeper.Shutdown(context.Background())

		scheduler := NewScheduler(keeper)

		// Initially should be empty
		tasks := scheduler.ListTasks()
		assert.Empty(t, tasks)

		// Register tasks
		lockTask := NewLockTask(keeper)
		settleTask := NewSettleTask(keeper)

		scheduler.RegisterTask("lock", lockTask, time.Hour)
		scheduler.RegisterTask("settle", settleTask, 2*time.Hour)

		// Should list both tasks
		tasks = scheduler.ListTasks()
		assert.Len(t, tasks, 2)

		// Check task names
		assert.Contains(t, tasks, "lock")
		assert.Contains(t, tasks, "settle")
	})
}
