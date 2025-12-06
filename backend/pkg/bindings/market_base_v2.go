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

// MarketBaseV2MetaData contains all meta data concerning the MarketBaseV2 contract.
var MarketBaseV2MetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"addLiquidity\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfBatch\",\"inputs\":[{\"name\":\"accounts\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"borrowedAmount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"calculateFee\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"fee\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"discountOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIFeeDiscountOracle\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"disputePeriod\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"emergencyWithdrawUser\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"exists\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"feeRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"feeRecipient\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"finalize\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getTimeUntilKickoff\",\"inputs\":[],\"outputs\":[{\"name\":\"timeUntilKickoff\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"canBet\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUserPosition\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isApprovedForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isLocked\",\"inputs\":[],\"outputs\":[{\"name\":\"_isLocked\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"kickoffTime\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"liquidityBorrowed\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"liquidityProvider\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractILiquidityProvider\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"liquidityRepaid\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"lock\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"lockTimestamp\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"outcomeCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"placeBet\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"placeBetWithSlippage\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippageBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"redeem\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"payout\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resolve\",\"inputs\":[{\"name\":\"winningOutcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resultOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIResultOracle\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"safeBatchTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDiscountOracle\",\"inputs\":[{\"name\":\"_discountOracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setFeeRate\",\"inputs\":[{\"name\":\"_feeRate\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setFeeRecipient\",\"inputs\":[{\"name\":\"_feeRecipient\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setResultOracle\",\"inputs\":[{\"name\":\"_resultOracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"settlementToken\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIERC20\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"status\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumIMarket.MarketStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalLiquidity\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalSupply\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalSupply\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateKickoffTime\",\"inputs\":[{\"name\":\"newKickoffTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"uri\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"winningOutcome\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"ApprovalForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BetPlaced\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"fee\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BorrowFailed\",\"inputs\":[{\"name\":\"requestedAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DiscountOracleUpdated\",\"inputs\":[{\"name\":\"oldOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EmergencyUserWithdrawal\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"admin\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeRateUpdated\",\"inputs\":[{\"name\":\"oldRate\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"newRate\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeRecipientUpdated\",\"inputs\":[{\"name\":\"oldRecipient\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newRecipient\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Finalized\",\"inputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"version\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"KickoffTimeUpdated\",\"inputs\":[{\"name\":\"oldKickoffTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"newKickoffTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"LiquidityAdded\",\"inputs\":[{\"name\":\"provider\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"totalAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"LiquidityBorrowed\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"LiquidityRepaid\",\"inputs\":[{\"name\":\"principal\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"revenue\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Locked\",\"inputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Redeemed\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"payout\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Resolved\",\"inputs\":[{\"name\":\"winningOutcome\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResolvedWithOracle\",\"inputs\":[{\"name\":\"winningOutcome\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"resultHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResultOracleUpdated\",\"inputs\":[{\"name\":\"newOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferBatch\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferSingle\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"URI\",\"inputs\":[{\"name\":\"value\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ERC1155InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"tokenId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidArrayLength\",\"inputs\":[{\"name\":\"idsLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"valuesLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidOperator\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155MissingApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidInitialization\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotInitializing\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// MarketBaseV2ABI is the input ABI used to generate the binding from.
// Deprecated: Use MarketBaseV2MetaData.ABI instead.
var MarketBaseV2ABI = MarketBaseV2MetaData.ABI

// MarketBaseV2 is an auto generated Go binding around an Ethereum contract.
type MarketBaseV2 struct {
	MarketBaseV2Caller     // Read-only binding to the contract
	MarketBaseV2Transactor // Write-only binding to the contract
	MarketBaseV2Filterer   // Log filterer for contract events
}

// MarketBaseV2Caller is an auto generated read-only Go binding around an Ethereum contract.
type MarketBaseV2Caller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketBaseV2Transactor is an auto generated write-only Go binding around an Ethereum contract.
type MarketBaseV2Transactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketBaseV2Filterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MarketBaseV2Filterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketBaseV2Session is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MarketBaseV2Session struct {
	Contract     *MarketBaseV2     // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// MarketBaseV2CallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MarketBaseV2CallerSession struct {
	Contract *MarketBaseV2Caller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts       // Call options to use throughout this session
}

// MarketBaseV2TransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MarketBaseV2TransactorSession struct {
	Contract     *MarketBaseV2Transactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts       // Transaction auth options to use throughout this session
}

// MarketBaseV2Raw is an auto generated low-level Go binding around an Ethereum contract.
type MarketBaseV2Raw struct {
	Contract *MarketBaseV2 // Generic contract binding to access the raw methods on
}

// MarketBaseV2CallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MarketBaseV2CallerRaw struct {
	Contract *MarketBaseV2Caller // Generic read-only contract binding to access the raw methods on
}

// MarketBaseV2TransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MarketBaseV2TransactorRaw struct {
	Contract *MarketBaseV2Transactor // Generic write-only contract binding to access the raw methods on
}

// NewMarketBaseV2 creates a new instance of MarketBaseV2, bound to a specific deployed contract.
func NewMarketBaseV2(address common.Address, backend bind.ContractBackend) (*MarketBaseV2, error) {
	contract, err := bindMarketBaseV2(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2{MarketBaseV2Caller: MarketBaseV2Caller{contract: contract}, MarketBaseV2Transactor: MarketBaseV2Transactor{contract: contract}, MarketBaseV2Filterer: MarketBaseV2Filterer{contract: contract}}, nil
}

// NewMarketBaseV2Caller creates a new read-only instance of MarketBaseV2, bound to a specific deployed contract.
func NewMarketBaseV2Caller(address common.Address, caller bind.ContractCaller) (*MarketBaseV2Caller, error) {
	contract, err := bindMarketBaseV2(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2Caller{contract: contract}, nil
}

// NewMarketBaseV2Transactor creates a new write-only instance of MarketBaseV2, bound to a specific deployed contract.
func NewMarketBaseV2Transactor(address common.Address, transactor bind.ContractTransactor) (*MarketBaseV2Transactor, error) {
	contract, err := bindMarketBaseV2(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2Transactor{contract: contract}, nil
}

// NewMarketBaseV2Filterer creates a new log filterer instance of MarketBaseV2, bound to a specific deployed contract.
func NewMarketBaseV2Filterer(address common.Address, filterer bind.ContractFilterer) (*MarketBaseV2Filterer, error) {
	contract, err := bindMarketBaseV2(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2Filterer{contract: contract}, nil
}

// bindMarketBaseV2 binds a generic wrapper to an already deployed contract.
func bindMarketBaseV2(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := MarketBaseV2MetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MarketBaseV2 *MarketBaseV2Raw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MarketBaseV2.Contract.MarketBaseV2Caller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MarketBaseV2 *MarketBaseV2Raw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.MarketBaseV2Transactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MarketBaseV2 *MarketBaseV2Raw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.MarketBaseV2Transactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MarketBaseV2 *MarketBaseV2CallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MarketBaseV2.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MarketBaseV2 *MarketBaseV2TransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MarketBaseV2 *MarketBaseV2TransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.contract.Transact(opts, method, params...)
}

// AddLiquidity is a free data retrieval call binding the contract method 0xa50118bf.
//
// Solidity: function addLiquidity(uint256 , uint256[] ) pure returns()
func (_MarketBaseV2 *MarketBaseV2Caller) AddLiquidity(opts *bind.CallOpts, arg0 *big.Int, arg1 []*big.Int) error {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "addLiquidity", arg0, arg1)

	if err != nil {
		return err
	}

	return err

}

// AddLiquidity is a free data retrieval call binding the contract method 0xa50118bf.
//
// Solidity: function addLiquidity(uint256 , uint256[] ) pure returns()
func (_MarketBaseV2 *MarketBaseV2Session) AddLiquidity(arg0 *big.Int, arg1 []*big.Int) error {
	return _MarketBaseV2.Contract.AddLiquidity(&_MarketBaseV2.CallOpts, arg0, arg1)
}

// AddLiquidity is a free data retrieval call binding the contract method 0xa50118bf.
//
// Solidity: function addLiquidity(uint256 , uint256[] ) pure returns()
func (_MarketBaseV2 *MarketBaseV2CallerSession) AddLiquidity(arg0 *big.Int, arg1 []*big.Int) error {
	return _MarketBaseV2.Contract.AddLiquidity(&_MarketBaseV2.CallOpts, arg0, arg1)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) BalanceOf(opts *bind.CallOpts, account common.Address, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "balanceOf", account, id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _MarketBaseV2.Contract.BalanceOf(&_MarketBaseV2.CallOpts, account, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _MarketBaseV2.Contract.BalanceOf(&_MarketBaseV2.CallOpts, account, id)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_MarketBaseV2 *MarketBaseV2Caller) BalanceOfBatch(opts *bind.CallOpts, accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "balanceOfBatch", accounts, ids)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_MarketBaseV2 *MarketBaseV2Session) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _MarketBaseV2.Contract.BalanceOfBatch(&_MarketBaseV2.CallOpts, accounts, ids)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_MarketBaseV2 *MarketBaseV2CallerSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _MarketBaseV2.Contract.BalanceOfBatch(&_MarketBaseV2.CallOpts, accounts, ids)
}

// BorrowedAmount is a free data retrieval call binding the contract method 0x1afbb7a4.
//
// Solidity: function borrowedAmount() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) BorrowedAmount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "borrowedAmount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BorrowedAmount is a free data retrieval call binding the contract method 0x1afbb7a4.
//
// Solidity: function borrowedAmount() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) BorrowedAmount() (*big.Int, error) {
	return _MarketBaseV2.Contract.BorrowedAmount(&_MarketBaseV2.CallOpts)
}

// BorrowedAmount is a free data retrieval call binding the contract method 0x1afbb7a4.
//
// Solidity: function borrowedAmount() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) BorrowedAmount() (*big.Int, error) {
	return _MarketBaseV2.Contract.BorrowedAmount(&_MarketBaseV2.CallOpts)
}

// CalculateFee is a free data retrieval call binding the contract method 0x8b28ab1e.
//
// Solidity: function calculateFee(address user, uint256 amount) view returns(uint256 fee)
func (_MarketBaseV2 *MarketBaseV2Caller) CalculateFee(opts *bind.CallOpts, user common.Address, amount *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "calculateFee", user, amount)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// CalculateFee is a free data retrieval call binding the contract method 0x8b28ab1e.
//
// Solidity: function calculateFee(address user, uint256 amount) view returns(uint256 fee)
func (_MarketBaseV2 *MarketBaseV2Session) CalculateFee(user common.Address, amount *big.Int) (*big.Int, error) {
	return _MarketBaseV2.Contract.CalculateFee(&_MarketBaseV2.CallOpts, user, amount)
}

// CalculateFee is a free data retrieval call binding the contract method 0x8b28ab1e.
//
// Solidity: function calculateFee(address user, uint256 amount) view returns(uint256 fee)
func (_MarketBaseV2 *MarketBaseV2CallerSession) CalculateFee(user common.Address, amount *big.Int) (*big.Int, error) {
	return _MarketBaseV2.Contract.CalculateFee(&_MarketBaseV2.CallOpts, user, amount)
}

