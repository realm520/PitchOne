package cli

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/charmbracelet/lipgloss"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/pitchone/sportsbook/internal/query"
	"github.com/pitchone/sportsbook/pkg/output"
)

// contractCmd 合约命令
var contractCmd = &cobra.Command{
	Use:   "contract",
	Short: "核心合约查询",
	Long:  `查询核心合约状态，包括 USDC、Vault、FeeRouter、Referral 等。`,
}

// contractInfoCmd 显示所有合约地址
var contractInfoCmd = &cobra.Command{
	Use:   "info",
	Short: "显示所有合约地址",
	Long:  `显示当前网络的所有核心合约地址。`,
	Run: func(cmd *cobra.Command, args []string) {
		format := GetOutput()

		network := viper.GetString("network")
		chainID := viper.GetInt64("chain_id")

		// 品牌色样式
		titleStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color("#00D4AA")).
			Bold(true)

		subtitleStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color("#9CA3AF"))

		// 网络徽章
		var badgeBg lipgloss.Color
		switch network {
		case "mainnet":
			badgeBg = lipgloss.Color("#10B981")
		case "testnet":
			badgeBg = lipgloss.Color("#F59E0B")
		default:
			badgeBg = lipgloss.Color("#7C3AED")
		}
		networkBadge := lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FFFFFF")).
			Background(badgeBg).
			Padding(0, 1).
			Bold(true).
			Render(network)

		fmt.Println()
		fmt.Println(titleStyle.Render("⚽ PitchOne Contract Addresses"))
		fmt.Printf("%s  %s\n\n", networkBadge, subtitleStyle.Render(fmt.Sprintf("Chain ID: %d", chainID)))

		contracts := [][]string{
			{"USDC", viper.GetString("contracts.usdc")},
			{"Vault", viper.GetString("contracts.vault")},
			{"ERC4626Provider", viper.GetString("contracts.erc4626_provider")},
			{"ParimutuelProvider", viper.GetString("contracts.parimutuel_provider")},
			{"ProviderFactory", viper.GetString("contracts.provider_factory")},
			{"CPMM", viper.GetString("contracts.cpmm")},
			{"Parimutuel", viper.GetString("contracts.parimutuel")},
			{"ReferralRegistry", viper.GetString("contracts.referral_registry")},
			{"FeeRouter", viper.GetString("contracts.fee_router")},
			{"Factory", viper.GetString("contracts.factory")},
		}

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Contract", "Address"})
		formatter.AddRows(contracts)
		formatter.Render()
	},
}

// usdcCmd USDC 子命令
var usdcCmd = &cobra.Command{
	Use:   "usdc",
	Short: "USDC 合约查询",
	Long:  `查询 USDC 合约状态。`,
}

// usdcSupplyCmd 查询 USDC 总供应量
var usdcSupplyCmd = &cobra.Command{
	Use:   "supply",
	Short: "查询总供应量",
	Long:  `查询 USDC 总供应量。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		info, err := svc.GetUSDCInfo(ctx)
		if err != nil {
			return fmt.Errorf("查询 USDC 信息失败: %w", err)
		}

		format := GetOutput()
		data := map[string]string{
			"Symbol":       info.Symbol,
			"Name":         info.Name,
			"Decimals":     fmt.Sprintf("%d", info.Decimals),
			"Total Supply": FormatUSDC(info.TotalSupply) + " USDC",
		}

		return output.PrintMap(format, data, "USDC Token Info")
	},
}

// usdcBalanceCmd 查询 USDC 余额
var usdcBalanceCmd = &cobra.Command{
	Use:   "balance <address>",
	Short: "查询账户余额",
	Long:  `查询指定地址的 USDC 余额。`,
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		addr, err := ParseAddress(args[0])
		if err != nil {
			return err
		}

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		balance, err := svc.GetUSDCBalance(ctx, addr)
		if err != nil {
			return fmt.Errorf("查询余额失败: %w", err)
		}

		format := GetOutput()
		data := map[string]string{
			"Address": addr.Hex(),
			"Balance": FormatUSDC(balance) + " USDC",
		}

		return output.PrintMap(format, data, "USDC Balance")
	},
}

// vaultCmd Vault 子命令
var vaultCmd = &cobra.Command{
	Use:   "vault",
	Short: "Vault 合约查询",
	Long:  `查询流动性 Vault 状态。`,
}

// vaultInfoCmd 查询 Vault 信息
var vaultInfoCmd = &cobra.Command{
	Use:   "info",
	Short: "查询 Vault 基本信息",
	Long:  `查询 Vault 的总资产、总份额、可用流动性等信息。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		info, err := svc.GetVaultInfo(ctx)
		if err != nil {
			return fmt.Errorf("查询 Vault 信息失败: %w", err)
		}

		format := GetOutput()
		data := map[string]string{
			"Total Assets":        FormatUSDC(info.TotalAssets) + " USDC",
			"Total Shares":        FormatShares(info.TotalShares) + " pLP",
			"Available Liquidity": FormatUSDC(info.AvailableLiquidity) + " USDC",
			"Utilization":         FormatPercentage(info.Utilization),
		}

		return output.PrintMap(format, data, "Vault Information")
	},
}

