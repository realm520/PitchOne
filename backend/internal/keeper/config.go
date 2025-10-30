package keeper

import (
	"errors"
	"fmt"
)

// Config holds Keeper service configuration
type Config struct {
	// Blockchain settings
	ChainID     int64  `mapstructure:"chain_id"`
	RPCEndpoint string `mapstructure:"rpc_endpoint"`
	PrivateKey  string `mapstructure:"private_key"`

	// Gas settings
	GasLimit    uint64 `mapstructure:"gas_limit"`
	MaxGasPrice string `mapstructure:"max_gas_price"` // In Gwei

	// Task settings
	TaskInterval  int `mapstructure:"task_interval"`   // Seconds between task runs
	LockLeadTime  int `mapstructure:"lock_lead_time"`  // Seconds before match to lock
	FinalizeDelay int `mapstructure:"finalize_delay"`  // Seconds to wait after resolution
	MaxConcurrent int `mapstructure:"max_concurrent"`  // Max concurrent tasks
	RetryAttempts int `mapstructure:"retry_attempts"`  // Max retry attempts
	RetryDelay    int `mapstructure:"retry_delay"`     // Seconds between retries

	// Database
	DatabaseURL string `mapstructure:"database_url"`

	// Monitoring
	HealthCheckPort int  `mapstructure:"health_check_port"`
	MetricsPort     int  `mapstructure:"metrics_port"`
	AlertsEnabled   bool `mapstructure:"alerts_enabled"`

	// Telegram alerts (optional)
	TelegramBotToken string `mapstructure:"telegram_bot_token"`
	TelegramChatID   string `mapstructure:"telegram_chat_id"`

	// Webhook alerts (optional)
	WebhookURL string `mapstructure:"webhook_url"`
}

// Validate validates the configuration
func (c *Config) Validate() error {
	if c.ChainID == 0 {
		return errors.New("chain_id is required")
	}

	if c.RPCEndpoint == "" {
		return errors.New("rpc_endpoint is required")
	}

	if c.PrivateKey == "" {
		return errors.New("private_key is required")
	}

	if c.GasLimit == 0 {
		c.GasLimit = 500000 // Default gas limit
	}

	if c.MaxGasPrice == "" {
		c.MaxGasPrice = "100" // Default 100 Gwei
	}

	if c.TaskInterval == 0 {
		c.TaskInterval = 60 // Default 60 seconds
	}

	if c.LockLeadTime == 0 {
		c.LockLeadTime = 300 // Default 5 minutes
	}

	if c.FinalizeDelay == 0 {
		c.FinalizeDelay = 7200 // Default 2 hours
	}

	if c.MaxConcurrent == 0 {
		c.MaxConcurrent = 10 // Default 10 concurrent tasks
	}

	if c.RetryAttempts == 0 {
		c.RetryAttempts = 3 // Default 3 retries
	}

	if c.RetryDelay == 0 {
		c.RetryDelay = 5 // Default 5 seconds
	}

	if c.DatabaseURL == "" {
		return errors.New("database_url is required")
	}

	if c.HealthCheckPort == 0 {
		c.HealthCheckPort = 8081 // Default port
	}

	if c.MetricsPort == 0 {
		c.MetricsPort = 9091 // Default port
	}

	return nil
}

// String returns a sanitized string representation of the config
// (hides sensitive fields like private key)
func (c *Config) String() string {
	return fmt.Sprintf(
		"Config{ChainID: %d, RPC: %s, GasLimit: %d, MaxGasPrice: %s, TaskInterval: %ds, DatabaseURL: %s}",
		c.ChainID,
		c.RPCEndpoint,
		c.GasLimit,
		c.MaxGasPrice,
		c.TaskInterval,
		maskDatabaseURL(c.DatabaseURL),
	)
}

// maskDatabaseURL masks the password in database URL
func maskDatabaseURL(url string) string {
	// Simple masking for display purposes
	// Example: "postgresql://user:password@host/db" -> "postgresql://user:***@host/db"
	if url == "" {
		return ""
	}

	// Find password section (between : and @)
	var masked string
	inPassword := false
	for i, c := range url {
		if c == ':' && i > 0 && url[i-1] != '/' {
			inPassword = true
			masked += string(c)
			continue
		}
		if c == '@' {
			inPassword = false
		}
		if inPassword {
			masked += "*"
		} else {
			masked += string(c)
		}
	}

	return masked
}
