package cli

import (
	"context"
	"fmt"
	"time"

	"github.com/spf13/cobra"

	"github.com/pitchone/sportsbook/internal/query"
	"github.com/pitchone/sportsbook/pkg/output"
)

// factoryCmd 工厂命令
var factoryCmd = &cobra.Command{
	Use:   "factory",
	Short: "市场工厂查询",
	Long:  `查询市场工厂信息，包括模板列表和已创建的市场。`,
}

// factoryInfoCmd 工厂基本信息
var factoryInfoCmd = &cobra.Command{
	Use:   "info",
	Short: "查询工厂基本信息",
	Long:  `查询市场工厂的基本信息，包括市场数量等。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		info, err := svc.GetFactoryInfo(ctx)
		if err != nil {
			return fmt.Errorf("查询工厂信息失败: %w", err)
		}

		format := GetOutput()
		data := map[string]string{
			"Factory Address": info.Address.Hex(),
			"Market Count":    fmt.Sprintf("%d", info.MarketCount),
		}

		return output.PrintMap(format, data, "Market Factory Information")
	},
}

// factoryTemplatesCmd 模板列表
var factoryTemplatesCmd = &cobra.Command{
	Use:   "templates",
	Short: "列出所有模板",
	Long:  `列出所有已注册的市场模板。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		templates, err := svc.ListTemplates(ctx)
		if err != nil {
			return fmt.Errorf("查询模板列表失败: %w", err)
		}

		if len(templates) == 0 {
			fmt.Println("没有注册的模板")
			return nil
		}

		format := GetOutput()

		rows := make([][]string, 0, len(templates))
		for _, t := range templates {
			active := "No"
			if t.Active {
				active = "Yes"
			}

			impl := FormatAddress(t.Implementation, false)
			if t.Implementation.Hex() == "0x0000000000000000000000000000000000000000" {
				impl = "-"
			}

			rows = append(rows, []string{
				t.Name,
				GetTemplateName(t.Name),
				active,
				impl,
			})
		}

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Name", "Description", "Active", "Implementation"})
		formatter.AddRows(rows)
		return formatter.Render()
	},
}

// marketsCmd 市场子命令
var marketsCmd = &cobra.Command{
	Use:   "markets",
	Short: "市场管理",
	Long:  `查询和管理已创建的市场。`,
}

var (
	marketListStatus   string
	marketListTemplate string
	marketListLimit    int
	marketListOffset   int
)

// marketsListCmd 市场列表
var marketsListCmd = &cobra.Command{
	Use:   "list",
	Short: "列出所有市场",
	Long:  `列出所有已创建的市场，支持按状态和模板筛选。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		opts := &query.ListMarketsOptions{
			Limit:  uint64(marketListLimit),
			Offset: uint64(marketListOffset),
		}

		// 解析状态筛选
		if marketListStatus != "" {
			status := parseStatus(marketListStatus)
			if status != 255 {
				opts.Status = &status
			}
		}

		// 解析模板筛选
		if marketListTemplate != "" {
			templateID, err := ParseBytes32(marketListTemplate)
			if err == nil {
				opts.TemplateID = &templateID
			}
		}

		markets, err := svc.ListMarkets(ctx, opts)
		if err != nil {
			return fmt.Errorf("查询市场列表失败: %w", err)
		}

		if len(markets) == 0 {
			fmt.Println("没有找到市场")
			return nil
		}

		format := GetOutput()

		rows := make([][]string, 0, len(markets))
		for _, m := range markets {
			rows = append(rows, []string{
				FormatAddress(m.Address, false),
				m.TemplateName,
				m.StatusName,
			})
		}

		fmt.Printf("\nMarkets (showing %d)\n\n", len(markets))

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Address", "Template", "Status"})
		formatter.AddRows(rows)
		return formatter.Render()
	},
}

// marketsCountCmd 市场数量
var marketsCountCmd = &cobra.Command{
	Use:   "count",
	Short: "查询市场总数",
	Long:  `查询已创建的市场总数。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		count, err := svc.GetMarketCount(ctx)
		if err != nil {
			return fmt.Errorf("查询市场数量失败: %w", err)
		}

		fmt.Printf("Total Markets: %d\n", count)
		return nil
	},
}

// marketsStatsCmd 市场统计
var marketsStatsCmd = &cobra.Command{
	Use:   "stats",
	Short: "市场状态统计",
	Long:  `按状态统计市场数量。`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		stats, err := svc.GetMarketsByStatus(ctx)
		if err != nil {
			return fmt.Errorf("查询市场统计失败: %w", err)
		}

		format := GetOutput()

		rows := [][]string{
			{"Open", fmt.Sprintf("%d", stats["Open"])},
			{"Locked", fmt.Sprintf("%d", stats["Locked"])},
			{"Resolved", fmt.Sprintf("%d", stats["Resolved"])},
			{"Finalized", fmt.Sprintf("%d", stats["Finalized"])},
			{"Cancelled", fmt.Sprintf("%d", stats["Cancelled"])},
		}

		// 计算总数
		total := uint64(0)
		for _, v := range stats {
			total += v
		}
		rows = append(rows, []string{"Total", fmt.Sprintf("%d", total)})

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Status", "Count"})
		formatter.AddRows(rows)
		return formatter.Render()
	},
}

func init() {
	rootCmd.AddCommand(factoryCmd)

	// info
	factoryCmd.AddCommand(factoryInfoCmd)

	// templates
	factoryCmd.AddCommand(factoryTemplatesCmd)

	// markets
	factoryCmd.AddCommand(marketsCmd)
	marketsCmd.AddCommand(marketsListCmd)
	marketsCmd.AddCommand(marketsCountCmd)
	marketsCmd.AddCommand(marketsStatsCmd)

	// markets list flags
	marketsListCmd.Flags().StringVar(&marketListStatus, "status", "", "按状态筛选 (open|locked|resolved|finalized|cancelled)")
	marketsListCmd.Flags().StringVar(&marketListTemplate, "template", "", "按模板 ID 筛选")
	marketsListCmd.Flags().IntVar(&marketListLimit, "limit", 20, "返回数量限制")
	marketsListCmd.Flags().IntVar(&marketListOffset, "offset", 0, "分页偏移")
}

// parseStatus 解析状态字符串
func parseStatus(s string) uint8 {
	switch s {
	case "open", "Open":
		return 0
	case "locked", "Locked":
		return 1
	case "resolved", "Resolved":
		return 2
	case "finalized", "Finalized":
		return 3
	case "cancelled", "Cancelled":
		return 4
	default:
		return 255 // 无效
	}
}