// DiscountOracle is a free data retrieval call binding the contract method 0xdac79060.
//
// Solidity: function discountOracle() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Caller) DiscountOracle(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "discountOracle")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// DiscountOracle is a free data retrieval call binding the contract method 0xdac79060.
//
// Solidity: function discountOracle() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Session) DiscountOracle() (common.Address, error) {
	return _MarketBaseV2.Contract.DiscountOracle(&_MarketBaseV2.CallOpts)
}

// DiscountOracle is a free data retrieval call binding the contract method 0xdac79060.
//
// Solidity: function discountOracle() view returns(address)
func (_MarketBaseV2 *MarketBaseV2CallerSession) DiscountOracle() (common.Address, error) {
	return _MarketBaseV2.Contract.DiscountOracle(&_MarketBaseV2.CallOpts)
}

// DisputePeriod is a free data retrieval call binding the contract method 0x5bf31d4d.
//
// Solidity: function disputePeriod() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) DisputePeriod(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "disputePeriod")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// DisputePeriod is a free data retrieval call binding the contract method 0x5bf31d4d.
//
// Solidity: function disputePeriod() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) DisputePeriod() (*big.Int, error) {
	return _MarketBaseV2.Contract.DisputePeriod(&_MarketBaseV2.CallOpts)
}

// DisputePeriod is a free data retrieval call binding the contract method 0x5bf31d4d.
//
// Solidity: function disputePeriod() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) DisputePeriod() (*big.Int, error) {
	return _MarketBaseV2.Contract.DisputePeriod(&_MarketBaseV2.CallOpts)
}

// Exists is a free data retrieval call binding the contract method 0x4f558e79.
//
// Solidity: function exists(uint256 id) view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Caller) Exists(opts *bind.CallOpts, id *big.Int) (bool, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "exists", id)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Exists is a free data retrieval call binding the contract method 0x4f558e79.
//
// Solidity: function exists(uint256 id) view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Session) Exists(id *big.Int) (bool, error) {
	return _MarketBaseV2.Contract.Exists(&_MarketBaseV2.CallOpts, id)
}

// Exists is a free data retrieval call binding the contract method 0x4f558e79.
//
// Solidity: function exists(uint256 id) view returns(bool)
func (_MarketBaseV2 *MarketBaseV2CallerSession) Exists(id *big.Int) (bool, error) {
	return _MarketBaseV2.Contract.Exists(&_MarketBaseV2.CallOpts, id)
}

// FeeRate is a free data retrieval call binding the contract method 0x978bbdb9.
//
// Solidity: function feeRate() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) FeeRate(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "feeRate")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// FeeRate is a free data retrieval call binding the contract method 0x978bbdb9.
//
// Solidity: function feeRate() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) FeeRate() (*big.Int, error) {
	return _MarketBaseV2.Contract.FeeRate(&_MarketBaseV2.CallOpts)
}

// FeeRate is a free data retrieval call binding the contract method 0x978bbdb9.
//
// Solidity: function feeRate() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) FeeRate() (*big.Int, error) {
	return _MarketBaseV2.Contract.FeeRate(&_MarketBaseV2.CallOpts)
}

// FeeRecipient is a free data retrieval call binding the contract method 0x46904840.
//
// Solidity: function feeRecipient() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Caller) FeeRecipient(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "feeRecipient")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// FeeRecipient is a free data retrieval call binding the contract method 0x46904840.
//
// Solidity: function feeRecipient() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Session) FeeRecipient() (common.Address, error) {
	return _MarketBaseV2.Contract.FeeRecipient(&_MarketBaseV2.CallOpts)
}

// FeeRecipient is a free data retrieval call binding the contract method 0x46904840.
//
// Solidity: function feeRecipient() view returns(address)
func (_MarketBaseV2 *MarketBaseV2CallerSession) FeeRecipient() (common.Address, error) {
	return _MarketBaseV2.Contract.FeeRecipient(&_MarketBaseV2.CallOpts)
}

// GetTimeUntilKickoff is a free data retrieval call binding the contract method 0xd15a8976.
//
// Solidity: function getTimeUntilKickoff() view returns(uint256 timeUntilKickoff, bool canBet)
func (_MarketBaseV2 *MarketBaseV2Caller) GetTimeUntilKickoff(opts *bind.CallOpts) (struct {
	TimeUntilKickoff *big.Int
	CanBet           bool
}, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "getTimeUntilKickoff")

	outstruct := new(struct {
		TimeUntilKickoff *big.Int
		CanBet           bool
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.TimeUntilKickoff = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.CanBet = *abi.ConvertType(out[1], new(bool)).(*bool)

	return *outstruct, err

}

// GetTimeUntilKickoff is a free data retrieval call binding the contract method 0xd15a8976.
//
// Solidity: function getTimeUntilKickoff() view returns(uint256 timeUntilKickoff, bool canBet)
func (_MarketBaseV2 *MarketBaseV2Session) GetTimeUntilKickoff() (struct {
	TimeUntilKickoff *big.Int
	CanBet           bool
}, error) {
	return _MarketBaseV2.Contract.GetTimeUntilKickoff(&_MarketBaseV2.CallOpts)
}

// GetTimeUntilKickoff is a free data retrieval call binding the contract method 0xd15a8976.
//
// Solidity: function getTimeUntilKickoff() view returns(uint256 timeUntilKickoff, bool canBet)
func (_MarketBaseV2 *MarketBaseV2CallerSession) GetTimeUntilKickoff() (struct {
	TimeUntilKickoff *big.Int
	CanBet           bool
}, error) {
	return _MarketBaseV2.Contract.GetTimeUntilKickoff(&_MarketBaseV2.CallOpts)
}

// GetUserPosition is a free data retrieval call binding the contract method 0x1c88ef1e.
//
// Solidity: function getUserPosition(address user, uint256 outcomeId) view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) GetUserPosition(opts *bind.CallOpts, user common.Address, outcomeId *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "getUserPosition", user, outcomeId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetUserPosition is a free data retrieval call binding the contract method 0x1c88ef1e.
//
// Solidity: function getUserPosition(address user, uint256 outcomeId) view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) GetUserPosition(user common.Address, outcomeId *big.Int) (*big.Int, error) {
	return _MarketBaseV2.Contract.GetUserPosition(&_MarketBaseV2.CallOpts, user, outcomeId)
}

// GetUserPosition is a free data retrieval call binding the contract method 0x1c88ef1e.
//
// Solidity: function getUserPosition(address user, uint256 outcomeId) view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) GetUserPosition(user common.Address, outcomeId *big.Int) (*big.Int, error) {
	return _MarketBaseV2.Contract.GetUserPosition(&_MarketBaseV2.CallOpts, user, outcomeId)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Caller) IsApprovedForAll(opts *bind.CallOpts, account common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "isApprovedForAll", account, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Session) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _MarketBaseV2.Contract.IsApprovedForAll(&_MarketBaseV2.CallOpts, account, operator)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_MarketBaseV2 *MarketBaseV2CallerSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _MarketBaseV2.Contract.IsApprovedForAll(&_MarketBaseV2.CallOpts, account, operator)
}

// IsLocked is a free data retrieval call binding the contract method 0xa4e2d634.
//
// Solidity: function isLocked() view returns(bool _isLocked)
func (_MarketBaseV2 *MarketBaseV2Caller) IsLocked(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "isLocked")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsLocked is a free data retrieval call binding the contract method 0xa4e2d634.
//
// Solidity: function isLocked() view returns(bool _isLocked)
func (_MarketBaseV2 *MarketBaseV2Session) IsLocked() (bool, error) {
	return _MarketBaseV2.Contract.IsLocked(&_MarketBaseV2.CallOpts)
}

// IsLocked is a free data retrieval call binding the contract method 0xa4e2d634.
//
// Solidity: function isLocked() view returns(bool _isLocked)
func (_MarketBaseV2 *MarketBaseV2CallerSession) IsLocked() (bool, error) {
	return _MarketBaseV2.Contract.IsLocked(&_MarketBaseV2.CallOpts)
}

// KickoffTime is a free data retrieval call binding the contract method 0x1f5dca1a.
//
// Solidity: function kickoffTime() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) KickoffTime(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "kickoffTime")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// KickoffTime is a free data retrieval call binding the contract method 0x1f5dca1a.
//
// Solidity: function kickoffTime() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) KickoffTime() (*big.Int, error) {
	return _MarketBaseV2.Contract.KickoffTime(&_MarketBaseV2.CallOpts)
}

// KickoffTime is a free data retrieval call binding the contract method 0x1f5dca1a.
//
// Solidity: function kickoffTime() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) KickoffTime() (*big.Int, error) {
	return _MarketBaseV2.Contract.KickoffTime(&_MarketBaseV2.CallOpts)
}

// LiquidityBorrowed is a free data retrieval call binding the contract method 0x681bd281.
//
// Solidity: function liquidityBorrowed() view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Caller) LiquidityBorrowed(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "liquidityBorrowed")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// LiquidityBorrowed is a free data retrieval call binding the contract method 0x681bd281.
//
// Solidity: function liquidityBorrowed() view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Session) LiquidityBorrowed() (bool, error) {
	return _MarketBaseV2.Contract.LiquidityBorrowed(&_MarketBaseV2.CallOpts)
}

// LiquidityBorrowed is a free data retrieval call binding the contract method 0x681bd281.
//
// Solidity: function liquidityBorrowed() view returns(bool)
func (_MarketBaseV2 *MarketBaseV2CallerSession) LiquidityBorrowed() (bool, error) {
	return _MarketBaseV2.Contract.LiquidityBorrowed(&_MarketBaseV2.CallOpts)
}

// LiquidityProvider is a free data retrieval call binding the contract method 0x5b8bec55.
//
// Solidity: function liquidityProvider() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Caller) LiquidityProvider(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "liquidityProvider")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// LiquidityProvider is a free data retrieval call binding the contract method 0x5b8bec55.
//
// Solidity: function liquidityProvider() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Session) LiquidityProvider() (common.Address, error) {
	return _MarketBaseV2.Contract.LiquidityProvider(&_MarketBaseV2.CallOpts)
}

// LiquidityProvider is a free data retrieval call binding the contract method 0x5b8bec55.
//
// Solidity: function liquidityProvider() view returns(address)
func (_MarketBaseV2 *MarketBaseV2CallerSession) LiquidityProvider() (common.Address, error) {
	return _MarketBaseV2.Contract.LiquidityProvider(&_MarketBaseV2.CallOpts)
}

// LiquidityRepaid is a free data retrieval call binding the contract method 0x526df34a.
//
// Solidity: function liquidityRepaid() view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Caller) LiquidityRepaid(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "liquidityRepaid")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// LiquidityRepaid is a free data retrieval call binding the contract method 0x526df34a.
//
// Solidity: function liquidityRepaid() view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Session) LiquidityRepaid() (bool, error) {
	return _MarketBaseV2.Contract.LiquidityRepaid(&_MarketBaseV2.CallOpts)
}

// LiquidityRepaid is a free data retrieval call binding the contract method 0x526df34a.
//
// Solidity: function liquidityRepaid() view returns(bool)
func (_MarketBaseV2 *MarketBaseV2CallerSession) LiquidityRepaid() (bool, error) {
	return _MarketBaseV2.Contract.LiquidityRepaid(&_MarketBaseV2.CallOpts)
}

// LockTimestamp is a free data retrieval call binding the contract method 0xb544bf83.
//
// Solidity: function lockTimestamp() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) LockTimestamp(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "lockTimestamp")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LockTimestamp is a free data retrieval call binding the contract method 0xb544bf83.
//
// Solidity: function lockTimestamp() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) LockTimestamp() (*big.Int, error) {
	return _MarketBaseV2.Contract.LockTimestamp(&_MarketBaseV2.CallOpts)
}

