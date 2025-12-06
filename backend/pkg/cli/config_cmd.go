package cli

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/pitchone/sportsbook/pkg/output"
)

// configCmd 配置命令
var configCmd = &cobra.Command{
	Use:   "config",
	Short: "配置管理",
	Long:  `查看和管理 p1cli 配置。`,
}

// configShowCmd 显示当前配置
var configShowCmd = &cobra.Command{
	Use:   "show",
	Short: "显示当前配置",
	Long:  `显示当前加载的配置信息。`,
	Run: func(cmd *cobra.Command, args []string) {
		format := GetOutput()

		data := map[string]string{
			"Network":     viper.GetString("network"),
			"Chain ID":    fmt.Sprintf("%d", viper.GetInt64("chain_id")),
			"RPC URL":     viper.GetString("rpc_url"),
			"Database":    maskDatabaseURL(viper.GetString("database.url")),
			"Config File": viper.ConfigFileUsed(),
		}

		title := fmt.Sprintf("Configuration (Network: %s)", viper.GetString("network"))
		if err := output.PrintMap(format, data, title); err != nil {
			fmt.Fprintf(os.Stderr, "输出失败: %v\n", err)
		}
	},
}

// configNetworksCmd 列出可用网络
var configNetworksCmd = &cobra.Command{
	Use:   "networks",
	Short: "列出可用网络",
	Long:  `列出所有可用的网络配置。`,
	Run: func(cmd *cobra.Command, args []string) {
		format := GetOutput()

		// 查找配置文件目录
		configDirs := []string{
			"./configs/networks",
			"../configs/networks",
			"../../configs/networks",
		}

		// 查找可执行文件目录
		if execPath, err := os.Executable(); err == nil {
			execDir := filepath.Dir(execPath)
			configDirs = append(configDirs,
				filepath.Join(execDir, "configs", "networks"),
				filepath.Join(execDir, "..", "configs", "networks"),
			)
		}

		networks := [][]string{}
		currentNetwork := viper.GetString("network")

		for _, dir := range configDirs {
			files, err := filepath.Glob(filepath.Join(dir, "*.yaml"))
			if err != nil {
				continue
			}

			for _, file := range files {
				name := filepath.Base(file)
				name = name[:len(name)-5] // 去掉 .yaml

				current := ""
				if name == currentNetwork {
					current = "*"
				}

				networks = append(networks, []string{name, dir, current})
			}
		}

		if len(networks) == 0 {
			fmt.Println("未找到网络配置文件")
			return
		}

		// 去重
		seen := make(map[string]bool)
		unique := [][]string{}
		for _, n := range networks {
			if !seen[n[0]] {
				seen[n[0]] = true
				unique = append(unique, n)
			}
		}

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Network", "Path", "Active"})
		formatter.AddRows(unique)
		formatter.Render()
	},
}

// configContractsCmd 显示合约地址
var configContractsCmd = &cobra.Command{
	Use:   "contracts",
	Short: "显示合约地址配置",
	Long:  `显示当前网络的所有合约地址。`,
	Run: func(cmd *cobra.Command, args []string) {
		format := GetOutput()

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

// configTemplatesCmd 显示模板 ID
var configTemplatesCmd = &cobra.Command{
	Use:   "templates",
	Short: "显示模板 ID 配置",
	Long:  `显示当前网络的所有模板 ID。`,
	Run: func(cmd *cobra.Command, args []string) {
		format := GetOutput()

		templates := [][]string{
			{"WDL", viper.GetString("templates.wdl")},
			{"OU", viper.GetString("templates.ou")},
			{"OU_MultiLine", viper.GetString("templates.ou_multi_line")},
			{"AH", viper.GetString("templates.ah")},
			{"OddEven", viper.GetString("templates.odd_even")},
			{"Score", viper.GetString("templates.score")},
			{"PlayerProps", viper.GetString("templates.player_props")},
		}

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Template", "ID"})
		formatter.AddRows(templates)
		formatter.Render()
	},
}

func init() {
	rootCmd.AddCommand(configCmd)
	configCmd.AddCommand(configShowCmd)
	configCmd.AddCommand(configNetworksCmd)
	configCmd.AddCommand(configContractsCmd)
	configCmd.AddCommand(configTemplatesCmd)
}

// maskDatabaseURL 隐藏数据库密码
func maskDatabaseURL(url string) string {
	if url == "" {
		return "(not configured)"
	}
	// 简单隐藏密码部分
	if len(url) > 20 {
		return url[:20] + "..."
	}
	return url
}
