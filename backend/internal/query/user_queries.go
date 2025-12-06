package query

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"

	"github.com/pitchone/sportsbook/pkg/bindings"
)

// GetUserBalance 获取用户 USDC 余额
func (s *Service) GetUserBalance(ctx context.Context, user common.Address) (*big.Int, error) {
	return s.GetUSDCBalance(ctx, user)
}

// GetUserAllPositions 获取用户在所有市场的头寸
func (s *Service) GetUserAllPositions(ctx context.Context, user common.Address) ([]*UserPosition, error) {
	if s.factory == nil {
		return nil, fmt.Errorf("Factory 合约未配置")
	}

	callOpts := s.callOpts(ctx)

	// 获取市场总数
	count, err := s.factory.GetMarketCount(callOpts)
	if err != nil {
		return nil, fmt.Errorf("获取市场数量失败: %w", err)
	}

	results := make([]*UserPosition, 0)

	// 遍历所有市场检查用户头寸
	for i := uint64(0); i < count.Uint64(); i++ {
		marketAddr, err := s.factory.Markets(callOpts, big.NewInt(int64(i)))
		if err != nil {
			continue
		}

		market, err := bindings.NewMarketBaseV2(marketAddr, s.client)
		if err != nil {
			continue
		}

		outcomeCount, err := market.OutcomeCount(callOpts)
		if err != nil {
			continue
		}

		// 获取市场摘要
		summary, _ := s.getMarketSummary(ctx, marketAddr)

		// 检查每个结果的头寸
		for j := uint64(0); j < outcomeCount.Uint64(); j++ {
			balance, err := market.BalanceOf(callOpts, user, big.NewInt(int64(j)))
			if err != nil {
				continue
			}

			if balance.Sign() > 0 {
				results = append(results, &UserPosition{
					Market:      marketAddr,
					MarketInfo:  summary,
					OutcomeID:   j,
					OutcomeName: getOutcomeName(summary.TemplateName, j),
					Balance:     balance,
				})
			}
		}
	}

	return results, nil
}

// GetUserReferralInfo 获取用户推荐信息
func (s *Service) GetUserReferralInfo(ctx context.Context, user common.Address) (*ReferralInfo, error) {
	return s.GetReferralInfo(ctx, user)
}

// GetUserOrders 获取用户订单历史（需要数据库）
func (s *Service) GetUserOrders(ctx context.Context, user common.Address, limit int) ([]*Order, error) {
	if s.db == nil {
		return nil, fmt.Errorf("数据库未配置，无法查询历史订单")
	}

	query := `
		SELECT id, market, outcome_id, amount, shares, price, timestamp, tx_hash
		FROM orders
		WHERE user_address = $1
		ORDER BY timestamp DESC
		LIMIT $2
	`

	rows, err := s.db.QueryContext(ctx, query, user.Hex(), limit)
	if err != nil {
		return nil, fmt.Errorf("查询订单失败: %w", err)
	}
	defer rows.Close()

	results := make([]*Order, 0)

	for rows.Next() {
		var order Order
		var marketHex, txHashHex string

		err := rows.Scan(
			&order.ID,
			&marketHex,
			&order.OutcomeID,
			&order.Amount,
			&order.Shares,
			&order.Price,
			&order.Timestamp,
			&txHashHex,
		)
		if err != nil {
			continue
		}

		order.User = user
		order.Market = common.HexToAddress(marketHex)
		order.TxHash = common.HexToHash(txHashHex)

		results = append(results, &order)
	}

	return results, nil
}

// GetUserRewards 获取用户奖励状态（需要数据库）
func (s *Service) GetUserRewards(ctx context.Context, user common.Address) (*big.Int, error) {
	if s.db == nil {
		return nil, fmt.Errorf("数据库未配置，无法查询奖励")
	}

	query := `
		SELECT COALESCE(SUM(amount), 0)
		FROM rewards
		WHERE user_address = $1 AND claimed = false
	`

	var total big.Int
	err := s.db.QueryRowContext(ctx, query, user.Hex()).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("查询奖励失败: %w", err)
	}

	return &total, nil
}
