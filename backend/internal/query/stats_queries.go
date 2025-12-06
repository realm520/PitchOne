package query

import (
	"context"
	"fmt"
	"math/big"
)

// GetPlatformStats 获取平台统计（需要数据库）
func (s *Service) GetPlatformStats(ctx context.Context) (*PlatformStats, error) {
	stats := &PlatformStats{
		TotalVolume:    big.NewInt(0),
		TotalFees:      big.NewInt(0),
		TotalLiquidity: big.NewInt(0),
	}

	// 从链上获取市场数量
	if s.factory != nil {
		count, err := s.factory.GetMarketCount(s.callOpts(ctx))
		if err == nil {
			stats.TotalMarkets = count.Uint64()
		}

		// 统计活跃市场
		statusStats, err := s.GetMarketsByStatus(ctx)
		if err == nil {
			stats.ActiveMarkets = statusStats["Open"]
		}
	}

	// 从链上获取总流动性
	if s.provider != nil {
		totalAssets, err := s.provider.TotalAssets(s.callOpts(ctx))
		if err == nil {
			stats.TotalLiquidity = totalAssets
		}
	}

	// 如果有数据库，获取更多统计
	if s.db != nil {
		// 总交易量
		var volume big.Int
		err := s.db.QueryRowContext(ctx, "SELECT COALESCE(SUM(amount), 0) FROM orders").Scan(&volume)
		if err == nil {
			stats.TotalVolume = &volume
		}

		// 总用户数
		var users uint64
		err = s.db.QueryRowContext(ctx, "SELECT COUNT(DISTINCT user_address) FROM orders").Scan(&users)
		if err == nil {
			stats.TotalUsers = users
		}
	}

	return stats, nil
}

// GetVolumeStats 获取交易量统计（需要数据库）
func (s *Service) GetVolumeStats(ctx context.Context, period string) ([]*VolumeData, error) {
	if s.db == nil {
		return nil, fmt.Errorf("数据库未配置，无法查询交易量统计")
	}

	var query string
	switch period {
	case "daily":
		query = `
			SELECT
				DATE(timestamp) as period,
				COALESCE(SUM(amount), 0) as volume,
				COUNT(*) as order_count,
				COUNT(DISTINCT user_address) as unique_users
			FROM orders
			WHERE timestamp >= NOW() - INTERVAL '30 days'
			GROUP BY DATE(timestamp)
			ORDER BY period DESC
		`
	case "weekly":
		query = `
			SELECT
				DATE_TRUNC('week', timestamp) as period,
				COALESCE(SUM(amount), 0) as volume,
				COUNT(*) as order_count,
				COUNT(DISTINCT user_address) as unique_users
			FROM orders
			WHERE timestamp >= NOW() - INTERVAL '12 weeks'
			GROUP BY DATE_TRUNC('week', timestamp)
			ORDER BY period DESC
		`
	case "monthly":
		query = `
			SELECT
				DATE_TRUNC('month', timestamp) as period,
				COALESCE(SUM(amount), 0) as volume,
				COUNT(*) as order_count,
				COUNT(DISTINCT user_address) as unique_users
			FROM orders
			WHERE timestamp >= NOW() - INTERVAL '12 months'
			GROUP BY DATE_TRUNC('month', timestamp)
			ORDER BY period DESC
		`
	default:
		return nil, fmt.Errorf("无效的时间周期: %s (支持: daily, weekly, monthly)", period)
	}

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("查询交易量失败: %w", err)
	}
	defer rows.Close()

	results := make([]*VolumeData, 0)

	for rows.Next() {
		var data VolumeData
		var volume big.Int

		err := rows.Scan(&data.Period, &volume, &data.OrderCount, &data.UniqueUsers)
		if err != nil {
			continue
		}

		data.Volume = &volume
		results = append(results, &data)
	}

	return results, nil
}

// GetTopMarkets 获取热门市场（需要数据库）
func (s *Service) GetTopMarkets(ctx context.Context, limit int) ([]*MarketSummary, error) {
	if s.db == nil {
		// 如果没有数据库，返回最近创建的市场
		return s.ListMarkets(ctx, &ListMarketsOptions{
			Limit: uint64(limit),
		})
	}

	query := `
		SELECT market, SUM(amount) as total_volume
		FROM orders
		WHERE timestamp >= NOW() - INTERVAL '7 days'
		GROUP BY market
		ORDER BY total_volume DESC
		LIMIT $1
	`

	rows, err := s.db.QueryContext(ctx, query, limit)
	if err != nil {
		return nil, fmt.Errorf("查询热门市场失败: %w", err)
	}
	defer rows.Close()

	results := make([]*MarketSummary, 0)

	for rows.Next() {
		var marketHex string
		var volume big.Int

		err := rows.Scan(&marketHex, &volume)
		if err != nil {
			continue
		}

		summary, err := s.getMarketSummary(ctx, parseAddress(marketHex))
		if err != nil {
			continue
		}

		results = append(results, summary)
	}

	return results, nil
}

// parseAddress 解析地址
func parseAddress(hex string) (addr [20]byte) {
	bytes := []byte(hex)
	if len(bytes) > 2 && bytes[0] == '0' && bytes[1] == 'x' {
		bytes = bytes[2:]
	}
	for i := 0; i < len(bytes) && i < 40; i++ {
		addr[i/2] |= hexToByte(bytes[i]) << (4 * (1 - uint(i%2)))
	}
	return
}

func hexToByte(b byte) byte {
	switch {
	case b >= '0' && b <= '9':
		return b - '0'
	case b >= 'a' && b <= 'f':
		return b - 'a' + 10
	case b >= 'A' && b <= 'F':
		return b - 'A' + 10
	}
	return 0
}
