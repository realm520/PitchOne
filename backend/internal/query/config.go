package query

import (
	"github.com/ethereum/go-ethereum/common"
)

// NetworkConfig 网络配置
type NetworkConfig struct {
	Network   string `mapstructure:"network"`
	ChainID   int64  `mapstructure:"chain_id"`
	RPCURL    string `mapstructure:"rpc_url"`
	Database  DatabaseConfig
	Contracts ContractAddresses
	Templates TemplateIDs
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	URL string `mapstructure:"url"`
}

// ContractAddresses 合约地址
type ContractAddresses struct {
	USDC               common.Address `mapstructure:"usdc"`
	Vault              common.Address `mapstructure:"vault"`
	ERC4626Provider    common.Address `mapstructure:"erc4626_provider"`
	ParimutuelProvider common.Address `mapstructure:"parimutuel_provider"`
	ProviderFactory    common.Address `mapstructure:"provider_factory"`
	CPMM               common.Address `mapstructure:"cpmm"`
	Parimutuel         common.Address `mapstructure:"parimutuel"`
	ReferralRegistry   common.Address `mapstructure:"referral_registry"`
	FeeRouter          common.Address `mapstructure:"fee_router"`
	Factory            common.Address `mapstructure:"factory"`
}

// TemplateIDs 模板 ID
type TemplateIDs struct {
	WDL         [32]byte `mapstructure:"wdl"`
	OU          [32]byte `mapstructure:"ou"`
	OUMultiLine [32]byte `mapstructure:"ou_multi_line"`
	AH          [32]byte `mapstructure:"ah"`
	OddEven     [32]byte `mapstructure:"odd_even"`
	Score       [32]byte `mapstructure:"score"`
	PlayerProps [32]byte `mapstructure:"player_props"`
}

// GetAllContracts 返回所有合约地址的 map
func (c *ContractAddresses) GetAllContracts() map[string]common.Address {
	return map[string]common.Address{
		"USDC":               c.USDC,
		"Vault":              c.Vault,
		"ERC4626Provider":    c.ERC4626Provider,
		"ParimutuelProvider": c.ParimutuelProvider,
		"ProviderFactory":    c.ProviderFactory,
		"CPMM":               c.CPMM,
		"Parimutuel":         c.Parimutuel,
		"ReferralRegistry":   c.ReferralRegistry,
		"FeeRouter":          c.FeeRouter,
		"Factory":            c.Factory,
	}
}

// GetAllTemplates 返回所有模板 ID 的 map
func (t *TemplateIDs) GetAllTemplates() map[string][32]byte {
	return map[string][32]byte{
		"WDL":         t.WDL,
		"OU":          t.OU,
		"OUMultiLine": t.OUMultiLine,
		"AH":          t.AH,
		"OddEven":     t.OddEven,
		"Score":       t.Score,
		"PlayerProps": t.PlayerProps,
	}
}