// LockTimestamp is a free data retrieval call binding the contract method 0xb544bf83.
//
// Solidity: function lockTimestamp() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) LockTimestamp() (*big.Int, error) {
	return _MarketBaseV2.Contract.LockTimestamp(&_MarketBaseV2.CallOpts)
}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) OutcomeCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "outcomeCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) OutcomeCount() (*big.Int, error) {
	return _MarketBaseV2.Contract.OutcomeCount(&_MarketBaseV2.CallOpts)
}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) OutcomeCount() (*big.Int, error) {
	return _MarketBaseV2.Contract.OutcomeCount(&_MarketBaseV2.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Caller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Session) Owner() (common.Address, error) {
	return _MarketBaseV2.Contract.Owner(&_MarketBaseV2.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MarketBaseV2 *MarketBaseV2CallerSession) Owner() (common.Address, error) {
	return _MarketBaseV2.Contract.Owner(&_MarketBaseV2.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Caller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Session) Paused() (bool, error) {
	return _MarketBaseV2.Contract.Paused(&_MarketBaseV2.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketBaseV2 *MarketBaseV2CallerSession) Paused() (bool, error) {
	return _MarketBaseV2.Contract.Paused(&_MarketBaseV2.CallOpts)
}

// ResultOracle is a free data retrieval call binding the contract method 0xc77e5042.
//
// Solidity: function resultOracle() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Caller) ResultOracle(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "resultOracle")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ResultOracle is a free data retrieval call binding the contract method 0xc77e5042.
//
// Solidity: function resultOracle() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Session) ResultOracle() (common.Address, error) {
	return _MarketBaseV2.Contract.ResultOracle(&_MarketBaseV2.CallOpts)
}

// ResultOracle is a free data retrieval call binding the contract method 0xc77e5042.
//
// Solidity: function resultOracle() view returns(address)
func (_MarketBaseV2 *MarketBaseV2CallerSession) ResultOracle() (common.Address, error) {
	return _MarketBaseV2.Contract.ResultOracle(&_MarketBaseV2.CallOpts)
}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Caller) SettlementToken(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "settlementToken")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_MarketBaseV2 *MarketBaseV2Session) SettlementToken() (common.Address, error) {
	return _MarketBaseV2.Contract.SettlementToken(&_MarketBaseV2.CallOpts)
}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_MarketBaseV2 *MarketBaseV2CallerSession) SettlementToken() (common.Address, error) {
	return _MarketBaseV2.Contract.SettlementToken(&_MarketBaseV2.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_MarketBaseV2 *MarketBaseV2Caller) Status(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "status")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_MarketBaseV2 *MarketBaseV2Session) Status() (uint8, error) {
	return _MarketBaseV2.Contract.Status(&_MarketBaseV2.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_MarketBaseV2 *MarketBaseV2CallerSession) Status() (uint8, error) {
	return _MarketBaseV2.Contract.Status(&_MarketBaseV2.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Caller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketBaseV2 *MarketBaseV2Session) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _MarketBaseV2.Contract.SupportsInterface(&_MarketBaseV2.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketBaseV2 *MarketBaseV2CallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _MarketBaseV2.Contract.SupportsInterface(&_MarketBaseV2.CallOpts, interfaceId)
}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) TotalLiquidity(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "totalLiquidity")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) TotalLiquidity() (*big.Int, error) {
	return _MarketBaseV2.Contract.TotalLiquidity(&_MarketBaseV2.CallOpts)
}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) TotalLiquidity() (*big.Int, error) {
	return _MarketBaseV2.Contract.TotalLiquidity(&_MarketBaseV2.CallOpts)
}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) TotalSupply(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "totalSupply")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) TotalSupply() (*big.Int, error) {
	return _MarketBaseV2.Contract.TotalSupply(&_MarketBaseV2.CallOpts)
}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) TotalSupply() (*big.Int, error) {
	return _MarketBaseV2.Contract.TotalSupply(&_MarketBaseV2.CallOpts)
}

// TotalSupply0 is a free data retrieval call binding the contract method 0xbd85b039.
//
// Solidity: function totalSupply(uint256 id) view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) TotalSupply0(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "totalSupply0", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalSupply0 is a free data retrieval call binding the contract method 0xbd85b039.
//
// Solidity: function totalSupply(uint256 id) view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) TotalSupply0(id *big.Int) (*big.Int, error) {
	return _MarketBaseV2.Contract.TotalSupply0(&_MarketBaseV2.CallOpts, id)
}

// TotalSupply0 is a free data retrieval call binding the contract method 0xbd85b039.
//
// Solidity: function totalSupply(uint256 id) view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) TotalSupply0(id *big.Int) (*big.Int, error) {
	return _MarketBaseV2.Contract.TotalSupply0(&_MarketBaseV2.CallOpts, id)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_MarketBaseV2 *MarketBaseV2Caller) Uri(opts *bind.CallOpts, arg0 *big.Int) (string, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "uri", arg0)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_MarketBaseV2 *MarketBaseV2Session) Uri(arg0 *big.Int) (string, error) {
	return _MarketBaseV2.Contract.Uri(&_MarketBaseV2.CallOpts, arg0)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_MarketBaseV2 *MarketBaseV2CallerSession) Uri(arg0 *big.Int) (string, error) {
	return _MarketBaseV2.Contract.Uri(&_MarketBaseV2.CallOpts, arg0)
}

// WinningOutcome is a free data retrieval call binding the contract method 0x9b34ae03.
//
// Solidity: function winningOutcome() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Caller) WinningOutcome(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBaseV2.contract.Call(opts, &out, "winningOutcome")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WinningOutcome is a free data retrieval call binding the contract method 0x9b34ae03.
//
// Solidity: function winningOutcome() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2Session) WinningOutcome() (*big.Int, error) {
	return _MarketBaseV2.Contract.WinningOutcome(&_MarketBaseV2.CallOpts)
}

// WinningOutcome is a free data retrieval call binding the contract method 0x9b34ae03.
//
// Solidity: function winningOutcome() view returns(uint256)
func (_MarketBaseV2 *MarketBaseV2CallerSession) WinningOutcome() (*big.Int, error) {
	return _MarketBaseV2.Contract.WinningOutcome(&_MarketBaseV2.CallOpts)
}

// EmergencyWithdrawUser is a paid mutator transaction binding the contract method 0x9795b07d.
//
// Solidity: function emergencyWithdrawUser(address user, uint256 outcomeId, uint256 shares) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) EmergencyWithdrawUser(opts *bind.TransactOpts, user common.Address, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "emergencyWithdrawUser", user, outcomeId, shares)
}

// EmergencyWithdrawUser is a paid mutator transaction binding the contract method 0x9795b07d.
//
// Solidity: function emergencyWithdrawUser(address user, uint256 outcomeId, uint256 shares) returns()
func (_MarketBaseV2 *MarketBaseV2Session) EmergencyWithdrawUser(user common.Address, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.EmergencyWithdrawUser(&_MarketBaseV2.TransactOpts, user, outcomeId, shares)
}

// EmergencyWithdrawUser is a paid mutator transaction binding the contract method 0x9795b07d.
//
// Solidity: function emergencyWithdrawUser(address user, uint256 outcomeId, uint256 shares) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) EmergencyWithdrawUser(user common.Address, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.EmergencyWithdrawUser(&_MarketBaseV2.TransactOpts, user, outcomeId, shares)
}

// Finalize is a paid mutator transaction binding the contract method 0x4bb278f3.
//
// Solidity: function finalize() returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) Finalize(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "finalize")
}

// Finalize is a paid mutator transaction binding the contract method 0x4bb278f3.
//
// Solidity: function finalize() returns()
func (_MarketBaseV2 *MarketBaseV2Session) Finalize() (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Finalize(&_MarketBaseV2.TransactOpts)
}

// Finalize is a paid mutator transaction binding the contract method 0x4bb278f3.
//
// Solidity: function finalize() returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) Finalize() (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Finalize(&_MarketBaseV2.TransactOpts)
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) Lock(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "lock")
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_MarketBaseV2 *MarketBaseV2Session) Lock() (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Lock(&_MarketBaseV2.TransactOpts)
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) Lock() (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Lock(&_MarketBaseV2.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) Pause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "pause")
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketBaseV2 *MarketBaseV2Session) Pause() (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Pause(&_MarketBaseV2.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) Pause() (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Pause(&_MarketBaseV2.TransactOpts)
}

// PlaceBet is a paid mutator transaction binding the contract method 0x4afe62b5.
//
// Solidity: function placeBet(uint256 outcomeId, uint256 amount) returns(uint256 shares)
func (_MarketBaseV2 *MarketBaseV2Transactor) PlaceBet(opts *bind.TransactOpts, outcomeId *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "placeBet", outcomeId, amount)
}

// PlaceBet is a paid mutator transaction binding the contract method 0x4afe62b5.
//
// Solidity: function placeBet(uint256 outcomeId, uint256 amount) returns(uint256 shares)
func (_MarketBaseV2 *MarketBaseV2Session) PlaceBet(outcomeId *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.PlaceBet(&_MarketBaseV2.TransactOpts, outcomeId, amount)
}

// PlaceBet is a paid mutator transaction binding the contract method 0x4afe62b5.
//
// Solidity: function placeBet(uint256 outcomeId, uint256 amount) returns(uint256 shares)
func (_MarketBaseV2 *MarketBaseV2TransactorSession) PlaceBet(outcomeId *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.PlaceBet(&_MarketBaseV2.TransactOpts, outcomeId, amount)
}

// PlaceBetWithSlippage is a paid mutator transaction binding the contract method 0x5184b2f2.
//
// Solidity: function placeBetWithSlippage(uint256 outcomeId, uint256 amount, uint256 maxSlippageBps) returns(uint256 shares)
func (_MarketBaseV2 *MarketBaseV2Transactor) PlaceBetWithSlippage(opts *bind.TransactOpts, outcomeId *big.Int, amount *big.Int, maxSlippageBps *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "placeBetWithSlippage", outcomeId, amount, maxSlippageBps)
}

// PlaceBetWithSlippage is a paid mutator transaction binding the contract method 0x5184b2f2.
//
// Solidity: function placeBetWithSlippage(uint256 outcomeId, uint256 amount, uint256 maxSlippageBps) returns(uint256 shares)
func (_MarketBaseV2 *MarketBaseV2Session) PlaceBetWithSlippage(outcomeId *big.Int, amount *big.Int, maxSlippageBps *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.PlaceBetWithSlippage(&_MarketBaseV2.TransactOpts, outcomeId, amount, maxSlippageBps)
}

// PlaceBetWithSlippage is a paid mutator transaction binding the contract method 0x5184b2f2.
//
// Solidity: function placeBetWithSlippage(uint256 outcomeId, uint256 amount, uint256 maxSlippageBps) returns(uint256 shares)
func (_MarketBaseV2 *MarketBaseV2TransactorSession) PlaceBetWithSlippage(outcomeId *big.Int, amount *big.Int, maxSlippageBps *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.PlaceBetWithSlippage(&_MarketBaseV2.TransactOpts, outcomeId, amount, maxSlippageBps)
}

