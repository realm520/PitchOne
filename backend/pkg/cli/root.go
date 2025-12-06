package cli

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	// 全局 flags
	cfgFile      string
	network      string
	outputFormat string
	rpcURL       string
	dbURL        string

	// Version 信息
	Version   = "dev"
	BuildTime = "unknown"
)

// rootCmd 根命令
var rootCmd = &cobra.Command{
	Use:   "p1cli",
	Short: "PitchOne CLI - 合约信息查询工具",
	Long: `p1cli 是 PitchOne 去中心化博彩平台的命令行查询工具。

支持查询:
  - 核心合约状态 (USDC, Vault, FeeRouter, Referral)
  - 市场工厂和模板信息
  - 单个市场详情、赔率、头寸
  - 用户余额、头寸、订单
  - 平台统计数据

示例:
  p1cli contract info                     # 显示所有合约地址
  p1cli contract vault info               # 查询 Vault 状态
  p1cli factory markets list --status open # 列出开放的市场
  p1cli market prices 0x1234...           # 查询市场赔率
  p1cli user positions 0x5678...          # 查询用户头寸`,
	Version: Version,
}

// Execute 执行根命令
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	cobra.OnInitialize(initConfig)

	// 全局 flags
	rootCmd.PersistentFlags().StringVarP(&cfgFile, "config", "c", "", "配置文件路径")
	rootCmd.PersistentFlags().StringVarP(&network, "network", "n", "localhost", "网络选择 (localhost|testnet|mainnet)")
	rootCmd.PersistentFlags().StringVarP(&outputFormat, "output", "o", "table", "输出格式 (table|json|csv)")
	rootCmd.PersistentFlags().StringVar(&rpcURL, "rpc", "", "覆盖 RPC URL")
	rootCmd.PersistentFlags().StringVar(&dbURL, "db", "", "覆盖数据库连接串")

	// 绑定到 viper
	viper.BindPFlag("network", rootCmd.PersistentFlags().Lookup("network"))
	viper.BindPFlag("output", rootCmd.PersistentFlags().Lookup("output"))
	viper.BindPFlag("rpc_url", rootCmd.PersistentFlags().Lookup("rpc"))
	viper.BindPFlag("database.url", rootCmd.PersistentFlags().Lookup("db"))
}

// initConfig 初始化配置
func initConfig() {
	if cfgFile != "" {
		// 使用指定的配置文件
		viper.SetConfigFile(cfgFile)
	} else {
		// 加载网络配置
		configPaths := []string{
			".",
			"./configs/networks",
			"../configs/networks",
			"../../configs/networks",
		}

		// 查找可执行文件所在目录
		if execPath, err := os.Executable(); err == nil {
			execDir := filepath.Dir(execPath)
			configPaths = append(configPaths,
				filepath.Join(execDir, "configs", "networks"),
				filepath.Join(execDir, "..", "configs", "networks"),
			)
		}

		viper.SetConfigName(network)
		viper.SetConfigType("yaml")
		for _, path := range configPaths {
			viper.AddConfigPath(path)
		}
	}

	// 环境变量
	viper.AutomaticEnv()
	viper.SetEnvPrefix("P1CLI")

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			fmt.Fprintf(os.Stderr, "警告: 未找到网络配置文件 '%s.yaml'\n", network)
		}
	}

	// 命令行覆盖
	if rpcURL != "" {
		viper.Set("rpc_url", rpcURL)
	}
	if dbURL != "" {
		viper.Set("database.url", dbURL)
	}
}

// GetNetwork 获取当前网络
func GetNetwork() string {
	return viper.GetString("network")
}

// GetOutput 获取输出格式
func GetOutput() string {
	return outputFormat
}

// GetRPCURL 获取 RPC URL
func GetRPCURL() string {
	return viper.GetString("rpc_url")
}

// GetDatabaseURL 获取数据库连接串
func GetDatabaseURL() string {
	return viper.GetString("database.url")
}

// GetChainID 获取链 ID
func GetChainID() int64 {
	return viper.GetInt64("chain_id")
}

// GetContractAddress 获取合约地址
func GetContractAddress(name string) string {
	return viper.GetString("contracts." + name)
}

// GetTemplateID 获取模板 ID
func GetTemplateID(name string) string {
	return viper.GetString("templates." + name)
}
