// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package bindings

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// IMarketV3MarketConfig is an auto generated low-level Go binding around an user-defined struct.
type IMarketV3MarketConfig struct {
	MarketId         [32]byte
	MatchId          string
	KickoffTime      *big.Int
	SettlementToken  common.Address
	PricingStrategy  common.Address
	ResultMapper     common.Address
	Vault            common.Address
	InitialLiquidity *big.Int
	OutcomeRules     []IMarketV3OutcomeRule
	Uri              string
	Admin            common.Address
	ParamController  common.Address
}

// IMarketV3MarketStats is an auto generated low-level Go binding around an user-defined struct.
type IMarketV3MarketStats struct {
	TotalLiquidity        *big.Int
	BorrowedAmount        *big.Int
	TotalBetAmount        *big.Int
	TotalSharesPerOutcome []*big.Int
	TotalBetPerOutcome    []*big.Int
}

// IMarketV3OutcomeRule is an auto generated low-level Go binding around an user-defined struct.
type IMarketV3OutcomeRule struct {
	Name       string
	PayoutType uint8
}

// IMarketV3SettlementResult is an auto generated low-level Go binding around an user-defined struct.
type IMarketV3SettlementResult struct {
	OutcomeIds []*big.Int
	Weights    []*big.Int
	RawResult  []byte
	SettledAt  *big.Int
	Resolved   bool
}

