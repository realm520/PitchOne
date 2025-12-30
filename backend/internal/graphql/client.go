// Package graphql 提供 Subgraph GraphQL API 的客户端
package graphql

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/ethereum/go-ethereum/common"
)

// Client 是 Subgraph GraphQL 客户端
type Client struct {
	endpoint   string
	httpClient *http.Client
}

// NewClient 创建新的 GraphQL 客户端
func NewClient(endpoint string) *Client {
	return &Client{
		endpoint: endpoint,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// graphqlRequest 表示 GraphQL 请求体
type graphqlRequest struct {
	Query     string                 `json:"query"`
	Variables map[string]interface{} `json:"variables,omitempty"`
}

// doQuery 执行 GraphQL 查询
func (c *Client) doQuery(ctx context.Context, query string, variables map[string]interface{}, result interface{}) error {
	reqBody := graphqlRequest{
		Query:     query,
		Variables: variables,
	}

	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", c.endpoint, bytes.NewBuffer(jsonBody))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to execute request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code %d: %s", resp.StatusCode, string(body))
	}

	if err := json.Unmarshal(body, result); err != nil {
		return fmt.Errorf("failed to unmarshal response: %w", err)
	}

	return nil
}

// GetMarketsToLock 查询需要锁盘的市场
// 返回状态为 Open 且 lockTime 在指定时间窗口内的市场
func (c *Client) GetMarketsToLock(ctx context.Context, now, lockWindow int64) ([]Market, error) {
	query := `
	query MarketsToLock($now: BigInt!, $lockWindow: BigInt!) {
		markets(
			where: {
				state: "Open",
				lockTime_lte: $lockWindow,
				lockTime_gt: $now
			}
			orderBy: lockTime
			orderDirection: asc
			first: 100
		) {
			id
			matchId
			templateId
			homeTeam
			awayTeam
			kickoffTime
			lockTime
			oracle
			version
		}
	}`

	variables := map[string]interface{}{
		"now":        strconv.FormatInt(now, 10),
		"lockWindow": strconv.FormatInt(lockWindow, 10),
	}

	var resp MarketsResponse
	if err := c.doQuery(ctx, query, variables, &resp); err != nil {
		return nil, err
	}

	if len(resp.Errors) > 0 {
		return nil, fmt.Errorf("graphql error: %s", resp.Errors[0].Message)
	}

	return resp.Data.Markets, nil
}

// GetMarketsToSettle 查询需要结算的市场
// 返回状态为 Locked 且 matchEndTime 在指定时间之前的市场
func (c *Client) GetMarketsToSettle(ctx context.Context, settleTime int64) ([]Market, error) {
	query := `
	query MarketsToSettle($settleTime: BigInt!) {
		markets(
			where: {
				state: "Locked",
				matchEndTime_lte: $settleTime,
				matchEndTime_not: null
			}
			orderBy: matchEndTime
			orderDirection: asc
			first: 100
		) {
			id
			matchId
			templateId
			homeTeam
			awayTeam
			kickoffTime
			matchEndTime
			oracle
			pricingEngine
			version
			line
			isHalfLine
		}
	}`

	variables := map[string]interface{}{
		"settleTime": strconv.FormatInt(settleTime, 10),
	}

	var resp MarketsResponse
	if err := c.doQuery(ctx, query, variables, &resp); err != nil {
		return nil, err
	}

	if len(resp.Errors) > 0 {
		return nil, fmt.Errorf("graphql error: %s", resp.Errors[0].Message)
	}

	return resp.Data.Markets, nil
}

// GetMarketByAddress 根据地址查询单个市场
func (c *Client) GetMarketByAddress(ctx context.Context, address common.Address) (*Market, error) {
	query := `
	query GetMarket($id: ID!) {
		market(id: $id) {
			id
			matchId
			templateId
			homeTeam
			awayTeam
			state
			kickoffTime
			lockTime
			matchEndTime
			lockedAt
			resolvedAt
			lockTxHash
			settleTxHash
			oracle
			pricingEngine
			version
			line
			isHalfLine
			homeScore
			awayScore
			winnerOutcome
		}
	}`

	variables := map[string]interface{}{
		"id": address.Hex(),
	}

	var resp MarketResponse
	if err := c.doQuery(ctx, query, variables, &resp); err != nil {
		return nil, err
	}

	if len(resp.Errors) > 0 {
		return nil, fmt.Errorf("graphql error: %s", resp.Errors[0].Message)
	}

	return resp.Data.Market, nil
}