// Redeem is a paid mutator transaction binding the contract method 0x7cbc2373.
//
// Solidity: function redeem(uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_MarketBaseV2 *MarketBaseV2Transactor) Redeem(opts *bind.TransactOpts, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "redeem", outcomeId, shares)
}

// Redeem is a paid mutator transaction binding the contract method 0x7cbc2373.
//
// Solidity: function redeem(uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_MarketBaseV2 *MarketBaseV2Session) Redeem(outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Redeem(&_MarketBaseV2.TransactOpts, outcomeId, shares)
}

// Redeem is a paid mutator transaction binding the contract method 0x7cbc2373.
//
// Solidity: function redeem(uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_MarketBaseV2 *MarketBaseV2TransactorSession) Redeem(outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Redeem(&_MarketBaseV2.TransactOpts, outcomeId, shares)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_MarketBaseV2 *MarketBaseV2Session) RenounceOwnership() (*types.Transaction, error) {
	return _MarketBaseV2.Contract.RenounceOwnership(&_MarketBaseV2.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _MarketBaseV2.Contract.RenounceOwnership(&_MarketBaseV2.TransactOpts)
}

// Resolve is a paid mutator transaction binding the contract method 0x4f896d4f.
//
// Solidity: function resolve(uint256 winningOutcomeId) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) Resolve(opts *bind.TransactOpts, winningOutcomeId *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "resolve", winningOutcomeId)
}

// Resolve is a paid mutator transaction binding the contract method 0x4f896d4f.
//
// Solidity: function resolve(uint256 winningOutcomeId) returns()
func (_MarketBaseV2 *MarketBaseV2Session) Resolve(winningOutcomeId *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Resolve(&_MarketBaseV2.TransactOpts, winningOutcomeId)
}

// Resolve is a paid mutator transaction binding the contract method 0x4f896d4f.
//
// Solidity: function resolve(uint256 winningOutcomeId) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) Resolve(winningOutcomeId *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Resolve(&_MarketBaseV2.TransactOpts, winningOutcomeId)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) SafeBatchTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "safeBatchTransferFrom", from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_MarketBaseV2 *MarketBaseV2Session) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SafeBatchTransferFrom(&_MarketBaseV2.TransactOpts, from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SafeBatchTransferFrom(&_MarketBaseV2.TransactOpts, from, to, ids, values, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "safeTransferFrom", from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_MarketBaseV2 *MarketBaseV2Session) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SafeTransferFrom(&_MarketBaseV2.TransactOpts, from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SafeTransferFrom(&_MarketBaseV2.TransactOpts, from, to, id, value, data)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_MarketBaseV2 *MarketBaseV2Session) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SetApprovalForAll(&_MarketBaseV2.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SetApprovalForAll(&_MarketBaseV2.TransactOpts, operator, approved)
}

// SetDiscountOracle is a paid mutator transaction binding the contract method 0x0736251c.
//
// Solidity: function setDiscountOracle(address _discountOracle) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) SetDiscountOracle(opts *bind.TransactOpts, _discountOracle common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "setDiscountOracle", _discountOracle)
}

// SetDiscountOracle is a paid mutator transaction binding the contract method 0x0736251c.
//
// Solidity: function setDiscountOracle(address _discountOracle) returns()
func (_MarketBaseV2 *MarketBaseV2Session) SetDiscountOracle(_discountOracle common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SetDiscountOracle(&_MarketBaseV2.TransactOpts, _discountOracle)
}

// SetDiscountOracle is a paid mutator transaction binding the contract method 0x0736251c.
//
// Solidity: function setDiscountOracle(address _discountOracle) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) SetDiscountOracle(_discountOracle common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SetDiscountOracle(&_MarketBaseV2.TransactOpts, _discountOracle)
}

// SetFeeRate is a paid mutator transaction binding the contract method 0x45596e2e.
//
// Solidity: function setFeeRate(uint256 _feeRate) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) SetFeeRate(opts *bind.TransactOpts, _feeRate *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "setFeeRate", _feeRate)
}

// SetFeeRate is a paid mutator transaction binding the contract method 0x45596e2e.
//
// Solidity: function setFeeRate(uint256 _feeRate) returns()
func (_MarketBaseV2 *MarketBaseV2Session) SetFeeRate(_feeRate *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SetFeeRate(&_MarketBaseV2.TransactOpts, _feeRate)
}

// SetFeeRate is a paid mutator transaction binding the contract method 0x45596e2e.
//
// Solidity: function setFeeRate(uint256 _feeRate) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) SetFeeRate(_feeRate *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SetFeeRate(&_MarketBaseV2.TransactOpts, _feeRate)
}

// SetFeeRecipient is a paid mutator transaction binding the contract method 0xe74b981b.
//
// Solidity: function setFeeRecipient(address _feeRecipient) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) SetFeeRecipient(opts *bind.TransactOpts, _feeRecipient common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "setFeeRecipient", _feeRecipient)
}

// SetFeeRecipient is a paid mutator transaction binding the contract method 0xe74b981b.
//
// Solidity: function setFeeRecipient(address _feeRecipient) returns()
func (_MarketBaseV2 *MarketBaseV2Session) SetFeeRecipient(_feeRecipient common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SetFeeRecipient(&_MarketBaseV2.TransactOpts, _feeRecipient)
}

// SetFeeRecipient is a paid mutator transaction binding the contract method 0xe74b981b.
//
// Solidity: function setFeeRecipient(address _feeRecipient) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) SetFeeRecipient(_feeRecipient common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SetFeeRecipient(&_MarketBaseV2.TransactOpts, _feeRecipient)
}

// SetResultOracle is a paid mutator transaction binding the contract method 0x17bc4648.
//
// Solidity: function setResultOracle(address _resultOracle) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) SetResultOracle(opts *bind.TransactOpts, _resultOracle common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "setResultOracle", _resultOracle)
}

// SetResultOracle is a paid mutator transaction binding the contract method 0x17bc4648.
//
// Solidity: function setResultOracle(address _resultOracle) returns()
func (_MarketBaseV2 *MarketBaseV2Session) SetResultOracle(_resultOracle common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SetResultOracle(&_MarketBaseV2.TransactOpts, _resultOracle)
}

// SetResultOracle is a paid mutator transaction binding the contract method 0x17bc4648.
//
// Solidity: function setResultOracle(address _resultOracle) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) SetResultOracle(_resultOracle common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.SetResultOracle(&_MarketBaseV2.TransactOpts, _resultOracle)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MarketBaseV2 *MarketBaseV2Session) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.TransferOwnership(&_MarketBaseV2.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.TransferOwnership(&_MarketBaseV2.TransactOpts, newOwner)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) Unpause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "unpause")
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketBaseV2 *MarketBaseV2Session) Unpause() (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Unpause(&_MarketBaseV2.TransactOpts)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) Unpause() (*types.Transaction, error) {
	return _MarketBaseV2.Contract.Unpause(&_MarketBaseV2.TransactOpts)
}

// UpdateKickoffTime is a paid mutator transaction binding the contract method 0xcc674e72.
//
// Solidity: function updateKickoffTime(uint256 newKickoffTime) returns()
func (_MarketBaseV2 *MarketBaseV2Transactor) UpdateKickoffTime(opts *bind.TransactOpts, newKickoffTime *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.contract.Transact(opts, "updateKickoffTime", newKickoffTime)
}

// UpdateKickoffTime is a paid mutator transaction binding the contract method 0xcc674e72.
//
// Solidity: function updateKickoffTime(uint256 newKickoffTime) returns()
func (_MarketBaseV2 *MarketBaseV2Session) UpdateKickoffTime(newKickoffTime *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.UpdateKickoffTime(&_MarketBaseV2.TransactOpts, newKickoffTime)
}

// UpdateKickoffTime is a paid mutator transaction binding the contract method 0xcc674e72.
//
// Solidity: function updateKickoffTime(uint256 newKickoffTime) returns()
func (_MarketBaseV2 *MarketBaseV2TransactorSession) UpdateKickoffTime(newKickoffTime *big.Int) (*types.Transaction, error) {
	return _MarketBaseV2.Contract.UpdateKickoffTime(&_MarketBaseV2.TransactOpts, newKickoffTime)
}