// MarketV3MetaData contains all meta data concerning the MarketV3 contract.
var MarketV3MetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_factory\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"KEEPER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"OPERATOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ORACLE_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"PAUSER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ROUTER_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfBatch\",\"inputs\":[{\"name\":\"accounts\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"borrowedAmount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"cancel\",\"inputs\":[{\"name\":\"reason\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"cancelResolved\",\"inputs\":[{\"name\":\"reason\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"checkLiabilityLimit\",\"inputs\":[],\"outputs\":[{\"name\":\"exceedsLimit\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"excessLoss\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"factory\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"finalize\",\"inputs\":[{\"name\":\"scaleBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"fundFromVault\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAllPrices\",\"inputs\":[],\"outputs\":[{\"name\":\"prices\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCurrentPnL\",\"inputs\":[],\"outputs\":[{\"name\":\"pnl\",\"type\":\"int256\",\"internalType\":\"int256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMarketStats\",\"inputs\":[],\"outputs\":[{\"name\":\"_totalLiquidity\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_initialLiquidity\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_sharesPerOutcome\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"_betAmountPerOutcome\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getOutcomeRules\",\"inputs\":[],\"outputs\":[{\"name\":\"rules\",\"type\":\"tuple[]\",\"internalType\":\"structIMarket_V3.OutcomeRule[]\",\"components\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"payoutType\",\"type\":\"uint8\",\"internalType\":\"enumIPricingStrategy.PayoutType\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPrice\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"price\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSettlementResult\",\"inputs\":[],\"outputs\":[{\"name\":\"result\",\"type\":\"tuple\",\"internalType\":\"structIMarket_V3.SettlementResult\",\"components\":[{\"name\":\"outcomeIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"weights\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"rawResult\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"settledAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"resolved\",\"type\":\"bool\",\"internalType\":\"bool\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStats\",\"inputs\":[],\"outputs\":[{\"name\":\"stats\",\"type\":\"tuple\",\"internalType\":\"structIMarket_V3.MarketStats\",\"components\":[{\"name\":\"totalLiquidity\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"borrowedAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalBetAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalSharesPerOutcome\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"totalBetPerOutcome\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialLiquidity\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"config\",\"type\":\"tuple\",\"internalType\":\"structIMarket_V3.MarketConfig\",\"components\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"matchId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"kickoffTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"settlementToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"pricingStrategy\",\"type\":\"address\",\"internalType\":\"contractIPricingStrategy\"},{\"name\":\"resultMapper\",\"type\":\"address\",\"internalType\":\"contractIResultMapper\"},{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"initialLiquidity\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outcomeRules\",\"type\":\"tuple[]\",\"internalType\":\"structIMarket_V3.OutcomeRule[]\",\"components\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"payoutType\",\"type\":\"uint8\",\"internalType\":\"enumIPricingStrategy.PayoutType\"}]},{\"name\":\"uri\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"admin\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"paramController\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isApprovedForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"kickoffTime\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"lock\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"marketId\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"matchId\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"outcomeCount\",\"inputs\":[],\"outputs\":[{\"name\":\"count\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"paramController\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIParamController\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"payoutScaleBps\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"placeBetFor\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"minShares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"previewBet\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"newPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pricingState\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pricingStrategy\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIPricingStrategy\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"redeemBatchFor\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"outcomeIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"sharesArray\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"totalPayout\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"redeemFor\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"payout\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"refundFor\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resolve\",\"inputs\":[{\"name\":\"rawResult\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resultMapper\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIResultMapper\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeBatchTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"settlementResult\",\"inputs\":[],\"outputs\":[{\"name\":\"rawResult\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"settledAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"resolved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"settlementToken\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIERC20\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"status\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumIMarket_V3.MarketStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalBetAmountPerOutcome\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalLiquidity\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalPayoutClaimed\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalSharesPerOutcome\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"uri\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"userExposure\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"vault\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractILiquidityVault_V3\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"ApprovalForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BetPlaced\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BetPlaced\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"version\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketCancelled\",\"inputs\":[{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketCancelled\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketCreated\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"matchId\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"kickoffTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"pricingStrategy\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"resultMapper\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketFinalized\",\"inputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketFinalized\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketInitialized\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"matchId\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"pricingStrategy\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"resultMapper\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"outcomeCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketLocked\",\"inputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketLocked\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketOpened\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketResolved\",\"inputs\":[{\"name\":\"outcomeIds\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"weights\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketResolved\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"outcomeIds\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"weights\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"rawResult\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PayoutClaimed\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"payout\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PayoutClaimed\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"payout\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PayoutScaled\",\"inputs\":[{\"name\":\"scaleBps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RefundClaimed\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RefundClaimed\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"refundAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferBatch\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferSingle\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"URI\",\"inputs\":[{\"name\":\"value\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultFunded\",\"inputs\":[{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultLossOnCancel\",\"inputs\":[{\"name\":\"lossAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultSettled\",\"inputs\":[{\"name\":\"principal\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"pnl\",\"type\":\"int256\",\"indexed\":false,\"internalType\":\"int256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"AfterKickoff\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BeforeKickoff\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ERC1155InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"tokenId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidArrayLength\",\"inputs\":[{\"name\":\"idsLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"valuesLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidOperator\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155MissingApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InsufficientShares\",\"inputs\":[{\"name\":\"requested\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"available\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"InvalidInitialization\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidOutcome\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"InvalidStatus\",\"inputs\":[{\"name\":\"expected\",\"type\":\"uint8\",\"internalType\":\"enumIMarket_V3.MarketStatus\"},{\"name\":\"actual\",\"type\":\"uint8\",\"internalType\":\"enumIMarket_V3.MarketStatus\"}]},{\"type\":\"error\",\"name\":\"MarketPayoutCapExceeded\",\"inputs\":[{\"name\":\"totalExposure\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"cap\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"NotAuthorized\",\"inputs\":[{\"name\":\"caller\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"NotInitializing\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotWinningOutcome\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"OddsOutOfRange\",\"inputs\":[{\"name\":\"odds\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"minOdds\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxOdds\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"OnlyFactory\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"SlippageExceeded\",\"inputs\":[{\"name\":\"minShares\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"actualShares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"UserExposureLimitExceeded\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"currentExposure\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"limit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}]",
	Bin: "0x60a06040523461022757604051601f615ab838819003918201601f19168301916001600160401b038311848410176102135780849260209460405283398101031261022757516001600160a01b0381168082036102275760405160208101906001600160401b03821181831017610213575f9160405252600254600181811c91168015610209575b60208210146101f557601f81116101ad575b505f6002556001600455612710601a5515610168576080525f516020615a985f395f51905f525460ff8160401c16610159576002600160401b03196001600160401b03821601610103575b60405161586c908161022c82396080518181816124a201526139920152f35b6001600160401b0319166001600160401b039081175f516020615a985f395f51905f52556040519081527fc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d290602090a15f6100e4565b63f92ee8a960e01b5f5260045ffd5b60405162461bcd60e51b815260206004820152601760248201527f4d61726b65743a20496e76616c696420666163746f72790000000000000000006044820152606490fd5b60025f52601f0160051c7f405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace908101905b8181106101ea5750610099565b5f81556001016101dd565b634e487b7160e01b5f52602260045260245ffd5b90607f1690610087565b634e487b7160e01b5f52604160045260245ffd5b5f80fdfe60806040526004361015610011575f80fd5b5f3560e01c8062fdd58e1461040357806301ffc9a7146103fe57806305261aea146103f957806307e2cea5146103f45780630b4f3f3d146103ef5780630c7a647b146103ea5780630e89341c146103e557806315770f92146103e057806317a0916b146103db5780631afbb7a4146103d65780631f5dca1a146103d1578063200d2ed2146103cc578063248a9ca3146103c75780632eb2c2d6146103c25780632f2ff15d146103bd57806330d643b5146103b8578063364bc15a146103b357806336568abe146103ae5780633f4ba83a146103a957806340702adc146103a457806341def6e71461039f578063445df9d61461039a57806344f8dbf0146103955780634e1273f4146103905780635c975abb1461038b5780635cee3ba11461038657806360261dd9146103815780636ed71ede1461037c5780637566d1301461037757806378b99c24146103725780637b9e618d1461036d578063800416fc1461036857806381e8d208146103635780638456cb591461035e5780638fd9bad91461035957806391d148541461035457806399892e471461034f578063a217fddf1461034a578063a22cb46514610345578063b426b82514610340578063b8056df81461033b578063bb99b50514610336578063c1a1d96414610331578063c45a01551461032c578063c59d484714610327578063c5a0fb8514610322578063c6ee69ff1461031d578063d0d1854d14610318578063d300cb3114610313578063d547741f1461030e578063de300b0014610309578063e405618614610304578063e63ab1e9146102ff578063e7572230146102fa578063e985e9c5146102f5578063eb0382cc146102f0578063f242432a146102eb578063f315f82b146102e6578063f5b541a6146102e1578063f83d08ba146102dc578063fbfa77cf146102d7578063fc35f991146102d25763ff4cd5b9146102cd575f80fd5b61308e565b613044565b61301c565b612f89565b612f62565b612e97565b612daa565b612cba565b612c6f565b612bdc565b612bb5565b612a1a565b612960565b612897565b61287a565b612852565b612801565b6125dd565b612524565b61248d565b612465565b612237565b6120f5565b61203f565b611f76565b611f52565b611e7c565b611c5f565b611c42565b611be9565b611bc1565b611ba4565b611b7c565b611b54565b6115fa565b6115dd565b6115b3565b611517565b611492565b6113d1565b6113a7565b6112f8565b611279565b61122e565b6111c8565b611180565b611159565b611132565b6110ec565b611058565b610ee0565b610eb7565b610e77565b610e5a565b610d29565b610d0c565b610ccf565b610b29565b61098a565b610914565b6104f4565b61046b565b61041d565b6001600160a01b0381160361041957565b5f80fd5b3461041957604036600319011261041957602061045060043561043f81610408565b6024355f525f835260405f20611264565b54604051908152f35b6001600160e01b031981160361041957565b346104195760203660031901126104195760043561048881610459565b63ffffffff60e01b16637965db0b60e01b81149081156104b1575b506040519015158152602090f35b636cdb3d1360e11b8114915081156104e3575b81156104d2575b505f6104a3565b6301ffc9a760e01b1490505f6104cb565b6303a24d0760e21b811491506104c4565b34610419576020366003190112610419576004356105106145d9565b61051e612710821115613110565b60105460ff1661052d81610ea8565b600381036108f45750600c546001600160a01b03906105559082165b6001600160a01b031690565b161515806108e9575b6105a8575b610575600460ff196010541617601055565b6040514281527fdcf9d491e583ce9369e93cab66baeac633ef4c5587e0a9bf3897e6b72c1786339080602081015b0390a1005b6105b0614810565b908061073a57505f811261070f576105ca81600d54613245565b80610683575b50600c546105e6906001600160a01b0316610549565b90600d5491803b1561041957604051631f917e2560e21b81526004810193909352602483018290525f908390604490829084905af191821561067e577f356ac6994e7660546dbe45178b00cffbb66604a6a65df6df552b6ad738304e2092610664575b50600d54604080519182526020820192909252a15b5f610563565b806106725f61067893610f62565b8061090a565b5f610649565b613282565b6009546106d19160209161069f906001600160a01b0316610549565b600c546106b4906001600160a01b0316610549565b5f60405180968195829463095ea7b360e01b845260048401613267565b03925af1801561067e57156105d0576107019060203d602011610708575b6106f98183610f62565b810190613252565b505f6105d0565b503d6106ef565b610718816131da565b600d5490808211156107325761072d91613238565b6105ca565b50505f6105ca565b9061074482601a55565b815f8212156108e35761076561076d91610760610772946131da565b613207565b612710900490565b6131da565b5f81126108b85761078581600d54613245565b8061086e575b50600c546107a1906001600160a01b0316610549565b90600d5491803b1561041957604051632b1f94c760e11b81526004810193909352602483018290525f908390604490829084905af191821561067e577f356ac6994e7660546dbe45178b00cffbb66604a6a65df6df552b6ad738304e209261085a575b50600d54604080519182526020820192909252a16127108110610828575b5061065e565b6040519081527f072a3954a6d26f8b2dbf96f4387a27ff0afb5edc4a967ce5154feb68016838e290602090a15f610822565b806106725f61086893610f62565b5f610804565b60095461088a9160209161069f906001600160a01b0316610549565b03925af1801561067e571561078b576108b19060203d602011610708576106f98183610f62565b505f61078b565b6108c1816131da565b600d5490808211156108db576108d691613238565b610785565b50505f610785565b50610772565b50600d54151561055e565b63f924664d60e01b5f5261090790613154565b5ffd5b5f91031261041957565b34610419575f3660031901126104195760206040515f5160206157775f395f51905f528152f35b906020600319830112610419576004356001600160401b0381116104195760040182601f82011215610419578035926001600160401b0384116104195760208481840193010111610419579190565b34610419576109983661093b565b6109a0614647565b6109ca6109af60105460ff1690565b6109b881610ea8565b60018114908115610b15575b5061328d565b600c546109df906001600160a01b0316610549565b6001600160a01b038116151580610b0a575b610a27575b505f5160206156f75f395f51905f5291610a18600560ff196010541617601055565b6105a3604051928392836132f1565b600954610a6491602091610a43906001600160a01b0316610549565b600d54915f60405180968195829463095ea7b360e01b845260048401613267565b03925af1801561067e57610aed575b50600c54610a89906001600160a01b0316610549565b91600d5492803b1561041957604051633596a5d560e11b815260048101949094525f908490602490829084905af192831561067e575f5160206156f75f395f51905f5293610ad9575b50916109f6565b806106725f610ae793610f62565b5f610ad2565b610b059060203d602011610708576106f98183610f62565b610a73565b50600d5415156109f1565b60029150610b2281610ea8565b145f6109c4565b34610419576020366003190112610419576004356001600160401b038111610419576101806003198236030112610419575f5160206157f75f395f51905f5254906001600160401b03610b9460ff604085901c1615610b87565b1590565b936001600160401b031690565b1680159081610c8f575b6001149081610c85575b159081610c7c575b50610c6d57610bf79082610bea60016001600160401b03195f5160206157f75f395f51905f525416175f5160206157f75f395f51905f5255565b610c49575b60040161398f565b610bfd57005b5f5160206157f75f395f51905f52805460ff60401b19169055604051600181527fc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d29080602081016105a3565b5f5160206157f75f395f51905f52805460ff60401b1916600160401b179055610bef565b63f92ee8a960e01b5f5260045ffd5b9050155f610bb0565b303b159150610ba8565b839150610b9e565b805180835260209291819084018484015e5f828201840152601f01601f1916010190565b906020610ccc928181520190610c97565b90565b3461041957602036600319011261041957610d08604051610cf1602082610f62565b5f8152604051918291602083526020830190610c97565b0390f35b34610419575f366003190112610419576020601754604051908152f35b34610419575f36600319011261041957610d41614647565b600c54610d64906001600160a01b0390610d5c908216610549565b161515613d82565b610d70600d5415613dcc565b610da6601854610d81811515613e11565b610da16001610d9260105460ff1690565b610d9b81610ea8565b14613e5d565b600d55565b600c54610dbb906001600160a01b0316610549565b60185490803b156104195760405163317afabb60e21b815260048101839052905f908290602490829084905af1801561067e57610e46575b600c54610e08906001600160a01b0316610549565b6018546040519081526001600160a01b0391909116907fba24bd9b798cca64d1031eda1ced9398802343e44e07779bb510d7a21ddddef190602090a2005b806106725f610e5493610f62565b80610df3565b34610419575f366003190112610419576020600d54604051908152f35b34610419575f366003190112610419576020600854604051908152f35b634e487b7160e01b5f52602160045260245ffd5b60061115610eb257565b610e94565b34610419575f3660031901126104195760ff601054166040516006821015610eb2576020918152f35b34610419576020366003190112610419576020610f0b6004355f526003602052600160405f20015490565b604051908152f35b634e487b7160e01b5f52604160045260245ffd5b60a081019081106001600160401b03821117610f4257604052565b610f13565b604081019081106001600160401b03821117610f4257604052565b90601f801991011681019081106001600160401b03821117610f4257604052565b6001600160401b038111610f425760051b60200190565b9080601f83011215610419578135610fb181610f83565b92610fbf6040519485610f62565b81845260208085019260051b82010192831161041957602001905b828210610fe75750505090565b8135815260209182019101610fda565b6001600160401b038111610f4257601f01601f191660200190565b81601f820112156104195780359061102982610ff7565b926110376040519485610f62565b8284526020838301011161041957815f926020809301838601378301015290565b346104195760a03660031901126104195760043561107581610408565b6024359061108282610408565b6044356001600160401b038111610419576110a1903690600401610f9a565b6064356001600160401b038111610419576110c0903690600401610f9a565b90608435936001600160401b038511610419576110e46110ea953690600401611012565b93613e9c565b005b34610419576040366003190112610419576110ea60243560043561110f82610408565b61112d611128825f526003602052600160405f20015490565b6147d9565b614b53565b34610419575f3660031901126104195760206040515f5160206158175f395f51905f528152f35b34610419575f3660031901126104195760206040515f5160206157575f395f51905f528152f35b34610419576040366003190112610419576004356024356111a081610408565b336001600160a01b038216036111b9576110ea91614bb8565b63334bd91960e11b5f5260045ffd5b34610419575f366003190112610419576111e06146a2565b60055460ff81161561121f5760ff19166005557f5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa6020604051338152a1005b638dfc202b60e01b5f5260045ffd5b34610419575f366003190112610419576020601854604051908152f35b6001600160a01b03165f908152601d6020526040902090565b9060018060a01b03165f5260205260405f2090565b346104195760203660031901126104195760043561129681610408565b60018060a01b03165f52601d602052602060405f2054604051908152f35b90602080835192838152019201905f5b8181106112d15750505090565b82518452602093840193909201916001016112c4565b906020610ccc9281815201906112b4565b34610419575f36600319011261041957600a54600f5460408051631e2463bf60e21b815260048101929092526024820152905f9082906001600160a01b0316818061134560448201611cec565b03915afa801561067e575f90611366575b610d0890604051918291826112e7565b503d805f833e6113768183610f62565b810190602081830312610419578051916001600160401b03831161041957610d08926113a29201613ef5565b611356565b34610419576020366003190112610419576004355f52601b602052602060405f2054604051908152f35b34610419576040366003190112610419576004356001600160401b03811161041957366023820112156104195780600401359061140d82610f83565b9161141b6040519384610f62565b8083526024602084019160051b8301019136831161041957602401905b82821061147857836024356001600160401b03811161041957610d089161146661146c923690600401610f9a565b90613f98565b604051918291826112e7565b60208091833561148781610408565b815201910190611438565b34610419575f36600319011261041957602060ff600554166040519015158152f35b6020815260a060806115036114ed6114d7865185602088015260c08701906112b4565b6020870151868203601f190160408801526112b4565b6040860151858203601f19016060870152610c97565b936060810151828501520151151591015290565b34610419575f366003190112610419575f608060405161153681610f27565b6060815260606020820152606060408201528260608201520152610d0860405161155f81610f27565b611567614012565b815261157161405a565b602082015260405161158d8161158681611d78565b0382610f62565b6040820152601554606082015260ff6016541615156080820152604051918291826114b4565b34610419576020366003190112610419576004355f52601c602052602060405f2054604051908152f35b34610419575f366003190112610419576020600654604051908152f35b346104195760803660031901126104195760043561161781610408565b6064356024356044356116286146fd565b611630614c28565b611638614c48565b60105460ff1661164781610ea8565b60018103611b415750600854421015611b3257600f54821015611b1e57600a54611679906001600160a01b0316610549565b604051630a03357b60e31b815293905f85806116998688600484016140cf565b0381845afa91821561067e575f955f93611af4575b50808610611add5750600e546116cc906001600160a01b0316610549565b6001600160a01b0381166117ad575b505083610d089561170c7f7363e6581df4db69463222156be4a09656528b9f1302890fa4c0b60819b69fc69361388b565b61172061171b85601754613245565b601755565b611732855f52601b60205260405f2090565b61173d838254613245565b9055611751855f52601c60205260405f2090565b61175c858254613245565b9055611771611769613d6e565b838784614c63565b6040805194855260208501929092526001600160a01b03169290819081015b0390a361179d6001600455565b6040519081529081906020820190565b6117bf846117ba886131ef565b61321a565b60405163dec9eea160e01b81527f7466e4685b64fc371ca29f17e7d140a13b060568f09797b5fb7012dac66d580760048201526127106024820152602081604481865afa90811561067e575f91611abe575b5060405163dec9eea160e01b81527f57a0b7847ae62b66f9c240e3a7b867601616a4e4e87c51d3bbf1aaf9f37b03dc600482015262989680602482015291602083604481875afa92831561067e575f93611a9d575b508181108015611a94575b611a7c57505060405163dec9eea160e01b81527f95effa720c999280aeed711fcfef3f6a5706c78edd85dba56295e4112e1b1bb66004820152640ba43b74006024820152929050602083604481855afa92831561067e575f93611a5b575b506118e3876118dd8a61124b565b54613245565b92808411611a375750602060049160405192838092631c631a2560e21b82525afa90811561067e575f91611a18575b50611957575b508561170c7f7363e6581df4db69463222156be4a09656528b9f1302890fa4c0b60819b69fc693879361194d610d089a61124b565b55935050956116db565b60405163dec9eea160e01b81527f3ed1e1dbf5d5ab4e0e69d2569d7b4d595f66d9e49b32d667470627723d11869960048201526509184e72a000602482015290602090829060449082905afa90811561067e575f916119e9575b506119c7866119c286601754613245565b613245565b8181116119d45750611918565b63f858019960e01b5f5260045260245260445ffd5b611a0b915060203d602011611a11575b611a038183610f62565b8101906140eb565b5f6119b1565b503d6119f9565b611a31915060203d602011610708576106f98183610f62565b5f611912565b6379062f2f60e11b5f526001600160a01b038916600452602484905260445260645ffd5b611a7591935060203d602011611a1157611a038183610f62565b915f6118cf565b634c4d396f60e11b5f5260045260245260445260645ffd5b50828111611871565b611ab791935060203d602011611a1157611a038183610f62565b915f611866565b611ad7915060203d602011611a1157611a038183610f62565b5f611811565b6371c4efed60e01b5f52600452602485905260445ffd5b909250611b149195503d805f833e611b0c8183610f62565b8101906140a2565b949094915f6116ae565b6316e55c9760e11b5f52600482905260245ffd5b631fa78bb960e21b5f5260045ffd5b63f924664d60e01b5f526109079061316b565b34610419575f36600319011261041957600a546040516001600160a01b039091168152602090f35b34610419575f366003190112610419576009546040516001600160a01b039091168152602090f35b34610419575f366003190112610419576020601a54604051908152f35b34610419575f366003190112610419576040611bdb614151565b825191151582526020820152f35b34610419575f36600319011261041957611c016146a2565b611c09614c48565b600160ff1960055416176005557f62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a2586020604051338152a1005b34610419575f366003190112610419576020601954604051908152f35b3461041957604036600319011261041957602060ff611c95602435600435611c8682610408565b5f526003845260405f20611264565b54166040519015158152f35b634e487b7160e01b5f525f60045260245ffd5b90600182811c92168015611ce2575b6020831014611cce57565b634e487b7160e01b5f52602260045260245ffd5b91607f1691611cc3565b6011545f9291611cfb82611cb4565b8082529160018116908115611d5c5750600114611d16575050565b60115f9081529293509091905f5160206157375f395f51905f525b838310611d42575060209250010190565b600181602092949394548385870101520191019190611d31565b9050602093945060ff929192191683830152151560051b010190565b6014545f9291611d8782611cb4565b8082529160018116908115611d5c5750600114611da2575050565b60145f9081529293509091907fce6d7b5282bd9a3661ae061feed1dbda4e52ab073b1f9285be6e155d9c38d4ec5b838310611de1575060209250010190565b600181602092949394548385870101520191019190611dd0565b5f9291815491611e0a83611cb4565b8083529260018116908115611e5f5750600114611e2657505050565b5f9081526020812093945091925b838310611e45575060209250010190565b600181602092949394548385870101520191019190611e34565b915050602093945060ff929192191683830152151560051b010190565b34610419575f366003190112610419576040515f600754611e9c81611cb4565b8084529060018116908115611f2e5750600114611ed0575b610d0883611ec481850382610f62565b60405191829182610cbb565b60075f9081527fa66cc928b5edb82af9bd49922954155ab7b0942694bea4ce44661d9a8736c688939250905b808210611f1457509091508101602001611ec4611eb4565b919260018160209254838588010152019101909291611efc565b60ff191660208086019190915291151560051b84019091019150611ec49050611eb4565b34610419575f3660031901126104195760206040515f8152f35b8015150361041957565b3461041957604036600319011261041957600435611f9381610408565b602435611f9f81611f6c565b6001600160a01b03821691821561200a5781611fc9611fda92335f52600160205260405f20611264565b9060ff801983541691151516179055565b60405190151581527f17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c3160203392a3005b62ced3e160e81b5f525f60045260245ffd5b60609060031901126104195760043561203481610408565b906024359060443590565b346104195761204d3661201c565b90612056614c28565b61205e614c48565b6001600160a01b0383163381141590816120a4575b506120915761208192614dac565b6001600455604051908152602090f35b634a0bfec160e01b5f523360045260245ffd5b90505f52600160205260ff6120bc3360405f20611264565b5416155f612073565b9181601f84011215610419578235916001600160401b038311610419576020808501948460051b01011161041957565b346104195760603660031901126104195760043561211281610408565b6024356001600160401b038111610419576121319036906004016120c5565b6044356001600160401b038111610419576121509036906004016120c5565b91909361215b614c28565b612163614c48565b5f94336001600160a01b038316141580612201575b6121ee57612187848414614240565b5f5b83811061219e57610d088761179d6001600455565b6121a9818684614286565b356121b7575b600101612189565b956121e66001916121e06121cc8a888b614286565b356121d88b8a88614286565b359087614dac565b90613245565b9690506121af565b634a0bfec160e01b5f523360045260245ffd5b50612232610b8361222b336122268660018060a01b03165f52600160205260405f2090565b611264565b5460ff1690565b612178565b34610419576122453661093b565b61224d614647565b61226d600361225e60105460ff1690565b61226781610ea8565b14614296565b600c54612282906001600160a01b0316610549565b916001600160a01b03831615158061245a575b6122bc575b5f5160206156f75f395f51905f529250610a18600560ff196010541617601055565b6009546122d1906001600160a01b0316610549565b6040516370a0823160e01b8152306004820152602081602481855afa90811561067e575f9161243b575b50600d54808210156124335750935b8461236b575b5050600d545f5160206156f75f395f51905f5293818110612333575b505061229a565b61179d612361917f2db84acdcb4d6409ed54c15f36309289e57bb4d5f16eb63f1b3798288e80354593613238565b0390a15f8061232c565b84612390926020925f60405180968195829463095ea7b360e01b845260048401613267565b03925af1801561067e57612416575b50600c546123b5906001600160a01b0316610549565b92833b1561041957604051633596a5d560e11b815260048101829052935f908590602490829084905af193841561067e575f5160206156f75f395f51905f5294612402575b819450612310565b806106725f61241093610f62565b5f6123fa565b61242e9060203d602011610708576106f98183610f62565b61239f565b90509361230a565b612454915060203d602011611a1157611a038183610f62565b5f6122fb565b50600d541515612295565b34610419575f36600319011261041957600b546040516001600160a01b039091168152602090f35b34610419575f366003190112610419576040517f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03168152602090f35b90610ccc9160208152815160208201526020820151604082015260408201516060820152608061250f606084015160a08385015260c08401906112b4565b9201519060a0601f19828503019101526112b4565b34610419575f3660031901126104195761253c6142dd565b600f54612559601754808452600d54602085015260185490613238565b604083015261256781613f52565b6060830190815261257782613f52565b90608084019182525f5b8381106125965760405180610d0887826124d1565b806125ab6001925f52601b60205260405f2090565b546125b7828551613f84565b526125ca815f52601c60205260405f2090565b546125d6828651613f84565b5201612581565b34610419576125eb3661201c565b91906125f5614c28565b6125fd614c48565b6001600160a01b03821633811415806127e1575b6120915760105460ff1661262481610ea8565b600581036127ce575061264283612226845f525f60205260405f2090565b548085116127b75750600a546126c59490602090612668906001600160a01b0316610549565b61267a855f52601b60205260405f2090565b549061268e865f52601c60205260405f2090565b54916040518099819482936324a29b4f60e01b8452888b600486019094939260609260808301968352602083015260408201520152565b03915afa93841561067e57610d08955f95612770575b5081612747868361270f7f2a62c9fef01ce4cfe24b93ff7cef58e2c929cc918e5d27a85cb76dd6bbbd6d1596898497615268565b836127198261124b565b5410612760576127288161124b565b612733858254613238565b90555b6009546001600160a01b0316615387565b6040805191825260208201929092529081908101611790565b5f61276a8261124b565b55612736565b6127479550916127af7f2a62c9fef01ce4cfe24b93ff7cef58e2c929cc918e5d27a85cb76dd6bbbd6d159360203d602011611a1157611a038183610f62565b9550916126db565b63658ec5dd60e11b5f52600485905260245260445ffd5b63f924664d60e01b5f5261090790613182565b50805f52600160205260ff6127f93360405f20611264565b541615612611565b34610419575f366003190112610419576128416040516128248161158681611d78565b60155460ff60165416604051938493606085526060850190610c97565b916020840152151560408301520390f35b34610419575f36600319011261041957600e546040516001600160a01b039091168152602090f35b34610419575f366003190112610419576020600f54604051908152f35b34610419576040366003190112610419576110ea6024356004356128ba82610408565b6128d3611128825f526003602052600160405f20015490565b614bb8565b906002821015610eb25752565b602081016020825282518091526040820191602060408360051b8301019401925f915b83831061291757505050505090565b9091929394602080600192603f1985820301865261295189519183806129468551604085526040850190610c97565b9401519101906128d8565b97019301930191939290612908565b34610419575f36600319011261041957600f5461297c81610f83565b6129896040519182610f62565b818152600f5f9081527f8d1108e10bcb7c27dddfc02ed9d693a074039d026cf4ea4240b40f7d581ac8029290602083015b8282106129cf5760405180610d0886826128e5565b6040516129db81610f47565b6040516129ec81611586818a611dfb565b815260ff6001870154166002811015610eb257600192826020928360029501528152019501910190936129ba565b3461041957612a283661093b565b90612a3161476b565b60105460ff16612a4081610ea8565b60028103612ba257612a7f5f8484612a62610549600b5460018060a01b031690565b906040518095819482936346e56c1160e01b8452600484016132f1565b03915afa90811561067e575f905f92612b7d575b50612aa08151151561434e565b612aad8151835114614240565b600f545f9290835b8251851015612b0757612aff600191612ad9612ad18887613f84565b511515614396565b612aee84612ae78989613f84565b51106143d8565b612af88786613f84565b5190613245565b940193612ab5565b8284612b386127107ffadc9677ca5f9faa603f27f608a14a82af1de8b4e0641f29b0f642955ea8f664941115614421565b612b4181614477565b612b4a826144ee565b612b5c600160ff196016541617601655565b612b6e600360ff196010541617601055565b6105a360405192839283614565565b9050612b9b91503d805f833e612b938183610f62565b810190614307565b9082612a93565b63f924664d60e01b5f5261090790613199565b34610419575f3660031901126104195760206040515f5160206157b75f395f51905f528152f35b3461041957602036600319011261041957600435600a546040805163e0b3c6fd60e01b81526004810193909352602483015260209082906001600160a01b03168180612c2a60448201611cec565b03915afa801561067e57610d08915f91612c50575b506040519081529081906020820190565b612c69915060203d602011611a1157611a038183610f62565b5f612c3f565b3461041957604036600319011261041957602060ff611c95600435612c9381610408565b60243590612ca082610408565b6001600160a01b03165f9081526001855260409020611264565b3461041957604036600319011261041957600435602435600a54612d08905f90612cec906001600160a01b0316610549565b9260405180938192630a03357b60e31b835287600484016140cf565b0381855afa801561067e57612d42935f925f92612d87575b50926020929360405180968194829363e0b3c6fd60e01b84526004840161458a565b03915afa91821561067e575f92612d66575b50604080519182526020820192909252f35b612d8091925060203d602011611a1157611a038183610f62565b905f612d54565b60209350612da09192503d805f833e611b0c8183610f62565b9092909190612d20565b346104195760a036600319011261041957600435612dc781610408565b602435612dd381610408565b60443590606435926084356001600160401b03811161041957612dfa903690600401611012565b926001600160a01b0382163381141580612e77575b612e61576001600160a01b03841615612e4e5715612e3c576110ea94612e34916151bd565b929091615021565b626a0d4560e21b5f525f60045260245ffd5b632bfa23e760e11b5f525f60045260245ffd5b63711bec9160e11b5f523360045260245260445ffd5b50805f52600160205260ff612e8f3360405f20611264565b541615612e0f565b34610419575f366003190112610419576040515f601154612eb781611cb4565b8084529060018116908115612f3e5750600114612ef3575b610d0883612edf81850382610f62565b604051918291602083526020830190610c97565b60115f9081525f5160206157375f395f51905f52939250905b808210612f2457509091508101602001612edf612ecf565b919260018160209254838588010152019101909291612f0c565b60ff191660208086019190915291151560051b84019091019150612edf9050612ecf565b34610419575f3660031901126104195760206040515f5160206157975f395f51905f528152f35b34610419575f36600319011261041957612fa16145d9565b60ff601054166006811015610eb25760018103612ffc57612fca600260ff196010541617601055565b6040514281527f2d597ad63f8c5090e993389fdab0249476d2f29bcbc52e99da3236a4370f11ba9080602081016105a3565b63f924664d60e01b5f5260016004526006811015610eb25760245260445ffd5b34610419575f36600319011261041957600c546040516001600160a01b039091168152602090f35b34610419575f366003190112610419576020610f0b6145a1565b92610ccc949261308092855260208501526080604085015260808401906112b4565b9160608184039101526112b4565b34610419575f3660031901126104195760175460185490600f546130b181613f52565b6130ba82613f52565b915f5b8181106130d757505090610d08916040519485948561305e565b806001915f52601b60205260405f20546130f18286613f84565b52805f52601c60205260405f20546131098287613f84565b52016130bd565b1561311757565b60405162461bcd60e51b81526020600482015260156024820152744d61726b65743a20496e76616c6964207363616c6560581b6044820152606490fd5b9060449160036004526006811015610eb257602452565b9060449160016004526006811015610eb257602452565b9060449160056004526006811015610eb257602452565b9060449160026004526006811015610eb257602452565b90604491600480526006811015610eb257602452565b634e487b7160e01b5f52601160045260245ffd5b600160ff1b81146131ea575f0390565b6131c6565b9061271082029180830461271014901517156131ea57565b818102929181159184041417156131ea57565b8115613224570490565b634e487b7160e01b5f52601260045260245ffd5b919082039182116131ea57565b919082018092116131ea57565b908160209103126104195751610ccc81611f6c565b6001600160a01b039091168152602081019190915260400190565b6040513d5f823e3d90fd5b1561329457565b60405162461bcd60e51b815260206004820152601560248201527413585c9ad95d0e8810d85b9b9bdd0818d85b98d95b605a1b6044820152606490fd5b908060209392818452848401375f828201840152601f01601f1916010190565b916020610ccc9381815201916132d1565b903590601e198136030182121561041957018035906001600160401b03821161041957602001918160051b3603831361041957565b1561333e57565b60405162461bcd60e51b81526020600482015260166024820152754d61726b65743a204d696e2032206f7574636f6d657360501b6044820152606490fd5b1561338357565b60405162461bcd60e51b81526020600482015260186024820152774d61726b65743a204d617820313030206f7574636f6d657360401b6044820152606490fd5b35610ccc81610408565b156133d457565b606460405162461bcd60e51b815260206004820152602060248201527f4d61726b65743a20496e76616c69642070726963696e672073747261746567796044820152fd5b1561341f57565b60405162461bcd60e51b815260206004820152601d60248201527f4d61726b65743a20496e76616c696420726573756c74206d61707065720000006044820152606490fd5b1561346b57565b606460405162461bcd60e51b815260206004820152602060248201527f4d61726b65743a20496e76616c696420736574746c656d656e7420746f6b656e6044820152fd5b156134b657565b60405162461bcd60e51b815260206004820152602160248201527f4d61726b65743a204b69636b6f6666206d75737420626520696e2066757475726044820152606560f81b6064820152608490fd5b903590601e198136030182121561041957018035906001600160401b0382116104195760200191813603831361041957565b818110613542575050565b5f8155600101613537565b9190601f811161355c57505050565b613586925f5260205f20906020601f840160051c83019310613588575b601f0160051c0190613537565b565b9091508190613579565b91906001600160401b038111610f42576135b8816135b1600754611cb4565b600761354d565b5f601f82116001146135f65781906135e693945f926135eb575b50508160011b915f199060031b1c19161790565b600755565b013590505f806135d2565b60075f52601f198216937fa66cc928b5edb82af9bd49922954155ab7b0942694bea4ce44661d9a8736c688915f5b86811061365b5750836001959610613642575b505050811b01600755565b01355f19600384901b60f8161c191690555f8080613637565b90926020600181928686013581550194019101613624565b634e487b7160e01b5f52603260045260245ffd5b91908110156136a95760051b81013590603e1981360301821215610419570190565b613673565b600f548110156136a957600f5f5260205f209060011b01905f90565b80548210156136a9575f5260205f209060011b01905f90565b3560028110156104195790565b906002811015610eb25760ff80198354169116179055565b90600f54600160401b811015610f425780600161372a9201600f55600f6136ca565b61381b576137388380613505565b6001600160401b038195929511610f425761375d816137578554611cb4565b8561354d565b5f601f82116001146137a6576001926137968361379f94602094613586999a5f926135eb5750508160011b915f199060031b1c19161790565b85555b016136e3565b91016136f0565b601f198216906137b9855f5260205f2090565b915f5b81811061380357508360209361358698996001979461379f978995106137ea575b505050811b018555613799565b01355f19600384901b60f8161c191690555f80806137dd565b9192602060018192868c0135815501940192016137bc565b611ca1565b81601f820112156104195780519061383782610ff7565b926138456040519485610f62565b8284526020838301011161041957815f9260208093018386015e8301015290565b906020828203126104195781516001600160401b03811161041957610ccc9201613820565b9081516001600160401b038111610f42576138b2816138ab601154611cb4565b601161354d565b602092601f82116001146138f1576138e1929382915f926138e65750508160011b915f199060031b1c19161790565b601155565b015190505f806135d2565b60115f52601f198216935f5160206157375f395f51905f52915f5b868110613942575083600195961061392a575b505050811b01601155565b01515f1960f88460031b161c191690555f808061391f565b9192602060018192868501518155019401920161390c565b9160609396959491613974916080855260808501916132d1565b6001600160a01b039687166020840152951660408201520152565b907f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0381163303613d5f578291613a846101008401926139e460026139db8688613302565b90501015613337565b6139fc60646139f38688613302565b9050111561337c565b60808501613a1f6001600160a01b03613a17610549846133c3565b1615156133cd565b60a08601613a3c613a35610549610549846133c3565b1515613418565b613abf613a9d61054960608a01613a5f613a58610549836133c3565b1515613464565b613a9860408c0135613a93613a8d60208f613a7b4286116134af565b80359d8e600655565b019e8f90613505565b90613592565b600855565b6133c3565b600980546001600160a01b0319166001600160a01b0392909216919091179055565b613aed613acb836133c3565b600a80546001600160a01b0319166001600160a01b0392909216919091179055565b613b1b613af9826133c3565b600b80546001600160a01b0319166001600160a01b0392909216919091179055565b60e088013590613b2a82601855565b5f5b613b36888b613302565b9050811015613b645780613b5e613b59600193613b538c8f613302565b90613687565b613708565b01613b2c565b50919396613bba95989193965f85613b86610549600a5460018060a01b031690565b613b908487613302565b6040516311bf0a3360e01b81529b8c94859350839260048401908152602081019190915260400190565b03915afa96871561067e57610549613caf613ca7613cbb95613c8e7f11373cf59c951d3f7ae9d93bd1a4fc1526b8d7569479f8263e6514e304b9362a9d613c17613cca9c6105499f61171b90613cb59a5f91613d3d575b5061388b565b613c22612710601a55565b60c08a01613c32610549826133c3565b613d06575b506101608a01613c49610549826133c3565b613ccf575b50613c88613c836101408c01613c6b613c66826133c3565b614981565b50613c7d613c78826133c3565b614a1f565b506133c3565b614ab9565b50614981565b50613ca1600160ff196010541617601055565b87613505565b9a90996133c3565b956133c3565b92613302565b9290506040519586958661395a565b0390a2565b613cde610549613d00926133c3565b600e80546001600160a01b0319166001600160a01b0392909216919091179055565b5f613c4e565b613d15610549613d37926133c3565b600c80546001600160a01b0319166001600160a01b0392909216919091179055565b5f613c37565b613d5991503d805f833e613d518183610f62565b810190613866565b5f613c11565b630636a15760e11b5f5260045ffd5b60405190613d7d602083610f62565b5f8252565b15613d8957565b60405162461bcd60e51b815260206004820152601b60248201527a13585c9ad95d0e88139bc81d985d5b1d0818dbdb999a59dd5c9959602a1b6044820152606490fd5b15613dd357565b60405162461bcd60e51b815260206004820152601660248201527513585c9ad95d0e88105b1c9958591e48199d5b99195960521b6044820152606490fd5b15613e1857565b60405162461bcd60e51b815260206004820152601c60248201527f4d61726b65743a204e6f20696e697469616c206c6971756964697479000000006044820152606490fd5b15613e6457565b60405162461bcd60e51b815260206004820152601060248201526f26b0b935b2ba1d102737ba1037b832b760811b6044820152606490fd5b939291906001600160a01b0385163381141580613ed5575b612e61576001600160a01b03821615612e4e5715612e3c5761358694615021565b50805f52600160205260ff613eed3360405f20611264565b541615613eb4565b9080601f83011215610419578151613f0c81610f83565b92613f1a6040519485610f62565b81845260208085019260051b82010192831161041957602001905b828210613f425750505090565b8151815260209182019101613f35565b90613f5c82610f83565b613f696040519182610f62565b8281528092613f7a601f1991610f83565b0190602036910137565b80518210156136a95760209160051b010190565b91909180518351808203613ffd575050613fb28151613f52565b905f5b8151811015613ff65780613fe460019260051b602080828701015191890101515f525f60205260405f20611264565b54613fef8286613f84565b5201613fb5565b5090925050565b635b05999160e01b5f5260045260245260445ffd5b60405190601254808352826020810160125f5260205f20925f5b81811061404157505061358692500383610f62565b845483526001948501948794506020909301920161402c565b60405190601354808352826020810160135f5260205f20925f5b81811061408957505061358692500383610f62565b8454835260019485019487945060209093019201614074565b9190916040818403126104195780519260208201516001600160401b03811161041957610ccc9201613820565b610ccc9260609282526020820152816040820152016011611dfb565b90816020910312610419575190565b90816080910312610419576040519060808201908282106001600160401b03831117610f4257606091604052805183526020810151602084015260408101516040840152015161414981611f6c565b606082015290565b600c54614166906001600160a01b0316610549565b6001600160a01b038116158015614236575b61422f57614184614810565b5f81121561422757614195906131da565b60405163f2e288b760e01b81523060048201529091608090829060249082905afa90811561067e576141db91610765915f916141f8575b506040600d5491015190613207565b8082116141ea5750505f905f90565b6141f391613238565b600191565b61421a915060803d608011614220575b6142128183610f62565b8101906140fa565b5f6141cc565b503d614208565b50505f905f90565b505f905f90565b50600d5415614178565b1561424757565b60405162461bcd60e51b815260206004820152601760248201527609ac2e4d6cae8744098cadccee8d040dad2e6dac2e8c6d604b1b6044820152606490fd5b91908110156136a95760051b0190565b1561429d57565b60405162461bcd60e51b815260206004820152601860248201527713585c9ad95d0e88135d5cdd0818994814995cdbdb1d995960421b6044820152606490fd5b604051906142ea82610f27565b60606080835f81525f60208201525f604082015282808201520152565b9190916040818403126104195780516001600160401b0381116104195783614330918301613ef5565b9260208201516001600160401b03811161041957610ccc9201613ef5565b1561435557565b60405162461bcd60e51b81526020600482015260196024820152784d61726b65743a20456d707479206f7574636f6d652049447360381b6044820152606490fd5b1561439d57565b60405162461bcd60e51b815260206004820152601360248201527213585c9ad95d0e8816995c9bc81dd95a59da1d606a1b6044820152606490fd5b156143df57565b60405162461bcd60e51b815260206004820152601a60248201527913585c9ad95d0e88125b9d985b1a59081bdd5d18dbdb5948125160321b6044820152606490fd5b1561442857565b60405162461bcd60e51b815260206004820152602160248201527f4d61726b65743a20546f74616c207765696768742065786365656473203130306044820152602560f81b6064820152608490fd5b8051906001600160401b038211610f4257600160401b8211610f4257602090601254836012558084106144d2575b500160125f5260205f205f5b8381106144be5750505050565b6001906020845194019381840155016144b1565b6144e89060125f5284845f209182019101613537565b5f6144a5565b8051906001600160401b038211610f4257600160401b8211610f425760209060135483601355808410614549575b500160135f5260205f205f5b8381106145355750505050565b600190602084519401938184015501614528565b61455f9060135f5284845f209182019101613537565b5f61451c565b909161457c610ccc936040845260408401906112b4565b9160208184039101526112b4565b604090610ccc939281528160208201520190610c97565b60ff601054166006811015610eb257600381141590816145cd575b506145c957610ccc614810565b5f90565b6004915014155f6145bc565b5f5160206157575f395f51905f525f52600360205260ff61461a337f20551584d875e09a232c0f7cfe15286d16779f9d1d243089c9bd7a2096f6f5f8611264565b54161561462357565b63e2517d3f60e01b5f52336004525f5160206157575f395f51905f5260245260445ffd5b5f5160206157975f395f51905f525f52600360205260ff614675335f5160206157d75f395f51905f52611264565b54161561467e57565b63e2517d3f60e01b5f52336004525f5160206157975f395f51905f5260245260445ffd5b5f5160206157b75f395f51905f525f52600360205260ff6146d0335f5160206157175f395f51905f52611264565b5416156146d957565b63e2517d3f60e01b5f52336004525f5160206157b75f395f51905f5260245260445ffd5b5f5160206158175f395f51905f525f52600360205260ff61473e337f1c289e1fc7b32955238f0ad74390eae82e15c4b9c9d6f82dbff695e7d59a0a32611264565b54161561474757565b63e2517d3f60e01b5f52336004525f5160206158175f395f51905f5260245260445ffd5b5f5160206157775f395f51905f525f52600360205260ff6147ac337ff89466c3aa8f23377c6aace9f611fcee97b80cbfca673b5d358db167957bd960611264565b5416156147b557565b63e2517d3f60e01b5f52336004525f5160206157775f395f51905f5260245260445ffd5b805f52600360205260ff6147f03360405f20611264565b5416156147fa5750565b63e2517d3f60e01b5f523360045260245260445ffd5b6017546018548103908082116131ea575f905f90601254600f5461483e610549600a5460018060a01b031690565b905b82851061486b57505050828410915061485e905057610ccc91613238565b610ccc9161076d91613238565b909192939461488661487c87614ff1565b90549060031b1c90565b9061489361487c88615009565b906148a6835f52601b60205260405f2090565b548015614974576148c460016148bb866136ae565b50015460ff1690565b936148ce86613f52565b945f5b87811061494d5750906148fd602093928b6040519889958695630aa065db60e31b875260048701614d78565b0381885afa801561067e57610765614923936121e0926001965f9161492f575b50613207565b955b0193929190614840565b614947915060203d8111611a1157611a038183610f62565b5f61491d565b806149626001925f52601b60205260405f2090565b5461496d828a613f84565b52016148d1565b5096905060019150614925565b5f8052600360205260ff6149b5827f3617319a054d772f909f7c479a2cebe5066e836a939412e32403c99029b92eff611264565b5416614a1a575f805260036020526149ed817f3617319a054d772f909f7c479a2cebe5066e836a939412e32403c99029b92eff611264565b805460ff1916600117905533906001600160a01b03165f5f5160206156b75f395f51905f528180a4600190565b505f90565b5f5160206157975f395f51905f525f52600360205260ff614a4d825f5160206157d75f395f51905f52611264565b5416614a1a575f5160206157975f395f51905f525f526003602052614a7f815f5160206157d75f395f51905f52611264565b805460ff1916600117905533906001600160a01b03165f5160206157975f395f51905f525f5160206156b75f395f51905f525f80a4600190565b5f5160206157b75f395f51905f525f52600360205260ff614ae7825f5160206157175f395f51905f52611264565b5416614a1a575f5160206157b75f395f51905f525f526003602052614b19815f5160206157175f395f51905f52611264565b805460ff1916600117905533906001600160a01b03165f5160206157b75f395f51905f525f5160206156b75f395f51905f525f80a4600190565b805f52600360205260ff614b6a8360405f20611264565b5416614bb257805f526003602052614b858260405f20611264565b805460ff1916600117905533916001600160a01b0316905f5160206156b75f395f51905f525f80a4600190565b50505f90565b805f52600360205260ff614bcf8360405f20611264565b541615614bb257805f526003602052614beb8260405f20611264565b805460ff1916905533916001600160a01b0316907ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b5f80a4600190565b600260045414614c39576002600455565b633ee5aeb560e01b5f5260045ffd5b60ff60055416614c5457565b63d93c066560e01b5f5260045ffd5b6001600160a01b03811693929091908415612e4e57614c81916151bd565b928151845190818103614d635750505f5b8251811015614cd7578060019160051b614ccf614cc787612226602080868b010151958c010151945f525f60205260405f2090565b918254613245565b905501614c92565b5092919360018251145f14614d3b576020828101518482015160408051928352928201525f9133915f5160206156d75f395f51905f529190a45b8051600103614d30579060208061358695930151910151915f336155f8565b613586935f336154c9565b5f6040515f5160206156975f395f51905f52339180614d5b888883614565565b0390a4614d11565b635b05999160e01b5f5260045260245260445ffd5b9061358694969593608093614d9f928452602084015260a0604084015260a08301906112b4565b95606082015201906128d8565b9291614dba60105460ff1690565b614dc381610ea8565b60048103614fde5750614dd5826151e2565b9015614fca57614df085612226855f525f60205260405f2090565b54808311614fb35750614e0760016148bb856136ae565b600f54614e1381613f52565b905f5b818110614f8c575050600a54614e61926020929091614e3d906001600160a01b0316610549565b906017549060405195869485938493630aa065db60e31b85528b8d60048701614d78565b03915afa91821561067e57614e8092610765925f91614f735750613207565b93601a546127108110614f3d575b508481614ebd84867f2edcf4f6b46ef86243e798d3e77c29846a9ddc05cf9c7267f2f5daabe893cfa595615268565b83614ec78261124b565b5410614f2d57614ed68161124b565b614ee1858254613238565b90555b614ef8614ef383601954613245565b601955565b600954614f1190839083906001600160a01b0316615387565b6040805194855260208501929092526001600160a01b031692a3565b5f614f378261124b565b55614ee4565b610765614f6c917f2edcf4f6b46ef86243e798d3e77c29846a9ddc05cf9c7267f2f5daabe893cfa59397613207565b9490614e8e565b614947915060203d602011611a1157611a038183610f62565b80614fa16001925f52601b60205260405f2090565b54614fac8286613f84565b5201614e16565b63658ec5dd60e11b5f52600483905260245260445ffd5b63e99344f360e01b5f52600483905260245ffd5b63f924664d60e01b5f52610907906131b0565b6012548110156136a95760125f5260205f2001905f90565b6013548110156136a95760135f5260205f2001905f90565b9493929091938451825190818103614d635750506001600160a01b038681169586151595918516801515939192905f5b8451811015615116578060051b90898988602080868b010151958c010151926150a9575b93600194615087575b50505001615051565b61509f91612226614cc7925f525f60205260405f2090565b90555f898161507e565b505090916150c28d612226835f525f60205260405f2090565b548281106150f3578291898f6150ea600197968f950391612226855f525f60205260405f2090565b55909450615075565b8d61511283856040519485946303dee4c560e01b86526004860161540e565b0390fd5b5091989593929790965060018851145f146151965760208881015186820151604080519283529282015233915f5160206156d75f395f51905f5291a45b61515f575b5050505050565b84516001036151855760208061517b96015192015192336155f8565b5f80808080615158565b615191949192336154c9565b61517b565b6040515f5160206156975f395f51905f523391806151b5898d83614565565b0390a4615153565b9160405192600184526020840152604083019160018352606084015260808301604052565b601254905f5b8281101561525f5760125f527fbb8a6a4669ba250d26cd7a459eca9d215f8307e33aebe50379bc5a3617ec34448101548214615226576001016151e8565b9150506013548110156136a95760135f527f66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a0900154600191565b5050505f905f90565b926001600160a01b038416929091908315612e3c57615286916151bd565b91906020915f6040516152998582610f62565b528151845190818103614d635750505f5b8251811015615322578060051b8480828601015191870101516152d889612226845f525f60205260405f2090565b54818110615303578961222660019594936152fc9303935f525f60205260405f2090565b55016152aa565b8961511284846040519485946303dee4c560e01b86526004860161540e565b50945090915f939260018351148514615366579182015191015160408051928352602083019190915233915f5160206156d75f395f51905f5291819081015b0390a4565b506153615f5160206156975f395f51905f5291604051918291339583614565565b916020916153b06153be5f936040519283918783019563a9059cbb60e01b875260248401613267565b03601f198101835282610f62565b519082855af115613282575f513d61540557506001600160a01b0381163b155b6153e55750565b635274afe760e01b5f9081526001600160a01b0391909116600452602490fd5b600114156153de565b90949392606092608083019660018060a01b03168352602083015260408201520152565b908160209103126104195751610ccc81610459565b6001600160a01b0391821681529116602082015260a060408201819052610ccc949193919261548c929161547e91908601906112b4565b9084820360608601526112b4565b916080818403910152610c97565b3d156154c4573d906154ab82610ff7565b916154b96040519384610f62565b82523d5f602084013e565b606090565b9091949293853b6154dd575b505050505050565b6020936154ff91604051968795869563bc197c8160e01b875260048701615447565b03815f6001600160a01b0387165af15f918161558e575b50615550575061552461549a565b805191908261554957632bfa23e760e11b5f526001600160a01b03821660045260245ffd5b6020915001fd5b6001600160e01b0319166343e6837f60e01b0161557357505f80808080806154d5565b632bfa23e760e11b5f526001600160a01b031660045260245ffd5b6155b191925060203d6020116155b8575b6155a98183610f62565b810190615432565b905f615516565b503d61559f565b6001600160a01b039182168152911660208201526040810191909152606081019190915260a060808201819052610ccc92910190610c97565b9091949293853b61560b57505050505050565b60209361562d91604051968795869563f23a6e6160e01b8752600487016155bf565b03815f6001600160a01b0387165af15f9181615675575b50615652575061552461549a565b6001600160e01b031916630dc5919f60e01b0161557357505f80808080806154d5565b61568f91925060203d6020116155b8576155a98183610f62565b905f61564456fe4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0dc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62d6d24c13b2278f52540b463e1336c607596333c270867c5d3f96725c269a1c7a30adeb818ef77f204f5a603c30fa5332397b6e28fb3b7f9d937ae6a6914716de31ecc21a745e3968a04e9570e4425bc18fa8019c68028196b546d1669c200c68fc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab68e79a7bf1e0bc45d0a330c573bc367f9cf464fd326078812f301165fbda4ef197667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b92965d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862ac03103fc9c0ad7e4001ede1c469953fc46455d111e3d6da3b661469b87ece8d5f0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a007a05a596cb0ce7fdea8a1e1ec73be300bdb35097c944ce1897202f7a13122eb2a26469706673582212205dd0fe9d88169fdc7c411d5837138a10090104cbdaaefcbe0a7bd54480e4efd464736f6c634300081e0033f0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00",
}

