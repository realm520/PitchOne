package query

import (
	"context"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/common"

	"github.com/pitchone/sportsbook/pkg/bindings"
)

// GetMarketInfo 获取市场详情
func (s *Service) GetMarketInfo(ctx context.Context, addr common.Address) (*MarketInfo, error) {
	market, err := bindings.NewMarketBaseV2(addr, s.client)
	if err != nil {
		return nil, fmt.Errorf("初始化市场合约失败: %w", err)
	}

	opts := s.callOpts(ctx)

	// 获取基本信息
	status, err := market.Status(opts)
	if err != nil {
		return nil, fmt.Errorf("获取状态失败: %w", err)
	}

	outcomeCount, err := market.OutcomeCount(opts)
	if err != nil {
		return nil, fmt.Errorf("获取结果数量失败: %w", err)
	}

	// 从 Factory 获取模板 ID
	var templateID [32]byte
	if s.factory != nil {
		templateID, _ = s.factory.MarketTemplate(opts, addr)
	}

	// 查找模板名称
	templateName := "Unknown"
	for name, id := range s.templates.GetAllTemplates() {
		if id == templateID {
			templateName = name
			break
		}
	}

	// 获取开球时间
	var kickoffTime time.Time
	if kickoff, err := market.KickoffTime(opts); err == nil && kickoff != nil && kickoff.Sign() > 0 {
		kickoffTime = time.Unix(kickoff.Int64(), 0)
	}

	// 获取费率
	var feeRate uint64
	if rate, err := market.FeeRate(opts); err == nil && rate != nil {
		feeRate = rate.Uint64()
	}

	// 获取获胜结果（如果已结算）
	winningOutcome := int64(-1)
	if status >= 2 { // Resolved 或更高状态
		if outcome, err := market.WinningOutcome(opts); err == nil && outcome != nil {
			winningOutcome = outcome.Int64()
		}
	}

	// 获取总流动性
	totalLiquidity := big.NewInt(0)
	if liquidity, err := market.TotalLiquidity(opts); err == nil {
		totalLiquidity = liquidity
	}

	return &MarketInfo{
		Address:        addr,
		TemplateID:     templateID,
		TemplateName:   templateName,
		KickoffTime:    kickoffTime,
		Status:         status,
		StatusName:     getStatusName(status),
		OutcomeCount:   outcomeCount.Uint64(),
		WinningOutcome: winningOutcome,
		TotalLiquidity: totalLiquidity,
		FeeRate:        feeRate,
	}, nil
}

// GetMarketPrices 获取市场赔率
func (s *Service) GetMarketPrices(ctx context.Context, addr common.Address) ([]*OutcomePrice, error) {
	market, err := bindings.NewMarketBaseV2(addr, s.client)
	if err != nil {
		return nil, fmt.Errorf("初始化市场合约失败: %w", err)
	}

	opts := s.callOpts(ctx)

	// 获取结果数量
	outcomeCount, err := market.OutcomeCount(opts)
	if err != nil {
		return nil, fmt.Errorf("获取结果数量失败: %w", err)
	}

	// 从 Factory 获取模板 ID 以确定结果名称
	var templateID [32]byte
	if s.factory != nil {
		templateID, _ = s.factory.MarketTemplate(opts, addr)
	}

	templateName := ""
	for name, id := range s.templates.GetAllTemplates() {
		if id == templateID {
			templateName = name
			break
		}
	}

	results := make([]*OutcomePrice, 0, outcomeCount.Uint64())

	// 尝试使用 WDL 模板获取价格
	if templateName == "wdl" {
		wdlMarket, err := bindings.NewWDLTemplate(addr, s.client)
		if err == nil {
			prices, err := wdlMarket.GetAllPrices(opts)
			if err == nil {
				for i, price := range prices {
					odds, impliedProb := calculateOddsFromPrice(price)
					results = append(results, &OutcomePrice{
						OutcomeID:   uint64(i),
						OutcomeName: getOutcomeName(templateName, uint64(i)),
						Price:       price,
						Odds:        odds,
						ImpliedProb: impliedProb,
						Reserve:     big.NewInt(0),
					})
				}
				return results, nil
			}
		}
	}

	// 默认情况：返回基本信息，无价格数据
	for i := uint64(0); i < outcomeCount.Uint64(); i++ {
		results = append(results, &OutcomePrice{
			OutcomeID:   i,
			OutcomeName: getOutcomeName(templateName, i),
			Price:       big.NewInt(0),
			Odds:        0,
			ImpliedProb: 0,
			Reserve:     big.NewInt(0),
		})
	}

	return results, nil
}

// calculateOddsFromPrice 从价格计算赔率和隐含概率
func calculateOddsFromPrice(price *big.Int) (odds float64, impliedProb float64) {
	if price == nil || price.Sign() <= 0 {
		return 0, 0
	}

	divisor := new(big.Float).SetInt(new(big.Int).Exp(big.NewInt(10), big.NewInt(18), nil))
	priceFloat := new(big.Float).SetInt(price)
	prob := new(big.Float).Quo(priceFloat, divisor)
	impliedProb, _ = prob.Float64()

	if impliedProb > 0 {
		odds = 1.0 / impliedProb
	}

	return odds, impliedProb * 100
}

// GetMarketPositions 获取市场头寸分布
func (s *Service) GetMarketPositions(ctx context.Context, addr common.Address) ([]*Position, error) {
	// 这需要通过事件日志或数据库来获取
	// 暂时返回空列表
	return []*Position{}, nil
}

// GetUserMarketPosition 获取用户在特定市场的头寸
func (s *Service) GetUserMarketPosition(ctx context.Context, market common.Address, user common.Address) ([]*Position, error) {
	marketContract, err := bindings.NewMarketBaseV2(market, s.client)
	if err != nil {
		return nil, fmt.Errorf("初始化市场合约失败: %w", err)
	}

	opts := s.callOpts(ctx)

	// 获取结果数量
	outcomeCount, err := marketContract.OutcomeCount(opts)
	if err != nil {
		return nil, fmt.Errorf("获取结果数量失败: %w", err)
	}

	results := make([]*Position, 0)

	for i := uint64(0); i < outcomeCount.Uint64(); i++ {
		balance, err := marketContract.BalanceOf(opts, user, big.NewInt(int64(i)))
		if err != nil {
			continue
		}

		if balance.Sign() > 0 {
			results = append(results, &Position{
				Owner:     user,
				OutcomeID: i,
				Balance:   balance,
			})
		}
	}

	return results, nil
}

// getOutcomeName 根据模板类型获取结果名称
func getOutcomeName(template string, outcomeID uint64) string {
	switch template {
	case "WDL":
		switch outcomeID {
		case 0:
			return "主胜"
		case 1:
			return "平局"
		case 2:
			return "客胜"
		}
	case "OU":
		switch outcomeID {
		case 0:
			return "大球"
		case 1:
			return "小球"
		}
	case "AH":
		switch outcomeID {
		case 0:
			return "主队让球胜"
		case 1:
			return "平局/走盘"
		case 2:
			return "客队让球胜"
		}
	case "OddEven":
		switch outcomeID {
		case 0:
			return "奇数"
		case 1:
			return "偶数"
		}
	}

	return fmt.Sprintf("Outcome %d", outcomeID)
}
