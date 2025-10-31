package keeper

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/smtp"
	"os"
	"strings"
	"time"

	"go.uber.org/zap"
)

// ========================================
// Log Notifier - Always enabled
// ========================================

// LogNotifier sends alerts to structured logs
type LogNotifier struct {
	logger *zap.Logger
}

// NewLogNotifier creates a new log-based notifier
func NewLogNotifier(logger *zap.Logger) *LogNotifier {
	return &LogNotifier{
		logger: logger,
	}
}

// Notify logs the alert
func (n *LogNotifier) Notify(ctx context.Context, alert *Alert) error {
	fields := []zap.Field{
		zap.String("severity", string(alert.Severity)),
		zap.String("type", string(alert.Type)),
		zap.String("title", alert.Title),
		zap.Time("timestamp", alert.Timestamp),
	}

	if alert.MarketAddress != nil {
		fields = append(fields, zap.String("market", alert.MarketAddress.Hex()))
	}

	if alert.TxHash != nil {
		fields = append(fields, zap.String("tx_hash", alert.TxHash.Hex()))
	}

	if alert.Error != nil {
		fields = append(fields, zap.Error(alert.Error))
	}

	// Add context fields
	for key, value := range alert.Context {
		fields = append(fields, zap.Any(key, value))
	}

	// Log at appropriate level based on severity
	switch alert.Severity {
	case AlertSeverityInfo:
		n.logger.Info(alert.Message, fields...)
	case AlertSeverityWarning:
		n.logger.Warn(alert.Message, fields...)
	case AlertSeverityError:
		n.logger.Error(alert.Message, fields...)
	case AlertSeverityCritical:
		n.logger.Error("[CRITICAL] "+alert.Message, fields...)
	default:
		n.logger.Info(alert.Message, fields...)
	}

	return nil
}

// IsEnabled returns true (log notifier is always enabled)
func (n *LogNotifier) IsEnabled() bool {
	return true
}

// Close is a no-op for log notifier
func (n *LogNotifier) Close() error {
	return nil
}

// ========================================
// File Notifier - Optional
// ========================================

// FileNotifier writes alerts to a file
type FileNotifier struct {
	filePath string
	enabled  bool
	logger   *zap.Logger
}

// NewFileNotifier creates a new file-based notifier
func NewFileNotifier(filePath string, logger *zap.Logger) *FileNotifier {
	enabled := filePath != ""
	return &FileNotifier{
		filePath: filePath,
		enabled:  enabled,
		logger:   logger,
	}
}

// Notify writes the alert to file
func (n *FileNotifier) Notify(ctx context.Context, alert *Alert) error {
	if !n.enabled {
		return nil
	}

	// Format alert as JSON
	alertData := map[string]interface{}{
		"timestamp":   alert.Timestamp.Format(time.RFC3339),
		"severity":    alert.Severity,
		"type":        alert.Type,
		"title":       alert.Title,
		"message":     alert.Message,
		"context":     alert.Context,
		"market":      nil,
		"tx_hash":     nil,
		"error":       nil,
	}

	if alert.MarketAddress != nil {
		alertData["market"] = alert.MarketAddress.Hex()
	}

	if alert.TxHash != nil {
		alertData["tx_hash"] = alert.TxHash.Hex()
	}

	if alert.Error != nil {
		alertData["error"] = alert.Error.Error()
	}

	jsonData, err := json.MarshalIndent(alertData, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal alert: %w", err)
	}

	// Append to file
	file, err := os.OpenFile(n.filePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return fmt.Errorf("failed to open alert file: %w", err)
	}
	defer file.Close()

	if _, err := file.Write(append(jsonData, '\n')); err != nil {
		return fmt.Errorf("failed to write alert to file: %w", err)
	}

	return nil
}

// IsEnabled returns whether file notifier is enabled
func (n *FileNotifier) IsEnabled() bool {
	return n.enabled
}

// Close is a no-op for file notifier
func (n *FileNotifier) Close() error {
	return nil
}

// ========================================
// Telegram Notifier - Optional
// ========================================

// TelegramNotifier sends alerts to Telegram
type TelegramNotifier struct {
	botToken string
	chatID   string
	enabled  bool
	client   *http.Client
	logger   *zap.Logger
}

// NewTelegramNotifier creates a new Telegram-based notifier
func NewTelegramNotifier(botToken, chatID string, logger *zap.Logger) *TelegramNotifier {
	enabled := botToken != "" && chatID != ""
	return &TelegramNotifier{
		botToken: botToken,
		chatID:   chatID,
		enabled:  enabled,
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
		logger: logger,
	}
}

