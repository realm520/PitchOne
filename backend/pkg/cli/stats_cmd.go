package cli

import (
	"context"
	"fmt"
	"time"

	"github.com/spf13/cobra"

	"github.com/pitchone/sportsbook/internal/query"
	"github.com/pitchone/sportsbook/pkg/output"
)

// statsCmd 统计命令
var statsCmd = &cobra.Command{
	Use:   "stats",
	Short: "统计分析",
	Long:  `查询平台统计数据。`,
}

// statsOverviewCmd 平台概览
var statsOverviewCmd = &cobra.Command{
	Use:   "overview",
	Short: "平台概览",
	Long:  `查询平台整体统计数据。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		stats, err := svc.GetPlatformStats(ctx)
		if err != nil {
			return fmt.Errorf("查询平台统计失败: %w", err)
		}

		format := GetOutput()
		data := map[string]string{
			"Total Markets":     fmt.Sprintf("%d", stats.TotalMarkets),
			"Active Markets":    fmt.Sprintf("%d", stats.ActiveMarkets),
			"Total Volume":      FormatUSDC(stats.TotalVolume) + " USDC",
			"Total Fees":        FormatUSDC(stats.TotalFees) + " USDC",
			"Total Users":       fmt.Sprintf("%d", stats.TotalUsers),
			"Total Liquidity":   FormatUSDC(stats.TotalLiquidity) + " USDC",
		}

		return output.PrintMap(format, data, "Platform Overview")
	},
}

var volumePeriod string

// statsVolumeCmd 交易量统计
var statsVolumeCmd = &cobra.Command{
	Use:   "volume",
	Short: "交易量统计",
	Long:  `按时间周期统计交易量（需要数据库支持）。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		volumes, err := svc.GetVolumeStats(ctx, volumePeriod)
		if err != nil {
			return fmt.Errorf("查询交易量统计失败: %w", err)
		}

		if len(volumes) == 0 {
			fmt.Println("没有交易量数据")
			return nil
		}

		format := GetOutput()

		fmt.Printf("\nVolume Statistics (%s)\n\n", volumePeriod)

		rows := make([][]string, 0, len(volumes))
		for _, v := range volumes {
			rows = append(rows, []string{
				v.Period,
				FormatUSDC(v.Volume) + " USDC",
				fmt.Sprintf("%d", v.OrderCount),
				fmt.Sprintf("%d", v.UniqueUsers),
			})
		}

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Period", "Volume", "Orders", "Users"})
		formatter.AddRows(rows)
		return formatter.Render()
	},
}

var topMarketsLimit int

// statsTopMarketsCmd 热门市场
var statsTopMarketsCmd = &cobra.Command{
	Use:   "top-markets",
	Short: "热门市场排名",
	Long:  `查询交易量最高的市场（需要数据库支持）。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		markets, err := svc.GetTopMarkets(ctx, topMarketsLimit)
		if err != nil {
			return fmt.Errorf("查询热门市场失败: %w", err)
		}

		if len(markets) == 0 {
			fmt.Println("没有市场数据")
			return nil
		}

		format := GetOutput()

		fmt.Printf("\nTop Markets (Top %d)\n\n", topMarketsLimit)

		rows := make([][]string, 0, len(markets))
		for i, m := range markets {
			rows = append(rows, []string{
				fmt.Sprintf("%d", i+1),
				FormatAddress(m.Address, false),
				m.TemplateName,
				m.StatusName,
			})
		}

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Rank", "Address", "Template", "Status"})
		formatter.AddRows(rows)
		return formatter.Render()
	},
}

func init() {
	rootCmd.AddCommand(statsCmd)

	statsCmd.AddCommand(statsOverviewCmd)
	statsCmd.AddCommand(statsVolumeCmd)
	statsCmd.AddCommand(statsTopMarketsCmd)

	// volume flags
	statsVolumeCmd.Flags().StringVar(&volumePeriod, "period", "daily", "时间周期 (daily|weekly|monthly)")

	// top-markets flags
	statsTopMarketsCmd.Flags().IntVar(&topMarketsLimit, "limit", 10, "返回数量")
}