// MarketV3ABI is the input ABI used to generate the binding from.
// Deprecated: Use MarketV3MetaData.ABI instead.
var MarketV3ABI = MarketV3MetaData.ABI

// MarketV3Bin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use MarketV3MetaData.Bin instead.
var MarketV3Bin = MarketV3MetaData.Bin

// DeployMarketV3 deploys a new Ethereum contract, binding an instance of MarketV3 to it.
func DeployMarketV3(auth *bind.TransactOpts, backend bind.ContractBackend, _factory common.Address) (common.Address, *types.Transaction, *MarketV3, error) {
	parsed, err := MarketV3MetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(MarketV3Bin), backend, _factory)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &MarketV3{MarketV3Caller: MarketV3Caller{contract: contract}, MarketV3Transactor: MarketV3Transactor{contract: contract}, MarketV3Filterer: MarketV3Filterer{contract: contract}}, nil
}

// MarketV3 is an auto generated Go binding around an Ethereum contract.
type MarketV3 struct {
	MarketV3Caller     // Read-only binding to the contract
	MarketV3Transactor // Write-only binding to the contract
	MarketV3Filterer   // Log filterer for contract events
}

// MarketV3Caller is an auto generated read-only Go binding around an Ethereum contract.
type MarketV3Caller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketV3Transactor is an auto generated write-only Go binding around an Ethereum contract.
type MarketV3Transactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketV3Filterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MarketV3Filterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketV3Session is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MarketV3Session struct {
	Contract     *MarketV3         // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// MarketV3CallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MarketV3CallerSession struct {
	Contract *MarketV3Caller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts   // Call options to use throughout this session
}

// MarketV3TransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MarketV3TransactorSession struct {
	Contract     *MarketV3Transactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// MarketV3Raw is an auto generated low-level Go binding around an Ethereum contract.
type MarketV3Raw struct {
	Contract *MarketV3 // Generic contract binding to access the raw methods on
}

// MarketV3CallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MarketV3CallerRaw struct {
	Contract *MarketV3Caller // Generic read-only contract binding to access the raw methods on
}

// MarketV3TransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MarketV3TransactorRaw struct {
	Contract *MarketV3Transactor // Generic write-only contract binding to access the raw methods on
}

// NewMarketV3 creates a new instance of MarketV3, bound to a specific deployed contract.
func NewMarketV3(address common.Address, backend bind.ContractBackend) (*MarketV3, error) {
	contract, err := bindMarketV3(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MarketV3{MarketV3Caller: MarketV3Caller{contract: contract}, MarketV3Transactor: MarketV3Transactor{contract: contract}, MarketV3Filterer: MarketV3Filterer{contract: contract}}, nil
}

// NewMarketV3Caller creates a new read-only instance of MarketV3, bound to a specific deployed contract.
func NewMarketV3Caller(address common.Address, caller bind.ContractCaller) (*MarketV3Caller, error) {
	contract, err := bindMarketV3(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MarketV3Caller{contract: contract}, nil
}

// NewMarketV3Transactor creates a new write-only instance of MarketV3, bound to a specific deployed contract.
func NewMarketV3Transactor(address common.Address, transactor bind.ContractTransactor) (*MarketV3Transactor, error) {
	contract, err := bindMarketV3(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MarketV3Transactor{contract: contract}, nil
}

// NewMarketV3Filterer creates a new log filterer instance of MarketV3, bound to a specific deployed contract.
func NewMarketV3Filterer(address common.Address, filterer bind.ContractFilterer) (*MarketV3Filterer, error) {
	contract, err := bindMarketV3(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MarketV3Filterer{contract: contract}, nil
}

// bindMarketV3 binds a generic wrapper to an already deployed contract.
func bindMarketV3(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := MarketV3MetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MarketV3 *MarketV3Raw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MarketV3.Contract.MarketV3Caller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MarketV3 *MarketV3Raw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketV3.Contract.MarketV3Transactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MarketV3 *MarketV3Raw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MarketV3.Contract.MarketV3Transactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MarketV3 *MarketV3CallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MarketV3.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MarketV3 *MarketV3TransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketV3.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MarketV3 *MarketV3TransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MarketV3.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Caller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Session) DEFAULTADMINROLE() ([32]byte, error) {
	return _MarketV3.Contract.DEFAULTADMINROLE(&_MarketV3.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3CallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _MarketV3.Contract.DEFAULTADMINROLE(&_MarketV3.CallOpts)
}

// KEEPERROLE is a free data retrieval call binding the contract method 0x364bc15a.
//
// Solidity: function KEEPER_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Caller) KEEPERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "KEEPER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// KEEPERROLE is a free data retrieval call binding the contract method 0x364bc15a.
//
// Solidity: function KEEPER_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Session) KEEPERROLE() ([32]byte, error) {
	return _MarketV3.Contract.KEEPERROLE(&_MarketV3.CallOpts)
}

// KEEPERROLE is a free data retrieval call binding the contract method 0x364bc15a.
//
// Solidity: function KEEPER_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3CallerSession) KEEPERROLE() ([32]byte, error) {
	return _MarketV3.Contract.KEEPERROLE(&_MarketV3.CallOpts)
}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Caller) OPERATORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "OPERATOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Session) OPERATORROLE() ([32]byte, error) {
	return _MarketV3.Contract.OPERATORROLE(&_MarketV3.CallOpts)
}

// OPERATORROLE is a free data retrieval call binding the contract method 0xf5b541a6.
//
// Solidity: function OPERATOR_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3CallerSession) OPERATORROLE() ([32]byte, error) {
	return _MarketV3.Contract.OPERATORROLE(&_MarketV3.CallOpts)
}

// ORACLEROLE is a free data retrieval call binding the contract method 0x07e2cea5.
//
// Solidity: function ORACLE_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Caller) ORACLEROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "ORACLE_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ORACLEROLE is a free data retrieval call binding the contract method 0x07e2cea5.
//
// Solidity: function ORACLE_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Session) ORACLEROLE() ([32]byte, error) {
	return _MarketV3.Contract.ORACLEROLE(&_MarketV3.CallOpts)
}

