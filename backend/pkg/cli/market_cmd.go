package cli

import (
	"context"
	"fmt"
	"time"

	"github.com/spf13/cobra"

	"github.com/pitchone/sportsbook/internal/query"
	"github.com/pitchone/sportsbook/pkg/output"
)

// marketCmd 市场命令
var marketCmd = &cobra.Command{
	Use:   "market",
	Short: "单个市场查询",
	Long:  `查询单个市场的详细信息，包括赔率、头寸等。`,
}

// marketInfoCmd 市场详情
var marketInfoCmd = &cobra.Command{
	Use:   "info <address>",
	Short: "查询市场详情",
	Long:  `查询指定市场的详细信息。`,
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

		info, err := svc.GetMarketInfo(ctx, addr)
		if err != nil {
			return fmt.Errorf("查询市场信息失败: %w", err)
		}

		format := GetOutput()

		kickoff := "-"
		if !info.KickoffTime.IsZero() {
			kickoff = info.KickoffTime.Format("2006-01-02 15:04:05")
		}

		winningOutcome := "-"
		if info.WinningOutcome >= 0 {
			winningOutcome = fmt.Sprintf("%d", info.WinningOutcome)
		}

		data := map[string]string{
			"Address":         info.Address.Hex(),
			"Template":        info.TemplateName,
			"Status":          info.StatusName,
			"Kickoff Time":    kickoff,
			"Outcome Count":   fmt.Sprintf("%d", info.OutcomeCount),
			"Winning Outcome": winningOutcome,
			"Total Liquidity": FormatUSDC(info.TotalLiquidity) + " USDC",
			"Fee Rate":        fmt.Sprintf("%d bps (%.2f%%)", info.FeeRate, float64(info.FeeRate)/100),
		}

		return output.PrintMap(format, data, "Market Information")
	},
}

// marketPricesCmd 市场赔率
var marketPricesCmd = &cobra.Command{
	Use:   "prices <address>",
	Short: "查询市场赔率",
	Long:  `查询指定市场各结果的赔率和隐含概率。`,
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

		// 先获取市场基本信息
		info, err := svc.GetMarketInfo(ctx, addr)
		if err != nil {
			return fmt.Errorf("查询市场信息失败: %w", err)
		}

		// 获取赔率
		prices, err := svc.GetMarketPrices(ctx, addr)
		if err != nil {
			return fmt.Errorf("查询赔率失败: %w", err)
		}

		if len(prices) == 0 {
			fmt.Println("没有结果数据")
			return nil
		}

		format := GetOutput()

		// 打印市场标题
		fmt.Printf("\nMarket: %s (%s)\n", FormatAddress(addr, false), info.TemplateName)
		fmt.Printf("Status: %s\n\n", info.StatusName)

		rows := make([][]string, 0, len(prices))
		for _, p := range prices {
			rows = append(rows, []string{
				fmt.Sprintf("%d", p.OutcomeID),
				p.OutcomeName,
				fmt.Sprintf("%.2f", p.Odds),
				fmt.Sprintf("%.1f%%", p.ImpliedProb),
				FormatUSDC(p.Reserve),
			})
		}

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"ID", "Outcome", "Odds", "Implied %", "Reserve"})
		formatter.AddRows(rows)
		if err := formatter.Render(); err != nil {
			return err
		}

		fmt.Printf("\nTotal Liquidity: %s USDC\n", FormatUSDC(info.TotalLiquidity))
		return nil
	},
}

// marketPositionsCmd 市场头寸
var marketPositionsCmd = &cobra.Command{
	Use:   "positions <address>",
	Short: "查询市场头寸分布",
	Long:  `查询指定市场的头寸分布情况。`,
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

		positions, err := svc.GetMarketPositions(ctx, addr)
		if err != nil {
			return fmt.Errorf("查询头寸失败: %w", err)
		}

		if len(positions) == 0 {
			fmt.Println("没有头寸数据（需要通过事件日志或数据库获取）")
			return nil
		}

		format := GetOutput()

		rows := make([][]string, 0, len(positions))
		for _, p := range positions {
			rows = append(rows, []string{
				FormatAddress(p.Owner, false),
				fmt.Sprintf("%d", p.OutcomeID),
				FormatShares(p.Balance),
			})
		}

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Owner", "Outcome", "Balance"})
		formatter.AddRows(rows)
		return formatter.Render()
	},
}

func init() {
	rootCmd.AddCommand(marketCmd)

	marketCmd.AddCommand(marketInfoCmd)
	marketCmd.AddCommand(marketPricesCmd)
	marketCmd.AddCommand(marketPositionsCmd)
}