// Notify sends the alert to Telegram
func (n *TelegramNotifier) Notify(ctx context.Context, alert *Alert) error {
	if !n.enabled {
		return nil
	}

	// Format message with Markdown
	message := n.formatTelegramMessage(alert)

	// Construct API URL
	apiURL := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", n.botToken)

	// Prepare request body
	requestBody := map[string]interface{}{
		"chat_id":    n.chatID,
		"text":       message,
		"parse_mode": "Markdown",
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return fmt.Errorf("failed to marshal telegram request: %w", err)
	}

	// Create HTTP request
	req, err := http.NewRequestWithContext(ctx, "POST", apiURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create telegram request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	// Send request
	resp, err := n.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send telegram notification: %w", err)
	}
	defer resp.Body.Close()

	// Check response
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("telegram API returned status %d", resp.StatusCode)
	}

	n.logger.Debug("telegram notification sent",
		zap.String("severity", string(alert.Severity)),
		zap.String("type", string(alert.Type)),
	)

	return nil
}

// formatTelegramMessage formats an alert for Telegram
func (n *TelegramNotifier) formatTelegramMessage(alert *Alert) string {
	var sb strings.Builder

	// Emoji based on severity
	emoji := map[AlertSeverity]string{
		AlertSeverityInfo:     "ℹ️",
		AlertSeverityWarning:  "⚠️",
		AlertSeverityError:    "❌",
		AlertSeverityCritical: "🚨",
	}[alert.Severity]

	// Title with emoji
	sb.WriteString(fmt.Sprintf("%s *%s*\n\n", emoji, alert.Title))

	// Severity and type
	sb.WriteString(fmt.Sprintf("*Severity:* %s\n", alert.Severity))
	sb.WriteString(fmt.Sprintf("*Type:* %s\n", alert.Type))

	// Message
	sb.WriteString(fmt.Sprintf("\n%s\n", alert.Message))

	// Additional context
	if alert.MarketAddress != nil {
		sb.WriteString(fmt.Sprintf("\n*Market:* `%s`", alert.MarketAddress.Hex()))
	}

	if alert.TxHash != nil {
		sb.WriteString(fmt.Sprintf("\n*Transaction:* `%s`", alert.TxHash.Hex()))
	}

	// Timestamp
	sb.WriteString(fmt.Sprintf("\n\n*Time:* %s", alert.Timestamp.Format(time.RFC3339)))

	return sb.String()
}

// IsEnabled returns whether telegram notifier is enabled
func (n *TelegramNotifier) IsEnabled() bool {
	return n.enabled
}

// Close is a no-op for telegram notifier
func (n *TelegramNotifier) Close() error {
	return nil
}

// ========================================
// Email Notifier - Optional
// ========================================

// EmailNotifier sends alerts via email
type EmailNotifier struct {
	smtpHost     string
	smtpPort     string
	smtpUser     string
	smtpPassword string
	fromEmail    string
	toEmails     []string
	enabled      bool
	logger       *zap.Logger
}

// EmailConfig holds email notifier configuration
type EmailConfig struct {
	SMTPHost     string   // e.g., "smtp.gmail.com"
	SMTPPort     string   // e.g., "587"
	SMTPUser     string   // SMTP username
	SMTPPassword string   // SMTP password
	FromEmail    string   // Sender email
	ToEmails     []string // Recipient emails
}

// NewEmailNotifier creates a new email-based notifier
func NewEmailNotifier(config EmailConfig, logger *zap.Logger) *EmailNotifier {
	enabled := config.SMTPHost != "" && config.SMTPUser != "" && len(config.ToEmails) > 0
	return &EmailNotifier{
		smtpHost:     config.SMTPHost,
		smtpPort:     config.SMTPPort,
		smtpUser:     config.SMTPUser,
		smtpPassword: config.SMTPPassword,
		fromEmail:    config.FromEmail,
		toEmails:     config.ToEmails,
		enabled:      enabled,
		logger:       logger,
	}
}

// Notify sends the alert via email
func (n *EmailNotifier) Notify(ctx context.Context, alert *Alert) error {
	if !n.enabled {
		return nil
	}

	// Format email
	subject := fmt.Sprintf("[PitchOne Keeper] %s - %s", alert.Severity, alert.Title)
	body := n.formatEmailBody(alert)

	// Construct email message
	message := fmt.Sprintf("From: %s\r\n", n.fromEmail)
	message += fmt.Sprintf("To: %s\r\n", strings.Join(n.toEmails, ", "))
	message += fmt.Sprintf("Subject: %s\r\n", subject)
	message += "Content-Type: text/plain; charset=UTF-8\r\n"
	message += "\r\n"
	message += body

	// SMTP authentication
	auth := smtp.PlainAuth("", n.smtpUser, n.smtpPassword, n.smtpHost)

	// Send email
	addr := fmt.Sprintf("%s:%s", n.smtpHost, n.smtpPort)
	err := smtp.SendMail(addr, auth, n.fromEmail, n.toEmails, []byte(message))
	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}

	n.logger.Debug("email notification sent",
		zap.String("severity", string(alert.Severity)),
		zap.String("type", string(alert.Type)),
		zap.Strings("recipients", n.toEmails),
	)

	return nil
}