// ORACLEROLE is a free data retrieval call binding the contract method 0x07e2cea5.
//
// Solidity: function ORACLE_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3CallerSession) ORACLEROLE() ([32]byte, error) {
	return _MarketV3.Contract.ORACLEROLE(&_MarketV3.CallOpts)
}

// PAUSERROLE is a free data retrieval call binding the contract method 0xe63ab1e9.
//
// Solidity: function PAUSER_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Caller) PAUSERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "PAUSER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// PAUSERROLE is a free data retrieval call binding the contract method 0xe63ab1e9.
//
// Solidity: function PAUSER_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Session) PAUSERROLE() ([32]byte, error) {
	return _MarketV3.Contract.PAUSERROLE(&_MarketV3.CallOpts)
}

// PAUSERROLE is a free data retrieval call binding the contract method 0xe63ab1e9.
//
// Solidity: function PAUSER_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3CallerSession) PAUSERROLE() ([32]byte, error) {
	return _MarketV3.Contract.PAUSERROLE(&_MarketV3.CallOpts)
}

// ROUTERROLE is a free data retrieval call binding the contract method 0x30d643b5.
//
// Solidity: function ROUTER_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Caller) ROUTERROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "ROUTER_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// ROUTERROLE is a free data retrieval call binding the contract method 0x30d643b5.
//
// Solidity: function ROUTER_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3Session) ROUTERROLE() ([32]byte, error) {
	return _MarketV3.Contract.ROUTERROLE(&_MarketV3.CallOpts)
}

// ROUTERROLE is a free data retrieval call binding the contract method 0x30d643b5.
//
// Solidity: function ROUTER_ROLE() view returns(bytes32)
func (_MarketV3 *MarketV3CallerSession) ROUTERROLE() ([32]byte, error) {
	return _MarketV3.Contract.ROUTERROLE(&_MarketV3.CallOpts)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_MarketV3 *MarketV3Caller) BalanceOf(opts *bind.CallOpts, account common.Address, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "balanceOf", account, id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_MarketV3 *MarketV3Session) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _MarketV3.Contract.BalanceOf(&_MarketV3.CallOpts, account, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_MarketV3 *MarketV3CallerSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _MarketV3.Contract.BalanceOf(&_MarketV3.CallOpts, account, id)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_MarketV3 *MarketV3Caller) BalanceOfBatch(opts *bind.CallOpts, accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "balanceOfBatch", accounts, ids)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_MarketV3 *MarketV3Session) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _MarketV3.Contract.BalanceOfBatch(&_MarketV3.CallOpts, accounts, ids)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_MarketV3 *MarketV3CallerSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _MarketV3.Contract.BalanceOfBatch(&_MarketV3.CallOpts, accounts, ids)
}

// BorrowedAmount is a free data retrieval call binding the contract method 0x1afbb7a4.
//
// Solidity: function borrowedAmount() view returns(uint256)
func (_MarketV3 *MarketV3Caller) BorrowedAmount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "borrowedAmount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BorrowedAmount is a free data retrieval call binding the contract method 0x1afbb7a4.
//
// Solidity: function borrowedAmount() view returns(uint256)
func (_MarketV3 *MarketV3Session) BorrowedAmount() (*big.Int, error) {
	return _MarketV3.Contract.BorrowedAmount(&_MarketV3.CallOpts)
}

// BorrowedAmount is a free data retrieval call binding the contract method 0x1afbb7a4.
//
// Solidity: function borrowedAmount() view returns(uint256)
func (_MarketV3 *MarketV3CallerSession) BorrowedAmount() (*big.Int, error) {
	return _MarketV3.Contract.BorrowedAmount(&_MarketV3.CallOpts)
}

// CheckLiabilityLimit is a free data retrieval call binding the contract method 0x81e8d208.
//
// Solidity: function checkLiabilityLimit() view returns(bool exceedsLimit, uint256 excessLoss)
func (_MarketV3 *MarketV3Caller) CheckLiabilityLimit(opts *bind.CallOpts) (struct {
	ExceedsLimit bool
	ExcessLoss   *big.Int
}, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "checkLiabilityLimit")

	outstruct := new(struct {
		ExceedsLimit bool
		ExcessLoss   *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ExceedsLimit = *abi.ConvertType(out[0], new(bool)).(*bool)
	outstruct.ExcessLoss = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// CheckLiabilityLimit is a free data retrieval call binding the contract method 0x81e8d208.
//
// Solidity: function checkLiabilityLimit() view returns(bool exceedsLimit, uint256 excessLoss)
func (_MarketV3 *MarketV3Session) CheckLiabilityLimit() (struct {
	ExceedsLimit bool
	ExcessLoss   *big.Int
}, error) {
	return _MarketV3.Contract.CheckLiabilityLimit(&_MarketV3.CallOpts)
}

// CheckLiabilityLimit is a free data retrieval call binding the contract method 0x81e8d208.
//
// Solidity: function checkLiabilityLimit() view returns(bool exceedsLimit, uint256 excessLoss)
func (_MarketV3 *MarketV3CallerSession) CheckLiabilityLimit() (struct {
	ExceedsLimit bool
	ExcessLoss   *big.Int
}, error) {
	return _MarketV3.Contract.CheckLiabilityLimit(&_MarketV3.CallOpts)
}

// Factory is a free data retrieval call binding the contract method 0xc45a0155.
//
// Solidity: function factory() view returns(address)
func (_MarketV3 *MarketV3Caller) Factory(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "factory")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Factory is a free data retrieval call binding the contract method 0xc45a0155.
//
// Solidity: function factory() view returns(address)
func (_MarketV3 *MarketV3Session) Factory() (common.Address, error) {
	return _MarketV3.Contract.Factory(&_MarketV3.CallOpts)
}

// Factory is a free data retrieval call binding the contract method 0xc45a0155.
//
// Solidity: function factory() view returns(address)
func (_MarketV3 *MarketV3CallerSession) Factory() (common.Address, error) {
	return _MarketV3.Contract.Factory(&_MarketV3.CallOpts)
}

// GetAllPrices is a free data retrieval call binding the contract method 0x445df9d6.
//
// Solidity: function getAllPrices() view returns(uint256[] prices)
func (_MarketV3 *MarketV3Caller) GetAllPrices(opts *bind.CallOpts) ([]*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "getAllPrices")

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// GetAllPrices is a free data retrieval call binding the contract method 0x445df9d6.
//
// Solidity: function getAllPrices() view returns(uint256[] prices)
func (_MarketV3 *MarketV3Session) GetAllPrices() ([]*big.Int, error) {
	return _MarketV3.Contract.GetAllPrices(&_MarketV3.CallOpts)
}

// GetAllPrices is a free data retrieval call binding the contract method 0x445df9d6.
//
// Solidity: function getAllPrices() view returns(uint256[] prices)
func (_MarketV3 *MarketV3CallerSession) GetAllPrices() ([]*big.Int, error) {
	return _MarketV3.Contract.GetAllPrices(&_MarketV3.CallOpts)
}

// GetCurrentPnL is a free data retrieval call binding the contract method 0xfc35f991.
//
// Solidity: function getCurrentPnL() view returns(int256 pnl)
func (_MarketV3 *MarketV3Caller) GetCurrentPnL(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "getCurrentPnL")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCurrentPnL is a free data retrieval call binding the contract method 0xfc35f991.
//
// Solidity: function getCurrentPnL() view returns(int256 pnl)
func (_MarketV3 *MarketV3Session) GetCurrentPnL() (*big.Int, error) {
	return _MarketV3.Contract.GetCurrentPnL(&_MarketV3.CallOpts)
}

// GetCurrentPnL is a free data retrieval call binding the contract method 0xfc35f991.
//
// Solidity: function getCurrentPnL() view returns(int256 pnl)
func (_MarketV3 *MarketV3CallerSession) GetCurrentPnL() (*big.Int, error) {
	return _MarketV3.Contract.GetCurrentPnL(&_MarketV3.CallOpts)
}

// GetMarketStats is a free data retrieval call binding the contract method 0xff4cd5b9.
//
// Solidity: function getMarketStats() view returns(uint256 _totalLiquidity, uint256 _initialLiquidity, uint256[] _sharesPerOutcome, uint256[] _betAmountPerOutcome)
func (_MarketV3 *MarketV3Caller) GetMarketStats(opts *bind.CallOpts) (struct {
	TotalLiquidity      *big.Int
	InitialLiquidity    *big.Int
	SharesPerOutcome    []*big.Int
	BetAmountPerOutcome []*big.Int
}, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "getMarketStats")

	outstruct := new(struct {
		TotalLiquidity      *big.Int
		InitialLiquidity    *big.Int
		SharesPerOutcome    []*big.Int
		BetAmountPerOutcome []*big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.TotalLiquidity = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.InitialLiquidity = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.SharesPerOutcome = *abi.ConvertType(out[2], new([]*big.Int)).(*[]*big.Int)
	outstruct.BetAmountPerOutcome = *abi.ConvertType(out[3], new([]*big.Int)).(*[]*big.Int)

	return *outstruct, err

}

// GetMarketStats is a free data retrieval call binding the contract method 0xff4cd5b9.
//
// Solidity: function getMarketStats() view returns(uint256 _totalLiquidity, uint256 _initialLiquidity, uint256[] _sharesPerOutcome, uint256[] _betAmountPerOutcome)
func (_MarketV3 *MarketV3Session) GetMarketStats() (struct {
	TotalLiquidity      *big.Int
	InitialLiquidity    *big.Int
	SharesPerOutcome    []*big.Int
	BetAmountPerOutcome []*big.Int
}, error) {
	return _MarketV3.Contract.GetMarketStats(&_MarketV3.CallOpts)
}

// GetMarketStats is a free data retrieval call binding the contract method 0xff4cd5b9.
//
// Solidity: function getMarketStats() view returns(uint256 _totalLiquidity, uint256 _initialLiquidity, uint256[] _sharesPerOutcome, uint256[] _betAmountPerOutcome)
func (_MarketV3 *MarketV3CallerSession) GetMarketStats() (struct {
	TotalLiquidity      *big.Int
	InitialLiquidity    *big.Int
	SharesPerOutcome    []*big.Int
	BetAmountPerOutcome []*big.Int
}, error) {
	return _MarketV3.Contract.GetMarketStats(&_MarketV3.CallOpts)
}

// GetOutcomeRules is a free data retrieval call binding the contract method 0xde300b00.
//
// Solidity: function getOutcomeRules() view returns((string,uint8)[] rules)
func (_MarketV3 *MarketV3Caller) GetOutcomeRules(opts *bind.CallOpts) ([]IMarketV3OutcomeRule, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "getOutcomeRules")

	if err != nil {
		return *new([]IMarketV3OutcomeRule), err
	}

	out0 := *abi.ConvertType(out[0], new([]IMarketV3OutcomeRule)).(*[]IMarketV3OutcomeRule)

	return out0, err

}

// GetOutcomeRules is a free data retrieval call binding the contract method 0xde300b00.
//
// Solidity: function getOutcomeRules() view returns((string,uint8)[] rules)
func (_MarketV3 *MarketV3Session) GetOutcomeRules() ([]IMarketV3OutcomeRule, error) {
	return _MarketV3.Contract.GetOutcomeRules(&_MarketV3.CallOpts)
}

// GetOutcomeRules is a free data retrieval call binding the contract method 0xde300b00.
//
// Solidity: function getOutcomeRules() view returns((string,uint8)[] rules)
func (_MarketV3 *MarketV3CallerSession) GetOutcomeRules() ([]IMarketV3OutcomeRule, error) {
	return _MarketV3.Contract.GetOutcomeRules(&_MarketV3.CallOpts)
}

// GetPrice is a free data retrieval call binding the contract method 0xe7572230.
//
// Solidity: function getPrice(uint256 outcomeId) view returns(uint256 price)
func (_MarketV3 *MarketV3Caller) GetPrice(opts *bind.CallOpts, outcomeId *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "getPrice", outcomeId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetPrice is a free data retrieval call binding the contract method 0xe7572230.
//
// Solidity: function getPrice(uint256 outcomeId) view returns(uint256 price)
func (_MarketV3 *MarketV3Session) GetPrice(outcomeId *big.Int) (*big.Int, error) {
	return _MarketV3.Contract.GetPrice(&_MarketV3.CallOpts, outcomeId)
}

// GetPrice is a free data retrieval call binding the contract method 0xe7572230.
//
// Solidity: function getPrice(uint256 outcomeId) view returns(uint256 price)
func (_MarketV3 *MarketV3CallerSession) GetPrice(outcomeId *big.Int) (*big.Int, error) {
	return _MarketV3.Contract.GetPrice(&_MarketV3.CallOpts, outcomeId)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_MarketV3 *MarketV3Caller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_MarketV3 *MarketV3Session) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _MarketV3.Contract.GetRoleAdmin(&_MarketV3.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_MarketV3 *MarketV3CallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _MarketV3.Contract.GetRoleAdmin(&_MarketV3.CallOpts, role)
}

// GetSettlementResult is a free data retrieval call binding the contract method 0x5cee3ba1.
//
// Solidity: function getSettlementResult() view returns((uint256[],uint256[],bytes,uint256,bool) result)
func (_MarketV3 *MarketV3Caller) GetSettlementResult(opts *bind.CallOpts) (IMarketV3SettlementResult, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "getSettlementResult")

	if err != nil {
		return *new(IMarketV3SettlementResult), err
	}

	out0 := *abi.ConvertType(out[0], new(IMarketV3SettlementResult)).(*IMarketV3SettlementResult)

	return out0, err

}

// GetSettlementResult is a free data retrieval call binding the contract method 0x5cee3ba1.
//
// Solidity: function getSettlementResult() view returns((uint256[],uint256[],bytes,uint256,bool) result)
func (_MarketV3 *MarketV3Session) GetSettlementResult() (IMarketV3SettlementResult, error) {
	return _MarketV3.Contract.GetSettlementResult(&_MarketV3.CallOpts)
}

// GetSettlementResult is a free data retrieval call binding the contract method 0x5cee3ba1.
//
// Solidity: function getSettlementResult() view returns((uint256[],uint256[],bytes,uint256,bool) result)
func (_MarketV3 *MarketV3CallerSession) GetSettlementResult() (IMarketV3SettlementResult, error) {
	return _MarketV3.Contract.GetSettlementResult(&_MarketV3.CallOpts)
}

// GetStats is a free data retrieval call binding the contract method 0xc59d4847.
//
// Solidity: function getStats() view returns((uint256,uint256,uint256,uint256[],uint256[]) stats)
func (_MarketV3 *MarketV3Caller) GetStats(opts *bind.CallOpts) (IMarketV3MarketStats, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "getStats")

	if err != nil {
		return *new(IMarketV3MarketStats), err
	}

	out0 := *abi.ConvertType(out[0], new(IMarketV3MarketStats)).(*IMarketV3MarketStats)

	return out0, err

}

// GetStats is a free data retrieval call binding the contract method 0xc59d4847.
//
// Solidity: function getStats() view returns((uint256,uint256,uint256,uint256[],uint256[]) stats)
func (_MarketV3 *MarketV3Session) GetStats() (IMarketV3MarketStats, error) {
	return _MarketV3.Contract.GetStats(&_MarketV3.CallOpts)
}

// GetStats is a free data retrieval call binding the contract method 0xc59d4847.
//
// Solidity: function getStats() view returns((uint256,uint256,uint256,uint256[],uint256[]) stats)
func (_MarketV3 *MarketV3CallerSession) GetStats() (IMarketV3MarketStats, error) {
	return _MarketV3.Contract.GetStats(&_MarketV3.CallOpts)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_MarketV3 *MarketV3Caller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_MarketV3 *MarketV3Session) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _MarketV3.Contract.HasRole(&_MarketV3.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_MarketV3 *MarketV3CallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _MarketV3.Contract.HasRole(&_MarketV3.CallOpts, role, account)
}

// InitialLiquidity is a free data retrieval call binding the contract method 0x40702adc.
//
// Solidity: function initialLiquidity() view returns(uint256)
func (_MarketV3 *MarketV3Caller) InitialLiquidity(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "initialLiquidity")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// InitialLiquidity is a free data retrieval call binding the contract method 0x40702adc.
//
// Solidity: function initialLiquidity() view returns(uint256)
func (_MarketV3 *MarketV3Session) InitialLiquidity() (*big.Int, error) {
	return _MarketV3.Contract.InitialLiquidity(&_MarketV3.CallOpts)
}

// InitialLiquidity is a free data retrieval call binding the contract method 0x40702adc.
//
// Solidity: function initialLiquidity() view returns(uint256)
func (_MarketV3 *MarketV3CallerSession) InitialLiquidity() (*big.Int, error) {
	return _MarketV3.Contract.InitialLiquidity(&_MarketV3.CallOpts)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_MarketV3 *MarketV3Caller) IsApprovedForAll(opts *bind.CallOpts, account common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "isApprovedForAll", account, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_MarketV3 *MarketV3Session) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _MarketV3.Contract.IsApprovedForAll(&_MarketV3.CallOpts, account, operator)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_MarketV3 *MarketV3CallerSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _MarketV3.Contract.IsApprovedForAll(&_MarketV3.CallOpts, account, operator)
}

// KickoffTime is a free data retrieval call binding the contract method 0x1f5dca1a.
//
// Solidity: function kickoffTime() view returns(uint256)
func (_MarketV3 *MarketV3Caller) KickoffTime(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "kickoffTime")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// KickoffTime is a free data retrieval call binding the contract method 0x1f5dca1a.
//
// Solidity: function kickoffTime() view returns(uint256)
func (_MarketV3 *MarketV3Session) KickoffTime() (*big.Int, error) {
	return _MarketV3.Contract.KickoffTime(&_MarketV3.CallOpts)
}

// KickoffTime is a free data retrieval call binding the contract method 0x1f5dca1a.
//
// Solidity: function kickoffTime() view returns(uint256)
func (_MarketV3 *MarketV3CallerSession) KickoffTime() (*big.Int, error) {
	return _MarketV3.Contract.KickoffTime(&_MarketV3.CallOpts)
}

// MarketId is a free data retrieval call binding the contract method 0x6ed71ede.
//
// Solidity: function marketId() view returns(bytes32)
func (_MarketV3 *MarketV3Caller) MarketId(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "marketId")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// MarketId is a free data retrieval call binding the contract method 0x6ed71ede.
//
// Solidity: function marketId() view returns(bytes32)
func (_MarketV3 *MarketV3Session) MarketId() ([32]byte, error) {
	return _MarketV3.Contract.MarketId(&_MarketV3.CallOpts)
}

// MarketId is a free data retrieval call binding the contract method 0x6ed71ede.
//
// Solidity: function marketId() view returns(bytes32)
func (_MarketV3 *MarketV3CallerSession) MarketId() ([32]byte, error) {
	return _MarketV3.Contract.MarketId(&_MarketV3.CallOpts)
}

// MatchId is a free data retrieval call binding the contract method 0x99892e47.
//
// Solidity: function matchId() view returns(string)
func (_MarketV3 *MarketV3Caller) MatchId(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "matchId")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// MatchId is a free data retrieval call binding the contract method 0x99892e47.
//
// Solidity: function matchId() view returns(string)
func (_MarketV3 *MarketV3Session) MatchId() (string, error) {
	return _MarketV3.Contract.MatchId(&_MarketV3.CallOpts)
}

// MatchId is a free data retrieval call binding the contract method 0x99892e47.
//
// Solidity: function matchId() view returns(string)
func (_MarketV3 *MarketV3CallerSession) MatchId() (string, error) {
	return _MarketV3.Contract.MatchId(&_MarketV3.CallOpts)
}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256 count)
func (_MarketV3 *MarketV3Caller) OutcomeCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "outcomeCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256 count)
func (_MarketV3 *MarketV3Session) OutcomeCount() (*big.Int, error) {
	return _MarketV3.Contract.OutcomeCount(&_MarketV3.CallOpts)
}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256 count)
func (_MarketV3 *MarketV3CallerSession) OutcomeCount() (*big.Int, error) {
	return _MarketV3.Contract.OutcomeCount(&_MarketV3.CallOpts)
}

// ParamController is a free data retrieval call binding the contract method 0xd0d1854d.
//
// Solidity: function paramController() view returns(address)
func (_MarketV3 *MarketV3Caller) ParamController(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "paramController")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ParamController is a free data retrieval call binding the contract method 0xd0d1854d.
//
// Solidity: function paramController() view returns(address)
func (_MarketV3 *MarketV3Session) ParamController() (common.Address, error) {
	return _MarketV3.Contract.ParamController(&_MarketV3.CallOpts)
}