// MarketBaseV2ApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the MarketBaseV2 contract.
type MarketBaseV2ApprovalForAllIterator struct {
	Event *MarketBaseV2ApprovalForAll // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2ApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2ApprovalForAll)
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
		it.Event = new(MarketBaseV2ApprovalForAll)
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
func (it *MarketBaseV2ApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2ApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2ApprovalForAll represents a ApprovalForAll event raised by the MarketBaseV2 contract.
type MarketBaseV2ApprovalForAll struct {
	Account  common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterApprovalForAll(opts *bind.FilterOpts, account []common.Address, operator []common.Address) (*MarketBaseV2ApprovalForAllIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2ApprovalForAllIterator{contract: _MarketBaseV2.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *MarketBaseV2ApprovalForAll, account []common.Address, operator []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2ApprovalForAll)
				if err := _MarketBaseV2.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
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
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseApprovalForAll(log types.Log) (*MarketBaseV2ApprovalForAll, error) {
	event := new(MarketBaseV2ApprovalForAll)
	if err := _MarketBaseV2.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2BetPlacedIterator is returned from FilterBetPlaced and is used to iterate over the raw logs and unpacked data for BetPlaced events raised by the MarketBaseV2 contract.
type MarketBaseV2BetPlacedIterator struct {
	Event *MarketBaseV2BetPlaced // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2BetPlacedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2BetPlaced)
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
		it.Event = new(MarketBaseV2BetPlaced)
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
func (it *MarketBaseV2BetPlacedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2BetPlacedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2BetPlaced represents a BetPlaced event raised by the MarketBaseV2 contract.
type MarketBaseV2BetPlaced struct {
	User      common.Address
	OutcomeId *big.Int
	Amount    *big.Int
	Shares    *big.Int
	Fee       *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterBetPlaced is a free log retrieval operation binding the contract event 0x935a8686694e2b5cc90f63054b327255f6fb92db3acd6d98c5a707d4987e93e1.
//
// Solidity: event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares, uint256 fee)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterBetPlaced(opts *bind.FilterOpts, user []common.Address, outcomeId []*big.Int) (*MarketBaseV2BetPlacedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "BetPlaced", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2BetPlacedIterator{contract: _MarketBaseV2.contract, event: "BetPlaced", logs: logs, sub: sub}, nil
}

// WatchBetPlaced is a free log subscription operation binding the contract event 0x935a8686694e2b5cc90f63054b327255f6fb92db3acd6d98c5a707d4987e93e1.
//
// Solidity: event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares, uint256 fee)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchBetPlaced(opts *bind.WatchOpts, sink chan<- *MarketBaseV2BetPlaced, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "BetPlaced", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2BetPlaced)
				if err := _MarketBaseV2.contract.UnpackLog(event, "BetPlaced", log); err != nil {
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

// ParseBetPlaced is a log parse operation binding the contract event 0x935a8686694e2b5cc90f63054b327255f6fb92db3acd6d98c5a707d4987e93e1.
//
// Solidity: event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares, uint256 fee)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseBetPlaced(log types.Log) (*MarketBaseV2BetPlaced, error) {
	event := new(MarketBaseV2BetPlaced)
	if err := _MarketBaseV2.contract.UnpackLog(event, "BetPlaced", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2BorrowFailedIterator is returned from FilterBorrowFailed and is used to iterate over the raw logs and unpacked data for BorrowFailed events raised by the MarketBaseV2 contract.
type MarketBaseV2BorrowFailedIterator struct {
	Event *MarketBaseV2BorrowFailed // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2BorrowFailedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2BorrowFailed)
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
		it.Event = new(MarketBaseV2BorrowFailed)
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
func (it *MarketBaseV2BorrowFailedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2BorrowFailedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2BorrowFailed represents a BorrowFailed event raised by the MarketBaseV2 contract.
type MarketBaseV2BorrowFailed struct {
	RequestedAmount *big.Int
	Reason          string
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterBorrowFailed is a free log retrieval operation binding the contract event 0x111c8f3300522c33be4528ddfec8eb8092016c8eb81cc867e9e77d9d94353a1b.
//
// Solidity: event BorrowFailed(uint256 requestedAmount, string reason)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterBorrowFailed(opts *bind.FilterOpts) (*MarketBaseV2BorrowFailedIterator, error) {

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "BorrowFailed")
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2BorrowFailedIterator{contract: _MarketBaseV2.contract, event: "BorrowFailed", logs: logs, sub: sub}, nil
}

// WatchBorrowFailed is a free log subscription operation binding the contract event 0x111c8f3300522c33be4528ddfec8eb8092016c8eb81cc867e9e77d9d94353a1b.
//
// Solidity: event BorrowFailed(uint256 requestedAmount, string reason)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchBorrowFailed(opts *bind.WatchOpts, sink chan<- *MarketBaseV2BorrowFailed) (event.Subscription, error) {

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "BorrowFailed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2BorrowFailed)
				if err := _MarketBaseV2.contract.UnpackLog(event, "BorrowFailed", log); err != nil {
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

// ParseBorrowFailed is a log parse operation binding the contract event 0x111c8f3300522c33be4528ddfec8eb8092016c8eb81cc867e9e77d9d94353a1b.
//
// Solidity: event BorrowFailed(uint256 requestedAmount, string reason)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseBorrowFailed(log types.Log) (*MarketBaseV2BorrowFailed, error) {
	event := new(MarketBaseV2BorrowFailed)
	if err := _MarketBaseV2.contract.UnpackLog(event, "BorrowFailed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2DiscountOracleUpdatedIterator is returned from FilterDiscountOracleUpdated and is used to iterate over the raw logs and unpacked data for DiscountOracleUpdated events raised by the MarketBaseV2 contract.
type MarketBaseV2DiscountOracleUpdatedIterator struct {
	Event *MarketBaseV2DiscountOracleUpdated // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2DiscountOracleUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2DiscountOracleUpdated)
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
		it.Event = new(MarketBaseV2DiscountOracleUpdated)
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
func (it *MarketBaseV2DiscountOracleUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2DiscountOracleUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2DiscountOracleUpdated represents a DiscountOracleUpdated event raised by the MarketBaseV2 contract.
type MarketBaseV2DiscountOracleUpdated struct {
	OldOracle common.Address
	NewOracle common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterDiscountOracleUpdated is a free log retrieval operation binding the contract event 0xb0a21792e739b32d34f3928764f774f8b8702f15d4b00f2e688689d23050aaa6.
//
// Solidity: event DiscountOracleUpdated(address indexed oldOracle, address indexed newOracle)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterDiscountOracleUpdated(opts *bind.FilterOpts, oldOracle []common.Address, newOracle []common.Address) (*MarketBaseV2DiscountOracleUpdatedIterator, error) {

	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "DiscountOracleUpdated", oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2DiscountOracleUpdatedIterator{contract: _MarketBaseV2.contract, event: "DiscountOracleUpdated", logs: logs, sub: sub}, nil
}

// WatchDiscountOracleUpdated is a free log subscription operation binding the contract event 0xb0a21792e739b32d34f3928764f774f8b8702f15d4b00f2e688689d23050aaa6.
//
// Solidity: event DiscountOracleUpdated(address indexed oldOracle, address indexed newOracle)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchDiscountOracleUpdated(opts *bind.WatchOpts, sink chan<- *MarketBaseV2DiscountOracleUpdated, oldOracle []common.Address, newOracle []common.Address) (event.Subscription, error) {

	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "DiscountOracleUpdated", oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2DiscountOracleUpdated)
				if err := _MarketBaseV2.contract.UnpackLog(event, "DiscountOracleUpdated", log); err != nil {
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

// ParseDiscountOracleUpdated is a log parse operation binding the contract event 0xb0a21792e739b32d34f3928764f774f8b8702f15d4b00f2e688689d23050aaa6.
//
// Solidity: event DiscountOracleUpdated(address indexed oldOracle, address indexed newOracle)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseDiscountOracleUpdated(log types.Log) (*MarketBaseV2DiscountOracleUpdated, error) {
	event := new(MarketBaseV2DiscountOracleUpdated)
	if err := _MarketBaseV2.contract.UnpackLog(event, "DiscountOracleUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2EmergencyUserWithdrawalIterator is returned from FilterEmergencyUserWithdrawal and is used to iterate over the raw logs and unpacked data for EmergencyUserWithdrawal events raised by the MarketBaseV2 contract.
type MarketBaseV2EmergencyUserWithdrawalIterator struct {
	Event *MarketBaseV2EmergencyUserWithdrawal // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2EmergencyUserWithdrawalIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2EmergencyUserWithdrawal)
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
		it.Event = new(MarketBaseV2EmergencyUserWithdrawal)
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
func (it *MarketBaseV2EmergencyUserWithdrawalIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2EmergencyUserWithdrawalIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2EmergencyUserWithdrawal represents a EmergencyUserWithdrawal event raised by the MarketBaseV2 contract.
type MarketBaseV2EmergencyUserWithdrawal struct {
	User      common.Address
	OutcomeId *big.Int
	Shares    *big.Int
	Amount    *big.Int
	Admin     common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterEmergencyUserWithdrawal is a free log retrieval operation binding the contract event 0xd7f648185b779c33700f273f5a9e1fee96643595686cf0933dfb6bbdb4b5d2c8.
//
// Solidity: event EmergencyUserWithdrawal(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 amount, address indexed admin)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterEmergencyUserWithdrawal(opts *bind.FilterOpts, user []common.Address, outcomeId []*big.Int, admin []common.Address) (*MarketBaseV2EmergencyUserWithdrawalIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	var adminRule []interface{}
	for _, adminItem := range admin {
		adminRule = append(adminRule, adminItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "EmergencyUserWithdrawal", userRule, outcomeIdRule, adminRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2EmergencyUserWithdrawalIterator{contract: _MarketBaseV2.contract, event: "EmergencyUserWithdrawal", logs: logs, sub: sub}, nil
}

// WatchEmergencyUserWithdrawal is a free log subscription operation binding the contract event 0xd7f648185b779c33700f273f5a9e1fee96643595686cf0933dfb6bbdb4b5d2c8.
//
// Solidity: event EmergencyUserWithdrawal(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 amount, address indexed admin)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchEmergencyUserWithdrawal(opts *bind.WatchOpts, sink chan<- *MarketBaseV2EmergencyUserWithdrawal, user []common.Address, outcomeId []*big.Int, admin []common.Address) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	var adminRule []interface{}
	for _, adminItem := range admin {
		adminRule = append(adminRule, adminItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "EmergencyUserWithdrawal", userRule, outcomeIdRule, adminRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2EmergencyUserWithdrawal)
				if err := _MarketBaseV2.contract.UnpackLog(event, "EmergencyUserWithdrawal", log); err != nil {
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

// ParseEmergencyUserWithdrawal is a log parse operation binding the contract event 0xd7f648185b779c33700f273f5a9e1fee96643595686cf0933dfb6bbdb4b5d2c8.
//
// Solidity: event EmergencyUserWithdrawal(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 amount, address indexed admin)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseEmergencyUserWithdrawal(log types.Log) (*MarketBaseV2EmergencyUserWithdrawal, error) {
	event := new(MarketBaseV2EmergencyUserWithdrawal)
	if err := _MarketBaseV2.contract.UnpackLog(event, "EmergencyUserWithdrawal", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2FeeRateUpdatedIterator is returned from FilterFeeRateUpdated and is used to iterate over the raw logs and unpacked data for FeeRateUpdated events raised by the MarketBaseV2 contract.
type MarketBaseV2FeeRateUpdatedIterator struct {
	Event *MarketBaseV2FeeRateUpdated // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2FeeRateUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2FeeRateUpdated)
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
		it.Event = new(MarketBaseV2FeeRateUpdated)
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
func (it *MarketBaseV2FeeRateUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2FeeRateUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2FeeRateUpdated represents a FeeRateUpdated event raised by the MarketBaseV2 contract.
type MarketBaseV2FeeRateUpdated struct {
	OldRate *big.Int
	NewRate *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterFeeRateUpdated is a free log retrieval operation binding the contract event 0x14914da2bf76024616fbe1859783fcd4dbddcb179b1f3a854949fbf920dcb957.
//
// Solidity: event FeeRateUpdated(uint256 oldRate, uint256 newRate)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterFeeRateUpdated(opts *bind.FilterOpts) (*MarketBaseV2FeeRateUpdatedIterator, error) {

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "FeeRateUpdated")
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2FeeRateUpdatedIterator{contract: _MarketBaseV2.contract, event: "FeeRateUpdated", logs: logs, sub: sub}, nil
}

// WatchFeeRateUpdated is a free log subscription operation binding the contract event 0x14914da2bf76024616fbe1859783fcd4dbddcb179b1f3a854949fbf920dcb957.
//
// Solidity: event FeeRateUpdated(uint256 oldRate, uint256 newRate)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchFeeRateUpdated(opts *bind.WatchOpts, sink chan<- *MarketBaseV2FeeRateUpdated) (event.Subscription, error) {

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "FeeRateUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2FeeRateUpdated)
				if err := _MarketBaseV2.contract.UnpackLog(event, "FeeRateUpdated", log); err != nil {
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

// ParseFeeRateUpdated is a log parse operation binding the contract event 0x14914da2bf76024616fbe1859783fcd4dbddcb179b1f3a854949fbf920dcb957.
//
// Solidity: event FeeRateUpdated(uint256 oldRate, uint256 newRate)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseFeeRateUpdated(log types.Log) (*MarketBaseV2FeeRateUpdated, error) {
	event := new(MarketBaseV2FeeRateUpdated)
	if err := _MarketBaseV2.contract.UnpackLog(event, "FeeRateUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2FeeRecipientUpdatedIterator is returned from FilterFeeRecipientUpdated and is used to iterate over the raw logs and unpacked data for FeeRecipientUpdated events raised by the MarketBaseV2 contract.
type MarketBaseV2FeeRecipientUpdatedIterator struct {
	Event *MarketBaseV2FeeRecipientUpdated // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2FeeRecipientUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2FeeRecipientUpdated)
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
		it.Event = new(MarketBaseV2FeeRecipientUpdated)
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
func (it *MarketBaseV2FeeRecipientUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2FeeRecipientUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2FeeRecipientUpdated represents a FeeRecipientUpdated event raised by the MarketBaseV2 contract.
type MarketBaseV2FeeRecipientUpdated struct {
	OldRecipient common.Address
	NewRecipient common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterFeeRecipientUpdated is a free log retrieval operation binding the contract event 0xaaebcf1bfa00580e41d966056b48521fa9f202645c86d4ddf28113e617c1b1d3.
//
// Solidity: event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterFeeRecipientUpdated(opts *bind.FilterOpts, oldRecipient []common.Address, newRecipient []common.Address) (*MarketBaseV2FeeRecipientUpdatedIterator, error) {

	var oldRecipientRule []interface{}
	for _, oldRecipientItem := range oldRecipient {
		oldRecipientRule = append(oldRecipientRule, oldRecipientItem)
	}
	var newRecipientRule []interface{}
	for _, newRecipientItem := range newRecipient {
		newRecipientRule = append(newRecipientRule, newRecipientItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "FeeRecipientUpdated", oldRecipientRule, newRecipientRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2FeeRecipientUpdatedIterator{contract: _MarketBaseV2.contract, event: "FeeRecipientUpdated", logs: logs, sub: sub}, nil
}

// WatchFeeRecipientUpdated is a free log subscription operation binding the contract event 0xaaebcf1bfa00580e41d966056b48521fa9f202645c86d4ddf28113e617c1b1d3.
//
// Solidity: event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchFeeRecipientUpdated(opts *bind.WatchOpts, sink chan<- *MarketBaseV2FeeRecipientUpdated, oldRecipient []common.Address, newRecipient []common.Address) (event.Subscription, error) {

	var oldRecipientRule []interface{}
	for _, oldRecipientItem := range oldRecipient {
		oldRecipientRule = append(oldRecipientRule, oldRecipientItem)
	}
	var newRecipientRule []interface{}
	for _, newRecipientItem := range newRecipient {
		newRecipientRule = append(newRecipientRule, newRecipientItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "FeeRecipientUpdated", oldRecipientRule, newRecipientRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2FeeRecipientUpdated)
				if err := _MarketBaseV2.contract.UnpackLog(event, "FeeRecipientUpdated", log); err != nil {
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

// ParseFeeRecipientUpdated is a log parse operation binding the contract event 0xaaebcf1bfa00580e41d966056b48521fa9f202645c86d4ddf28113e617c1b1d3.
//
// Solidity: event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseFeeRecipientUpdated(log types.Log) (*MarketBaseV2FeeRecipientUpdated, error) {
	event := new(MarketBaseV2FeeRecipientUpdated)
	if err := _MarketBaseV2.contract.UnpackLog(event, "FeeRecipientUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2FinalizedIterator is returned from FilterFinalized and is used to iterate over the raw logs and unpacked data for Finalized events raised by the MarketBaseV2 contract.
type MarketBaseV2FinalizedIterator struct {
	Event *MarketBaseV2Finalized // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2FinalizedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2Finalized)
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
		it.Event = new(MarketBaseV2Finalized)
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
func (it *MarketBaseV2FinalizedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2FinalizedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2Finalized represents a Finalized event raised by the MarketBaseV2 contract.
type MarketBaseV2Finalized struct {
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterFinalized is a free log retrieval operation binding the contract event 0x839cf22e1ba87ce2f5b9bbf46cf0175a09eed52febdfaac8852478e68203c763.
//
// Solidity: event Finalized(uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterFinalized(opts *bind.FilterOpts) (*MarketBaseV2FinalizedIterator, error) {

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "Finalized")
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2FinalizedIterator{contract: _MarketBaseV2.contract, event: "Finalized", logs: logs, sub: sub}, nil
}

// WatchFinalized is a free log subscription operation binding the contract event 0x839cf22e1ba87ce2f5b9bbf46cf0175a09eed52febdfaac8852478e68203c763.
//
// Solidity: event Finalized(uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchFinalized(opts *bind.WatchOpts, sink chan<- *MarketBaseV2Finalized) (event.Subscription, error) {

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "Finalized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2Finalized)
				if err := _MarketBaseV2.contract.UnpackLog(event, "Finalized", log); err != nil {
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

// ParseFinalized is a log parse operation binding the contract event 0x839cf22e1ba87ce2f5b9bbf46cf0175a09eed52febdfaac8852478e68203c763.
//
// Solidity: event Finalized(uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseFinalized(log types.Log) (*MarketBaseV2Finalized, error) {
	event := new(MarketBaseV2Finalized)
	if err := _MarketBaseV2.contract.UnpackLog(event, "Finalized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2InitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the MarketBaseV2 contract.
type MarketBaseV2InitializedIterator struct {
	Event *MarketBaseV2Initialized // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2InitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2Initialized)
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
		it.Event = new(MarketBaseV2Initialized)
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
func (it *MarketBaseV2InitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2InitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2Initialized represents a Initialized event raised by the MarketBaseV2 contract.
type MarketBaseV2Initialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterInitialized(opts *bind.FilterOpts) (*MarketBaseV2InitializedIterator, error) {

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2InitializedIterator{contract: _MarketBaseV2.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *MarketBaseV2Initialized) (event.Subscription, error) {

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2Initialized)
				if err := _MarketBaseV2.contract.UnpackLog(event, "Initialized", log); err != nil {
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
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseInitialized(log types.Log) (*MarketBaseV2Initialized, error) {
	event := new(MarketBaseV2Initialized)
	if err := _MarketBaseV2.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2KickoffTimeUpdatedIterator is returned from FilterKickoffTimeUpdated and is used to iterate over the raw logs and unpacked data for KickoffTimeUpdated events raised by the MarketBaseV2 contract.
type MarketBaseV2KickoffTimeUpdatedIterator struct {
	Event *MarketBaseV2KickoffTimeUpdated // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2KickoffTimeUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2KickoffTimeUpdated)
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
		it.Event = new(MarketBaseV2KickoffTimeUpdated)
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
func (it *MarketBaseV2KickoffTimeUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2KickoffTimeUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2KickoffTimeUpdated represents a KickoffTimeUpdated event raised by the MarketBaseV2 contract.
type MarketBaseV2KickoffTimeUpdated struct {
	OldKickoffTime *big.Int
	NewKickoffTime *big.Int
	Timestamp      *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterKickoffTimeUpdated is a free log retrieval operation binding the contract event 0x2fbb1dae33e5d2d3336775576daac32646f0591e9511022b025285e6808ed033.
//
// Solidity: event KickoffTimeUpdated(uint256 oldKickoffTime, uint256 newKickoffTime, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterKickoffTimeUpdated(opts *bind.FilterOpts) (*MarketBaseV2KickoffTimeUpdatedIterator, error) {

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "KickoffTimeUpdated")
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2KickoffTimeUpdatedIterator{contract: _MarketBaseV2.contract, event: "KickoffTimeUpdated", logs: logs, sub: sub}, nil
}

// WatchKickoffTimeUpdated is a free log subscription operation binding the contract event 0x2fbb1dae33e5d2d3336775576daac32646f0591e9511022b025285e6808ed033.
//
// Solidity: event KickoffTimeUpdated(uint256 oldKickoffTime, uint256 newKickoffTime, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchKickoffTimeUpdated(opts *bind.WatchOpts, sink chan<- *MarketBaseV2KickoffTimeUpdated) (event.Subscription, error) {

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "KickoffTimeUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2KickoffTimeUpdated)
				if err := _MarketBaseV2.contract.UnpackLog(event, "KickoffTimeUpdated", log); err != nil {
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

// ParseKickoffTimeUpdated is a log parse operation binding the contract event 0x2fbb1dae33e5d2d3336775576daac32646f0591e9511022b025285e6808ed033.
//
// Solidity: event KickoffTimeUpdated(uint256 oldKickoffTime, uint256 newKickoffTime, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseKickoffTimeUpdated(log types.Log) (*MarketBaseV2KickoffTimeUpdated, error) {
	event := new(MarketBaseV2KickoffTimeUpdated)
	if err := _MarketBaseV2.contract.UnpackLog(event, "KickoffTimeUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2LiquidityAddedIterator is returned from FilterLiquidityAdded and is used to iterate over the raw logs and unpacked data for LiquidityAdded events raised by the MarketBaseV2 contract.
type MarketBaseV2LiquidityAddedIterator struct {
	Event *MarketBaseV2LiquidityAdded // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2LiquidityAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2LiquidityAdded)
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
		it.Event = new(MarketBaseV2LiquidityAdded)
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
func (it *MarketBaseV2LiquidityAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2LiquidityAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2LiquidityAdded represents a LiquidityAdded event raised by the MarketBaseV2 contract.
type MarketBaseV2LiquidityAdded struct {
	Provider    common.Address
	TotalAmount *big.Int
	Timestamp   *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterLiquidityAdded is a free log retrieval operation binding the contract event 0xac1d76749e5447b7b16f5ab61447e1bd502f3bb4807af3b28e620d1700a6ee45.
//
// Solidity: event LiquidityAdded(address indexed provider, uint256 totalAmount, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterLiquidityAdded(opts *bind.FilterOpts, provider []common.Address) (*MarketBaseV2LiquidityAddedIterator, error) {

	var providerRule []interface{}
	for _, providerItem := range provider {
		providerRule = append(providerRule, providerItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "LiquidityAdded", providerRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2LiquidityAddedIterator{contract: _MarketBaseV2.contract, event: "LiquidityAdded", logs: logs, sub: sub}, nil
}

// WatchLiquidityAdded is a free log subscription operation binding the contract event 0xac1d76749e5447b7b16f5ab61447e1bd502f3bb4807af3b28e620d1700a6ee45.
//
// Solidity: event LiquidityAdded(address indexed provider, uint256 totalAmount, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchLiquidityAdded(opts *bind.WatchOpts, sink chan<- *MarketBaseV2LiquidityAdded, provider []common.Address) (event.Subscription, error) {

	var providerRule []interface{}
	for _, providerItem := range provider {
		providerRule = append(providerRule, providerItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "LiquidityAdded", providerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2LiquidityAdded)
				if err := _MarketBaseV2.contract.UnpackLog(event, "LiquidityAdded", log); err != nil {
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

// ParseLiquidityAdded is a log parse operation binding the contract event 0xac1d76749e5447b7b16f5ab61447e1bd502f3bb4807af3b28e620d1700a6ee45.
//
// Solidity: event LiquidityAdded(address indexed provider, uint256 totalAmount, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseLiquidityAdded(log types.Log) (*MarketBaseV2LiquidityAdded, error) {
	event := new(MarketBaseV2LiquidityAdded)
	if err := _MarketBaseV2.contract.UnpackLog(event, "LiquidityAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2LiquidityBorrowedIterator is returned from FilterLiquidityBorrowed and is used to iterate over the raw logs and unpacked data for LiquidityBorrowed events raised by the MarketBaseV2 contract.
type MarketBaseV2LiquidityBorrowedIterator struct {
	Event *MarketBaseV2LiquidityBorrowed // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2LiquidityBorrowedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2LiquidityBorrowed)
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
		it.Event = new(MarketBaseV2LiquidityBorrowed)
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
func (it *MarketBaseV2LiquidityBorrowedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2LiquidityBorrowedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2LiquidityBorrowed represents a LiquidityBorrowed event raised by the MarketBaseV2 contract.
type MarketBaseV2LiquidityBorrowed struct {
	Amount    *big.Int
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterLiquidityBorrowed is a free log retrieval operation binding the contract event 0xe494fcc032d16ffb98b8f0f02abf0b4bc6b9421680ccd7bc386a5ff8224fd656.
//
// Solidity: event LiquidityBorrowed(uint256 amount, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterLiquidityBorrowed(opts *bind.FilterOpts) (*MarketBaseV2LiquidityBorrowedIterator, error) {

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "LiquidityBorrowed")
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2LiquidityBorrowedIterator{contract: _MarketBaseV2.contract, event: "LiquidityBorrowed", logs: logs, sub: sub}, nil
}

// WatchLiquidityBorrowed is a free log subscription operation binding the contract event 0xe494fcc032d16ffb98b8f0f02abf0b4bc6b9421680ccd7bc386a5ff8224fd656.
//
// Solidity: event LiquidityBorrowed(uint256 amount, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchLiquidityBorrowed(opts *bind.WatchOpts, sink chan<- *MarketBaseV2LiquidityBorrowed) (event.Subscription, error) {

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "LiquidityBorrowed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2LiquidityBorrowed)
				if err := _MarketBaseV2.contract.UnpackLog(event, "LiquidityBorrowed", log); err != nil {
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

// ParseLiquidityBorrowed is a log parse operation binding the contract event 0xe494fcc032d16ffb98b8f0f02abf0b4bc6b9421680ccd7bc386a5ff8224fd656.
//
// Solidity: event LiquidityBorrowed(uint256 amount, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseLiquidityBorrowed(log types.Log) (*MarketBaseV2LiquidityBorrowed, error) {
	event := new(MarketBaseV2LiquidityBorrowed)
	if err := _MarketBaseV2.contract.UnpackLog(event, "LiquidityBorrowed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2LiquidityRepaidIterator is returned from FilterLiquidityRepaid and is used to iterate over the raw logs and unpacked data for LiquidityRepaid events raised by the MarketBaseV2 contract.
type MarketBaseV2LiquidityRepaidIterator struct {
	Event *MarketBaseV2LiquidityRepaid // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2LiquidityRepaidIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2LiquidityRepaid)
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
		it.Event = new(MarketBaseV2LiquidityRepaid)
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
func (it *MarketBaseV2LiquidityRepaidIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2LiquidityRepaidIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2LiquidityRepaid represents a LiquidityRepaid event raised by the MarketBaseV2 contract.
type MarketBaseV2LiquidityRepaid struct {
	Principal *big.Int
	Revenue   *big.Int
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterLiquidityRepaid is a free log retrieval operation binding the contract event 0x6759e2271caead8005f6c56051491412f7623bdfff2f1d316be4c6545d1d98fe.
//
// Solidity: event LiquidityRepaid(uint256 principal, uint256 revenue, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterLiquidityRepaid(opts *bind.FilterOpts) (*MarketBaseV2LiquidityRepaidIterator, error) {

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "LiquidityRepaid")
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2LiquidityRepaidIterator{contract: _MarketBaseV2.contract, event: "LiquidityRepaid", logs: logs, sub: sub}, nil
}

// WatchLiquidityRepaid is a free log subscription operation binding the contract event 0x6759e2271caead8005f6c56051491412f7623bdfff2f1d316be4c6545d1d98fe.
//
// Solidity: event LiquidityRepaid(uint256 principal, uint256 revenue, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchLiquidityRepaid(opts *bind.WatchOpts, sink chan<- *MarketBaseV2LiquidityRepaid) (event.Subscription, error) {

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "LiquidityRepaid")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2LiquidityRepaid)
				if err := _MarketBaseV2.contract.UnpackLog(event, "LiquidityRepaid", log); err != nil {
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

// ParseLiquidityRepaid is a log parse operation binding the contract event 0x6759e2271caead8005f6c56051491412f7623bdfff2f1d316be4c6545d1d98fe.
//
// Solidity: event LiquidityRepaid(uint256 principal, uint256 revenue, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseLiquidityRepaid(log types.Log) (*MarketBaseV2LiquidityRepaid, error) {
	event := new(MarketBaseV2LiquidityRepaid)
	if err := _MarketBaseV2.contract.UnpackLog(event, "LiquidityRepaid", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2LockedIterator is returned from FilterLocked and is used to iterate over the raw logs and unpacked data for Locked events raised by the MarketBaseV2 contract.
type MarketBaseV2LockedIterator struct {
	Event *MarketBaseV2Locked // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2LockedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2Locked)
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
		it.Event = new(MarketBaseV2Locked)
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
func (it *MarketBaseV2LockedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2LockedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2Locked represents a Locked event raised by the MarketBaseV2 contract.
type MarketBaseV2Locked struct {
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterLocked is a free log retrieval operation binding the contract event 0x032bc66be43dbccb7487781d168eb7bda224628a3b2c3388bdf69b532a3a1611.
//
// Solidity: event Locked(uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterLocked(opts *bind.FilterOpts) (*MarketBaseV2LockedIterator, error) {

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "Locked")
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2LockedIterator{contract: _MarketBaseV2.contract, event: "Locked", logs: logs, sub: sub}, nil
}

// WatchLocked is a free log subscription operation binding the contract event 0x032bc66be43dbccb7487781d168eb7bda224628a3b2c3388bdf69b532a3a1611.
//
// Solidity: event Locked(uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchLocked(opts *bind.WatchOpts, sink chan<- *MarketBaseV2Locked) (event.Subscription, error) {

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "Locked")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2Locked)
				if err := _MarketBaseV2.contract.UnpackLog(event, "Locked", log); err != nil {
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

// ParseLocked is a log parse operation binding the contract event 0x032bc66be43dbccb7487781d168eb7bda224628a3b2c3388bdf69b532a3a1611.
//
// Solidity: event Locked(uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseLocked(log types.Log) (*MarketBaseV2Locked, error) {
	event := new(MarketBaseV2Locked)
	if err := _MarketBaseV2.contract.UnpackLog(event, "Locked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2OwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the MarketBaseV2 contract.
type MarketBaseV2OwnershipTransferredIterator struct {
	Event *MarketBaseV2OwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2OwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2OwnershipTransferred)
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
		it.Event = new(MarketBaseV2OwnershipTransferred)
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
func (it *MarketBaseV2OwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2OwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2OwnershipTransferred represents a OwnershipTransferred event raised by the MarketBaseV2 contract.
type MarketBaseV2OwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*MarketBaseV2OwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2OwnershipTransferredIterator{contract: _MarketBaseV2.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *MarketBaseV2OwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2OwnershipTransferred)
				if err := _MarketBaseV2.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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

// ParseOwnershipTransferred is a log parse operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseOwnershipTransferred(log types.Log) (*MarketBaseV2OwnershipTransferred, error) {
	event := new(MarketBaseV2OwnershipTransferred)
	if err := _MarketBaseV2.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2PausedIterator is returned from FilterPaused and is used to iterate over the raw logs and unpacked data for Paused events raised by the MarketBaseV2 contract.
type MarketBaseV2PausedIterator struct {
	Event *MarketBaseV2Paused // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2PausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2Paused)
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
		it.Event = new(MarketBaseV2Paused)
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
func (it *MarketBaseV2PausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2PausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2Paused represents a Paused event raised by the MarketBaseV2 contract.
type MarketBaseV2Paused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterPaused is a free log retrieval operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterPaused(opts *bind.FilterOpts) (*MarketBaseV2PausedIterator, error) {

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2PausedIterator{contract: _MarketBaseV2.contract, event: "Paused", logs: logs, sub: sub}, nil
}

// WatchPaused is a free log subscription operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchPaused(opts *bind.WatchOpts, sink chan<- *MarketBaseV2Paused) (event.Subscription, error) {

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2Paused)
				if err := _MarketBaseV2.contract.UnpackLog(event, "Paused", log); err != nil {
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
func (_MarketBaseV2 *MarketBaseV2Filterer) ParsePaused(log types.Log) (*MarketBaseV2Paused, error) {
	event := new(MarketBaseV2Paused)
	if err := _MarketBaseV2.contract.UnpackLog(event, "Paused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2RedeemedIterator is returned from FilterRedeemed and is used to iterate over the raw logs and unpacked data for Redeemed events raised by the MarketBaseV2 contract.
type MarketBaseV2RedeemedIterator struct {
	Event *MarketBaseV2Redeemed // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2RedeemedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2Redeemed)
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
		it.Event = new(MarketBaseV2Redeemed)
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
func (it *MarketBaseV2RedeemedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2RedeemedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2Redeemed represents a Redeemed event raised by the MarketBaseV2 contract.
type MarketBaseV2Redeemed struct {
	User      common.Address
	OutcomeId *big.Int
	Shares    *big.Int
	Payout    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterRedeemed is a free log retrieval operation binding the contract event 0x484c40561359f3e3b8be9101897f8680aa82fbe1df9fd9038e0dbc6284032646.
//
// Solidity: event Redeemed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterRedeemed(opts *bind.FilterOpts, user []common.Address, outcomeId []*big.Int) (*MarketBaseV2RedeemedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "Redeemed", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2RedeemedIterator{contract: _MarketBaseV2.contract, event: "Redeemed", logs: logs, sub: sub}, nil
}

// WatchRedeemed is a free log subscription operation binding the contract event 0x484c40561359f3e3b8be9101897f8680aa82fbe1df9fd9038e0dbc6284032646.
//
// Solidity: event Redeemed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchRedeemed(opts *bind.WatchOpts, sink chan<- *MarketBaseV2Redeemed, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "Redeemed", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2Redeemed)
				if err := _MarketBaseV2.contract.UnpackLog(event, "Redeemed", log); err != nil {
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

// ParseRedeemed is a log parse operation binding the contract event 0x484c40561359f3e3b8be9101897f8680aa82fbe1df9fd9038e0dbc6284032646.
//
// Solidity: event Redeemed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseRedeemed(log types.Log) (*MarketBaseV2Redeemed, error) {
	event := new(MarketBaseV2Redeemed)
	if err := _MarketBaseV2.contract.UnpackLog(event, "Redeemed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2ResolvedIterator is returned from FilterResolved and is used to iterate over the raw logs and unpacked data for Resolved events raised by the MarketBaseV2 contract.
type MarketBaseV2ResolvedIterator struct {
	Event *MarketBaseV2Resolved // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2ResolvedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2Resolved)
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
		it.Event = new(MarketBaseV2Resolved)
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
func (it *MarketBaseV2ResolvedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2ResolvedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2Resolved represents a Resolved event raised by the MarketBaseV2 contract.
type MarketBaseV2Resolved struct {
	WinningOutcome *big.Int
	Timestamp      *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterResolved is a free log retrieval operation binding the contract event 0x8a1cc9089f9efc6450ff2639ff6d6b27f6aaaac01cccae1789c0a36dffc21041.
//
// Solidity: event Resolved(uint256 indexed winningOutcome, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterResolved(opts *bind.FilterOpts, winningOutcome []*big.Int) (*MarketBaseV2ResolvedIterator, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "Resolved", winningOutcomeRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2ResolvedIterator{contract: _MarketBaseV2.contract, event: "Resolved", logs: logs, sub: sub}, nil
}

// WatchResolved is a free log subscription operation binding the contract event 0x8a1cc9089f9efc6450ff2639ff6d6b27f6aaaac01cccae1789c0a36dffc21041.
//
// Solidity: event Resolved(uint256 indexed winningOutcome, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchResolved(opts *bind.WatchOpts, sink chan<- *MarketBaseV2Resolved, winningOutcome []*big.Int) (event.Subscription, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "Resolved", winningOutcomeRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2Resolved)
				if err := _MarketBaseV2.contract.UnpackLog(event, "Resolved", log); err != nil {
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

// ParseResolved is a log parse operation binding the contract event 0x8a1cc9089f9efc6450ff2639ff6d6b27f6aaaac01cccae1789c0a36dffc21041.
//
// Solidity: event Resolved(uint256 indexed winningOutcome, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseResolved(log types.Log) (*MarketBaseV2Resolved, error) {
	event := new(MarketBaseV2Resolved)
	if err := _MarketBaseV2.contract.UnpackLog(event, "Resolved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2ResolvedWithOracleIterator is returned from FilterResolvedWithOracle and is used to iterate over the raw logs and unpacked data for ResolvedWithOracle events raised by the MarketBaseV2 contract.
type MarketBaseV2ResolvedWithOracleIterator struct {
	Event *MarketBaseV2ResolvedWithOracle // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2ResolvedWithOracleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2ResolvedWithOracle)
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
		it.Event = new(MarketBaseV2ResolvedWithOracle)
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
func (it *MarketBaseV2ResolvedWithOracleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2ResolvedWithOracleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2ResolvedWithOracle represents a ResolvedWithOracle event raised by the MarketBaseV2 contract.
type MarketBaseV2ResolvedWithOracle struct {
	WinningOutcome *big.Int
	ResultHash     [32]byte
	Timestamp      *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterResolvedWithOracle is a free log retrieval operation binding the contract event 0x483e2cc22780ed0b10a1da294bc4acc4d4b81340fdebab99bb0a346644b020b3.
//
// Solidity: event ResolvedWithOracle(uint256 indexed winningOutcome, bytes32 indexed resultHash, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterResolvedWithOracle(opts *bind.FilterOpts, winningOutcome []*big.Int, resultHash [][32]byte) (*MarketBaseV2ResolvedWithOracleIterator, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}
	var resultHashRule []interface{}
	for _, resultHashItem := range resultHash {
		resultHashRule = append(resultHashRule, resultHashItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "ResolvedWithOracle", winningOutcomeRule, resultHashRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2ResolvedWithOracleIterator{contract: _MarketBaseV2.contract, event: "ResolvedWithOracle", logs: logs, sub: sub}, nil
}

// WatchResolvedWithOracle is a free log subscription operation binding the contract event 0x483e2cc22780ed0b10a1da294bc4acc4d4b81340fdebab99bb0a346644b020b3.
//
// Solidity: event ResolvedWithOracle(uint256 indexed winningOutcome, bytes32 indexed resultHash, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchResolvedWithOracle(opts *bind.WatchOpts, sink chan<- *MarketBaseV2ResolvedWithOracle, winningOutcome []*big.Int, resultHash [][32]byte) (event.Subscription, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}
	var resultHashRule []interface{}
	for _, resultHashItem := range resultHash {
		resultHashRule = append(resultHashRule, resultHashItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "ResolvedWithOracle", winningOutcomeRule, resultHashRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2ResolvedWithOracle)
				if err := _MarketBaseV2.contract.UnpackLog(event, "ResolvedWithOracle", log); err != nil {
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

// ParseResolvedWithOracle is a log parse operation binding the contract event 0x483e2cc22780ed0b10a1da294bc4acc4d4b81340fdebab99bb0a346644b020b3.
//
// Solidity: event ResolvedWithOracle(uint256 indexed winningOutcome, bytes32 indexed resultHash, uint256 timestamp)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseResolvedWithOracle(log types.Log) (*MarketBaseV2ResolvedWithOracle, error) {
	event := new(MarketBaseV2ResolvedWithOracle)
	if err := _MarketBaseV2.contract.UnpackLog(event, "ResolvedWithOracle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2ResultOracleUpdatedIterator is returned from FilterResultOracleUpdated and is used to iterate over the raw logs and unpacked data for ResultOracleUpdated events raised by the MarketBaseV2 contract.
type MarketBaseV2ResultOracleUpdatedIterator struct {
	Event *MarketBaseV2ResultOracleUpdated // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2ResultOracleUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2ResultOracleUpdated)
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
		it.Event = new(MarketBaseV2ResultOracleUpdated)
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
func (it *MarketBaseV2ResultOracleUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2ResultOracleUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2ResultOracleUpdated represents a ResultOracleUpdated event raised by the MarketBaseV2 contract.
type MarketBaseV2ResultOracleUpdated struct {
	NewOracle common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterResultOracleUpdated is a free log retrieval operation binding the contract event 0xf4f6d8a1c53b96aaa54cac2192218b21030f6371f0b3e3a0fb15124fa1f08e8d.
//
// Solidity: event ResultOracleUpdated(address indexed newOracle)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterResultOracleUpdated(opts *bind.FilterOpts, newOracle []common.Address) (*MarketBaseV2ResultOracleUpdatedIterator, error) {

	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "ResultOracleUpdated", newOracleRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2ResultOracleUpdatedIterator{contract: _MarketBaseV2.contract, event: "ResultOracleUpdated", logs: logs, sub: sub}, nil
}

// WatchResultOracleUpdated is a free log subscription operation binding the contract event 0xf4f6d8a1c53b96aaa54cac2192218b21030f6371f0b3e3a0fb15124fa1f08e8d.
//
// Solidity: event ResultOracleUpdated(address indexed newOracle)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchResultOracleUpdated(opts *bind.WatchOpts, sink chan<- *MarketBaseV2ResultOracleUpdated, newOracle []common.Address) (event.Subscription, error) {

	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "ResultOracleUpdated", newOracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2ResultOracleUpdated)
				if err := _MarketBaseV2.contract.UnpackLog(event, "ResultOracleUpdated", log); err != nil {
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

// ParseResultOracleUpdated is a log parse operation binding the contract event 0xf4f6d8a1c53b96aaa54cac2192218b21030f6371f0b3e3a0fb15124fa1f08e8d.
//
// Solidity: event ResultOracleUpdated(address indexed newOracle)
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseResultOracleUpdated(log types.Log) (*MarketBaseV2ResultOracleUpdated, error) {
	event := new(MarketBaseV2ResultOracleUpdated)
	if err := _MarketBaseV2.contract.UnpackLog(event, "ResultOracleUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2TransferBatchIterator is returned from FilterTransferBatch and is used to iterate over the raw logs and unpacked data for TransferBatch events raised by the MarketBaseV2 contract.
type MarketBaseV2TransferBatchIterator struct {
	Event *MarketBaseV2TransferBatch // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2TransferBatchIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2TransferBatch)
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
		it.Event = new(MarketBaseV2TransferBatch)
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
func (it *MarketBaseV2TransferBatchIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2TransferBatchIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2TransferBatch represents a TransferBatch event raised by the MarketBaseV2 contract.
type MarketBaseV2TransferBatch struct {
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
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterTransferBatch(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*MarketBaseV2TransferBatchIterator, error) {

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

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2TransferBatchIterator{contract: _MarketBaseV2.contract, event: "TransferBatch", logs: logs, sub: sub}, nil
}

// WatchTransferBatch is a free log subscription operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchTransferBatch(opts *bind.WatchOpts, sink chan<- *MarketBaseV2TransferBatch, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2TransferBatch)
				if err := _MarketBaseV2.contract.UnpackLog(event, "TransferBatch", log); err != nil {
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
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseTransferBatch(log types.Log) (*MarketBaseV2TransferBatch, error) {
	event := new(MarketBaseV2TransferBatch)
	if err := _MarketBaseV2.contract.UnpackLog(event, "TransferBatch", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2TransferSingleIterator is returned from FilterTransferSingle and is used to iterate over the raw logs and unpacked data for TransferSingle events raised by the MarketBaseV2 contract.
type MarketBaseV2TransferSingleIterator struct {
	Event *MarketBaseV2TransferSingle // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2TransferSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2TransferSingle)
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
		it.Event = new(MarketBaseV2TransferSingle)
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
func (it *MarketBaseV2TransferSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2TransferSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2TransferSingle represents a TransferSingle event raised by the MarketBaseV2 contract.
type MarketBaseV2TransferSingle struct {
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
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterTransferSingle(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*MarketBaseV2TransferSingleIterator, error) {

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

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2TransferSingleIterator{contract: _MarketBaseV2.contract, event: "TransferSingle", logs: logs, sub: sub}, nil
}

// WatchTransferSingle is a free log subscription operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchTransferSingle(opts *bind.WatchOpts, sink chan<- *MarketBaseV2TransferSingle, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2TransferSingle)
				if err := _MarketBaseV2.contract.UnpackLog(event, "TransferSingle", log); err != nil {
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
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseTransferSingle(log types.Log) (*MarketBaseV2TransferSingle, error) {
	event := new(MarketBaseV2TransferSingle)
	if err := _MarketBaseV2.contract.UnpackLog(event, "TransferSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2URIIterator is returned from FilterURI and is used to iterate over the raw logs and unpacked data for URI events raised by the MarketBaseV2 contract.
type MarketBaseV2URIIterator struct {
	Event *MarketBaseV2URI // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2URIIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2URI)
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
		it.Event = new(MarketBaseV2URI)
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
func (it *MarketBaseV2URIIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2URIIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2URI represents a URI event raised by the MarketBaseV2 contract.
type MarketBaseV2URI struct {
	Value string
	Id    *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterURI is a free log retrieval operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterURI(opts *bind.FilterOpts, id []*big.Int) (*MarketBaseV2URIIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2URIIterator{contract: _MarketBaseV2.contract, event: "URI", logs: logs, sub: sub}, nil
}

// WatchURI is a free log subscription operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchURI(opts *bind.WatchOpts, sink chan<- *MarketBaseV2URI, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2URI)
				if err := _MarketBaseV2.contract.UnpackLog(event, "URI", log); err != nil {
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
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseURI(log types.Log) (*MarketBaseV2URI, error) {
	event := new(MarketBaseV2URI)
	if err := _MarketBaseV2.contract.UnpackLog(event, "URI", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseV2UnpausedIterator is returned from FilterUnpaused and is used to iterate over the raw logs and unpacked data for Unpaused events raised by the MarketBaseV2 contract.
type MarketBaseV2UnpausedIterator struct {
	Event *MarketBaseV2Unpaused // Event containing the contract specifics and raw log

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
func (it *MarketBaseV2UnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseV2Unpaused)
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
		it.Event = new(MarketBaseV2Unpaused)
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
func (it *MarketBaseV2UnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseV2UnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseV2Unpaused represents a Unpaused event raised by the MarketBaseV2 contract.
type MarketBaseV2Unpaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUnpaused is a free log retrieval operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_MarketBaseV2 *MarketBaseV2Filterer) FilterUnpaused(opts *bind.FilterOpts) (*MarketBaseV2UnpausedIterator, error) {

	logs, sub, err := _MarketBaseV2.contract.FilterLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return &MarketBaseV2UnpausedIterator{contract: _MarketBaseV2.contract, event: "Unpaused", logs: logs, sub: sub}, nil
}

// WatchUnpaused is a free log subscription operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_MarketBaseV2 *MarketBaseV2Filterer) WatchUnpaused(opts *bind.WatchOpts, sink chan<- *MarketBaseV2Unpaused) (event.Subscription, error) {

	logs, sub, err := _MarketBaseV2.contract.WatchLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseV2Unpaused)
				if err := _MarketBaseV2.contract.UnpackLog(event, "Unpaused", log); err != nil {
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
func (_MarketBaseV2 *MarketBaseV2Filterer) ParseUnpaused(log types.Log) (*MarketBaseV2Unpaused, error) {
	event := new(MarketBaseV2Unpaused)
	if err := _MarketBaseV2.contract.UnpackLog(event, "Unpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
