package db

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
	"go.uber.org/zap"
)

// Client PostgreSQL 数据库客户端
type Client struct {
	db     *sql.DB
	logger *zap.Logger
}

// Config 数据库配置
type Config struct {
	Host            string
	Port            int
	User            string
	Password        string
	DBName          string
	SSLMode         string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
	QueryTimeout    time.Duration
}

// NewClient 创建数据库客户端
func NewClient(cfg Config, logger *zap.Logger) (*Client, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName, cfg.SSLMode,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// 设置连接池参数
	db.SetMaxOpenConns(cfg.MaxOpenConns)
	db.SetMaxIdleConns(cfg.MaxIdleConns)
	db.SetConnMaxLifetime(cfg.ConnMaxLifetime)

	// 测试连接
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	logger.Info("database connected",
		zap.String("host", cfg.Host),
		zap.Int("port", cfg.Port),
		zap.String("dbname", cfg.DBName),
	)

	return &Client{
		db:     db,
		logger: logger,
	}, nil
}

// Close 关闭数据库连接
func (c *Client) Close() error {
	return c.db.Close()
}

// DB 获取底层 sql.DB 实例
func (c *Client) DB() *sql.DB {
	return c.db
}

// BeginTx 开始事务
func (c *Client) BeginTx(ctx context.Context) (*sql.Tx, error) {
	return c.db.BeginTx(ctx, nil)
}

// GetLastProcessedBlock 获取最后处理的区块
func (c *Client) GetLastProcessedBlock(ctx context.Context) (uint64, error) {
	var blockNumber sql.NullInt64
	query := `SELECT last_processed_block FROM indexer_state WHERE id = 1`

	err := c.db.QueryRowContext(ctx, query).Scan(&blockNumber)
	if err == sql.ErrNoRows {
		// 首次启动，返回 0
		return 0, nil
	}
	if err != nil {
		return 0, fmt.Errorf("failed to get last processed block: %w", err)
	}

	if !blockNumber.Valid {
		return 0, nil
	}

	return uint64(blockNumber.Int64), nil
}

// UpdateLastProcessedBlock 更新最后处理的区块
func (c *Client) UpdateLastProcessedBlock(ctx context.Context, blockNumber uint64) error {
	query := `
		INSERT INTO indexer_state (id, last_processed_block, updated_at)
		VALUES (1, $1, $2)
		ON CONFLICT (id) DO UPDATE
		SET last_processed_block = EXCLUDED.last_processed_block,
		    updated_at = EXCLUDED.updated_at
	`

	_, err := c.db.ExecContext(ctx, query, blockNumber, time.Now())
	if err != nil {
		return fmt.Errorf("failed to update last processed block: %w", err)
	}

	return nil
}

// Health 健康检查
func (c *Client) Health(ctx context.Context) error {
	return c.db.PingContext(ctx)
}
