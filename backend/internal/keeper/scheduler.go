package keeper

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"
)

// Task represents a scheduled task
type Task interface {
	Execute(ctx context.Context) error
}

// ScheduledTask wraps a task with scheduling information
type ScheduledTask struct {
	Name     string
	Task     Task
	Interval time.Duration
	ticker   *time.Ticker
	stopChan chan struct{}
}

// Scheduler manages scheduled tasks
type Scheduler struct {
	keeper  *Keeper
	tasks   map[string]*ScheduledTask
	mu      sync.RWMutex
	wg      sync.WaitGroup
	stopped bool
}

// NewScheduler creates a new Scheduler instance
func NewScheduler(keeper *Keeper) *Scheduler {
	return &Scheduler{
		keeper: keeper,
		tasks:  make(map[string]*ScheduledTask),
	}
}

// RegisterTask registers a new task with the scheduler
func (s *Scheduler) RegisterTask(name string, task Task, interval time.Duration) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.keeper.logger.Info("registering task",
		zap.String("name", name),
		zap.Duration("interval", interval),
	)

	s.tasks[name] = &ScheduledTask{
		Name:     name,
		Task:     task,
		Interval: interval,
		stopChan: make(chan struct{}),
	}
}

// Start starts the scheduler and all registered tasks
func (s *Scheduler) Start(ctx context.Context) error {
	s.keeper.logger.Info("starting scheduler",
		zap.Int("tasks", len(s.tasks)),
	)

	// Start all tasks
	s.mu.RLock()
	for _, task := range s.tasks {
		s.wg.Add(1)
		go s.runTask(ctx, task)
	}
	s.mu.RUnlock()

	// Wait for context cancellation
	<-ctx.Done()
	s.keeper.logger.Info("scheduler context cancelled")

	// Stop all tasks
	s.Stop()

	// Wait for all tasks to finish
	s.wg.Wait()

	s.keeper.logger.Info("scheduler stopped")
	return nil
}

// Stop stops all running tasks
func (s *Scheduler) Stop() {
	s.keeper.logger.Info("stopping scheduler")

	s.mu.Lock()
	defer s.mu.Unlock()

	// Prevent multiple stops
	if s.stopped {
		return
	}
	s.stopped = true

	for _, task := range s.tasks {
		close(task.stopChan)
		if task.ticker != nil {
			task.ticker.Stop()
		}
	}
}

// runTask runs a single task on its schedule
func (s *Scheduler) runTask(ctx context.Context, task *ScheduledTask) {
	defer s.wg.Done()

	s.keeper.logger.Info("starting task",
		zap.String("name", task.Name),
		zap.Duration("interval", task.Interval),
	)

	// Create ticker for this task
	task.ticker = time.NewTicker(task.Interval)
	defer task.ticker.Stop()

	// Run task immediately on start
	s.executeTask(ctx, task)

	// Run task on interval
	for {
		select {
		case <-ctx.Done():
			s.keeper.logger.Info("task context cancelled",
				zap.String("name", task.Name),
			)
			return
		case <-task.stopChan:
			s.keeper.logger.Info("task stop signal received",
				zap.String("name", task.Name),
			)
			return
		case <-task.ticker.C:
			s.executeTask(ctx, task)
		}
	}
}

// executeTask executes a task with retry logic
func (s *Scheduler) executeTask(ctx context.Context, task *ScheduledTask) {
	s.keeper.logger.Debug("executing task",
		zap.String("name", task.Name),
	)

	startTime := time.Now()

	// Execute with retries
	var lastErr error
	for attempt := 1; attempt <= s.keeper.config.RetryAttempts; attempt++ {
		err := task.Task.Execute(ctx)
		if err == nil {
			// Success
			duration := time.Since(startTime)
			s.keeper.logger.Info("task executed successfully",
				zap.String("name", task.Name),
				zap.Duration("duration", duration),
			)
			return
		}

		lastErr = err
		s.keeper.logger.Warn("task execution failed",
			zap.String("name", task.Name),
			zap.Int("attempt", attempt),
			zap.Int("maxAttempts", s.keeper.config.RetryAttempts),
			zap.Error(err),
		)

		// Don't retry if context cancelled
		if ctx.Err() != nil {
			return
		}

		// Wait before retry (except on last attempt)
		if attempt < s.keeper.config.RetryAttempts {
			retryDelay := time.Duration(s.keeper.config.RetryDelay) * time.Second
			s.keeper.logger.Info("retrying task",
				zap.String("name", task.Name),
				zap.Duration("delay", retryDelay),
			)

			// Use timer to allow context cancellation during sleep
			timer := time.NewTimer(retryDelay)
			select {
			case <-ctx.Done():
				timer.Stop()
				return
			case <-timer.C:
				// Continue to next retry
			}
		}
	}

	// All retries failed
	duration := time.Since(startTime)
	s.keeper.logger.Error("task failed after all retries",
		zap.String("name", task.Name),
		zap.Int("attempts", s.keeper.config.RetryAttempts),
		zap.Duration("duration", duration),
		zap.Error(lastErr),
	)

	// TODO: Send alert
}

// GetTaskStatus returns the status of a task
func (s *Scheduler) GetTaskStatus(name string) (map[string]interface{}, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	task, exists := s.tasks[name]
	if !exists {
		return nil, fmt.Errorf("task not found: %s", name)
	}

	status := map[string]interface{}{
		"name":     task.Name,
		"interval": task.Interval.String(),
		"running":  task.ticker != nil,
	}

	return status, nil
}

// ListTasks returns a list of all registered tasks
func (s *Scheduler) ListTasks() []string {
	s.mu.RLock()
	defer s.mu.RUnlock()

	names := make([]string, 0, len(s.tasks))
	for name := range s.tasks {
		names = append(names, name)
	}

	return names
}