// formatEmailBody formats an alert for email
func (n *EmailNotifier) formatEmailBody(alert *Alert) string {
	var sb strings.Builder

	sb.WriteString(fmt.Sprintf("Alert: %s\n", alert.Title))
	sb.WriteString(fmt.Sprintf("Severity: %s\n", alert.Severity))
	sb.WriteString(fmt.Sprintf("Type: %s\n", alert.Type))
	sb.WriteString(fmt.Sprintf("Time: %s\n", alert.Timestamp.Format(time.RFC3339)))
	sb.WriteString("\n")
	sb.WriteString(fmt.Sprintf("Message:\n%s\n", alert.Message))

	if alert.MarketAddress != nil {
		sb.WriteString(fmt.Sprintf("\nMarket: %s\n", alert.MarketAddress.Hex()))
	}

	if alert.TxHash != nil {
		sb.WriteString(fmt.Sprintf("Transaction: %s\n", alert.TxHash.Hex()))
	}

	if alert.Error != nil {
		sb.WriteString(fmt.Sprintf("\nError Details:\n%s\n", alert.Error.Error()))
	}

	if len(alert.Context) > 0 {
		sb.WriteString("\nAdditional Context:\n")
		for key, value := range alert.Context {
			sb.WriteString(fmt.Sprintf("  %s: %v\n", key, value))
		}
	}

	sb.WriteString("\n---\n")
	sb.WriteString("PitchOne Keeper Alert System\n")

	return sb.String()
}

// IsEnabled returns whether email notifier is enabled
func (n *EmailNotifier) IsEnabled() bool {
	return n.enabled
}

// Close is a no-op for email notifier
func (n *EmailNotifier) Close() error {
	return nil
}

// ========================================
// Factory Function
// ========================================

// NewAlertManagerFromEnv creates an AlertManager with notifiers configured from environment variables
func NewAlertManagerFromEnv(logger *zap.Logger) *AlertManager {
	// Log notifier (always enabled)
	logNotifier := NewLogNotifier(logger)

	// File notifier (optional)
	alertFilePath := os.Getenv("KEEPER_ALERT_FILE")
	fileNotifier := NewFileNotifier(alertFilePath, logger)

	// Telegram notifier (optional)
	telegramBotToken := os.Getenv("TELEGRAM_BOT_TOKEN")
	telegramChatID := os.Getenv("TELEGRAM_CHAT_ID")
	telegramNotifier := NewTelegramNotifier(telegramBotToken, telegramChatID, logger)

	// Email notifier (optional)
	emailConfig := EmailConfig{
		SMTPHost:     os.Getenv("SMTP_HOST"),
		SMTPPort:     os.Getenv("SMTP_PORT"),
		SMTPUser:     os.Getenv("SMTP_USER"),
		SMTPPassword: os.Getenv("SMTP_PASSWORD"),
		FromEmail:    os.Getenv("SMTP_FROM_EMAIL"),
		ToEmails:     splitEmailList(os.Getenv("SMTP_TO_EMAILS")),
	}
	emailNotifier := NewEmailNotifier(emailConfig, logger)

	// Log enabled notifiers
	enabledNotifiers := []string{"log"}
	if fileNotifier.IsEnabled() {
		enabledNotifiers = append(enabledNotifiers, "file")
	}
	if telegramNotifier.IsEnabled() {
		enabledNotifiers = append(enabledNotifiers, "telegram")
	}
	if emailNotifier.IsEnabled() {
		enabledNotifiers = append(enabledNotifiers, "email")
	}

	logger.Info("alert notifiers initialized",
		zap.Strings("enabled", enabledNotifiers),
	)

	return NewAlertManager(logNotifier, fileNotifier, telegramNotifier, emailNotifier)
}

// splitEmailList splits a comma-separated email list
func splitEmailList(emails string) []string {
	if emails == "" {
		return nil
	}

	parts := strings.Split(emails, ",")
	result := make([]string, 0, len(parts))
	for _, email := range parts {
		trimmed := strings.TrimSpace(email)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}

	return result
}