// ParamController is a free data retrieval call binding the contract method 0xd0d1854d.
//
// Solidity: function paramController() view returns(address)
func (_MarketV3 *MarketV3CallerSession) ParamController() (common.Address, error) {
	return _MarketV3.Contract.ParamController(&_MarketV3.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketV3 *MarketV3Caller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketV3 *MarketV3Session) Paused() (bool, error) {
	return _MarketV3.Contract.Paused(&_MarketV3.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketV3 *MarketV3CallerSession) Paused() (bool, error) {
	return _MarketV3.Contract.Paused(&_MarketV3.CallOpts)
}

// PayoutScaleBps is a free data retrieval call binding the contract method 0x800416fc.
//
// Solidity: function payoutScaleBps() view returns(uint256)
func (_MarketV3 *MarketV3Caller) PayoutScaleBps(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "payoutScaleBps")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PayoutScaleBps is a free data retrieval call binding the contract method 0x800416fc.
//
// Solidity: function payoutScaleBps() view returns(uint256)
func (_MarketV3 *MarketV3Session) PayoutScaleBps() (*big.Int, error) {
	return _MarketV3.Contract.PayoutScaleBps(&_MarketV3.CallOpts)
}

// PayoutScaleBps is a free data retrieval call binding the contract method 0x800416fc.
//
// Solidity: function payoutScaleBps() view returns(uint256)
func (_MarketV3 *MarketV3CallerSession) PayoutScaleBps() (*big.Int, error) {
	return _MarketV3.Contract.PayoutScaleBps(&_MarketV3.CallOpts)
}

// PreviewBet is a free data retrieval call binding the contract method 0xeb0382cc.
//
// Solidity: function previewBet(uint256 outcomeId, uint256 amount) view returns(uint256 shares, uint256 newPrice)
func (_MarketV3 *MarketV3Caller) PreviewBet(opts *bind.CallOpts, outcomeId *big.Int, amount *big.Int) (struct {
	Shares   *big.Int
	NewPrice *big.Int
}, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "previewBet", outcomeId, amount)

	outstruct := new(struct {
		Shares   *big.Int
		NewPrice *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Shares = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.NewPrice = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// PreviewBet is a free data retrieval call binding the contract method 0xeb0382cc.
//
// Solidity: function previewBet(uint256 outcomeId, uint256 amount) view returns(uint256 shares, uint256 newPrice)
func (_MarketV3 *MarketV3Session) PreviewBet(outcomeId *big.Int, amount *big.Int) (struct {
	Shares   *big.Int
	NewPrice *big.Int
}, error) {
	return _MarketV3.Contract.PreviewBet(&_MarketV3.CallOpts, outcomeId, amount)
}

// PreviewBet is a free data retrieval call binding the contract method 0xeb0382cc.
//
// Solidity: function previewBet(uint256 outcomeId, uint256 amount) view returns(uint256 shares, uint256 newPrice)
func (_MarketV3 *MarketV3CallerSession) PreviewBet(outcomeId *big.Int, amount *big.Int) (struct {
	Shares   *big.Int
	NewPrice *big.Int
}, error) {
	return _MarketV3.Contract.PreviewBet(&_MarketV3.CallOpts, outcomeId, amount)
}

// PricingState is a free data retrieval call binding the contract method 0xf315f82b.
//
// Solidity: function pricingState() view returns(bytes)
func (_MarketV3 *MarketV3Caller) PricingState(opts *bind.CallOpts) ([]byte, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "pricingState")

	if err != nil {
		return *new([]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([]byte)).(*[]byte)

	return out0, err

}

// PricingState is a free data retrieval call binding the contract method 0xf315f82b.
//
// Solidity: function pricingState() view returns(bytes)
func (_MarketV3 *MarketV3Session) PricingState() ([]byte, error) {
	return _MarketV3.Contract.PricingState(&_MarketV3.CallOpts)
}

// PricingState is a free data retrieval call binding the contract method 0xf315f82b.
//
// Solidity: function pricingState() view returns(bytes)
func (_MarketV3 *MarketV3CallerSession) PricingState() ([]byte, error) {
	return _MarketV3.Contract.PricingState(&_MarketV3.CallOpts)
}

// PricingStrategy is a free data retrieval call binding the contract method 0x78b99c24.
//
// Solidity: function pricingStrategy() view returns(address)
func (_MarketV3 *MarketV3Caller) PricingStrategy(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "pricingStrategy")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// PricingStrategy is a free data retrieval call binding the contract method 0x78b99c24.
//
// Solidity: function pricingStrategy() view returns(address)
func (_MarketV3 *MarketV3Session) PricingStrategy() (common.Address, error) {
	return _MarketV3.Contract.PricingStrategy(&_MarketV3.CallOpts)
}

// PricingStrategy is a free data retrieval call binding the contract method 0x78b99c24.
//
// Solidity: function pricingStrategy() view returns(address)
func (_MarketV3 *MarketV3CallerSession) PricingStrategy() (common.Address, error) {
	return _MarketV3.Contract.PricingStrategy(&_MarketV3.CallOpts)
}

// ResultMapper is a free data retrieval call binding the contract method 0xc1a1d964.
//
// Solidity: function resultMapper() view returns(address)
func (_MarketV3 *MarketV3Caller) ResultMapper(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "resultMapper")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ResultMapper is a free data retrieval call binding the contract method 0xc1a1d964.
//
// Solidity: function resultMapper() view returns(address)
func (_MarketV3 *MarketV3Session) ResultMapper() (common.Address, error) {
	return _MarketV3.Contract.ResultMapper(&_MarketV3.CallOpts)
}

// ResultMapper is a free data retrieval call binding the contract method 0xc1a1d964.
//
// Solidity: function resultMapper() view returns(address)
func (_MarketV3 *MarketV3CallerSession) ResultMapper() (common.Address, error) {
	return _MarketV3.Contract.ResultMapper(&_MarketV3.CallOpts)
}

// SettlementResult is a free data retrieval call binding the contract method 0xc6ee69ff.
//
// Solidity: function settlementResult() view returns(bytes rawResult, uint256 settledAt, bool resolved)
func (_MarketV3 *MarketV3Caller) SettlementResult(opts *bind.CallOpts) (struct {
	RawResult []byte
	SettledAt *big.Int
	Resolved  bool
}, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "settlementResult")

	outstruct := new(struct {
		RawResult []byte
		SettledAt *big.Int
		Resolved  bool
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.RawResult = *abi.ConvertType(out[0], new([]byte)).(*[]byte)
	outstruct.SettledAt = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.Resolved = *abi.ConvertType(out[2], new(bool)).(*bool)

	return *outstruct, err

}

// SettlementResult is a free data retrieval call binding the contract method 0xc6ee69ff.
//
// Solidity: function settlementResult() view returns(bytes rawResult, uint256 settledAt, bool resolved)
func (_MarketV3 *MarketV3Session) SettlementResult() (struct {
	RawResult []byte
	SettledAt *big.Int
	Resolved  bool
}, error) {
	return _MarketV3.Contract.SettlementResult(&_MarketV3.CallOpts)
}

// SettlementResult is a free data retrieval call binding the contract method 0xc6ee69ff.
//
// Solidity: function settlementResult() view returns(bytes rawResult, uint256 settledAt, bool resolved)
func (_MarketV3 *MarketV3CallerSession) SettlementResult() (struct {
	RawResult []byte
	SettledAt *big.Int
	Resolved  bool
}, error) {
	return _MarketV3.Contract.SettlementResult(&_MarketV3.CallOpts)
}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_MarketV3 *MarketV3Caller) SettlementToken(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "settlementToken")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_MarketV3 *MarketV3Session) SettlementToken() (common.Address, error) {
	return _MarketV3.Contract.SettlementToken(&_MarketV3.CallOpts)
}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_MarketV3 *MarketV3CallerSession) SettlementToken() (common.Address, error) {
	return _MarketV3.Contract.SettlementToken(&_MarketV3.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_MarketV3 *MarketV3Caller) Status(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "status")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_MarketV3 *MarketV3Session) Status() (uint8, error) {
	return _MarketV3.Contract.Status(&_MarketV3.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_MarketV3 *MarketV3CallerSession) Status() (uint8, error) {
	return _MarketV3.Contract.Status(&_MarketV3.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketV3 *MarketV3Caller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketV3 *MarketV3Session) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _MarketV3.Contract.SupportsInterface(&_MarketV3.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketV3 *MarketV3CallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _MarketV3.Contract.SupportsInterface(&_MarketV3.CallOpts, interfaceId)
}

// TotalBetAmountPerOutcome is a free data retrieval call binding the contract method 0x60261dd9.
//
// Solidity: function totalBetAmountPerOutcome(uint256 ) view returns(uint256)
func (_MarketV3 *MarketV3Caller) TotalBetAmountPerOutcome(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "totalBetAmountPerOutcome", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalBetAmountPerOutcome is a free data retrieval call binding the contract method 0x60261dd9.
//
// Solidity: function totalBetAmountPerOutcome(uint256 ) view returns(uint256)
func (_MarketV3 *MarketV3Session) TotalBetAmountPerOutcome(arg0 *big.Int) (*big.Int, error) {
	return _MarketV3.Contract.TotalBetAmountPerOutcome(&_MarketV3.CallOpts, arg0)
}

// TotalBetAmountPerOutcome is a free data retrieval call binding the contract method 0x60261dd9.
//
// Solidity: function totalBetAmountPerOutcome(uint256 ) view returns(uint256)
func (_MarketV3 *MarketV3CallerSession) TotalBetAmountPerOutcome(arg0 *big.Int) (*big.Int, error) {
	return _MarketV3.Contract.TotalBetAmountPerOutcome(&_MarketV3.CallOpts, arg0)
}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_MarketV3 *MarketV3Caller) TotalLiquidity(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "totalLiquidity")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_MarketV3 *MarketV3Session) TotalLiquidity() (*big.Int, error) {
	return _MarketV3.Contract.TotalLiquidity(&_MarketV3.CallOpts)
}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_MarketV3 *MarketV3CallerSession) TotalLiquidity() (*big.Int, error) {
	return _MarketV3.Contract.TotalLiquidity(&_MarketV3.CallOpts)
}

// TotalPayoutClaimed is a free data retrieval call binding the contract method 0x8fd9bad9.
//
// Solidity: function totalPayoutClaimed() view returns(uint256)
func (_MarketV3 *MarketV3Caller) TotalPayoutClaimed(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "totalPayoutClaimed")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalPayoutClaimed is a free data retrieval call binding the contract method 0x8fd9bad9.
//
// Solidity: function totalPayoutClaimed() view returns(uint256)
func (_MarketV3 *MarketV3Session) TotalPayoutClaimed() (*big.Int, error) {
	return _MarketV3.Contract.TotalPayoutClaimed(&_MarketV3.CallOpts)
}

// TotalPayoutClaimed is a free data retrieval call binding the contract method 0x8fd9bad9.
//
// Solidity: function totalPayoutClaimed() view returns(uint256)
func (_MarketV3 *MarketV3CallerSession) TotalPayoutClaimed() (*big.Int, error) {
	return _MarketV3.Contract.TotalPayoutClaimed(&_MarketV3.CallOpts)
}

// TotalSharesPerOutcome is a free data retrieval call binding the contract method 0x44f8dbf0.
//
// Solidity: function totalSharesPerOutcome(uint256 ) view returns(uint256)
func (_MarketV3 *MarketV3Caller) TotalSharesPerOutcome(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "totalSharesPerOutcome", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalSharesPerOutcome is a free data retrieval call binding the contract method 0x44f8dbf0.
//
// Solidity: function totalSharesPerOutcome(uint256 ) view returns(uint256)
func (_MarketV3 *MarketV3Session) TotalSharesPerOutcome(arg0 *big.Int) (*big.Int, error) {
	return _MarketV3.Contract.TotalSharesPerOutcome(&_MarketV3.CallOpts, arg0)
}

// TotalSharesPerOutcome is a free data retrieval call binding the contract method 0x44f8dbf0.
//
// Solidity: function totalSharesPerOutcome(uint256 ) view returns(uint256)
func (_MarketV3 *MarketV3CallerSession) TotalSharesPerOutcome(arg0 *big.Int) (*big.Int, error) {
	return _MarketV3.Contract.TotalSharesPerOutcome(&_MarketV3.CallOpts, arg0)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) pure returns(string)
func (_MarketV3 *MarketV3Caller) Uri(opts *bind.CallOpts, arg0 *big.Int) (string, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "uri", arg0)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) pure returns(string)
func (_MarketV3 *MarketV3Session) Uri(arg0 *big.Int) (string, error) {
	return _MarketV3.Contract.Uri(&_MarketV3.CallOpts, arg0)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) pure returns(string)
func (_MarketV3 *MarketV3CallerSession) Uri(arg0 *big.Int) (string, error) {
	return _MarketV3.Contract.Uri(&_MarketV3.CallOpts, arg0)
}

// UserExposure is a free data retrieval call binding the contract method 0x41def6e7.
//
// Solidity: function userExposure(address ) view returns(uint256)
func (_MarketV3 *MarketV3Caller) UserExposure(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "userExposure", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// UserExposure is a free data retrieval call binding the contract method 0x41def6e7.
//
// Solidity: function userExposure(address ) view returns(uint256)
func (_MarketV3 *MarketV3Session) UserExposure(arg0 common.Address) (*big.Int, error) {
	return _MarketV3.Contract.UserExposure(&_MarketV3.CallOpts, arg0)
}

// UserExposure is a free data retrieval call binding the contract method 0x41def6e7.
//
// Solidity: function userExposure(address ) view returns(uint256)
func (_MarketV3 *MarketV3CallerSession) UserExposure(arg0 common.Address) (*big.Int, error) {
	return _MarketV3.Contract.UserExposure(&_MarketV3.CallOpts, arg0)
}

// Vault is a free data retrieval call binding the contract method 0xfbfa77cf.
//
// Solidity: function vault() view returns(address)
func (_MarketV3 *MarketV3Caller) Vault(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketV3.contract.Call(opts, &out, "vault")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Vault is a free data retrieval call binding the contract method 0xfbfa77cf.
//
// Solidity: function vault() view returns(address)
func (_MarketV3 *MarketV3Session) Vault() (common.Address, error) {
	return _MarketV3.Contract.Vault(&_MarketV3.CallOpts)
}

// Vault is a free data retrieval call binding the contract method 0xfbfa77cf.
//
// Solidity: function vault() view returns(address)
func (_MarketV3 *MarketV3CallerSession) Vault() (common.Address, error) {
	return _MarketV3.Contract.Vault(&_MarketV3.CallOpts)
}

// Cancel is a paid mutator transaction binding the contract method 0x0b4f3f3d.
//
// Solidity: function cancel(string reason) returns()
func (_MarketV3 *MarketV3Transactor) Cancel(opts *bind.TransactOpts, reason string) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "cancel", reason)
}

// Cancel is a paid mutator transaction binding the contract method 0x0b4f3f3d.
//
// Solidity: function cancel(string reason) returns()
func (_MarketV3 *MarketV3Session) Cancel(reason string) (*types.Transaction, error) {
	return _MarketV3.Contract.Cancel(&_MarketV3.TransactOpts, reason)
}

// Cancel is a paid mutator transaction binding the contract method 0x0b4f3f3d.
//
// Solidity: function cancel(string reason) returns()
func (_MarketV3 *MarketV3TransactorSession) Cancel(reason string) (*types.Transaction, error) {
	return _MarketV3.Contract.Cancel(&_MarketV3.TransactOpts, reason)
}

// CancelResolved is a paid mutator transaction binding the contract method 0xbb99b505.
//
// Solidity: function cancelResolved(string reason) returns()
func (_MarketV3 *MarketV3Transactor) CancelResolved(opts *bind.TransactOpts, reason string) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "cancelResolved", reason)
}

// CancelResolved is a paid mutator transaction binding the contract method 0xbb99b505.
//
// Solidity: function cancelResolved(string reason) returns()
func (_MarketV3 *MarketV3Session) CancelResolved(reason string) (*types.Transaction, error) {
	return _MarketV3.Contract.CancelResolved(&_MarketV3.TransactOpts, reason)
}

// CancelResolved is a paid mutator transaction binding the contract method 0xbb99b505.
//
// Solidity: function cancelResolved(string reason) returns()
func (_MarketV3 *MarketV3TransactorSession) CancelResolved(reason string) (*types.Transaction, error) {
	return _MarketV3.Contract.CancelResolved(&_MarketV3.TransactOpts, reason)
}

// Finalize is a paid mutator transaction binding the contract method 0x05261aea.
//
// Solidity: function finalize(uint256 scaleBps) returns()
func (_MarketV3 *MarketV3Transactor) Finalize(opts *bind.TransactOpts, scaleBps *big.Int) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "finalize", scaleBps)
}

// Finalize is a paid mutator transaction binding the contract method 0x05261aea.
//
// Solidity: function finalize(uint256 scaleBps) returns()
func (_MarketV3 *MarketV3Session) Finalize(scaleBps *big.Int) (*types.Transaction, error) {
	return _MarketV3.Contract.Finalize(&_MarketV3.TransactOpts, scaleBps)
}

// Finalize is a paid mutator transaction binding the contract method 0x05261aea.
//
// Solidity: function finalize(uint256 scaleBps) returns()
func (_MarketV3 *MarketV3TransactorSession) Finalize(scaleBps *big.Int) (*types.Transaction, error) {
	return _MarketV3.Contract.Finalize(&_MarketV3.TransactOpts, scaleBps)
}

// FundFromVault is a paid mutator transaction binding the contract method 0x17a0916b.
//
// Solidity: function fundFromVault() returns()
func (_MarketV3 *MarketV3Transactor) FundFromVault(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "fundFromVault")
}

// FundFromVault is a paid mutator transaction binding the contract method 0x17a0916b.
//
// Solidity: function fundFromVault() returns()
func (_MarketV3 *MarketV3Session) FundFromVault() (*types.Transaction, error) {
	return _MarketV3.Contract.FundFromVault(&_MarketV3.TransactOpts)
}

// FundFromVault is a paid mutator transaction binding the contract method 0x17a0916b.
//
// Solidity: function fundFromVault() returns()
func (_MarketV3 *MarketV3TransactorSession) FundFromVault() (*types.Transaction, error) {
	return _MarketV3.Contract.FundFromVault(&_MarketV3.TransactOpts)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_MarketV3 *MarketV3Transactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_MarketV3 *MarketV3Session) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketV3.Contract.GrantRole(&_MarketV3.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_MarketV3 *MarketV3TransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketV3.Contract.GrantRole(&_MarketV3.TransactOpts, role, account)
}

// Initialize is a paid mutator transaction binding the contract method 0x0c7a647b.
//
// Solidity: function initialize((bytes32,string,uint256,address,address,address,address,uint256,(string,uint8)[],string,address,address) config) returns()
func (_MarketV3 *MarketV3Transactor) Initialize(opts *bind.TransactOpts, config IMarketV3MarketConfig) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "initialize", config)
}

// Initialize is a paid mutator transaction binding the contract method 0x0c7a647b.
//
// Solidity: function initialize((bytes32,string,uint256,address,address,address,address,uint256,(string,uint8)[],string,address,address) config) returns()
func (_MarketV3 *MarketV3Session) Initialize(config IMarketV3MarketConfig) (*types.Transaction, error) {
	return _MarketV3.Contract.Initialize(&_MarketV3.TransactOpts, config)
}

// Initialize is a paid mutator transaction binding the contract method 0x0c7a647b.
//
// Solidity: function initialize((bytes32,string,uint256,address,address,address,address,uint256,(string,uint8)[],string,address,address) config) returns()
func (_MarketV3 *MarketV3TransactorSession) Initialize(config IMarketV3MarketConfig) (*types.Transaction, error) {
	return _MarketV3.Contract.Initialize(&_MarketV3.TransactOpts, config)
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_MarketV3 *MarketV3Transactor) Lock(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "lock")
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_MarketV3 *MarketV3Session) Lock() (*types.Transaction, error) {
	return _MarketV3.Contract.Lock(&_MarketV3.TransactOpts)
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_MarketV3 *MarketV3TransactorSession) Lock() (*types.Transaction, error) {
	return _MarketV3.Contract.Lock(&_MarketV3.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketV3 *MarketV3Transactor) Pause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "pause")
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketV3 *MarketV3Session) Pause() (*types.Transaction, error) {
	return _MarketV3.Contract.Pause(&_MarketV3.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketV3 *MarketV3TransactorSession) Pause() (*types.Transaction, error) {
	return _MarketV3.Contract.Pause(&_MarketV3.TransactOpts)
}

// PlaceBetFor is a paid mutator transaction binding the contract method 0x7566d130.
//
// Solidity: function placeBetFor(address user, uint256 outcomeId, uint256 amount, uint256 minShares) returns(uint256 shares)
func (_MarketV3 *MarketV3Transactor) PlaceBetFor(opts *bind.TransactOpts, user common.Address, outcomeId *big.Int, amount *big.Int, minShares *big.Int) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "placeBetFor", user, outcomeId, amount, minShares)
}

// PlaceBetFor is a paid mutator transaction binding the contract method 0x7566d130.
//
// Solidity: function placeBetFor(address user, uint256 outcomeId, uint256 amount, uint256 minShares) returns(uint256 shares)
func (_MarketV3 *MarketV3Session) PlaceBetFor(user common.Address, outcomeId *big.Int, amount *big.Int, minShares *big.Int) (*types.Transaction, error) {
	return _MarketV3.Contract.PlaceBetFor(&_MarketV3.TransactOpts, user, outcomeId, amount, minShares)
}

// PlaceBetFor is a paid mutator transaction binding the contract method 0x7566d130.
//
// Solidity: function placeBetFor(address user, uint256 outcomeId, uint256 amount, uint256 minShares) returns(uint256 shares)
func (_MarketV3 *MarketV3TransactorSession) PlaceBetFor(user common.Address, outcomeId *big.Int, amount *big.Int, minShares *big.Int) (*types.Transaction, error) {
	return _MarketV3.Contract.PlaceBetFor(&_MarketV3.TransactOpts, user, outcomeId, amount, minShares)
}

