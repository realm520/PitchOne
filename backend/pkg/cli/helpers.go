package cli

import (
	"context"
	"fmt"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// 状态名称映射
var statusNames = map[uint8]string{
	0: "Open",
	1: "Locked",
	2: "Resolved",
	3: "Finalized",
	4: "Cancelled",
}

// 模板名称映射
var templateNames = map[string]string{
	"wdl":          "WDL (胜平负)",
	"ou":           "OU (大小球)",
	"ou_multi_line": "OU_MultiLine (多线大小球)",
	"ah":           "AH (让球)",
	"odd_even":     "OddEven (单双)",
	"score":        "Score (精确比分)",
	"player_props": "PlayerProps (球员道具)",
}

// GetStatusName 获取状态名称
func GetStatusName(status uint8) string {
	if name, ok := statusNames[status]; ok {
		return name
	}
	return fmt.Sprintf("Unknown(%d)", status)
}

// GetTemplateName 获取模板名称
func GetTemplateName(templateKey string) string {
	if name, ok := templateNames[templateKey]; ok {
		return name
	}
	return templateKey
}

// FormatAddress 格式化地址（缩短显示）
func FormatAddress(addr common.Address, full bool) string {
	if full {
		return addr.Hex()
	}
	hex := addr.Hex()
	return hex[:6] + "..." + hex[len(hex)-4:]
}

// FormatUSDC 格式化 USDC 金额（6 位小数）
func FormatUSDC(amount *big.Int) string {
	if amount == nil {
		return "0.00"
	}

	// USDC 有 6 位小数
	divisor := new(big.Int).Exp(big.NewInt(10), big.NewInt(6), nil)
	whole := new(big.Int).Div(amount, divisor)
	remainder := new(big.Int).Mod(amount, divisor)

	// 格式化小数部分
	fracStr := fmt.Sprintf("%06d", remainder)
	// 去除尾部的零，但至少保留 2 位
	fracStr = strings.TrimRight(fracStr, "0")
	if len(fracStr) < 2 {
		fracStr = fracStr + strings.Repeat("0", 2-len(fracStr))
	}

	return fmt.Sprintf("%s.%s", formatWithCommas(whole.String()), fracStr)
}

// FormatShares 格式化份额（18 位小数）
func FormatShares(amount *big.Int) string {
	if amount == nil {
		return "0.00"
	}

	// 18 位小数
	divisor := new(big.Int).Exp(big.NewInt(10), big.NewInt(18), nil)
	whole := new(big.Int).Div(amount, divisor)
	remainder := new(big.Int).Mod(amount, divisor)

	// 只显示 2 位小数
	remainder = new(big.Int).Div(remainder, new(big.Int).Exp(big.NewInt(10), big.NewInt(16), nil))

	return fmt.Sprintf("%s.%02d", formatWithCommas(whole.String()), remainder)
}

// FormatOdds 格式化赔率（从 1e18 精度转换）
func FormatOdds(price *big.Int) string {
	if price == nil || price.Sign() == 0 {
		return "-"
	}

	// price 是概率 (0-1e18)，赔率 = 1 / price
	divisor := new(big.Int).Exp(big.NewInt(10), big.NewInt(18), nil)

	// 计算赔率 = divisor / price
	odds := new(big.Float).Quo(
		new(big.Float).SetInt(divisor),
		new(big.Float).SetInt(price),
	)

	result, _ := odds.Float64()
	return fmt.Sprintf("%.2f", result)
}

// FormatImpliedProbability 格式化隐含概率
func FormatImpliedProbability(price *big.Int) string {
	if price == nil {
		return "-"
	}

	divisor := new(big.Int).Exp(big.NewInt(10), big.NewInt(18), nil)
	prob := new(big.Float).Quo(
		new(big.Float).SetInt(price),
		new(big.Float).SetInt(divisor),
	)

	result, _ := prob.Float64()
	return fmt.Sprintf("%.1f%%", result*100)
}

// FormatPercentage 格式化百分比
func FormatPercentage(value float64) string {
	return fmt.Sprintf("%.2f%%", value)
}

// FormatBps 格式化基点值（bps -> 百分比）
func FormatBps(bps *big.Int) string {
	if bps == nil {
		return "0.00%"
	}
	// 1 bps = 0.01%, 所以除以 100 得到百分比
	percent := float64(bps.Int64()) / 100.0
	return fmt.Sprintf("%.2f%%", percent)
}

// formatWithCommas 添加千位分隔符
func formatWithCommas(s string) string {
	n := len(s)
	if n <= 3 {
		return s
	}

	var result strings.Builder
	pre := n % 3
	if pre > 0 {
		result.WriteString(s[:pre])
	}
	for i := pre; i < n; i += 3 {
		if result.Len() > 0 {
			result.WriteString(",")
		}
		result.WriteString(s[i : i+3])
	}
	return result.String()
}

// ParseAddress 解析地址
func ParseAddress(s string) (common.Address, error) {
	if !common.IsHexAddress(s) {
		return common.Address{}, fmt.Errorf("无效的以太坊地址: %s", s)
	}
	return common.HexToAddress(s), nil
}

// ParseBytes32 解析 bytes32
func ParseBytes32(s string) ([32]byte, error) {
	var result [32]byte

	// 移除 0x 前缀
	s = strings.TrimPrefix(s, "0x")

	if len(s) != 64 {
		return result, fmt.Errorf("无效的 bytes32: 长度应为 64 个十六进制字符")
	}

	bytes := common.Hex2Bytes(s)
	copy(result[:], bytes)
	return result, nil
}

// NewEthClient 创建以太坊客户端
func NewEthClient(ctx context.Context) (*ethclient.Client, error) {
	rpcURL := GetRPCURL()
	if rpcURL == "" {
		return nil, fmt.Errorf("RPC URL 未配置，请设置 --rpc 参数或在配置文件中指定")
	}

	client, err := ethclient.DialContext(ctx, rpcURL)
	if err != nil {
		return nil, fmt.Errorf("连接 RPC 失败: %w", err)
	}

	return client, nil
}

// CheckNetwork 检查网络连接
func CheckNetwork(ctx context.Context, client *ethclient.Client) error {
	chainID, err := client.ChainID(ctx)
	if err != nil {
		return fmt.Errorf("获取链 ID 失败: %w", err)
	}

	expectedChainID := GetChainID()
	if expectedChainID != 0 && chainID.Int64() != expectedChainID {
		return fmt.Errorf("链 ID 不匹配: 期望 %d, 实际 %d", expectedChainID, chainID.Int64())
	}

	return nil
}

// MustParseAddress 解析地址（失败则 panic）
func MustParseAddress(s string) common.Address {
	addr, err := ParseAddress(s)
	if err != nil {
		panic(err)
	}
	return addr
}
