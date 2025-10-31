package keeper

import (
	"context"
	"time"

	"github.com/ethereum/go-ethereum/common"
)

// AlertSeverity defines the severity level of an alert
type AlertSeverity string

const (
	// AlertSeverityInfo for informational alerts
	AlertSeverityInfo AlertSeverity = "info"
	// AlertSeverityWarning for warning alerts
	AlertSeverityWarning AlertSeverity = "warning"
	// AlertSeverityError for error alerts
	AlertSeverityError AlertSeverity = "error"
	// AlertSeverityCritical for critical alerts requiring immediate attention
	AlertSeverityCritical AlertSeverity = "critical"
)

// AlertType defines the type of alert
type AlertType string

const (
	// AlertTypeLockFailure when market lock operation fails
	AlertTypeLockFailure AlertType = "lock_failure"
	// AlertTypeSettleFailure when market settlement operation fails
	AlertTypeSettleFailure AlertType = "settle_failure"
	// AlertTypeDatabaseFailure when database operations fail
	AlertTypeDatabaseFailure AlertType = "database_failure"
	// AlertTypeRPCFailure when RPC/blockchain operations fail
	AlertTypeRPCFailure AlertType = "rpc_failure"
	// AlertTypeTaskExecutionFailure when scheduled task execution fails
	AlertTypeTaskExecutionFailure AlertType = "task_execution_failure"
	// AlertTypeDataSourceFailure when external data source fails
	AlertTypeDataSourceFailure AlertType = "data_source_failure"
	// AlertTypeTransactionFailure when blockchain transaction fails
	AlertTypeTransactionFailure AlertType = "transaction_failure"
	// AlertTypeHighGasPrice when gas price exceeds configured maximum
	AlertTypeHighGasPrice AlertType = "high_gas_price"
)

// Alert represents an alert event
type Alert struct {
	// Severity level of the alert
	Severity AlertSeverity
	// Type of alert
	Type AlertType
	// Title is a short description
	Title string
	// Message is the detailed alert message
	Message string
	// Timestamp when the alert was created
	Timestamp time.Time
	// Context contains additional contextual information
	Context map[string]interface{}
	// MarketAddress if the alert is related to a specific market
	MarketAddress *common.Address
	// TxHash if the alert is related to a specific transaction
	TxHash *common.Hash
	// Error associated with the alert
	Error error
}

// AlertNotifier defines the interface for sending alerts
type AlertNotifier interface {
	// Notify sends an alert through the configured channels
	Notify(ctx context.Context, alert *Alert) error
	// IsEnabled returns whether the notifier is enabled
	IsEnabled() bool
	// Close gracefully shuts down the notifier
	Close() error
}

// AlertManager manages multiple alert notifiers
type AlertManager struct {
	notifiers []AlertNotifier
}

// NewAlertManager creates a new AlertManager
func NewAlertManager(notifiers ...AlertNotifier) *AlertManager {
	return &AlertManager{
		notifiers: notifiers,
	}
}

// Notify sends an alert to all enabled notifiers
func (m *AlertManager) Notify(ctx context.Context, alert *Alert) error {
	if alert.Timestamp.IsZero() {
		alert.Timestamp = time.Now()
	}

	var lastErr error
	for _, notifier := range m.notifiers {
		if !notifier.IsEnabled() {
			continue
		}

		if err := notifier.Notify(ctx, alert); err != nil {
			lastErr = err
			// Continue trying other notifiers even if one fails
		}
	}

	return lastErr
}

// AddNotifier adds a new notifier to the manager
func (m *AlertManager) AddNotifier(notifier AlertNotifier) {
	m.notifiers = append(m.notifiers, notifier)
}

// Close gracefully shuts down all notifiers
func (m *AlertManager) Close() error {
	var lastErr error
	for _, notifier := range m.notifiers {
		if err := notifier.Close(); err != nil {
			lastErr = err
		}
	}
	return lastErr
}

// Helper functions to create common alerts

// NewLockFailureAlert creates an alert for market lock failures
func NewLockFailureAlert(marketAddr common.Address, err error, context map[string]interface{}) *Alert {
	return &Alert{
		Severity:      AlertSeverityCritical,
		Type:          AlertTypeLockFailure,
		Title:         "Market Lock Failed",
		Message:       "Failed to lock market: " + err.Error(),
		MarketAddress: &marketAddr,
		Error:         err,
		Context:       context,
	}
}

// NewSettleFailureAlert creates an alert for market settlement failures
func NewSettleFailureAlert(marketAddr common.Address, err error, context map[string]interface{}) *Alert {
	return &Alert{
		Severity:      AlertSeverityCritical,
		Type:          AlertTypeSettleFailure,
		Title:         "Market Settlement Failed",
		Message:       "Failed to settle market: " + err.Error(),
		MarketAddress: &marketAddr,
		Error:         err,
		Context:       context,
	}
}

// NewDatabaseFailureAlert creates an alert for database failures
func NewDatabaseFailureAlert(operation string, err error, context map[string]interface{}) *Alert {
	return &Alert{
		Severity: AlertSeverityError,
		Type:     AlertTypeDatabaseFailure,
		Title:    "Database Operation Failed",
		Message:  "Database operation '" + operation + "' failed: " + err.Error(),
		Error:    err,
		Context:  context,
	}
}

// NewRPCFailureAlert creates an alert for RPC/blockchain failures
func NewRPCFailureAlert(operation string, err error, context map[string]interface{}) *Alert {
	return &Alert{
		Severity: AlertSeverityError,
		Type:     AlertTypeRPCFailure,
		Title:    "RPC Operation Failed",
		Message:  "RPC operation '" + operation + "' failed: " + err.Error(),
		Error:    err,
		Context:  context,
	}
}

// NewTransactionFailureAlert creates an alert for transaction failures
func NewTransactionFailureAlert(txHash common.Hash, marketAddr *common.Address, err error, context map[string]interface{}) *Alert {
	return &Alert{
		Severity:      AlertSeverityCritical,
		Type:          AlertTypeTransactionFailure,
		Title:         "Transaction Failed",
		Message:       "Transaction failed: " + err.Error(),
		TxHash:        &txHash,
		MarketAddress: marketAddr,
		Error:         err,
		Context:       context,
	}
}

// NewHighGasPriceAlert creates an alert for high gas prices
func NewHighGasPriceAlert(currentPrice, maxPrice string, context map[string]interface{}) *Alert {
	return &Alert{
		Severity: AlertSeverityWarning,
		Type:     AlertTypeHighGasPrice,
		Title:    "Gas Price Exceeds Maximum",
		Message:  "Current gas price (" + currentPrice + ") exceeds configured maximum (" + maxPrice + ")",
		Context:  context,
	}
}

// NewDataSourceFailureAlert creates an alert for data source failures
func NewDataSourceFailureAlert(source string, err error, context map[string]interface{}) *Alert {
	return &Alert{
		Severity: AlertSeverityError,
		Type:     AlertTypeDataSourceFailure,
		Title:    "Data Source Failure",
		Message:  "Failed to fetch data from " + source + ": " + err.Error(),
		Error:    err,
		Context:  context,
	}
}

// NewTaskExecutionFailureAlert creates an alert for task execution failures
func NewTaskExecutionFailureAlert(taskName string, err error, context map[string]interface{}) *Alert {
	return &Alert{
		Severity: AlertSeverityError,
		Type:     AlertTypeTaskExecutionFailure,
		Title:    "Task Execution Failed",
		Message:  "Task '" + taskName + "' execution failed: " + err.Error(),
		Error:    err,
		Context:  context,
	}
}