// RedeemBatchFor is a paid mutator transaction binding the contract method 0xb8056df8.
//
// Solidity: function redeemBatchFor(address user, uint256[] outcomeIds, uint256[] sharesArray) returns(uint256 totalPayout)
func (_MarketV3 *MarketV3Transactor) RedeemBatchFor(opts *bind.TransactOpts, user common.Address, outcomeIds []*big.Int, sharesArray []*big.Int) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "redeemBatchFor", user, outcomeIds, sharesArray)
}

// RedeemBatchFor is a paid mutator transaction binding the contract method 0xb8056df8.
//
// Solidity: function redeemBatchFor(address user, uint256[] outcomeIds, uint256[] sharesArray) returns(uint256 totalPayout)
func (_MarketV3 *MarketV3Session) RedeemBatchFor(user common.Address, outcomeIds []*big.Int, sharesArray []*big.Int) (*types.Transaction, error) {
	return _MarketV3.Contract.RedeemBatchFor(&_MarketV3.TransactOpts, user, outcomeIds, sharesArray)
}

// RedeemBatchFor is a paid mutator transaction binding the contract method 0xb8056df8.
//
// Solidity: function redeemBatchFor(address user, uint256[] outcomeIds, uint256[] sharesArray) returns(uint256 totalPayout)
func (_MarketV3 *MarketV3TransactorSession) RedeemBatchFor(user common.Address, outcomeIds []*big.Int, sharesArray []*big.Int) (*types.Transaction, error) {
	return _MarketV3.Contract.RedeemBatchFor(&_MarketV3.TransactOpts, user, outcomeIds, sharesArray)
}

// RedeemFor is a paid mutator transaction binding the contract method 0xb426b825.
//
// Solidity: function redeemFor(address user, uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_MarketV3 *MarketV3Transactor) RedeemFor(opts *bind.TransactOpts, user common.Address, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "redeemFor", user, outcomeId, shares)
}

// RedeemFor is a paid mutator transaction binding the contract method 0xb426b825.
//
// Solidity: function redeemFor(address user, uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_MarketV3 *MarketV3Session) RedeemFor(user common.Address, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketV3.Contract.RedeemFor(&_MarketV3.TransactOpts, user, outcomeId, shares)
}

// RedeemFor is a paid mutator transaction binding the contract method 0xb426b825.
//
// Solidity: function redeemFor(address user, uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_MarketV3 *MarketV3TransactorSession) RedeemFor(user common.Address, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketV3.Contract.RedeemFor(&_MarketV3.TransactOpts, user, outcomeId, shares)
}

// RefundFor is a paid mutator transaction binding the contract method 0xc5a0fb85.
//
// Solidity: function refundFor(address user, uint256 outcomeId, uint256 shares) returns(uint256 amount)
func (_MarketV3 *MarketV3Transactor) RefundFor(opts *bind.TransactOpts, user common.Address, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "refundFor", user, outcomeId, shares)
}

// RefundFor is a paid mutator transaction binding the contract method 0xc5a0fb85.
//
// Solidity: function refundFor(address user, uint256 outcomeId, uint256 shares) returns(uint256 amount)
func (_MarketV3 *MarketV3Session) RefundFor(user common.Address, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketV3.Contract.RefundFor(&_MarketV3.TransactOpts, user, outcomeId, shares)
}

// RefundFor is a paid mutator transaction binding the contract method 0xc5a0fb85.
//
// Solidity: function refundFor(address user, uint256 outcomeId, uint256 shares) returns(uint256 amount)
func (_MarketV3 *MarketV3TransactorSession) RefundFor(user common.Address, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketV3.Contract.RefundFor(&_MarketV3.TransactOpts, user, outcomeId, shares)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_MarketV3 *MarketV3Transactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_MarketV3 *MarketV3Session) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _MarketV3.Contract.RenounceRole(&_MarketV3.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_MarketV3 *MarketV3TransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _MarketV3.Contract.RenounceRole(&_MarketV3.TransactOpts, role, callerConfirmation)
}

// Resolve is a paid mutator transaction binding the contract method 0xe4056186.
//
// Solidity: function resolve(bytes rawResult) returns()
func (_MarketV3 *MarketV3Transactor) Resolve(opts *bind.TransactOpts, rawResult []byte) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "resolve", rawResult)
}

// Resolve is a paid mutator transaction binding the contract method 0xe4056186.
//
// Solidity: function resolve(bytes rawResult) returns()
func (_MarketV3 *MarketV3Session) Resolve(rawResult []byte) (*types.Transaction, error) {
	return _MarketV3.Contract.Resolve(&_MarketV3.TransactOpts, rawResult)
}

// Resolve is a paid mutator transaction binding the contract method 0xe4056186.
//
// Solidity: function resolve(bytes rawResult) returns()
func (_MarketV3 *MarketV3TransactorSession) Resolve(rawResult []byte) (*types.Transaction, error) {
	return _MarketV3.Contract.Resolve(&_MarketV3.TransactOpts, rawResult)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_MarketV3 *MarketV3Transactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_MarketV3 *MarketV3Session) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketV3.Contract.RevokeRole(&_MarketV3.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_MarketV3 *MarketV3TransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketV3.Contract.RevokeRole(&_MarketV3.TransactOpts, role, account)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_MarketV3 *MarketV3Transactor) SafeBatchTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "safeBatchTransferFrom", from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_MarketV3 *MarketV3Session) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _MarketV3.Contract.SafeBatchTransferFrom(&_MarketV3.TransactOpts, from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_MarketV3 *MarketV3TransactorSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _MarketV3.Contract.SafeBatchTransferFrom(&_MarketV3.TransactOpts, from, to, ids, values, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_MarketV3 *MarketV3Transactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "safeTransferFrom", from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_MarketV3 *MarketV3Session) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _MarketV3.Contract.SafeTransferFrom(&_MarketV3.TransactOpts, from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_MarketV3 *MarketV3TransactorSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _MarketV3.Contract.SafeTransferFrom(&_MarketV3.TransactOpts, from, to, id, value, data)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_MarketV3 *MarketV3Transactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_MarketV3 *MarketV3Session) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _MarketV3.Contract.SetApprovalForAll(&_MarketV3.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_MarketV3 *MarketV3TransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _MarketV3.Contract.SetApprovalForAll(&_MarketV3.TransactOpts, operator, approved)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketV3 *MarketV3Transactor) Unpause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketV3.contract.Transact(opts, "unpause")
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketV3 *MarketV3Session) Unpause() (*types.Transaction, error) {
	return _MarketV3.Contract.Unpause(&_MarketV3.TransactOpts)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketV3 *MarketV3TransactorSession) Unpause() (*types.Transaction, error) {
	return _MarketV3.Contract.Unpause(&_MarketV3.TransactOpts)
}

