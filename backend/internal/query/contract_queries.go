package query

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// GetUSDCInfo 获取 USDC 信息
func (s *Service) GetUSDCInfo(ctx context.Context) (*USDCInfo, error) {
	if s.usdc == nil {
		return nil, fmt.Errorf("USDC 合约未配置")
	}

	opts := s.callOpts(ctx)

	totalSupply, err := s.usdc.TotalSupply(opts)
	if err != nil {
		return nil, fmt.Errorf("获取总供应量失败: %w", err)
	}

	return &USDCInfo{
		TotalSupply: totalSupply,
		Decimals:    6,
		Symbol:      "USDC",
		Name:        "USD Coin",
	}, nil
}

// GetUSDCBalance 获取 USDC 余额
func (s *Service) GetUSDCBalance(ctx context.Context, addr common.Address) (*big.Int, error) {
	if s.usdc == nil {
		return nil, fmt.Errorf("USDC 合约未配置")
	}

	return s.usdc.BalanceOf(s.callOpts(ctx), addr)
}

// GetVaultInfo 获取 Vault 信息
func (s *Service) GetVaultInfo(ctx context.Context) (*VaultInfo, error) {
	if s.provider == nil {
		return nil, fmt.Errorf("ERC4626Provider 合约未配置")
	}

	opts := s.callOpts(ctx)

	totalAssets, err := s.provider.TotalAssets(opts)
	if err != nil {
		return nil, fmt.Errorf("获取总资产失败: %w", err)
	}

	totalShares, err := s.provider.TotalSupply(opts)
	if err != nil {
		return nil, fmt.Errorf("获取总份额失败: %w", err)
	}

	// 尝试获取可用流动性（如果合约支持）
	availableLiquidity := totalAssets // 默认等于总资产

	// 计算利用率
	var utilization float64
	if totalAssets.Sign() > 0 {
		borrowed := new(big.Int).Sub(totalAssets, availableLiquidity)
		util := new(big.Float).Quo(
			new(big.Float).SetInt(borrowed),
			new(big.Float).SetInt(totalAssets),
		)
		utilization, _ = util.Float64()
		utilization *= 100
	}

	return &VaultInfo{
		TotalAssets:        totalAssets,
		TotalShares:        totalShares,
		AvailableLiquidity: availableLiquidity,
		Utilization:        utilization,
	}, nil
}

// GetFeeRouterConfig 获取费用路由配置
func (s *Service) GetFeeRouterConfig(ctx context.Context) (*FeeRouterConfig, error) {
	if s.feeRouter == nil {
		return nil, fmt.Errorf("FeeRouter 合约未配置")
	}

	opts := s.callOpts(ctx)

	// 获取费用分配比例
	feeSplit, err := s.feeRouter.FeeSplit(opts)
	if err != nil {
		return nil, fmt.Errorf("获取费用分配比例失败: %w", err)
	}

	// 获取接收地址
	recipients, err := s.feeRouter.Recipients(opts)
	if err != nil {
		return nil, fmt.Errorf("获取接收地址失败: %w", err)
	}

	return &FeeRouterConfig{
		LpBps:        feeSplit.LpBps,
		PromoBps:     feeSplit.PromoBps,
		InsuranceBps: feeSplit.InsuranceBps,
		TreasuryBps:  feeSplit.TreasuryBps,
		LpVault:      recipients.LpVault,
		PromoPool:    recipients.PromoPool,
		Insurance:    recipients.InsuranceFund,
		Treasury:     recipients.Treasury,
	}, nil
}

// GetReferralInfo 获取用户推荐信息
func (s *Service) GetReferralInfo(ctx context.Context, user common.Address) (*ReferralInfo, error) {
	if s.referral == nil {
		return nil, fmt.Errorf("ReferralRegistry 合约未配置")
	}

	opts := s.callOpts(ctx)

	// 获取推荐人
	referrer, err := s.referral.Referrer(opts, user)
	if err != nil {
		return nil, fmt.Errorf("获取推荐人失败: %w", err)
	}

	// 获取下级数量
	referralCount, err := s.referral.ReferralCount(opts, user)
	if err != nil {
		return nil, fmt.Errorf("获取下级数量失败: %w", err)
	}

	// 获取总奖励
	totalRewards, err := s.referral.TotalReferralRewards(opts, user)
	if err != nil {
		totalRewards = big.NewInt(0) // 如果获取失败，默认为 0
	}

	hasReferrer := referrer != (common.Address{})

	return &ReferralInfo{
		User:          user,
		Referrer:      referrer,
		HasReferrer:   hasReferrer,
		ReferralCount: referralCount.Uint64(),
		TotalRewards:  totalRewards,
	}, nil
}
