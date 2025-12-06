package query

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"

	"github.com/pitchone/sportsbook/pkg/bindings"
)

// GetFactoryInfo 获取工厂信息
func (s *Service) GetFactoryInfo(ctx context.Context) (*FactoryInfo, error) {
	if s.factory == nil {
		return nil, fmt.Errorf("Factory 合约未配置")
	}

	opts := s.callOpts(ctx)

	marketCount, err := s.factory.GetMarketCount(opts)
	if err != nil {
		return nil, fmt.Errorf("获取市场数量失败: %w", err)
	}

	return &FactoryInfo{
		Address:     s.contracts.Factory,
		MarketCount: marketCount.Uint64(),
	}, nil
}

// ListTemplates 列出所有模板
func (s *Service) ListTemplates(ctx context.Context) ([]*TemplateInfo, error) {
	templates := s.templates.GetAllTemplates()
	result := make([]*TemplateInfo, 0, len(templates))

	for name, id := range templates {
		if isZeroBytes32(id) {
			continue
		}

		info := &TemplateInfo{
			ID:     id,
			Name:   name,
			Active: true, // 假设所有配置的模板都是激活的
		}

		// 如果 Factory 可用，尝试获取更多信息
		if s.factory != nil {
			opts := s.callOpts(ctx)
			templateInfo, err := s.factory.Templates(opts, id)
			if err == nil {
				info.Implementation = templateInfo.Implementation
				info.Active = templateInfo.Active
			}
		}

		result = append(result, info)
	}

	return result, nil
}

// GetTemplateInfo 获取单个模板信息
func (s *Service) GetTemplateInfo(ctx context.Context, templateID [32]byte) (*TemplateInfo, error) {
	if s.factory == nil {
		return nil, fmt.Errorf("Factory 合约未配置")
	}

	opts := s.callOpts(ctx)

	templateInfo, err := s.factory.Templates(opts, templateID)
	if err != nil {
		return nil, fmt.Errorf("获取模板信息失败: %w", err)
	}

	// 查找模板名称
	name := "Unknown"
	for n, id := range s.templates.GetAllTemplates() {
		if id == templateID {
			name = n
			break
		}
	}

	return &TemplateInfo{
		ID:             templateID,
		Name:           name,
		Implementation: templateInfo.Implementation,
		Active:         templateInfo.Active,
	}, nil
}

// ListMarkets 列出市场
func (s *Service) ListMarkets(ctx context.Context, opts *ListMarketsOptions) ([]*MarketSummary, error) {
	if s.factory == nil {
		return nil, fmt.Errorf("Factory 合约未配置")
	}

	callOpts := s.callOpts(ctx)

	// 获取市场总数
	count, err := s.factory.GetMarketCount(callOpts)
	if err != nil {
		return nil, fmt.Errorf("获取市场数量失败: %w", err)
	}

	if count.Uint64() == 0 {
		return []*MarketSummary{}, nil
	}

	// 设置默认分页
	limit := uint64(20)
	offset := uint64(0)
	if opts != nil {
		if opts.Limit > 0 && opts.Limit <= 100 {
			limit = opts.Limit
		}
		offset = opts.Offset
	}

	// 计算结束索引
	end := offset + limit
	total := count.Uint64()
	if end > total {
		end = total
	}

	result := make([]*MarketSummary, 0, end-offset)

	// 遍历市场
	for i := offset; i < end; i++ {
		marketAddr, err := s.factory.Markets(callOpts, big.NewInt(int64(i)))
		if err != nil {
			continue
		}

		summary, err := s.getMarketSummary(ctx, marketAddr)
		if err != nil {
			continue
		}

		// 应用过滤条件
		if opts != nil {
			if opts.Status != nil && summary.Status != *opts.Status {
				continue
			}
			if opts.TemplateID != nil && summary.TemplateID != *opts.TemplateID {
				continue
			}
		}

		result = append(result, summary)
	}

	return result, nil
}

// getMarketSummary 获取市场摘要
func (s *Service) getMarketSummary(ctx context.Context, addr common.Address) (*MarketSummary, error) {
	market, err := bindings.NewMarketBaseV2(addr, s.client)
	if err != nil {
		return nil, err
	}

	opts := s.callOpts(ctx)

	status, err := market.Status(opts)
	if err != nil {
		return nil, err
	}

	// 从 Factory 获取模板 ID
	var templateID [32]byte
	if s.factory != nil {
		templateID, err = s.factory.MarketTemplate(opts, addr)
		if err != nil {
			// 某些市场可能没有 templateId，使用零值
			templateID = [32]byte{}
		}
	}

	// 查找模板名称
	templateName := "Unknown"
	for name, id := range s.templates.GetAllTemplates() {
		if id == templateID {
			templateName = name
			break
		}
	}

	return &MarketSummary{
		Address:      addr,
		TemplateID:   templateID,
		TemplateName: templateName,
		Status:       status,
		StatusName:   getStatusName(status),
	}, nil
}

// GetMarketCount 获取市场数量
func (s *Service) GetMarketCount(ctx context.Context) (uint64, error) {
	if s.factory == nil {
		return 0, fmt.Errorf("Factory 合约未配置")
	}

	count, err := s.factory.GetMarketCount(s.callOpts(ctx))
	if err != nil {
		return 0, err
	}

	return count.Uint64(), nil
}

// GetMarketsByStatus 按状态统计市场
func (s *Service) GetMarketsByStatus(ctx context.Context) (map[string]uint64, error) {
	if s.factory == nil {
		return nil, fmt.Errorf("Factory 合约未配置")
	}

	callOpts := s.callOpts(ctx)
	count, err := s.factory.GetMarketCount(callOpts)
	if err != nil {
		return nil, err
	}

	stats := map[string]uint64{
		"Open":      0,
		"Locked":    0,
		"Resolved":  0,
		"Finalized": 0,
		"Cancelled": 0,
	}

	for i := uint64(0); i < count.Uint64(); i++ {
		marketAddr, err := s.factory.Markets(callOpts, big.NewInt(int64(i)))
		if err != nil {
			continue
		}

		market, err := bindings.NewMarketBaseV2(marketAddr, s.client)
		if err != nil {
			continue
		}

		status, err := market.Status(callOpts)
		if err != nil {
			continue
		}

		statusName := getStatusName(status)
		stats[statusName]++
	}

	return stats, nil
}

// getStatusName 获取状态名称
func getStatusName(status uint8) string {
	switch status {
	case 0:
		return "Open"
	case 1:
		return "Locked"
	case 2:
		return "Resolved"
	case 3:
		return "Finalized"
	case 4:
		return "Cancelled"
	default:
		return fmt.Sprintf("Unknown(%d)", status)
	}
}