// MarketV3ApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the MarketV3 contract.
type MarketV3ApprovalForAllIterator struct {
	Event *MarketV3ApprovalForAll // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3ApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3ApprovalForAll)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3ApprovalForAll)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3ApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3ApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3ApprovalForAll represents a ApprovalForAll event raised by the MarketV3 contract.
type MarketV3ApprovalForAll struct {
	Account  common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_MarketV3 *MarketV3Filterer) FilterApprovalForAll(opts *bind.FilterOpts, account []common.Address, operator []common.Address) (*MarketV3ApprovalForAllIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3ApprovalForAllIterator{contract: _MarketV3.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_MarketV3 *MarketV3Filterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *MarketV3ApprovalForAll, account []common.Address, operator []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3ApprovalForAll)
				if err := _MarketV3.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseApprovalForAll is a log parse operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_MarketV3 *MarketV3Filterer) ParseApprovalForAll(log types.Log) (*MarketV3ApprovalForAll, error) {
	event := new(MarketV3ApprovalForAll)
	if err := _MarketV3.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3BetPlacedIterator is returned from FilterBetPlaced and is used to iterate over the raw logs and unpacked data for BetPlaced events raised by the MarketV3 contract.
type MarketV3BetPlacedIterator struct {
	Event *MarketV3BetPlaced // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3BetPlacedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3BetPlaced)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3BetPlaced)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3BetPlacedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3BetPlacedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3BetPlaced represents a BetPlaced event raised by the MarketV3 contract.
type MarketV3BetPlaced struct {
	User      common.Address
	OutcomeId *big.Int
	Amount    *big.Int
	Shares    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterBetPlaced is a free log retrieval operation binding the contract event 0x7363e6581df4db69463222156be4a09656528b9f1302890fa4c0b60819b69fc6.
//
// Solidity: event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares)
func (_MarketV3 *MarketV3Filterer) FilterBetPlaced(opts *bind.FilterOpts, user []common.Address, outcomeId []*big.Int) (*MarketV3BetPlacedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "BetPlaced", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3BetPlacedIterator{contract: _MarketV3.contract, event: "BetPlaced", logs: logs, sub: sub}, nil
}

// WatchBetPlaced is a free log subscription operation binding the contract event 0x7363e6581df4db69463222156be4a09656528b9f1302890fa4c0b60819b69fc6.
//
// Solidity: event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares)
func (_MarketV3 *MarketV3Filterer) WatchBetPlaced(opts *bind.WatchOpts, sink chan<- *MarketV3BetPlaced, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "BetPlaced", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3BetPlaced)
				if err := _MarketV3.contract.UnpackLog(event, "BetPlaced", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseBetPlaced is a log parse operation binding the contract event 0x7363e6581df4db69463222156be4a09656528b9f1302890fa4c0b60819b69fc6.
//
// Solidity: event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares)
func (_MarketV3 *MarketV3Filterer) ParseBetPlaced(log types.Log) (*MarketV3BetPlaced, error) {
	event := new(MarketV3BetPlaced)
	if err := _MarketV3.contract.UnpackLog(event, "BetPlaced", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3BetPlaced0Iterator is returned from FilterBetPlaced0 and is used to iterate over the raw logs and unpacked data for BetPlaced0 events raised by the MarketV3 contract.
type MarketV3BetPlaced0Iterator struct {
	Event *MarketV3BetPlaced0 // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3BetPlaced0Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3BetPlaced0)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3BetPlaced0)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3BetPlaced0Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3BetPlaced0Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3BetPlaced0 represents a BetPlaced0 event raised by the MarketV3 contract.
type MarketV3BetPlaced0 struct {
	MarketId  [32]byte
	User      common.Address
	OutcomeId *big.Int
	Amount    *big.Int
	Shares    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterBetPlaced0 is a free log retrieval operation binding the contract event 0x99c1ad6c4a15b1653746cf2a0df7a9d06289b9c1dd277d45f25edc2362cd2d8d.
//
// Solidity: event BetPlaced(bytes32 indexed marketId, address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares)
func (_MarketV3 *MarketV3Filterer) FilterBetPlaced0(opts *bind.FilterOpts, marketId [][32]byte, user []common.Address, outcomeId []*big.Int) (*MarketV3BetPlaced0Iterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "BetPlaced0", marketIdRule, userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3BetPlaced0Iterator{contract: _MarketV3.contract, event: "BetPlaced0", logs: logs, sub: sub}, nil
}

// WatchBetPlaced0 is a free log subscription operation binding the contract event 0x99c1ad6c4a15b1653746cf2a0df7a9d06289b9c1dd277d45f25edc2362cd2d8d.
//
// Solidity: event BetPlaced(bytes32 indexed marketId, address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares)
func (_MarketV3 *MarketV3Filterer) WatchBetPlaced0(opts *bind.WatchOpts, sink chan<- *MarketV3BetPlaced0, marketId [][32]byte, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "BetPlaced0", marketIdRule, userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3BetPlaced0)
				if err := _MarketV3.contract.UnpackLog(event, "BetPlaced0", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseBetPlaced0 is a log parse operation binding the contract event 0x99c1ad6c4a15b1653746cf2a0df7a9d06289b9c1dd277d45f25edc2362cd2d8d.
//
// Solidity: event BetPlaced(bytes32 indexed marketId, address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares)
func (_MarketV3 *MarketV3Filterer) ParseBetPlaced0(log types.Log) (*MarketV3BetPlaced0, error) {
	event := new(MarketV3BetPlaced0)
	if err := _MarketV3.contract.UnpackLog(event, "BetPlaced0", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3InitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the MarketV3 contract.
type MarketV3InitializedIterator struct {
	Event *MarketV3Initialized // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3InitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3Initialized)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3Initialized)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3InitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3InitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3Initialized represents a Initialized event raised by the MarketV3 contract.
type MarketV3Initialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_MarketV3 *MarketV3Filterer) FilterInitialized(opts *bind.FilterOpts) (*MarketV3InitializedIterator, error) {

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &MarketV3InitializedIterator{contract: _MarketV3.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_MarketV3 *MarketV3Filterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *MarketV3Initialized) (event.Subscription, error) {

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3Initialized)
				if err := _MarketV3.contract.UnpackLog(event, "Initialized", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseInitialized is a log parse operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_MarketV3 *MarketV3Filterer) ParseInitialized(log types.Log) (*MarketV3Initialized, error) {
	event := new(MarketV3Initialized)
	if err := _MarketV3.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketCancelledIterator is returned from FilterMarketCancelled and is used to iterate over the raw logs and unpacked data for MarketCancelled events raised by the MarketV3 contract.
type MarketV3MarketCancelledIterator struct {
	Event *MarketV3MarketCancelled // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketCancelledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketCancelled)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketCancelled)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketCancelledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketCancelledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketCancelled represents a MarketCancelled event raised by the MarketV3 contract.
type MarketV3MarketCancelled struct {
	Reason string
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterMarketCancelled is a free log retrieval operation binding the contract event 0xd6d24c13b2278f52540b463e1336c607596333c270867c5d3f96725c269a1c7a.
//
// Solidity: event MarketCancelled(string reason)
func (_MarketV3 *MarketV3Filterer) FilterMarketCancelled(opts *bind.FilterOpts) (*MarketV3MarketCancelledIterator, error) {

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketCancelled")
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketCancelledIterator{contract: _MarketV3.contract, event: "MarketCancelled", logs: logs, sub: sub}, nil
}

// WatchMarketCancelled is a free log subscription operation binding the contract event 0xd6d24c13b2278f52540b463e1336c607596333c270867c5d3f96725c269a1c7a.
//
// Solidity: event MarketCancelled(string reason)
func (_MarketV3 *MarketV3Filterer) WatchMarketCancelled(opts *bind.WatchOpts, sink chan<- *MarketV3MarketCancelled) (event.Subscription, error) {

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketCancelled")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketCancelled)
				if err := _MarketV3.contract.UnpackLog(event, "MarketCancelled", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketCancelled is a log parse operation binding the contract event 0xd6d24c13b2278f52540b463e1336c607596333c270867c5d3f96725c269a1c7a.
//
// Solidity: event MarketCancelled(string reason)
func (_MarketV3 *MarketV3Filterer) ParseMarketCancelled(log types.Log) (*MarketV3MarketCancelled, error) {
	event := new(MarketV3MarketCancelled)
	if err := _MarketV3.contract.UnpackLog(event, "MarketCancelled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketCancelled0Iterator is returned from FilterMarketCancelled0 and is used to iterate over the raw logs and unpacked data for MarketCancelled0 events raised by the MarketV3 contract.
type MarketV3MarketCancelled0Iterator struct {
	Event *MarketV3MarketCancelled0 // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketCancelled0Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketCancelled0)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketCancelled0)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketCancelled0Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketCancelled0Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketCancelled0 represents a MarketCancelled0 event raised by the MarketV3 contract.
type MarketV3MarketCancelled0 struct {
	MarketId [32]byte
	Reason   string
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterMarketCancelled0 is a free log retrieval operation binding the contract event 0x57e91a25415b0162e415e7e6e78df294e0eaef73716a2839359618ec85d99e67.
//
// Solidity: event MarketCancelled(bytes32 indexed marketId, string reason)
func (_MarketV3 *MarketV3Filterer) FilterMarketCancelled0(opts *bind.FilterOpts, marketId [][32]byte) (*MarketV3MarketCancelled0Iterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketCancelled0", marketIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketCancelled0Iterator{contract: _MarketV3.contract, event: "MarketCancelled0", logs: logs, sub: sub}, nil
}

// WatchMarketCancelled0 is a free log subscription operation binding the contract event 0x57e91a25415b0162e415e7e6e78df294e0eaef73716a2839359618ec85d99e67.
//
// Solidity: event MarketCancelled(bytes32 indexed marketId, string reason)
func (_MarketV3 *MarketV3Filterer) WatchMarketCancelled0(opts *bind.WatchOpts, sink chan<- *MarketV3MarketCancelled0, marketId [][32]byte) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketCancelled0", marketIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketCancelled0)
				if err := _MarketV3.contract.UnpackLog(event, "MarketCancelled0", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketCancelled0 is a log parse operation binding the contract event 0x57e91a25415b0162e415e7e6e78df294e0eaef73716a2839359618ec85d99e67.
//
// Solidity: event MarketCancelled(bytes32 indexed marketId, string reason)
func (_MarketV3 *MarketV3Filterer) ParseMarketCancelled0(log types.Log) (*MarketV3MarketCancelled0, error) {
	event := new(MarketV3MarketCancelled0)
	if err := _MarketV3.contract.UnpackLog(event, "MarketCancelled0", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketCreatedIterator is returned from FilterMarketCreated and is used to iterate over the raw logs and unpacked data for MarketCreated events raised by the MarketV3 contract.
type MarketV3MarketCreatedIterator struct {
	Event *MarketV3MarketCreated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketCreatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketCreated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketCreated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketCreatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketCreatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketCreated represents a MarketCreated event raised by the MarketV3 contract.
type MarketV3MarketCreated struct {
	MarketId        [32]byte
	MatchId         string
	KickoffTime     *big.Int
	PricingStrategy common.Address
	ResultMapper    common.Address
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterMarketCreated is a free log retrieval operation binding the contract event 0x63b5cdba4a6529d632ec599fbac0c291bc71918e9a45817e26b74c21ad1de4e0.
//
// Solidity: event MarketCreated(bytes32 indexed marketId, string matchId, uint256 kickoffTime, address pricingStrategy, address resultMapper)
func (_MarketV3 *MarketV3Filterer) FilterMarketCreated(opts *bind.FilterOpts, marketId [][32]byte) (*MarketV3MarketCreatedIterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketCreated", marketIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketCreatedIterator{contract: _MarketV3.contract, event: "MarketCreated", logs: logs, sub: sub}, nil
}

// WatchMarketCreated is a free log subscription operation binding the contract event 0x63b5cdba4a6529d632ec599fbac0c291bc71918e9a45817e26b74c21ad1de4e0.
//
// Solidity: event MarketCreated(bytes32 indexed marketId, string matchId, uint256 kickoffTime, address pricingStrategy, address resultMapper)
func (_MarketV3 *MarketV3Filterer) WatchMarketCreated(opts *bind.WatchOpts, sink chan<- *MarketV3MarketCreated, marketId [][32]byte) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketCreated", marketIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketCreated)
				if err := _MarketV3.contract.UnpackLog(event, "MarketCreated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketCreated is a log parse operation binding the contract event 0x63b5cdba4a6529d632ec599fbac0c291bc71918e9a45817e26b74c21ad1de4e0.
//
// Solidity: event MarketCreated(bytes32 indexed marketId, string matchId, uint256 kickoffTime, address pricingStrategy, address resultMapper)
func (_MarketV3 *MarketV3Filterer) ParseMarketCreated(log types.Log) (*MarketV3MarketCreated, error) {
	event := new(MarketV3MarketCreated)
	if err := _MarketV3.contract.UnpackLog(event, "MarketCreated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketFinalizedIterator is returned from FilterMarketFinalized and is used to iterate over the raw logs and unpacked data for MarketFinalized events raised by the MarketV3 contract.
type MarketV3MarketFinalizedIterator struct {
	Event *MarketV3MarketFinalized // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketFinalizedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketFinalized)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketFinalized)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketFinalizedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketFinalizedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketFinalized represents a MarketFinalized event raised by the MarketV3 contract.
type MarketV3MarketFinalized struct {
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterMarketFinalized is a free log retrieval operation binding the contract event 0xdcf9d491e583ce9369e93cab66baeac633ef4c5587e0a9bf3897e6b72c178633.
//
// Solidity: event MarketFinalized(uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) FilterMarketFinalized(opts *bind.FilterOpts) (*MarketV3MarketFinalizedIterator, error) {

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketFinalized")
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketFinalizedIterator{contract: _MarketV3.contract, event: "MarketFinalized", logs: logs, sub: sub}, nil
}

// WatchMarketFinalized is a free log subscription operation binding the contract event 0xdcf9d491e583ce9369e93cab66baeac633ef4c5587e0a9bf3897e6b72c178633.
//
// Solidity: event MarketFinalized(uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) WatchMarketFinalized(opts *bind.WatchOpts, sink chan<- *MarketV3MarketFinalized) (event.Subscription, error) {

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketFinalized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketFinalized)
				if err := _MarketV3.contract.UnpackLog(event, "MarketFinalized", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketFinalized is a log parse operation binding the contract event 0xdcf9d491e583ce9369e93cab66baeac633ef4c5587e0a9bf3897e6b72c178633.
//
// Solidity: event MarketFinalized(uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) ParseMarketFinalized(log types.Log) (*MarketV3MarketFinalized, error) {
	event := new(MarketV3MarketFinalized)
	if err := _MarketV3.contract.UnpackLog(event, "MarketFinalized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketFinalized0Iterator is returned from FilterMarketFinalized0 and is used to iterate over the raw logs and unpacked data for MarketFinalized0 events raised by the MarketV3 contract.
type MarketV3MarketFinalized0Iterator struct {
	Event *MarketV3MarketFinalized0 // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketFinalized0Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketFinalized0)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketFinalized0)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketFinalized0Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketFinalized0Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketFinalized0 represents a MarketFinalized0 event raised by the MarketV3 contract.
type MarketV3MarketFinalized0 struct {
	MarketId  [32]byte
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterMarketFinalized0 is a free log retrieval operation binding the contract event 0x22569dd5dc686b4ca9d030800ad1d2c36479c284514f04b4c90ca30fd2c73f92.
//
// Solidity: event MarketFinalized(bytes32 indexed marketId, uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) FilterMarketFinalized0(opts *bind.FilterOpts, marketId [][32]byte) (*MarketV3MarketFinalized0Iterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketFinalized0", marketIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketFinalized0Iterator{contract: _MarketV3.contract, event: "MarketFinalized0", logs: logs, sub: sub}, nil
}

// WatchMarketFinalized0 is a free log subscription operation binding the contract event 0x22569dd5dc686b4ca9d030800ad1d2c36479c284514f04b4c90ca30fd2c73f92.
//
// Solidity: event MarketFinalized(bytes32 indexed marketId, uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) WatchMarketFinalized0(opts *bind.WatchOpts, sink chan<- *MarketV3MarketFinalized0, marketId [][32]byte) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketFinalized0", marketIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketFinalized0)
				if err := _MarketV3.contract.UnpackLog(event, "MarketFinalized0", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketFinalized0 is a log parse operation binding the contract event 0x22569dd5dc686b4ca9d030800ad1d2c36479c284514f04b4c90ca30fd2c73f92.
//
// Solidity: event MarketFinalized(bytes32 indexed marketId, uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) ParseMarketFinalized0(log types.Log) (*MarketV3MarketFinalized0, error) {
	event := new(MarketV3MarketFinalized0)
	if err := _MarketV3.contract.UnpackLog(event, "MarketFinalized0", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketInitializedIterator is returned from FilterMarketInitialized and is used to iterate over the raw logs and unpacked data for MarketInitialized events raised by the MarketV3 contract.
type MarketV3MarketInitializedIterator struct {
	Event *MarketV3MarketInitialized // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketInitialized)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketInitialized)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketInitialized represents a MarketInitialized event raised by the MarketV3 contract.
type MarketV3MarketInitialized struct {
	MarketId        [32]byte
	MatchId         string
	PricingStrategy common.Address
	ResultMapper    common.Address
	OutcomeCount    *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterMarketInitialized is a free log retrieval operation binding the contract event 0x11373cf59c951d3f7ae9d93bd1a4fc1526b8d7569479f8263e6514e304b9362a.
//
// Solidity: event MarketInitialized(bytes32 indexed marketId, string matchId, address pricingStrategy, address resultMapper, uint256 outcomeCount)
func (_MarketV3 *MarketV3Filterer) FilterMarketInitialized(opts *bind.FilterOpts, marketId [][32]byte) (*MarketV3MarketInitializedIterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketInitialized", marketIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketInitializedIterator{contract: _MarketV3.contract, event: "MarketInitialized", logs: logs, sub: sub}, nil
}

// WatchMarketInitialized is a free log subscription operation binding the contract event 0x11373cf59c951d3f7ae9d93bd1a4fc1526b8d7569479f8263e6514e304b9362a.
//
// Solidity: event MarketInitialized(bytes32 indexed marketId, string matchId, address pricingStrategy, address resultMapper, uint256 outcomeCount)
func (_MarketV3 *MarketV3Filterer) WatchMarketInitialized(opts *bind.WatchOpts, sink chan<- *MarketV3MarketInitialized, marketId [][32]byte) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketInitialized", marketIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketInitialized)
				if err := _MarketV3.contract.UnpackLog(event, "MarketInitialized", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketInitialized is a log parse operation binding the contract event 0x11373cf59c951d3f7ae9d93bd1a4fc1526b8d7569479f8263e6514e304b9362a.
//
// Solidity: event MarketInitialized(bytes32 indexed marketId, string matchId, address pricingStrategy, address resultMapper, uint256 outcomeCount)
func (_MarketV3 *MarketV3Filterer) ParseMarketInitialized(log types.Log) (*MarketV3MarketInitialized, error) {
	event := new(MarketV3MarketInitialized)
	if err := _MarketV3.contract.UnpackLog(event, "MarketInitialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketLockedIterator is returned from FilterMarketLocked and is used to iterate over the raw logs and unpacked data for MarketLocked events raised by the MarketV3 contract.
type MarketV3MarketLockedIterator struct {
	Event *MarketV3MarketLocked // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketLockedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketLocked)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketLocked)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketLockedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketLockedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketLocked represents a MarketLocked event raised by the MarketV3 contract.
type MarketV3MarketLocked struct {
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterMarketLocked is a free log retrieval operation binding the contract event 0x2d597ad63f8c5090e993389fdab0249476d2f29bcbc52e99da3236a4370f11ba.
//
// Solidity: event MarketLocked(uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) FilterMarketLocked(opts *bind.FilterOpts) (*MarketV3MarketLockedIterator, error) {

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketLocked")
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketLockedIterator{contract: _MarketV3.contract, event: "MarketLocked", logs: logs, sub: sub}, nil
}

// WatchMarketLocked is a free log subscription operation binding the contract event 0x2d597ad63f8c5090e993389fdab0249476d2f29bcbc52e99da3236a4370f11ba.
//
// Solidity: event MarketLocked(uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) WatchMarketLocked(opts *bind.WatchOpts, sink chan<- *MarketV3MarketLocked) (event.Subscription, error) {

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketLocked")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketLocked)
				if err := _MarketV3.contract.UnpackLog(event, "MarketLocked", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketLocked is a log parse operation binding the contract event 0x2d597ad63f8c5090e993389fdab0249476d2f29bcbc52e99da3236a4370f11ba.
//
// Solidity: event MarketLocked(uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) ParseMarketLocked(log types.Log) (*MarketV3MarketLocked, error) {
	event := new(MarketV3MarketLocked)
	if err := _MarketV3.contract.UnpackLog(event, "MarketLocked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketLocked0Iterator is returned from FilterMarketLocked0 and is used to iterate over the raw logs and unpacked data for MarketLocked0 events raised by the MarketV3 contract.
type MarketV3MarketLocked0Iterator struct {
	Event *MarketV3MarketLocked0 // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketLocked0Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketLocked0)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketLocked0)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketLocked0Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketLocked0Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketLocked0 represents a MarketLocked0 event raised by the MarketV3 contract.
type MarketV3MarketLocked0 struct {
	MarketId  [32]byte
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterMarketLocked0 is a free log retrieval operation binding the contract event 0xd5305d3bbc595dce689e378f9b2cf18e9c73019de0ec6dd71e37870a60dafaee.
//
// Solidity: event MarketLocked(bytes32 indexed marketId, uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) FilterMarketLocked0(opts *bind.FilterOpts, marketId [][32]byte) (*MarketV3MarketLocked0Iterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketLocked0", marketIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketLocked0Iterator{contract: _MarketV3.contract, event: "MarketLocked0", logs: logs, sub: sub}, nil
}

// WatchMarketLocked0 is a free log subscription operation binding the contract event 0xd5305d3bbc595dce689e378f9b2cf18e9c73019de0ec6dd71e37870a60dafaee.
//
// Solidity: event MarketLocked(bytes32 indexed marketId, uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) WatchMarketLocked0(opts *bind.WatchOpts, sink chan<- *MarketV3MarketLocked0, marketId [][32]byte) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketLocked0", marketIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketLocked0)
				if err := _MarketV3.contract.UnpackLog(event, "MarketLocked0", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketLocked0 is a log parse operation binding the contract event 0xd5305d3bbc595dce689e378f9b2cf18e9c73019de0ec6dd71e37870a60dafaee.
//
// Solidity: event MarketLocked(bytes32 indexed marketId, uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) ParseMarketLocked0(log types.Log) (*MarketV3MarketLocked0, error) {
	event := new(MarketV3MarketLocked0)
	if err := _MarketV3.contract.UnpackLog(event, "MarketLocked0", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketOpenedIterator is returned from FilterMarketOpened and is used to iterate over the raw logs and unpacked data for MarketOpened events raised by the MarketV3 contract.
type MarketV3MarketOpenedIterator struct {
	Event *MarketV3MarketOpened // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketOpenedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketOpened)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketOpened)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketOpenedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketOpenedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketOpened represents a MarketOpened event raised by the MarketV3 contract.
type MarketV3MarketOpened struct {
	MarketId  [32]byte
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterMarketOpened is a free log retrieval operation binding the contract event 0x2619c7172b98c717684f44b03cd08fa424e5ab7843604d0d00df935ffc6b99a9.
//
// Solidity: event MarketOpened(bytes32 indexed marketId, uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) FilterMarketOpened(opts *bind.FilterOpts, marketId [][32]byte) (*MarketV3MarketOpenedIterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketOpened", marketIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketOpenedIterator{contract: _MarketV3.contract, event: "MarketOpened", logs: logs, sub: sub}, nil
}

// WatchMarketOpened is a free log subscription operation binding the contract event 0x2619c7172b98c717684f44b03cd08fa424e5ab7843604d0d00df935ffc6b99a9.
//
// Solidity: event MarketOpened(bytes32 indexed marketId, uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) WatchMarketOpened(opts *bind.WatchOpts, sink chan<- *MarketV3MarketOpened, marketId [][32]byte) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketOpened", marketIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketOpened)
				if err := _MarketV3.contract.UnpackLog(event, "MarketOpened", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketOpened is a log parse operation binding the contract event 0x2619c7172b98c717684f44b03cd08fa424e5ab7843604d0d00df935ffc6b99a9.
//
// Solidity: event MarketOpened(bytes32 indexed marketId, uint256 timestamp)
func (_MarketV3 *MarketV3Filterer) ParseMarketOpened(log types.Log) (*MarketV3MarketOpened, error) {
	event := new(MarketV3MarketOpened)
	if err := _MarketV3.contract.UnpackLog(event, "MarketOpened", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketResolvedIterator is returned from FilterMarketResolved and is used to iterate over the raw logs and unpacked data for MarketResolved events raised by the MarketV3 contract.
type MarketV3MarketResolvedIterator struct {
	Event *MarketV3MarketResolved // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketResolvedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketResolved)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketResolved)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketResolvedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketResolvedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketResolved represents a MarketResolved event raised by the MarketV3 contract.
type MarketV3MarketResolved struct {
	OutcomeIds []*big.Int
	Weights    []*big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterMarketResolved is a free log retrieval operation binding the contract event 0xfadc9677ca5f9faa603f27f608a14a82af1de8b4e0641f29b0f642955ea8f664.
//
// Solidity: event MarketResolved(uint256[] outcomeIds, uint256[] weights)
func (_MarketV3 *MarketV3Filterer) FilterMarketResolved(opts *bind.FilterOpts) (*MarketV3MarketResolvedIterator, error) {

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketResolved")
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketResolvedIterator{contract: _MarketV3.contract, event: "MarketResolved", logs: logs, sub: sub}, nil
}

// WatchMarketResolved is a free log subscription operation binding the contract event 0xfadc9677ca5f9faa603f27f608a14a82af1de8b4e0641f29b0f642955ea8f664.
//
// Solidity: event MarketResolved(uint256[] outcomeIds, uint256[] weights)
func (_MarketV3 *MarketV3Filterer) WatchMarketResolved(opts *bind.WatchOpts, sink chan<- *MarketV3MarketResolved) (event.Subscription, error) {

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketResolved")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketResolved)
				if err := _MarketV3.contract.UnpackLog(event, "MarketResolved", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketResolved is a log parse operation binding the contract event 0xfadc9677ca5f9faa603f27f608a14a82af1de8b4e0641f29b0f642955ea8f664.
//
// Solidity: event MarketResolved(uint256[] outcomeIds, uint256[] weights)
func (_MarketV3 *MarketV3Filterer) ParseMarketResolved(log types.Log) (*MarketV3MarketResolved, error) {
	event := new(MarketV3MarketResolved)
	if err := _MarketV3.contract.UnpackLog(event, "MarketResolved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3MarketResolved0Iterator is returned from FilterMarketResolved0 and is used to iterate over the raw logs and unpacked data for MarketResolved0 events raised by the MarketV3 contract.
type MarketV3MarketResolved0Iterator struct {
	Event *MarketV3MarketResolved0 // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3MarketResolved0Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3MarketResolved0)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3MarketResolved0)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3MarketResolved0Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3MarketResolved0Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3MarketResolved0 represents a MarketResolved0 event raised by the MarketV3 contract.
type MarketV3MarketResolved0 struct {
	MarketId   [32]byte
	OutcomeIds []*big.Int
	Weights    []*big.Int
	RawResult  []byte
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterMarketResolved0 is a free log retrieval operation binding the contract event 0x7cfaa096456f3577fd954ed905262a89ad7324a06e0f78ac5a950f84ac236c9b.
//
// Solidity: event MarketResolved(bytes32 indexed marketId, uint256[] outcomeIds, uint256[] weights, bytes rawResult)
func (_MarketV3 *MarketV3Filterer) FilterMarketResolved0(opts *bind.FilterOpts, marketId [][32]byte) (*MarketV3MarketResolved0Iterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "MarketResolved0", marketIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3MarketResolved0Iterator{contract: _MarketV3.contract, event: "MarketResolved0", logs: logs, sub: sub}, nil
}

// WatchMarketResolved0 is a free log subscription operation binding the contract event 0x7cfaa096456f3577fd954ed905262a89ad7324a06e0f78ac5a950f84ac236c9b.
//
// Solidity: event MarketResolved(bytes32 indexed marketId, uint256[] outcomeIds, uint256[] weights, bytes rawResult)
func (_MarketV3 *MarketV3Filterer) WatchMarketResolved0(opts *bind.WatchOpts, sink chan<- *MarketV3MarketResolved0, marketId [][32]byte) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "MarketResolved0", marketIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3MarketResolved0)
				if err := _MarketV3.contract.UnpackLog(event, "MarketResolved0", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseMarketResolved0 is a log parse operation binding the contract event 0x7cfaa096456f3577fd954ed905262a89ad7324a06e0f78ac5a950f84ac236c9b.
//
// Solidity: event MarketResolved(bytes32 indexed marketId, uint256[] outcomeIds, uint256[] weights, bytes rawResult)
func (_MarketV3 *MarketV3Filterer) ParseMarketResolved0(log types.Log) (*MarketV3MarketResolved0, error) {
	event := new(MarketV3MarketResolved0)
	if err := _MarketV3.contract.UnpackLog(event, "MarketResolved0", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3PausedIterator is returned from FilterPaused and is used to iterate over the raw logs and unpacked data for Paused events raised by the MarketV3 contract.
type MarketV3PausedIterator struct {
	Event *MarketV3Paused // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3PausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3Paused)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3Paused)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3PausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3PausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3Paused represents a Paused event raised by the MarketV3 contract.
type MarketV3Paused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterPaused is a free log retrieval operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_MarketV3 *MarketV3Filterer) FilterPaused(opts *bind.FilterOpts) (*MarketV3PausedIterator, error) {

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return &MarketV3PausedIterator{contract: _MarketV3.contract, event: "Paused", logs: logs, sub: sub}, nil
}

// WatchPaused is a free log subscription operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_MarketV3 *MarketV3Filterer) WatchPaused(opts *bind.WatchOpts, sink chan<- *MarketV3Paused) (event.Subscription, error) {

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3Paused)
				if err := _MarketV3.contract.UnpackLog(event, "Paused", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParsePaused is a log parse operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_MarketV3 *MarketV3Filterer) ParsePaused(log types.Log) (*MarketV3Paused, error) {
	event := new(MarketV3Paused)
	if err := _MarketV3.contract.UnpackLog(event, "Paused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3PayoutClaimedIterator is returned from FilterPayoutClaimed and is used to iterate over the raw logs and unpacked data for PayoutClaimed events raised by the MarketV3 contract.
type MarketV3PayoutClaimedIterator struct {
	Event *MarketV3PayoutClaimed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3PayoutClaimedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3PayoutClaimed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3PayoutClaimed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3PayoutClaimedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3PayoutClaimedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3PayoutClaimed represents a PayoutClaimed event raised by the MarketV3 contract.
type MarketV3PayoutClaimed struct {
	User      common.Address
	OutcomeId *big.Int
	Shares    *big.Int
	Payout    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterPayoutClaimed is a free log retrieval operation binding the contract event 0x2edcf4f6b46ef86243e798d3e77c29846a9ddc05cf9c7267f2f5daabe893cfa5.
//
// Solidity: event PayoutClaimed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketV3 *MarketV3Filterer) FilterPayoutClaimed(opts *bind.FilterOpts, user []common.Address, outcomeId []*big.Int) (*MarketV3PayoutClaimedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "PayoutClaimed", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3PayoutClaimedIterator{contract: _MarketV3.contract, event: "PayoutClaimed", logs: logs, sub: sub}, nil
}

// WatchPayoutClaimed is a free log subscription operation binding the contract event 0x2edcf4f6b46ef86243e798d3e77c29846a9ddc05cf9c7267f2f5daabe893cfa5.
//
// Solidity: event PayoutClaimed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketV3 *MarketV3Filterer) WatchPayoutClaimed(opts *bind.WatchOpts, sink chan<- *MarketV3PayoutClaimed, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "PayoutClaimed", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3PayoutClaimed)
				if err := _MarketV3.contract.UnpackLog(event, "PayoutClaimed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParsePayoutClaimed is a log parse operation binding the contract event 0x2edcf4f6b46ef86243e798d3e77c29846a9ddc05cf9c7267f2f5daabe893cfa5.
//
// Solidity: event PayoutClaimed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketV3 *MarketV3Filterer) ParsePayoutClaimed(log types.Log) (*MarketV3PayoutClaimed, error) {
	event := new(MarketV3PayoutClaimed)
	if err := _MarketV3.contract.UnpackLog(event, "PayoutClaimed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3PayoutClaimed0Iterator is returned from FilterPayoutClaimed0 and is used to iterate over the raw logs and unpacked data for PayoutClaimed0 events raised by the MarketV3 contract.
type MarketV3PayoutClaimed0Iterator struct {
	Event *MarketV3PayoutClaimed0 // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3PayoutClaimed0Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3PayoutClaimed0)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3PayoutClaimed0)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3PayoutClaimed0Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3PayoutClaimed0Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3PayoutClaimed0 represents a PayoutClaimed0 event raised by the MarketV3 contract.
type MarketV3PayoutClaimed0 struct {
	MarketId  [32]byte
	User      common.Address
	OutcomeId *big.Int
	Shares    *big.Int
	Payout    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterPayoutClaimed0 is a free log retrieval operation binding the contract event 0x8b532e8544aaba4081e6679ce58881ffd75103cdb593e8478f0fb9126ea57944.
//
// Solidity: event PayoutClaimed(bytes32 indexed marketId, address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketV3 *MarketV3Filterer) FilterPayoutClaimed0(opts *bind.FilterOpts, marketId [][32]byte, user []common.Address, outcomeId []*big.Int) (*MarketV3PayoutClaimed0Iterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "PayoutClaimed0", marketIdRule, userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3PayoutClaimed0Iterator{contract: _MarketV3.contract, event: "PayoutClaimed0", logs: logs, sub: sub}, nil
}

// WatchPayoutClaimed0 is a free log subscription operation binding the contract event 0x8b532e8544aaba4081e6679ce58881ffd75103cdb593e8478f0fb9126ea57944.
//
// Solidity: event PayoutClaimed(bytes32 indexed marketId, address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketV3 *MarketV3Filterer) WatchPayoutClaimed0(opts *bind.WatchOpts, sink chan<- *MarketV3PayoutClaimed0, marketId [][32]byte, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "PayoutClaimed0", marketIdRule, userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3PayoutClaimed0)
				if err := _MarketV3.contract.UnpackLog(event, "PayoutClaimed0", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParsePayoutClaimed0 is a log parse operation binding the contract event 0x8b532e8544aaba4081e6679ce58881ffd75103cdb593e8478f0fb9126ea57944.
//
// Solidity: event PayoutClaimed(bytes32 indexed marketId, address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketV3 *MarketV3Filterer) ParsePayoutClaimed0(log types.Log) (*MarketV3PayoutClaimed0, error) {
	event := new(MarketV3PayoutClaimed0)
	if err := _MarketV3.contract.UnpackLog(event, "PayoutClaimed0", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3PayoutScaledIterator is returned from FilterPayoutScaled and is used to iterate over the raw logs and unpacked data for PayoutScaled events raised by the MarketV3 contract.
type MarketV3PayoutScaledIterator struct {
	Event *MarketV3PayoutScaled // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3PayoutScaledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3PayoutScaled)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3PayoutScaled)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3PayoutScaledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3PayoutScaledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3PayoutScaled represents a PayoutScaled event raised by the MarketV3 contract.
type MarketV3PayoutScaled struct {
	ScaleBps *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterPayoutScaled is a free log retrieval operation binding the contract event 0x072a3954a6d26f8b2dbf96f4387a27ff0afb5edc4a967ce5154feb68016838e2.
//
// Solidity: event PayoutScaled(uint256 scaleBps)
func (_MarketV3 *MarketV3Filterer) FilterPayoutScaled(opts *bind.FilterOpts) (*MarketV3PayoutScaledIterator, error) {

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "PayoutScaled")
	if err != nil {
		return nil, err
	}
	return &MarketV3PayoutScaledIterator{contract: _MarketV3.contract, event: "PayoutScaled", logs: logs, sub: sub}, nil
}

// WatchPayoutScaled is a free log subscription operation binding the contract event 0x072a3954a6d26f8b2dbf96f4387a27ff0afb5edc4a967ce5154feb68016838e2.
//
// Solidity: event PayoutScaled(uint256 scaleBps)
func (_MarketV3 *MarketV3Filterer) WatchPayoutScaled(opts *bind.WatchOpts, sink chan<- *MarketV3PayoutScaled) (event.Subscription, error) {

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "PayoutScaled")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3PayoutScaled)
				if err := _MarketV3.contract.UnpackLog(event, "PayoutScaled", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParsePayoutScaled is a log parse operation binding the contract event 0x072a3954a6d26f8b2dbf96f4387a27ff0afb5edc4a967ce5154feb68016838e2.
//
// Solidity: event PayoutScaled(uint256 scaleBps)
func (_MarketV3 *MarketV3Filterer) ParsePayoutScaled(log types.Log) (*MarketV3PayoutScaled, error) {
	event := new(MarketV3PayoutScaled)
	if err := _MarketV3.contract.UnpackLog(event, "PayoutScaled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3RefundClaimedIterator is returned from FilterRefundClaimed and is used to iterate over the raw logs and unpacked data for RefundClaimed events raised by the MarketV3 contract.
type MarketV3RefundClaimedIterator struct {
	Event *MarketV3RefundClaimed // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3RefundClaimedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3RefundClaimed)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3RefundClaimed)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3RefundClaimedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3RefundClaimedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3RefundClaimed represents a RefundClaimed event raised by the MarketV3 contract.
type MarketV3RefundClaimed struct {
	User      common.Address
	OutcomeId *big.Int
	Shares    *big.Int
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterRefundClaimed is a free log retrieval operation binding the contract event 0x2a62c9fef01ce4cfe24b93ff7cef58e2c929cc918e5d27a85cb76dd6bbbd6d15.
//
// Solidity: event RefundClaimed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 amount)
func (_MarketV3 *MarketV3Filterer) FilterRefundClaimed(opts *bind.FilterOpts, user []common.Address, outcomeId []*big.Int) (*MarketV3RefundClaimedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "RefundClaimed", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3RefundClaimedIterator{contract: _MarketV3.contract, event: "RefundClaimed", logs: logs, sub: sub}, nil
}

// WatchRefundClaimed is a free log subscription operation binding the contract event 0x2a62c9fef01ce4cfe24b93ff7cef58e2c929cc918e5d27a85cb76dd6bbbd6d15.
//
// Solidity: event RefundClaimed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 amount)
func (_MarketV3 *MarketV3Filterer) WatchRefundClaimed(opts *bind.WatchOpts, sink chan<- *MarketV3RefundClaimed, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "RefundClaimed", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3RefundClaimed)
				if err := _MarketV3.contract.UnpackLog(event, "RefundClaimed", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRefundClaimed is a log parse operation binding the contract event 0x2a62c9fef01ce4cfe24b93ff7cef58e2c929cc918e5d27a85cb76dd6bbbd6d15.
//
// Solidity: event RefundClaimed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 amount)
func (_MarketV3 *MarketV3Filterer) ParseRefundClaimed(log types.Log) (*MarketV3RefundClaimed, error) {
	event := new(MarketV3RefundClaimed)
	if err := _MarketV3.contract.UnpackLog(event, "RefundClaimed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3RefundClaimed0Iterator is returned from FilterRefundClaimed0 and is used to iterate over the raw logs and unpacked data for RefundClaimed0 events raised by the MarketV3 contract.
type MarketV3RefundClaimed0Iterator struct {
	Event *MarketV3RefundClaimed0 // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3RefundClaimed0Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3RefundClaimed0)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3RefundClaimed0)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3RefundClaimed0Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3RefundClaimed0Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3RefundClaimed0 represents a RefundClaimed0 event raised by the MarketV3 contract.
type MarketV3RefundClaimed0 struct {
	MarketId     [32]byte
	User         common.Address
	OutcomeId    *big.Int
	Shares       *big.Int
	RefundAmount *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterRefundClaimed0 is a free log retrieval operation binding the contract event 0x88e83ee0e55575bb8661b0b6d9a09589ed061dd30480a3c153128b0acba85c2a.
//
// Solidity: event RefundClaimed(bytes32 indexed marketId, address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 refundAmount)
func (_MarketV3 *MarketV3Filterer) FilterRefundClaimed0(opts *bind.FilterOpts, marketId [][32]byte, user []common.Address, outcomeId []*big.Int) (*MarketV3RefundClaimed0Iterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "RefundClaimed0", marketIdRule, userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3RefundClaimed0Iterator{contract: _MarketV3.contract, event: "RefundClaimed0", logs: logs, sub: sub}, nil
}

// WatchRefundClaimed0 is a free log subscription operation binding the contract event 0x88e83ee0e55575bb8661b0b6d9a09589ed061dd30480a3c153128b0acba85c2a.
//
// Solidity: event RefundClaimed(bytes32 indexed marketId, address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 refundAmount)
func (_MarketV3 *MarketV3Filterer) WatchRefundClaimed0(opts *bind.WatchOpts, sink chan<- *MarketV3RefundClaimed0, marketId [][32]byte, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "RefundClaimed0", marketIdRule, userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3RefundClaimed0)
				if err := _MarketV3.contract.UnpackLog(event, "RefundClaimed0", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRefundClaimed0 is a log parse operation binding the contract event 0x88e83ee0e55575bb8661b0b6d9a09589ed061dd30480a3c153128b0acba85c2a.
//
// Solidity: event RefundClaimed(bytes32 indexed marketId, address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 refundAmount)
func (_MarketV3 *MarketV3Filterer) ParseRefundClaimed0(log types.Log) (*MarketV3RefundClaimed0, error) {
	event := new(MarketV3RefundClaimed0)
	if err := _MarketV3.contract.UnpackLog(event, "RefundClaimed0", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3RoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the MarketV3 contract.
type MarketV3RoleAdminChangedIterator struct {
	Event *MarketV3RoleAdminChanged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3RoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3RoleAdminChanged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3RoleAdminChanged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3RoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3RoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3RoleAdminChanged represents a RoleAdminChanged event raised by the MarketV3 contract.
type MarketV3RoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_MarketV3 *MarketV3Filterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*MarketV3RoleAdminChangedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3RoleAdminChangedIterator{contract: _MarketV3.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_MarketV3 *MarketV3Filterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *MarketV3RoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3RoleAdminChanged)
				if err := _MarketV3.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleAdminChanged is a log parse operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_MarketV3 *MarketV3Filterer) ParseRoleAdminChanged(log types.Log) (*MarketV3RoleAdminChanged, error) {
	event := new(MarketV3RoleAdminChanged)
	if err := _MarketV3.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3RoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the MarketV3 contract.
type MarketV3RoleGrantedIterator struct {
	Event *MarketV3RoleGranted // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3RoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3RoleGranted)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3RoleGranted)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3RoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3RoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3RoleGranted represents a RoleGranted event raised by the MarketV3 contract.
type MarketV3RoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_MarketV3 *MarketV3Filterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*MarketV3RoleGrantedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3RoleGrantedIterator{contract: _MarketV3.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_MarketV3 *MarketV3Filterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *MarketV3RoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3RoleGranted)
				if err := _MarketV3.contract.UnpackLog(event, "RoleGranted", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleGranted is a log parse operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_MarketV3 *MarketV3Filterer) ParseRoleGranted(log types.Log) (*MarketV3RoleGranted, error) {
	event := new(MarketV3RoleGranted)
	if err := _MarketV3.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3RoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the MarketV3 contract.
type MarketV3RoleRevokedIterator struct {
	Event *MarketV3RoleRevoked // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3RoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3RoleRevoked)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3RoleRevoked)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3RoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3RoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3RoleRevoked represents a RoleRevoked event raised by the MarketV3 contract.
type MarketV3RoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_MarketV3 *MarketV3Filterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*MarketV3RoleRevokedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3RoleRevokedIterator{contract: _MarketV3.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_MarketV3 *MarketV3Filterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *MarketV3RoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3RoleRevoked)
				if err := _MarketV3.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleRevoked is a log parse operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_MarketV3 *MarketV3Filterer) ParseRoleRevoked(log types.Log) (*MarketV3RoleRevoked, error) {
	event := new(MarketV3RoleRevoked)
	if err := _MarketV3.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3TransferBatchIterator is returned from FilterTransferBatch and is used to iterate over the raw logs and unpacked data for TransferBatch events raised by the MarketV3 contract.
type MarketV3TransferBatchIterator struct {
	Event *MarketV3TransferBatch // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3TransferBatchIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3TransferBatch)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3TransferBatch)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3TransferBatchIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3TransferBatchIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3TransferBatch represents a TransferBatch event raised by the MarketV3 contract.
type MarketV3TransferBatch struct {
	Operator common.Address
	From     common.Address
	To       common.Address
	Ids      []*big.Int
	Values   []*big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTransferBatch is a free log retrieval operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_MarketV3 *MarketV3Filterer) FilterTransferBatch(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*MarketV3TransferBatchIterator, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3TransferBatchIterator{contract: _MarketV3.contract, event: "TransferBatch", logs: logs, sub: sub}, nil
}

// WatchTransferBatch is a free log subscription operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_MarketV3 *MarketV3Filterer) WatchTransferBatch(opts *bind.WatchOpts, sink chan<- *MarketV3TransferBatch, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3TransferBatch)
				if err := _MarketV3.contract.UnpackLog(event, "TransferBatch", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseTransferBatch is a log parse operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_MarketV3 *MarketV3Filterer) ParseTransferBatch(log types.Log) (*MarketV3TransferBatch, error) {
	event := new(MarketV3TransferBatch)
	if err := _MarketV3.contract.UnpackLog(event, "TransferBatch", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3TransferSingleIterator is returned from FilterTransferSingle and is used to iterate over the raw logs and unpacked data for TransferSingle events raised by the MarketV3 contract.
type MarketV3TransferSingleIterator struct {
	Event *MarketV3TransferSingle // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3TransferSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3TransferSingle)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3TransferSingle)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3TransferSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3TransferSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3TransferSingle represents a TransferSingle event raised by the MarketV3 contract.
type MarketV3TransferSingle struct {
	Operator common.Address
	From     common.Address
	To       common.Address
	Id       *big.Int
	Value    *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTransferSingle is a free log retrieval operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_MarketV3 *MarketV3Filterer) FilterTransferSingle(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*MarketV3TransferSingleIterator, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3TransferSingleIterator{contract: _MarketV3.contract, event: "TransferSingle", logs: logs, sub: sub}, nil
}

// WatchTransferSingle is a free log subscription operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_MarketV3 *MarketV3Filterer) WatchTransferSingle(opts *bind.WatchOpts, sink chan<- *MarketV3TransferSingle, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3TransferSingle)
				if err := _MarketV3.contract.UnpackLog(event, "TransferSingle", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseTransferSingle is a log parse operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_MarketV3 *MarketV3Filterer) ParseTransferSingle(log types.Log) (*MarketV3TransferSingle, error) {
	event := new(MarketV3TransferSingle)
	if err := _MarketV3.contract.UnpackLog(event, "TransferSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3URIIterator is returned from FilterURI and is used to iterate over the raw logs and unpacked data for URI events raised by the MarketV3 contract.
type MarketV3URIIterator struct {
	Event *MarketV3URI // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3URIIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3URI)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3URI)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3URIIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3URIIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3URI represents a URI event raised by the MarketV3 contract.
type MarketV3URI struct {
	Value string
	Id    *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterURI is a free log retrieval operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_MarketV3 *MarketV3Filterer) FilterURI(opts *bind.FilterOpts, id []*big.Int) (*MarketV3URIIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3URIIterator{contract: _MarketV3.contract, event: "URI", logs: logs, sub: sub}, nil
}

// WatchURI is a free log subscription operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_MarketV3 *MarketV3Filterer) WatchURI(opts *bind.WatchOpts, sink chan<- *MarketV3URI, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3URI)
				if err := _MarketV3.contract.UnpackLog(event, "URI", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseURI is a log parse operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_MarketV3 *MarketV3Filterer) ParseURI(log types.Log) (*MarketV3URI, error) {
	event := new(MarketV3URI)
	if err := _MarketV3.contract.UnpackLog(event, "URI", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3UnpausedIterator is returned from FilterUnpaused and is used to iterate over the raw logs and unpacked data for Unpaused events raised by the MarketV3 contract.
type MarketV3UnpausedIterator struct {
	Event *MarketV3Unpaused // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3UnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3Unpaused)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3Unpaused)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3UnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3UnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3Unpaused represents a Unpaused event raised by the MarketV3 contract.
type MarketV3Unpaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUnpaused is a free log retrieval operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_MarketV3 *MarketV3Filterer) FilterUnpaused(opts *bind.FilterOpts) (*MarketV3UnpausedIterator, error) {

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return &MarketV3UnpausedIterator{contract: _MarketV3.contract, event: "Unpaused", logs: logs, sub: sub}, nil
}

// WatchUnpaused is a free log subscription operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_MarketV3 *MarketV3Filterer) WatchUnpaused(opts *bind.WatchOpts, sink chan<- *MarketV3Unpaused) (event.Subscription, error) {

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3Unpaused)
				if err := _MarketV3.contract.UnpackLog(event, "Unpaused", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseUnpaused is a log parse operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_MarketV3 *MarketV3Filterer) ParseUnpaused(log types.Log) (*MarketV3Unpaused, error) {
	event := new(MarketV3Unpaused)
	if err := _MarketV3.contract.UnpackLog(event, "Unpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3VaultFundedIterator is returned from FilterVaultFunded and is used to iterate over the raw logs and unpacked data for VaultFunded events raised by the MarketV3 contract.
type MarketV3VaultFundedIterator struct {
	Event *MarketV3VaultFunded // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3VaultFundedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3VaultFunded)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3VaultFunded)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3VaultFundedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3VaultFundedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3VaultFunded represents a VaultFunded event raised by the MarketV3 contract.
type MarketV3VaultFunded struct {
	Vault  common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterVaultFunded is a free log retrieval operation binding the contract event 0xba24bd9b798cca64d1031eda1ced9398802343e44e07779bb510d7a21ddddef1.
//
// Solidity: event VaultFunded(address indexed vault, uint256 amount)
func (_MarketV3 *MarketV3Filterer) FilterVaultFunded(opts *bind.FilterOpts, vault []common.Address) (*MarketV3VaultFundedIterator, error) {

	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "VaultFunded", vaultRule)
	if err != nil {
		return nil, err
	}
	return &MarketV3VaultFundedIterator{contract: _MarketV3.contract, event: "VaultFunded", logs: logs, sub: sub}, nil
}

// WatchVaultFunded is a free log subscription operation binding the contract event 0xba24bd9b798cca64d1031eda1ced9398802343e44e07779bb510d7a21ddddef1.
//
// Solidity: event VaultFunded(address indexed vault, uint256 amount)
func (_MarketV3 *MarketV3Filterer) WatchVaultFunded(opts *bind.WatchOpts, sink chan<- *MarketV3VaultFunded, vault []common.Address) (event.Subscription, error) {

	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "VaultFunded", vaultRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3VaultFunded)
				if err := _MarketV3.contract.UnpackLog(event, "VaultFunded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseVaultFunded is a log parse operation binding the contract event 0xba24bd9b798cca64d1031eda1ced9398802343e44e07779bb510d7a21ddddef1.
//
// Solidity: event VaultFunded(address indexed vault, uint256 amount)
func (_MarketV3 *MarketV3Filterer) ParseVaultFunded(log types.Log) (*MarketV3VaultFunded, error) {
	event := new(MarketV3VaultFunded)
	if err := _MarketV3.contract.UnpackLog(event, "VaultFunded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3VaultLossOnCancelIterator is returned from FilterVaultLossOnCancel and is used to iterate over the raw logs and unpacked data for VaultLossOnCancel events raised by the MarketV3 contract.
type MarketV3VaultLossOnCancelIterator struct {
	Event *MarketV3VaultLossOnCancel // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3VaultLossOnCancelIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3VaultLossOnCancel)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3VaultLossOnCancel)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3VaultLossOnCancelIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3VaultLossOnCancelIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3VaultLossOnCancel represents a VaultLossOnCancel event raised by the MarketV3 contract.
type MarketV3VaultLossOnCancel struct {
	LossAmount *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterVaultLossOnCancel is a free log retrieval operation binding the contract event 0x2db84acdcb4d6409ed54c15f36309289e57bb4d5f16eb63f1b3798288e803545.
//
// Solidity: event VaultLossOnCancel(uint256 lossAmount)
func (_MarketV3 *MarketV3Filterer) FilterVaultLossOnCancel(opts *bind.FilterOpts) (*MarketV3VaultLossOnCancelIterator, error) {

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "VaultLossOnCancel")
	if err != nil {
		return nil, err
	}
	return &MarketV3VaultLossOnCancelIterator{contract: _MarketV3.contract, event: "VaultLossOnCancel", logs: logs, sub: sub}, nil
}

// WatchVaultLossOnCancel is a free log subscription operation binding the contract event 0x2db84acdcb4d6409ed54c15f36309289e57bb4d5f16eb63f1b3798288e803545.
//
// Solidity: event VaultLossOnCancel(uint256 lossAmount)
func (_MarketV3 *MarketV3Filterer) WatchVaultLossOnCancel(opts *bind.WatchOpts, sink chan<- *MarketV3VaultLossOnCancel) (event.Subscription, error) {

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "VaultLossOnCancel")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3VaultLossOnCancel)
				if err := _MarketV3.contract.UnpackLog(event, "VaultLossOnCancel", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseVaultLossOnCancel is a log parse operation binding the contract event 0x2db84acdcb4d6409ed54c15f36309289e57bb4d5f16eb63f1b3798288e803545.
//
// Solidity: event VaultLossOnCancel(uint256 lossAmount)
func (_MarketV3 *MarketV3Filterer) ParseVaultLossOnCancel(log types.Log) (*MarketV3VaultLossOnCancel, error) {
	event := new(MarketV3VaultLossOnCancel)
	if err := _MarketV3.contract.UnpackLog(event, "VaultLossOnCancel", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketV3VaultSettledIterator is returned from FilterVaultSettled and is used to iterate over the raw logs and unpacked data for VaultSettled events raised by the MarketV3 contract.
type MarketV3VaultSettledIterator struct {
	Event *MarketV3VaultSettled // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *MarketV3VaultSettledIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketV3VaultSettled)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(MarketV3VaultSettled)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *MarketV3VaultSettledIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketV3VaultSettledIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketV3VaultSettled represents a VaultSettled event raised by the MarketV3 contract.
type MarketV3VaultSettled struct {
	Principal *big.Int
	Pnl       *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterVaultSettled is a free log retrieval operation binding the contract event 0x356ac6994e7660546dbe45178b00cffbb66604a6a65df6df552b6ad738304e20.
//
// Solidity: event VaultSettled(uint256 principal, int256 pnl)
func (_MarketV3 *MarketV3Filterer) FilterVaultSettled(opts *bind.FilterOpts) (*MarketV3VaultSettledIterator, error) {

	logs, sub, err := _MarketV3.contract.FilterLogs(opts, "VaultSettled")
	if err != nil {
		return nil, err
	}
	return &MarketV3VaultSettledIterator{contract: _MarketV3.contract, event: "VaultSettled", logs: logs, sub: sub}, nil
}

// WatchVaultSettled is a free log subscription operation binding the contract event 0x356ac6994e7660546dbe45178b00cffbb66604a6a65df6df552b6ad738304e20.
//
// Solidity: event VaultSettled(uint256 principal, int256 pnl)
func (_MarketV3 *MarketV3Filterer) WatchVaultSettled(opts *bind.WatchOpts, sink chan<- *MarketV3VaultSettled) (event.Subscription, error) {

	logs, sub, err := _MarketV3.contract.WatchLogs(opts, "VaultSettled")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketV3VaultSettled)
				if err := _MarketV3.contract.UnpackLog(event, "VaultSettled", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseVaultSettled is a log parse operation binding the contract event 0x356ac6994e7660546dbe45178b00cffbb66604a6a65df6df552b6ad738304e20.
//
// Solidity: event VaultSettled(uint256 principal, int256 pnl)
func (_MarketV3 *MarketV3Filterer) ParseVaultSettled(log types.Log) (*MarketV3VaultSettled, error) {
	event := new(MarketV3VaultSettled)
	if err := _MarketV3.contract.UnpackLog(event, "VaultSettled", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