// IsMarketLocked 检查市场是否已锁盘（通过查询链上状态）
func (c *Client) IsMarketLocked(ctx context.Context, address common.Address) (bool, error) {
	market, err := c.GetMarketByAddress(ctx, address)
	if err != nil {
		return false, err
	}
	if market == nil {
		return false, fmt.Errorf("market not found: %s", address.Hex())
	}
	return market.State == "Locked" || market.State == "Resolved" || market.State == "Finalized", nil
}

// IsMarketResolved 检查市场是否已结算
func (c *Client) IsMarketResolved(ctx context.Context, address common.Address) (bool, error) {
	market, err := c.GetMarketByAddress(ctx, address)
	if err != nil {
		return false, err
	}
	if market == nil {
		return false, fmt.Errorf("market not found: %s", address.Hex())
	}
	return market.State == "Resolved" || market.State == "Finalized", nil
}

// GetOrdersByTimeRange 查询指定时间范围内的订单（用于 Rewards 聚合）
func (c *Client) GetOrdersByTimeRange(ctx context.Context, start, end int64, first int, skip int) ([]Order, error) {
	query := `
	query Orders($start: BigInt!, $end: BigInt!, $first: Int!, $skip: Int!) {
		orders(
			where: {
				timestamp_gte: $start,
				timestamp_lt: $end
			}
			orderBy: timestamp
			orderDirection: asc
			first: $first
			skip: $skip
		) {
			id
			market { id }
			user { id }
			outcome
			amount
			shares
			fee
			referrer
			timestamp
		}
	}`

	variables := map[string]interface{}{
		"start": strconv.FormatInt(start, 10),
		"end":   strconv.FormatInt(end, 10),
		"first": first,
		"skip":  skip,
	}

	var resp OrdersResponse
	if err := c.doQuery(ctx, query, variables, &resp); err != nil {
		return nil, err
	}

	if len(resp.Errors) > 0 {
		return nil, fmt.Errorf("graphql error: %s", resp.Errors[0].Message)
	}

	return resp.Data.Orders, nil
}

// GetReferralRewardsByTimeRange 查询指定时间范围内的推荐奖励
func (c *Client) GetReferralRewardsByTimeRange(ctx context.Context, start, end int64) ([]ReferralReward, error) {
	query := `
	query ReferralRewards($start: BigInt!, $end: BigInt!) {
		referralRewards(
			where: {
				timestamp_gte: $start,
				timestamp_lt: $end
			}
			orderBy: timestamp
			orderDirection: asc
			first: 1000
		) {
			id
			referrer { id }
			referee { id }
			amount
			timestamp
		}
	}`

	variables := map[string]interface{}{
		"start": strconv.FormatInt(start, 10),
		"end":   strconv.FormatInt(end, 10),
	}

	var resp ReferralRewardsResponse
	if err := c.doQuery(ctx, query, variables, &resp); err != nil {
		return nil, err
	}

	if len(resp.Errors) > 0 {
		return nil, fmt.Errorf("graphql error: %s", resp.Errors[0].Message)
	}

	return resp.Data.ReferralRewards, nil
}

// GetQuestRewardClaimsByTimeRange 查询指定时间范围内的任务奖励领取
func (c *Client) GetQuestRewardClaimsByTimeRange(ctx context.Context, start, end int64) ([]QuestRewardClaim, error) {
	query := `
	query QuestRewardClaims($start: BigInt!, $end: BigInt!) {
		questRewardClaims(
			where: {
				timestamp_gte: $start,
				timestamp_lt: $end
			}
			orderBy: timestamp
			orderDirection: asc
			first: 1000
		) {
			id
			user { id }
			rewardAmount
			timestamp
		}
	}`

	variables := map[string]interface{}{
		"start": strconv.FormatInt(start, 10),
		"end":   strconv.FormatInt(end, 10),
	}

	var resp QuestRewardClaimsResponse
	if err := c.doQuery(ctx, query, variables, &resp); err != nil {
		return nil, err
	}

	if len(resp.Errors) > 0 {
		return nil, fmt.Errorf("graphql error: %s", resp.Errors[0].Message)
	}

	return resp.Data.QuestRewardClaims, nil
}

// HealthCheck 检查 Subgraph 是否可用
func (c *Client) HealthCheck(ctx context.Context) error {
	query := `{ _meta { block { number } } }`

	var resp struct {
		Data struct {
			Meta struct {
				Block struct {
					Number int `json:"number"`
				} `json:"block"`
			} `json:"_meta"`
		} `json:"data"`
		Errors []GraphQLError `json:"errors,omitempty"`
	}

	if err := c.doQuery(ctx, query, nil, &resp); err != nil {
		return err
	}

	if len(resp.Errors) > 0 {
		return fmt.Errorf("graphql error: %s", resp.Errors[0].Message)
	}

	return nil
}
