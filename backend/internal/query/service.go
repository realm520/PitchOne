package query

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/spf13/viper"

	"github.com/pitchone/sportsbook/pkg/bindings"
)

// Service 查询服务
type Service struct {
	client *ethclient.Client
	db     *sql.DB // 可选

	// 配置
	network   string
	chainID   int64
	contracts ContractAddresses
	templates TemplateIDs

	// 合约实例缓存
	usdc     *bindings.IERC20
	provider *bindings.ERC4626LiquidityProvider
	factory  *bindings.MarketFactory
	feeRouter *bindings.FeeRouter
	referral *bindings.ReferralRegistry
}

// NewService 创建查询服务
func NewService(ctx context.Context) (*Service, error) {
	rpcURL := viper.GetString("rpc_url")
	if rpcURL == "" {
		return nil, fmt.Errorf("RPC URL 未配置")
	}

	client, err := ethclient.DialContext(ctx, rpcURL)
	if err != nil {
		return nil, fmt.Errorf("连接 RPC 失败: %w", err)
	}

	s := &Service{
		client:  client,
		network: viper.GetString("network"),
		chainID: viper.GetInt64("chain_id"),
	}

	// 加载合约地址
	s.contracts = ContractAddresses{
		USDC:               common.HexToAddress(viper.GetString("contracts.usdc")),
		Vault:              common.HexToAddress(viper.GetString("contracts.vault")),
		ERC4626Provider:    common.HexToAddress(viper.GetString("contracts.erc4626_provider")),
		ParimutuelProvider: common.HexToAddress(viper.GetString("contracts.parimutuel_provider")),
		ProviderFactory:    common.HexToAddress(viper.GetString("contracts.provider_factory")),
		CPMM:               common.HexToAddress(viper.GetString("contracts.cpmm")),
		Parimutuel:         common.HexToAddress(viper.GetString("contracts.parimutuel")),
		ReferralRegistry:   common.HexToAddress(viper.GetString("contracts.referral_registry")),
		FeeRouter:          common.HexToAddress(viper.GetString("contracts.fee_router")),
		Factory:            common.HexToAddress(viper.GetString("contracts.factory")),
	}

	// 加载模板 ID
	s.templates = TemplateIDs{
		WDL:         parseBytes32(viper.GetString("templates.wdl")),
		OU:          parseBytes32(viper.GetString("templates.ou")),
		OUMultiLine: parseBytes32(viper.GetString("templates.ou_multi_line")),
		AH:          parseBytes32(viper.GetString("templates.ah")),
		OddEven:     parseBytes32(viper.GetString("templates.odd_even")),
		Score:       parseBytes32(viper.GetString("templates.score")),
		PlayerProps: parseBytes32(viper.GetString("templates.player_props")),
	}

	// 初始化合约实例
	if err := s.initContracts(); err != nil {
		return nil, err
	}

	// 可选：连接数据库
	dbURL := viper.GetString("database.url")
	if dbURL != "" {
		db, err := sql.Open("postgres", dbURL)
		if err == nil {
			s.db = db
		}
	}

	return s, nil
}

// initContracts 初始化合约实例
func (s *Service) initContracts() error {
	var err error

	// USDC
	if s.contracts.USDC != (common.Address{}) {
		s.usdc, err = bindings.NewIERC20(s.contracts.USDC, s.client)
		if err != nil {
			return fmt.Errorf("初始化 USDC 合约失败: %w", err)
		}
	}

	// ERC4626Provider
	if s.contracts.ERC4626Provider != (common.Address{}) {
		s.provider, err = bindings.NewERC4626LiquidityProvider(s.contracts.ERC4626Provider, s.client)
		if err != nil {
			return fmt.Errorf("初始化 ERC4626Provider 合约失败: %w", err)
		}
	}

	// Factory
	if s.contracts.Factory != (common.Address{}) {
		s.factory, err = bindings.NewMarketFactory(s.contracts.Factory, s.client)
		if err != nil {
			return fmt.Errorf("初始化 Factory 合约失败: %w", err)
		}
	}

	// FeeRouter
	if s.contracts.FeeRouter != (common.Address{}) {
		s.feeRouter, err = bindings.NewFeeRouter(s.contracts.FeeRouter, s.client)
		if err != nil {
			return fmt.Errorf("初始化 FeeRouter 合约失败: %w", err)
		}
	}

	// ReferralRegistry
	if s.contracts.ReferralRegistry != (common.Address{}) {
		s.referral, err = bindings.NewReferralRegistry(s.contracts.ReferralRegistry, s.client)
		if err != nil {
			return fmt.Errorf("初始化 ReferralRegistry 合约失败: %w", err)
		}
	}

	return nil
}

// Close 关闭服务
func (s *Service) Close() {
	if s.client != nil {
		s.client.Close()
	}
	if s.db != nil {
		s.db.Close()
	}
}

// GetNetwork 获取网络名称
func (s *Service) GetNetwork() string {
	return s.network
}

// GetChainID 获取链 ID
func (s *Service) GetChainID() int64 {
	return s.chainID
}

// GetContractAddresses 获取所有合约地址
func (s *Service) GetContractAddresses() *ContractAddresses {
	return &s.contracts
}

// GetTemplateIDs 获取所有模板 ID
func (s *Service) GetTemplateIDs() *TemplateIDs {
	return &s.templates
}

// callOpts 返回默认调用选项
func (s *Service) callOpts(ctx context.Context) *bind.CallOpts {
	return &bind.CallOpts{Context: ctx}
}

// parseBytes32 解析 bytes32 字符串
func parseBytes32(s string) [32]byte {
	var result [32]byte
	s = strings.TrimPrefix(s, "0x")
	if len(s) == 64 {
		bytes := common.Hex2Bytes(s)
		copy(result[:], bytes)
	}
	return result
}

// formatBytes32 格式化 bytes32 为字符串
func formatBytes32(b [32]byte) string {
	return "0x" + common.Bytes2Hex(b[:])
}

// isZeroAddress 检查是否为零地址
func isZeroAddress(addr common.Address) bool {
	return addr == common.Address{}
}

// isZeroBytes32 检查是否为零 bytes32
func isZeroBytes32(b [32]byte) bool {
	return b == [32]byte{}
}