// feeRouterCmd FeeRouter 子命令
var feeRouterCmd = &cobra.Command{
	Use:   "fee-router",
	Short: "费用路由查询",
	Long:  `查询费用路由配置和统计。`,
}

// feeRouterConfigCmd 查询费用路由配置
var feeRouterConfigCmd = &cobra.Command{
	Use:   "config",
	Short: "查询费用分配配置",
	Long:  `查询费用分配比例和接收地址。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		config, err := svc.GetFeeRouterConfig(ctx)
		if err != nil {
			return fmt.Errorf("查询费用路由配置失败: %w", err)
		}

		format := GetOutput()

		// 费用分配比例
		fmt.Println("\nFee Distribution")
		fmt.Println("────────────────")

		rows := [][]string{
			{"LP", fmt.Sprintf("%s bps (%s)", config.LpBps.String(), FormatBps(config.LpBps)), FormatAddress(config.LpVault, false)},
			{"Promo", fmt.Sprintf("%s bps (%s)", config.PromoBps.String(), FormatBps(config.PromoBps)), FormatAddress(config.PromoPool, false)},
			{"Insurance", fmt.Sprintf("%s bps (%s)", config.InsuranceBps.String(), FormatBps(config.InsuranceBps)), FormatAddress(config.Insurance, false)},
			{"Treasury", fmt.Sprintf("%s bps (%s)", config.TreasuryBps.String(), FormatBps(config.TreasuryBps)), FormatAddress(config.Treasury, false)},
		}

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Category", "Allocation", "Recipient"})
		formatter.AddRows(rows)
		return formatter.Render()
	},
}

// referralCmd Referral 子命令
var referralCmd = &cobra.Command{
	Use:   "referral",
	Short: "推荐系统查询",
	Long:  `查询推荐系统信息。`,
}

// referralInfoCmd 查询用户推荐信息
var referralInfoCmd = &cobra.Command{
	Use:   "info <address>",
	Short: "查询用户推荐信息",
	Long:  `查询指定用户的推荐关系和统计。`,
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		addr, err := ParseAddress(args[0])
		if err != nil {
			return err
		}

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		info, err := svc.GetReferralInfo(ctx, addr)
		if err != nil {
			return fmt.Errorf("查询推荐信息失败: %w", err)
		}

		format := GetOutput()

		referrer := "None"
		if info.HasReferrer {
			referrer = info.Referrer.Hex()
		}

		data := map[string]string{
			"User":           info.User.Hex(),
			"Referrer":       referrer,
			"Referral Count": fmt.Sprintf("%d", info.ReferralCount),
			"Total Rewards":  FormatUSDC(info.TotalRewards) + " USDC",
		}

		return output.PrintMap(format, data, "Referral Information")
	},
}

func init() {
	rootCmd.AddCommand(contractCmd)

	// info
	contractCmd.AddCommand(contractInfoCmd)

	// usdc
	contractCmd.AddCommand(usdcCmd)
	usdcCmd.AddCommand(usdcSupplyCmd)
	usdcCmd.AddCommand(usdcBalanceCmd)

	// vault
	contractCmd.AddCommand(vaultCmd)
	vaultCmd.AddCommand(vaultInfoCmd)

	// fee-router
	contractCmd.AddCommand(feeRouterCmd)
	feeRouterCmd.AddCommand(feeRouterConfigCmd)

	// referral
	contractCmd.AddCommand(referralCmd)
	referralCmd.AddCommand(referralInfoCmd)
}

func printError(err error) {
	fmt.Fprintf(os.Stderr, "错误: %v\n", err)
}
