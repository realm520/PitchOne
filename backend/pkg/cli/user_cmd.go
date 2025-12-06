package cli

import (
	"context"
	"fmt"
	"time"

	"github.com/spf13/cobra"

	"github.com/pitchone/sportsbook/internal/query"
	"github.com/pitchone/sportsbook/pkg/output"
)

// userCmd 用户命令
var userCmd = &cobra.Command{
	Use:   "user",
	Short: "用户信息查询",
	Long:  `查询用户的余额、头寸、订单、推荐关系等信息。`,
}

// userBalanceCmd 用户余额
var userBalanceCmd = &cobra.Command{
	Use:   "balance <address>",
	Short: "查询用户 USDC 余额",
	Long:  `查询指定用户的 USDC 余额。`,
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

		balance, err := svc.GetUserBalance(ctx, addr)
		if err != nil {
			return fmt.Errorf("查询余额失败: %w", err)
		}

		format := GetOutput()
		data := map[string]string{
			"Address": addr.Hex(),
			"Balance": FormatUSDC(balance) + " USDC",
		}

		return output.PrintMap(format, data, "User Balance")
	},
}

// userPositionsCmd 用户头寸
var userPositionsCmd = &cobra.Command{
	Use:   "positions <address>",
	Short: "查询用户所有头寸",
	Long:  `查询指定用户在所有市场的头寸。`,
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		addr, err := ParseAddress(args[0])
		if err != nil {
			return err
		}

		ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
		defer cancel()

		svc, err := query.NewService(ctx)
		if err != nil {
			return fmt.Errorf("初始化查询服务失败: %w", err)
		}
		defer svc.Close()

		fmt.Printf("正在查询 %s 的头寸...\n", FormatAddress(addr, false))

		positions, err := svc.GetUserAllPositions(ctx, addr)
		if err != nil {
			return fmt.Errorf("查询头寸失败: %w", err)
		}

		if len(positions) == 0 {
			fmt.Println("\n该用户没有持有任何头寸")
			return nil
		}

		format := GetOutput()

		rows := make([][]string, 0, len(positions))
		for _, p := range positions {
			status := ""
			template := ""
			if p.MarketInfo != nil {
				status = p.MarketInfo.StatusName
				template = p.MarketInfo.TemplateName
			}

			rows = append(rows, []string{
				FormatAddress(p.Market, false),
				template,
				status,
				p.OutcomeName,
				FormatShares(p.Balance),
			})
		}

		fmt.Printf("\nUser Positions (%d)\n\n", len(positions))

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Market", "Template", "Status", "Outcome", "Balance"})
		formatter.AddRows(rows)
		return formatter.Render()
	},
}

// userOrdersCmd 用户订单
var userOrdersCmd = &cobra.Command{
	Use:   "orders <address>",
	Short: "查询用户订单历史",
	Long:  `查询指定用户的历史订单（需要数据库支持）。`,
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

		orders, err := svc.GetUserOrders(ctx, addr, 50)
		if err != nil {
			return fmt.Errorf("查询订单失败: %w", err)
		}

		if len(orders) == 0 {
			fmt.Println("没有订单记录")
			return nil
		}

		format := GetOutput()

		rows := make([][]string, 0, len(orders))
		for _, o := range orders {
			rows = append(rows, []string{
				FormatAddress(o.Market, false),
				fmt.Sprintf("%d", o.OutcomeID),
				FormatUSDC(o.Amount),
				FormatShares(o.Shares),
				o.Timestamp.Format("2006-01-02 15:04:05"),
			})
		}

		formatter := output.NewFromString(format)
		formatter.SetHeader([]string{"Market", "Outcome", "Amount", "Shares", "Time"})
		formatter.AddRows(rows)
		return formatter.Render()
	},
}

// userReferralCmd 用户推荐信息
var userReferralCmd = &cobra.Command{
	Use:   "referral <address>",
	Short: "查询用户推荐关系",
	Long:  `查询指定用户的推荐关系。`,
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

		info, err := svc.GetUserReferralInfo(ctx, addr)
		if err != nil {
			return fmt.Errorf("查询推荐信息失败: %w", err)
		}

		format := GetOutput()

		referrer := "None"
		if info.HasReferrer {
			referrer = info.Referrer.Hex()
		}

		data := map[string]string{
			"User":            info.User.Hex(),
			"Referrer":        referrer,
			"Referrals Count": fmt.Sprintf("%d", info.ReferralCount),
			"Total Rewards":   FormatUSDC(info.TotalRewards) + " USDC",
		}

		return output.PrintMap(format, data, "User Referral Info")
	},
}

// userRewardsCmd 用户奖励
var userRewardsCmd = &cobra.Command{
	Use:   "rewards <address>",
	Short: "查询用户奖励状态",
	Long:  `查询指定用户的未领取奖励（需要数据库支持）。`,
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

		rewards, err := svc.GetUserRewards(ctx, addr)
		if err != nil {
			return fmt.Errorf("查询奖励失败: %w", err)
		}

		format := GetOutput()
		data := map[string]string{
			"Address":           addr.Hex(),
			"Unclaimed Rewards": FormatUSDC(rewards) + " USDC",
		}

		return output.PrintMap(format, data, "User Rewards")
	},
}

func init() {
	rootCmd.AddCommand(userCmd)

	userCmd.AddCommand(userBalanceCmd)
	userCmd.AddCommand(userPositionsCmd)
	userCmd.AddCommand(userOrdersCmd)
	userCmd.AddCommand(userReferralCmd)
	userCmd.AddCommand(userRewardsCmd)
}
