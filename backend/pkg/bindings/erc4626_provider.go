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

// ERC4626LiquidityProviderMetaData contains all meta data concerning the ERC4626LiquidityProvider contract.
var ERC4626LiquidityProviderMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_asset\",\"type\":\"address\",\"internalType\":\"contractIERC20\"},{\"name\":\"_name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"_symbol\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"MAX_MARKET_BORROW_BPS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MAX_UTILIZATION_BPS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"allowance\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"approve\",\"inputs\":[{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"asset\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"authorizeMarket\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"authorizedMarkets\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"availableLiquidity\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"borrow\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"borrowed\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"convertToAssets\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"convertToShares\",\"inputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"decimals\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deposit\",\"inputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"emergencyWithdraw\",\"inputs\":[{\"name\":\"recipient\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAuthorizedMarkets\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCurrentYield\",\"inputs\":[{\"name\":\"lp\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMarketBorrowInfo\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isAuthorizedMarket\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"markets\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxDeposit\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxMint\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxRedeem\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"maxWithdraw\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"mint\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"name\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewDeposit\",\"inputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewMint\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewRedeem\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewWithdraw\",\"inputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"providerType\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"redeem\",\"inputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"repay\",\"inputs\":[{\"name\":\"principal\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"revenue\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeMarket\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"symbol\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalAssets\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalBorrowed\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalLiquidity\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalRevenueAccumulated\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalSupply\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transfer\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"utilizationRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdraw\",\"inputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"Approval\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"spender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Deposit\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"EmergencyWithdrawal\",\"inputs\":[{\"name\":\"admin\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"recipient\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"LiquidityBorrowed\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"LiquidityRepaid\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"principal\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"revenue\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketAuthorizationChanged\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"authorized\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RevenueDistributed\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"totalAssets\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"totalShares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Transfer\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Withdraw\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ERC20InsufficientAllowance\",\"inputs\":[{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"allowance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC20InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC20InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC20InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC20InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC20InvalidSpender\",\"inputs\":[{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC4626ExceededMaxDeposit\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"max\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC4626ExceededMaxMint\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"max\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC4626ExceededMaxRedeem\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"max\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC4626ExceededMaxWithdraw\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"max\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExceedsMarketBorrowLimit\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"requested\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"limit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ExceedsUtilizationLimit\",\"inputs\":[{\"name\":\"requested\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"available\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InsufficientBorrowBalance\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"InsufficientLiquidity\",\"inputs\":[{\"name\":\"requested\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"available\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"NoRevenueToDistribute\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"UnauthorizedMarket\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// ERC4626LiquidityProviderABI is the input ABI used to generate the binding from.
// Deprecated: Use ERC4626LiquidityProviderMetaData.ABI instead.
var ERC4626LiquidityProviderABI = ERC4626LiquidityProviderMetaData.ABI

// ERC4626LiquidityProvider is an auto generated Go binding around an Ethereum contract.
type ERC4626LiquidityProvider struct {
	ERC4626LiquidityProviderCaller     // Read-only binding to the contract
	ERC4626LiquidityProviderTransactor // Write-only binding to the contract
	ERC4626LiquidityProviderFilterer   // Log filterer for contract events
}

// ERC4626LiquidityProviderCaller is an auto generated read-only Go binding around an Ethereum contract.
type ERC4626LiquidityProviderCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ERC4626LiquidityProviderTransactor is an auto generated write-only Go binding around an Ethereum contract.
type ERC4626LiquidityProviderTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ERC4626LiquidityProviderFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type ERC4626LiquidityProviderFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ERC4626LiquidityProviderSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type ERC4626LiquidityProviderSession struct {
	Contract     *ERC4626LiquidityProvider // Generic contract binding to set the session for
	CallOpts     bind.CallOpts             // Call options to use throughout this session
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// ERC4626LiquidityProviderCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type ERC4626LiquidityProviderCallerSession struct {
	Contract *ERC4626LiquidityProviderCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts                   // Call options to use throughout this session
}

// ERC4626LiquidityProviderTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type ERC4626LiquidityProviderTransactorSession struct {
	Contract     *ERC4626LiquidityProviderTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts                   // Transaction auth options to use throughout this session
}

// ERC4626LiquidityProviderRaw is an auto generated low-level Go binding around an Ethereum contract.
type ERC4626LiquidityProviderRaw struct {
	Contract *ERC4626LiquidityProvider // Generic contract binding to access the raw methods on
}

// ERC4626LiquidityProviderCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type ERC4626LiquidityProviderCallerRaw struct {
	Contract *ERC4626LiquidityProviderCaller // Generic read-only contract binding to access the raw methods on
}

// ERC4626LiquidityProviderTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type ERC4626LiquidityProviderTransactorRaw struct {
	Contract *ERC4626LiquidityProviderTransactor // Generic write-only contract binding to access the raw methods on
}

// NewERC4626LiquidityProvider creates a new instance of ERC4626LiquidityProvider, bound to a specific deployed contract.
func NewERC4626LiquidityProvider(address common.Address, backend bind.ContractBackend) (*ERC4626LiquidityProvider, error) {
	contract, err := bindERC4626LiquidityProvider(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProvider{ERC4626LiquidityProviderCaller: ERC4626LiquidityProviderCaller{contract: contract}, ERC4626LiquidityProviderTransactor: ERC4626LiquidityProviderTransactor{contract: contract}, ERC4626LiquidityProviderFilterer: ERC4626LiquidityProviderFilterer{contract: contract}}, nil
}

// NewERC4626LiquidityProviderCaller creates a new read-only instance of ERC4626LiquidityProvider, bound to a specific deployed contract.
func NewERC4626LiquidityProviderCaller(address common.Address, caller bind.ContractCaller) (*ERC4626LiquidityProviderCaller, error) {
	contract, err := bindERC4626LiquidityProvider(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderCaller{contract: contract}, nil
}

// NewERC4626LiquidityProviderTransactor creates a new write-only instance of ERC4626LiquidityProvider, bound to a specific deployed contract.
func NewERC4626LiquidityProviderTransactor(address common.Address, transactor bind.ContractTransactor) (*ERC4626LiquidityProviderTransactor, error) {
	contract, err := bindERC4626LiquidityProvider(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderTransactor{contract: contract}, nil
}

// NewERC4626LiquidityProviderFilterer creates a new log filterer instance of ERC4626LiquidityProvider, bound to a specific deployed contract.
func NewERC4626LiquidityProviderFilterer(address common.Address, filterer bind.ContractFilterer) (*ERC4626LiquidityProviderFilterer, error) {
	contract, err := bindERC4626LiquidityProvider(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderFilterer{contract: contract}, nil
}

// bindERC4626LiquidityProvider binds a generic wrapper to an already deployed contract.
func bindERC4626LiquidityProvider(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := ERC4626LiquidityProviderMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ERC4626LiquidityProvider.Contract.ERC4626LiquidityProviderCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.ERC4626LiquidityProviderTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.ERC4626LiquidityProviderTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ERC4626LiquidityProvider.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.contract.Transact(opts, method, params...)
}

// MAXMARKETBORROWBPS is a free data retrieval call binding the contract method 0xbba8f828.
//
// Solidity: function MAX_MARKET_BORROW_BPS() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) MAXMARKETBORROWBPS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "MAX_MARKET_BORROW_BPS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXMARKETBORROWBPS is a free data retrieval call binding the contract method 0xbba8f828.
//
// Solidity: function MAX_MARKET_BORROW_BPS() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) MAXMARKETBORROWBPS() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MAXMARKETBORROWBPS(&_ERC4626LiquidityProvider.CallOpts)
}

// MAXMARKETBORROWBPS is a free data retrieval call binding the contract method 0xbba8f828.
//
// Solidity: function MAX_MARKET_BORROW_BPS() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) MAXMARKETBORROWBPS() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MAXMARKETBORROWBPS(&_ERC4626LiquidityProvider.CallOpts)
}

// MAXUTILIZATIONBPS is a free data retrieval call binding the contract method 0xe05fee4a.
//
// Solidity: function MAX_UTILIZATION_BPS() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) MAXUTILIZATIONBPS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "MAX_UTILIZATION_BPS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXUTILIZATIONBPS is a free data retrieval call binding the contract method 0xe05fee4a.
//
// Solidity: function MAX_UTILIZATION_BPS() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) MAXUTILIZATIONBPS() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MAXUTILIZATIONBPS(&_ERC4626LiquidityProvider.CallOpts)
}

// MAXUTILIZATIONBPS is a free data retrieval call binding the contract method 0xe05fee4a.
//
// Solidity: function MAX_UTILIZATION_BPS() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) MAXUTILIZATIONBPS() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MAXUTILIZATIONBPS(&_ERC4626LiquidityProvider.CallOpts)
}

// Allowance is a free data retrieval call binding the contract method 0xdd62ed3e.
//
// Solidity: function allowance(address owner, address spender) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) Allowance(opts *bind.CallOpts, owner common.Address, spender common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "allowance", owner, spender)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Allowance is a free data retrieval call binding the contract method 0xdd62ed3e.
//
// Solidity: function allowance(address owner, address spender) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Allowance(owner common.Address, spender common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.Allowance(&_ERC4626LiquidityProvider.CallOpts, owner, spender)
}

// Allowance is a free data retrieval call binding the contract method 0xdd62ed3e.
//
// Solidity: function allowance(address owner, address spender) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) Allowance(owner common.Address, spender common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.Allowance(&_ERC4626LiquidityProvider.CallOpts, owner, spender)
}

// Asset is a free data retrieval call binding the contract method 0x38d52e0f.
//
// Solidity: function asset() view returns(address)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) Asset(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "asset")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Asset is a free data retrieval call binding the contract method 0x38d52e0f.
//
// Solidity: function asset() view returns(address)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Asset() (common.Address, error) {
	return _ERC4626LiquidityProvider.Contract.Asset(&_ERC4626LiquidityProvider.CallOpts)
}

// Asset is a free data retrieval call binding the contract method 0x38d52e0f.
//
// Solidity: function asset() view returns(address)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) Asset() (common.Address, error) {
	return _ERC4626LiquidityProvider.Contract.Asset(&_ERC4626LiquidityProvider.CallOpts)
}

// AuthorizedMarkets is a free data retrieval call binding the contract method 0x4299b8a2.
//
// Solidity: function authorizedMarkets(address ) view returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) AuthorizedMarkets(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "authorizedMarkets", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AuthorizedMarkets is a free data retrieval call binding the contract method 0x4299b8a2.
//
// Solidity: function authorizedMarkets(address ) view returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) AuthorizedMarkets(arg0 common.Address) (bool, error) {
	return _ERC4626LiquidityProvider.Contract.AuthorizedMarkets(&_ERC4626LiquidityProvider.CallOpts, arg0)
}

// AuthorizedMarkets is a free data retrieval call binding the contract method 0x4299b8a2.
//
// Solidity: function authorizedMarkets(address ) view returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) AuthorizedMarkets(arg0 common.Address) (bool, error) {
	return _ERC4626LiquidityProvider.Contract.AuthorizedMarkets(&_ERC4626LiquidityProvider.CallOpts, arg0)
}

// AvailableLiquidity is a free data retrieval call binding the contract method 0x74375359.
//
// Solidity: function availableLiquidity() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) AvailableLiquidity(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "availableLiquidity")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AvailableLiquidity is a free data retrieval call binding the contract method 0x74375359.
//
// Solidity: function availableLiquidity() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) AvailableLiquidity() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.AvailableLiquidity(&_ERC4626LiquidityProvider.CallOpts)
}

// AvailableLiquidity is a free data retrieval call binding the contract method 0x74375359.
//
// Solidity: function availableLiquidity() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) AvailableLiquidity() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.AvailableLiquidity(&_ERC4626LiquidityProvider.CallOpts)
}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address account) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) BalanceOf(opts *bind.CallOpts, account common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "balanceOf", account)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address account) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) BalanceOf(account common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.BalanceOf(&_ERC4626LiquidityProvider.CallOpts, account)
}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address account) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) BalanceOf(account common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.BalanceOf(&_ERC4626LiquidityProvider.CallOpts, account)
}

// Borrowed is a free data retrieval call binding the contract method 0x0941cb3d.
//
// Solidity: function borrowed(address ) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) Borrowed(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "borrowed", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Borrowed is a free data retrieval call binding the contract method 0x0941cb3d.
//
// Solidity: function borrowed(address ) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Borrowed(arg0 common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.Borrowed(&_ERC4626LiquidityProvider.CallOpts, arg0)
}

// Borrowed is a free data retrieval call binding the contract method 0x0941cb3d.
//
// Solidity: function borrowed(address ) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) Borrowed(arg0 common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.Borrowed(&_ERC4626LiquidityProvider.CallOpts, arg0)
}

// ConvertToAssets is a free data retrieval call binding the contract method 0x07a2d13a.
//
// Solidity: function convertToAssets(uint256 shares) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) ConvertToAssets(opts *bind.CallOpts, shares *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "convertToAssets", shares)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ConvertToAssets is a free data retrieval call binding the contract method 0x07a2d13a.
//
// Solidity: function convertToAssets(uint256 shares) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) ConvertToAssets(shares *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.ConvertToAssets(&_ERC4626LiquidityProvider.CallOpts, shares)
}

// ConvertToAssets is a free data retrieval call binding the contract method 0x07a2d13a.
//
// Solidity: function convertToAssets(uint256 shares) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) ConvertToAssets(shares *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.ConvertToAssets(&_ERC4626LiquidityProvider.CallOpts, shares)
}

// ConvertToShares is a free data retrieval call binding the contract method 0xc6e6f592.
//
// Solidity: function convertToShares(uint256 assets) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) ConvertToShares(opts *bind.CallOpts, assets *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "convertToShares", assets)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ConvertToShares is a free data retrieval call binding the contract method 0xc6e6f592.
//
// Solidity: function convertToShares(uint256 assets) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) ConvertToShares(assets *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.ConvertToShares(&_ERC4626LiquidityProvider.CallOpts, assets)
}

// ConvertToShares is a free data retrieval call binding the contract method 0xc6e6f592.
//
// Solidity: function convertToShares(uint256 assets) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) ConvertToShares(assets *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.ConvertToShares(&_ERC4626LiquidityProvider.CallOpts, assets)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) Decimals(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "decimals")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Decimals() (uint8, error) {
	return _ERC4626LiquidityProvider.Contract.Decimals(&_ERC4626LiquidityProvider.CallOpts)
}

// Decimals is a free data retrieval call binding the contract method 0x313ce567.
//
// Solidity: function decimals() view returns(uint8)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) Decimals() (uint8, error) {
	return _ERC4626LiquidityProvider.Contract.Decimals(&_ERC4626LiquidityProvider.CallOpts)
}

// GetAuthorizedMarkets is a free data retrieval call binding the contract method 0x7b803f84.
//
// Solidity: function getAuthorizedMarkets() view returns(address[])
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) GetAuthorizedMarkets(opts *bind.CallOpts) ([]common.Address, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "getAuthorizedMarkets")

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetAuthorizedMarkets is a free data retrieval call binding the contract method 0x7b803f84.
//
// Solidity: function getAuthorizedMarkets() view returns(address[])
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) GetAuthorizedMarkets() ([]common.Address, error) {
	return _ERC4626LiquidityProvider.Contract.GetAuthorizedMarkets(&_ERC4626LiquidityProvider.CallOpts)
}

// GetAuthorizedMarkets is a free data retrieval call binding the contract method 0x7b803f84.
//
// Solidity: function getAuthorizedMarkets() view returns(address[])
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) GetAuthorizedMarkets() ([]common.Address, error) {
	return _ERC4626LiquidityProvider.Contract.GetAuthorizedMarkets(&_ERC4626LiquidityProvider.CallOpts)
}

// GetCurrentYield is a free data retrieval call binding the contract method 0xd1edbc53.
//
// Solidity: function getCurrentYield(address lp) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) GetCurrentYield(opts *bind.CallOpts, lp common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "getCurrentYield", lp)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCurrentYield is a free data retrieval call binding the contract method 0xd1edbc53.
//
// Solidity: function getCurrentYield(address lp) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) GetCurrentYield(lp common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.GetCurrentYield(&_ERC4626LiquidityProvider.CallOpts, lp)
}

// GetCurrentYield is a free data retrieval call binding the contract method 0xd1edbc53.
//
// Solidity: function getCurrentYield(address lp) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) GetCurrentYield(lp common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.GetCurrentYield(&_ERC4626LiquidityProvider.CallOpts, lp)
}

// GetMarketBorrowInfo is a free data retrieval call binding the contract method 0x63ec6ca8.
//
// Solidity: function getMarketBorrowInfo(address market) view returns(uint256, uint256, uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) GetMarketBorrowInfo(opts *bind.CallOpts, market common.Address) (*big.Int, *big.Int, *big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "getMarketBorrowInfo", market)

	if err != nil {
		return *new(*big.Int), *new(*big.Int), *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	out1 := *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	out2 := *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)

	return out0, out1, out2, err

}

// GetMarketBorrowInfo is a free data retrieval call binding the contract method 0x63ec6ca8.
//
// Solidity: function getMarketBorrowInfo(address market) view returns(uint256, uint256, uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) GetMarketBorrowInfo(market common.Address) (*big.Int, *big.Int, *big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.GetMarketBorrowInfo(&_ERC4626LiquidityProvider.CallOpts, market)
}

// GetMarketBorrowInfo is a free data retrieval call binding the contract method 0x63ec6ca8.
//
// Solidity: function getMarketBorrowInfo(address market) view returns(uint256, uint256, uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) GetMarketBorrowInfo(market common.Address) (*big.Int, *big.Int, *big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.GetMarketBorrowInfo(&_ERC4626LiquidityProvider.CallOpts, market)
}

// IsAuthorizedMarket is a free data retrieval call binding the contract method 0x99079671.
//
// Solidity: function isAuthorizedMarket(address market) view returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) IsAuthorizedMarket(opts *bind.CallOpts, market common.Address) (bool, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "isAuthorizedMarket", market)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsAuthorizedMarket is a free data retrieval call binding the contract method 0x99079671.
//
// Solidity: function isAuthorizedMarket(address market) view returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) IsAuthorizedMarket(market common.Address) (bool, error) {
	return _ERC4626LiquidityProvider.Contract.IsAuthorizedMarket(&_ERC4626LiquidityProvider.CallOpts, market)
}

// IsAuthorizedMarket is a free data retrieval call binding the contract method 0x99079671.
//
// Solidity: function isAuthorizedMarket(address market) view returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) IsAuthorizedMarket(market common.Address) (bool, error) {
	return _ERC4626LiquidityProvider.Contract.IsAuthorizedMarket(&_ERC4626LiquidityProvider.CallOpts, market)
}

// Markets is a free data retrieval call binding the contract method 0xb1283e77.
//
// Solidity: function markets(uint256 ) view returns(address)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) Markets(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "markets", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Markets is a free data retrieval call binding the contract method 0xb1283e77.
//
// Solidity: function markets(uint256 ) view returns(address)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Markets(arg0 *big.Int) (common.Address, error) {
	return _ERC4626LiquidityProvider.Contract.Markets(&_ERC4626LiquidityProvider.CallOpts, arg0)
}

// Markets is a free data retrieval call binding the contract method 0xb1283e77.
//
// Solidity: function markets(uint256 ) view returns(address)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) Markets(arg0 *big.Int) (common.Address, error) {
	return _ERC4626LiquidityProvider.Contract.Markets(&_ERC4626LiquidityProvider.CallOpts, arg0)
}

// MaxDeposit is a free data retrieval call binding the contract method 0x402d267d.
//
// Solidity: function maxDeposit(address ) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) MaxDeposit(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "maxDeposit", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxDeposit is a free data retrieval call binding the contract method 0x402d267d.
//
// Solidity: function maxDeposit(address ) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) MaxDeposit(arg0 common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MaxDeposit(&_ERC4626LiquidityProvider.CallOpts, arg0)
}

// MaxDeposit is a free data retrieval call binding the contract method 0x402d267d.
//
// Solidity: function maxDeposit(address ) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) MaxDeposit(arg0 common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MaxDeposit(&_ERC4626LiquidityProvider.CallOpts, arg0)
}

// MaxMint is a free data retrieval call binding the contract method 0xc63d75b6.
//
// Solidity: function maxMint(address ) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) MaxMint(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "maxMint", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxMint is a free data retrieval call binding the contract method 0xc63d75b6.
//
// Solidity: function maxMint(address ) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) MaxMint(arg0 common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MaxMint(&_ERC4626LiquidityProvider.CallOpts, arg0)
}

// MaxMint is a free data retrieval call binding the contract method 0xc63d75b6.
//
// Solidity: function maxMint(address ) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) MaxMint(arg0 common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MaxMint(&_ERC4626LiquidityProvider.CallOpts, arg0)
}

// MaxRedeem is a free data retrieval call binding the contract method 0xd905777e.
//
// Solidity: function maxRedeem(address owner) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) MaxRedeem(opts *bind.CallOpts, owner common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "maxRedeem", owner)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxRedeem is a free data retrieval call binding the contract method 0xd905777e.
//
// Solidity: function maxRedeem(address owner) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) MaxRedeem(owner common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MaxRedeem(&_ERC4626LiquidityProvider.CallOpts, owner)
}

// MaxRedeem is a free data retrieval call binding the contract method 0xd905777e.
//
// Solidity: function maxRedeem(address owner) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) MaxRedeem(owner common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MaxRedeem(&_ERC4626LiquidityProvider.CallOpts, owner)
}

// MaxWithdraw is a free data retrieval call binding the contract method 0xce96cb77.
//
// Solidity: function maxWithdraw(address owner) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) MaxWithdraw(opts *bind.CallOpts, owner common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "maxWithdraw", owner)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MaxWithdraw is a free data retrieval call binding the contract method 0xce96cb77.
//
// Solidity: function maxWithdraw(address owner) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) MaxWithdraw(owner common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MaxWithdraw(&_ERC4626LiquidityProvider.CallOpts, owner)
}

// MaxWithdraw is a free data retrieval call binding the contract method 0xce96cb77.
//
// Solidity: function maxWithdraw(address owner) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) MaxWithdraw(owner common.Address) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.MaxWithdraw(&_ERC4626LiquidityProvider.CallOpts, owner)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) Name(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "name")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Name() (string, error) {
	return _ERC4626LiquidityProvider.Contract.Name(&_ERC4626LiquidityProvider.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) Name() (string, error) {
	return _ERC4626LiquidityProvider.Contract.Name(&_ERC4626LiquidityProvider.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Owner() (common.Address, error) {
	return _ERC4626LiquidityProvider.Contract.Owner(&_ERC4626LiquidityProvider.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) Owner() (common.Address, error) {
	return _ERC4626LiquidityProvider.Contract.Owner(&_ERC4626LiquidityProvider.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Paused() (bool, error) {
	return _ERC4626LiquidityProvider.Contract.Paused(&_ERC4626LiquidityProvider.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) Paused() (bool, error) {
	return _ERC4626LiquidityProvider.Contract.Paused(&_ERC4626LiquidityProvider.CallOpts)
}

// PreviewDeposit is a free data retrieval call binding the contract method 0xef8b30f7.
//
// Solidity: function previewDeposit(uint256 assets) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) PreviewDeposit(opts *bind.CallOpts, assets *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "previewDeposit", assets)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewDeposit is a free data retrieval call binding the contract method 0xef8b30f7.
//
// Solidity: function previewDeposit(uint256 assets) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) PreviewDeposit(assets *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.PreviewDeposit(&_ERC4626LiquidityProvider.CallOpts, assets)
}

// PreviewDeposit is a free data retrieval call binding the contract method 0xef8b30f7.
//
// Solidity: function previewDeposit(uint256 assets) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) PreviewDeposit(assets *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.PreviewDeposit(&_ERC4626LiquidityProvider.CallOpts, assets)
}

// PreviewMint is a free data retrieval call binding the contract method 0xb3d7f6b9.
//
// Solidity: function previewMint(uint256 shares) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) PreviewMint(opts *bind.CallOpts, shares *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "previewMint", shares)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewMint is a free data retrieval call binding the contract method 0xb3d7f6b9.
//
// Solidity: function previewMint(uint256 shares) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) PreviewMint(shares *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.PreviewMint(&_ERC4626LiquidityProvider.CallOpts, shares)
}

// PreviewMint is a free data retrieval call binding the contract method 0xb3d7f6b9.
//
// Solidity: function previewMint(uint256 shares) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) PreviewMint(shares *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.PreviewMint(&_ERC4626LiquidityProvider.CallOpts, shares)
}

// PreviewRedeem is a free data retrieval call binding the contract method 0x4cdad506.
//
// Solidity: function previewRedeem(uint256 shares) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) PreviewRedeem(opts *bind.CallOpts, shares *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "previewRedeem", shares)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewRedeem is a free data retrieval call binding the contract method 0x4cdad506.
//
// Solidity: function previewRedeem(uint256 shares) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) PreviewRedeem(shares *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.PreviewRedeem(&_ERC4626LiquidityProvider.CallOpts, shares)
}

// PreviewRedeem is a free data retrieval call binding the contract method 0x4cdad506.
//
// Solidity: function previewRedeem(uint256 shares) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) PreviewRedeem(shares *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.PreviewRedeem(&_ERC4626LiquidityProvider.CallOpts, shares)
}

// PreviewWithdraw is a free data retrieval call binding the contract method 0x0a28a477.
//
// Solidity: function previewWithdraw(uint256 assets) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) PreviewWithdraw(opts *bind.CallOpts, assets *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "previewWithdraw", assets)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewWithdraw is a free data retrieval call binding the contract method 0x0a28a477.
//
// Solidity: function previewWithdraw(uint256 assets) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) PreviewWithdraw(assets *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.PreviewWithdraw(&_ERC4626LiquidityProvider.CallOpts, assets)
}

// PreviewWithdraw is a free data retrieval call binding the contract method 0x0a28a477.
//
// Solidity: function previewWithdraw(uint256 assets) view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) PreviewWithdraw(assets *big.Int) (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.PreviewWithdraw(&_ERC4626LiquidityProvider.CallOpts, assets)
}

// ProviderType is a free data retrieval call binding the contract method 0x5552ea40.
//
// Solidity: function providerType() pure returns(string)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) ProviderType(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "providerType")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// ProviderType is a free data retrieval call binding the contract method 0x5552ea40.
//
// Solidity: function providerType() pure returns(string)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) ProviderType() (string, error) {
	return _ERC4626LiquidityProvider.Contract.ProviderType(&_ERC4626LiquidityProvider.CallOpts)
}

// ProviderType is a free data retrieval call binding the contract method 0x5552ea40.
//
// Solidity: function providerType() pure returns(string)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) ProviderType() (string, error) {
	return _ERC4626LiquidityProvider.Contract.ProviderType(&_ERC4626LiquidityProvider.CallOpts)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) Symbol(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "symbol")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Symbol() (string, error) {
	return _ERC4626LiquidityProvider.Contract.Symbol(&_ERC4626LiquidityProvider.CallOpts)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) Symbol() (string, error) {
	return _ERC4626LiquidityProvider.Contract.Symbol(&_ERC4626LiquidityProvider.CallOpts)
}

// TotalAssets is a free data retrieval call binding the contract method 0x01e1d114.
//
// Solidity: function totalAssets() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) TotalAssets(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "totalAssets")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalAssets is a free data retrieval call binding the contract method 0x01e1d114.
//
// Solidity: function totalAssets() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) TotalAssets() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.TotalAssets(&_ERC4626LiquidityProvider.CallOpts)
}

// TotalAssets is a free data retrieval call binding the contract method 0x01e1d114.
//
// Solidity: function totalAssets() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) TotalAssets() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.TotalAssets(&_ERC4626LiquidityProvider.CallOpts)
}

// TotalBorrowed is a free data retrieval call binding the contract method 0x4c19386c.
//
// Solidity: function totalBorrowed() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) TotalBorrowed(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "totalBorrowed")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalBorrowed is a free data retrieval call binding the contract method 0x4c19386c.
//
// Solidity: function totalBorrowed() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) TotalBorrowed() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.TotalBorrowed(&_ERC4626LiquidityProvider.CallOpts)
}

// TotalBorrowed is a free data retrieval call binding the contract method 0x4c19386c.
//
// Solidity: function totalBorrowed() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) TotalBorrowed() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.TotalBorrowed(&_ERC4626LiquidityProvider.CallOpts)
}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) TotalLiquidity(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "totalLiquidity")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) TotalLiquidity() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.TotalLiquidity(&_ERC4626LiquidityProvider.CallOpts)
}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) TotalLiquidity() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.TotalLiquidity(&_ERC4626LiquidityProvider.CallOpts)
}

// TotalRevenueAccumulated is a free data retrieval call binding the contract method 0xb4ba2e5c.
//
// Solidity: function totalRevenueAccumulated() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) TotalRevenueAccumulated(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "totalRevenueAccumulated")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalRevenueAccumulated is a free data retrieval call binding the contract method 0xb4ba2e5c.
//
// Solidity: function totalRevenueAccumulated() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) TotalRevenueAccumulated() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.TotalRevenueAccumulated(&_ERC4626LiquidityProvider.CallOpts)
}

// TotalRevenueAccumulated is a free data retrieval call binding the contract method 0xb4ba2e5c.
//
// Solidity: function totalRevenueAccumulated() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) TotalRevenueAccumulated() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.TotalRevenueAccumulated(&_ERC4626LiquidityProvider.CallOpts)
}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) TotalSupply(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "totalSupply")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) TotalSupply() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.TotalSupply(&_ERC4626LiquidityProvider.CallOpts)
}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) TotalSupply() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.TotalSupply(&_ERC4626LiquidityProvider.CallOpts)
}

// UtilizationRate is a free data retrieval call binding the contract method 0x6c321c8a.
//
// Solidity: function utilizationRate() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCaller) UtilizationRate(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626LiquidityProvider.contract.Call(opts, &out, "utilizationRate")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// UtilizationRate is a free data retrieval call binding the contract method 0x6c321c8a.
//
// Solidity: function utilizationRate() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) UtilizationRate() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.UtilizationRate(&_ERC4626LiquidityProvider.CallOpts)
}

// UtilizationRate is a free data retrieval call binding the contract method 0x6c321c8a.
//
// Solidity: function utilizationRate() view returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderCallerSession) UtilizationRate() (*big.Int, error) {
	return _ERC4626LiquidityProvider.Contract.UtilizationRate(&_ERC4626LiquidityProvider.CallOpts)
}

// Approve is a paid mutator transaction binding the contract method 0x095ea7b3.
//
// Solidity: function approve(address spender, uint256 value) returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) Approve(opts *bind.TransactOpts, spender common.Address, value *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "approve", spender, value)
}

// Approve is a paid mutator transaction binding the contract method 0x095ea7b3.
//
// Solidity: function approve(address spender, uint256 value) returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Approve(spender common.Address, value *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Approve(&_ERC4626LiquidityProvider.TransactOpts, spender, value)
}

// Approve is a paid mutator transaction binding the contract method 0x095ea7b3.
//
// Solidity: function approve(address spender, uint256 value) returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) Approve(spender common.Address, value *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Approve(&_ERC4626LiquidityProvider.TransactOpts, spender, value)
}

// AuthorizeMarket is a paid mutator transaction binding the contract method 0xf2862e67.
//
// Solidity: function authorizeMarket(address market) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) AuthorizeMarket(opts *bind.TransactOpts, market common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "authorizeMarket", market)
}

// AuthorizeMarket is a paid mutator transaction binding the contract method 0xf2862e67.
//
// Solidity: function authorizeMarket(address market) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) AuthorizeMarket(market common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.AuthorizeMarket(&_ERC4626LiquidityProvider.TransactOpts, market)
}

// AuthorizeMarket is a paid mutator transaction binding the contract method 0xf2862e67.
//
// Solidity: function authorizeMarket(address market) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) AuthorizeMarket(market common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.AuthorizeMarket(&_ERC4626LiquidityProvider.TransactOpts, market)
}

// Borrow is a paid mutator transaction binding the contract method 0xc5ebeaec.
//
// Solidity: function borrow(uint256 amount) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) Borrow(opts *bind.TransactOpts, amount *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "borrow", amount)
}

// Borrow is a paid mutator transaction binding the contract method 0xc5ebeaec.
//
// Solidity: function borrow(uint256 amount) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Borrow(amount *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Borrow(&_ERC4626LiquidityProvider.TransactOpts, amount)
}

// Borrow is a paid mutator transaction binding the contract method 0xc5ebeaec.
//
// Solidity: function borrow(uint256 amount) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) Borrow(amount *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Borrow(&_ERC4626LiquidityProvider.TransactOpts, amount)
}

// Deposit is a paid mutator transaction binding the contract method 0x6e553f65.
//
// Solidity: function deposit(uint256 assets, address receiver) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) Deposit(opts *bind.TransactOpts, assets *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "deposit", assets, receiver)
}

// Deposit is a paid mutator transaction binding the contract method 0x6e553f65.
//
// Solidity: function deposit(uint256 assets, address receiver) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Deposit(assets *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Deposit(&_ERC4626LiquidityProvider.TransactOpts, assets, receiver)
}

// Deposit is a paid mutator transaction binding the contract method 0x6e553f65.
//
// Solidity: function deposit(uint256 assets, address receiver) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) Deposit(assets *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Deposit(&_ERC4626LiquidityProvider.TransactOpts, assets, receiver)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address recipient, uint256 amount) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) EmergencyWithdraw(opts *bind.TransactOpts, recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "emergencyWithdraw", recipient, amount)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address recipient, uint256 amount) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) EmergencyWithdraw(recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.EmergencyWithdraw(&_ERC4626LiquidityProvider.TransactOpts, recipient, amount)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address recipient, uint256 amount) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) EmergencyWithdraw(recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.EmergencyWithdraw(&_ERC4626LiquidityProvider.TransactOpts, recipient, amount)
}

// Mint is a paid mutator transaction binding the contract method 0x94bf804d.
//
// Solidity: function mint(uint256 shares, address receiver) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) Mint(opts *bind.TransactOpts, shares *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "mint", shares, receiver)
}

// Mint is a paid mutator transaction binding the contract method 0x94bf804d.
//
// Solidity: function mint(uint256 shares, address receiver) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Mint(shares *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Mint(&_ERC4626LiquidityProvider.TransactOpts, shares, receiver)
}

// Mint is a paid mutator transaction binding the contract method 0x94bf804d.
//
// Solidity: function mint(uint256 shares, address receiver) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) Mint(shares *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Mint(&_ERC4626LiquidityProvider.TransactOpts, shares, receiver)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) Pause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "pause")
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Pause() (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Pause(&_ERC4626LiquidityProvider.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) Pause() (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Pause(&_ERC4626LiquidityProvider.TransactOpts)
}

// Redeem is a paid mutator transaction binding the contract method 0xba087652.
//
// Solidity: function redeem(uint256 shares, address receiver, address owner) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) Redeem(opts *bind.TransactOpts, shares *big.Int, receiver common.Address, owner common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "redeem", shares, receiver, owner)
}

// Redeem is a paid mutator transaction binding the contract method 0xba087652.
//
// Solidity: function redeem(uint256 shares, address receiver, address owner) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Redeem(shares *big.Int, receiver common.Address, owner common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Redeem(&_ERC4626LiquidityProvider.TransactOpts, shares, receiver, owner)
}

// Redeem is a paid mutator transaction binding the contract method 0xba087652.
//
// Solidity: function redeem(uint256 shares, address receiver, address owner) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) Redeem(shares *big.Int, receiver common.Address, owner common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Redeem(&_ERC4626LiquidityProvider.TransactOpts, shares, receiver, owner)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) RenounceOwnership() (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.RenounceOwnership(&_ERC4626LiquidityProvider.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.RenounceOwnership(&_ERC4626LiquidityProvider.TransactOpts)
}

// Repay is a paid mutator transaction binding the contract method 0xd8aed145.
//
// Solidity: function repay(uint256 principal, uint256 revenue) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) Repay(opts *bind.TransactOpts, principal *big.Int, revenue *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "repay", principal, revenue)
}

// Repay is a paid mutator transaction binding the contract method 0xd8aed145.
//
// Solidity: function repay(uint256 principal, uint256 revenue) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Repay(principal *big.Int, revenue *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Repay(&_ERC4626LiquidityProvider.TransactOpts, principal, revenue)
}

// Repay is a paid mutator transaction binding the contract method 0xd8aed145.
//
// Solidity: function repay(uint256 principal, uint256 revenue) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) Repay(principal *big.Int, revenue *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Repay(&_ERC4626LiquidityProvider.TransactOpts, principal, revenue)
}

// RevokeMarket is a paid mutator transaction binding the contract method 0x29527b82.
//
// Solidity: function revokeMarket(address market) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) RevokeMarket(opts *bind.TransactOpts, market common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "revokeMarket", market)
}

// RevokeMarket is a paid mutator transaction binding the contract method 0x29527b82.
//
// Solidity: function revokeMarket(address market) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) RevokeMarket(market common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.RevokeMarket(&_ERC4626LiquidityProvider.TransactOpts, market)
}

// RevokeMarket is a paid mutator transaction binding the contract method 0x29527b82.
//
// Solidity: function revokeMarket(address market) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) RevokeMarket(market common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.RevokeMarket(&_ERC4626LiquidityProvider.TransactOpts, market)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address to, uint256 value) returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) Transfer(opts *bind.TransactOpts, to common.Address, value *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "transfer", to, value)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address to, uint256 value) returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Transfer(to common.Address, value *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Transfer(&_ERC4626LiquidityProvider.TransactOpts, to, value)
}

// Transfer is a paid mutator transaction binding the contract method 0xa9059cbb.
//
// Solidity: function transfer(address to, uint256 value) returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) Transfer(to common.Address, value *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Transfer(&_ERC4626LiquidityProvider.TransactOpts, to, value)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 value) returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) TransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, value *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "transferFrom", from, to, value)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 value) returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) TransferFrom(from common.Address, to common.Address, value *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.TransferFrom(&_ERC4626LiquidityProvider.TransactOpts, from, to, value)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 value) returns(bool)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) TransferFrom(from common.Address, to common.Address, value *big.Int) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.TransferFrom(&_ERC4626LiquidityProvider.TransactOpts, from, to, value)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.TransferOwnership(&_ERC4626LiquidityProvider.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.TransferOwnership(&_ERC4626LiquidityProvider.TransactOpts, newOwner)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) Unpause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "unpause")
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Unpause() (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Unpause(&_ERC4626LiquidityProvider.TransactOpts)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) Unpause() (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Unpause(&_ERC4626LiquidityProvider.TransactOpts)
}

// Withdraw is a paid mutator transaction binding the contract method 0xb460af94.
//
// Solidity: function withdraw(uint256 assets, address receiver, address owner) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactor) Withdraw(opts *bind.TransactOpts, assets *big.Int, receiver common.Address, owner common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.contract.Transact(opts, "withdraw", assets, receiver, owner)
}

// Withdraw is a paid mutator transaction binding the contract method 0xb460af94.
//
// Solidity: function withdraw(uint256 assets, address receiver, address owner) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderSession) Withdraw(assets *big.Int, receiver common.Address, owner common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Withdraw(&_ERC4626LiquidityProvider.TransactOpts, assets, receiver, owner)
}

// Withdraw is a paid mutator transaction binding the contract method 0xb460af94.
//
// Solidity: function withdraw(uint256 assets, address receiver, address owner) returns(uint256)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderTransactorSession) Withdraw(assets *big.Int, receiver common.Address, owner common.Address) (*types.Transaction, error) {
	return _ERC4626LiquidityProvider.Contract.Withdraw(&_ERC4626LiquidityProvider.TransactOpts, assets, receiver, owner)
}

// ERC4626LiquidityProviderApprovalIterator is returned from FilterApproval and is used to iterate over the raw logs and unpacked data for Approval events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderApprovalIterator struct {
	Event *ERC4626LiquidityProviderApproval // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderApprovalIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderApproval)
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
		it.Event = new(ERC4626LiquidityProviderApproval)
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
func (it *ERC4626LiquidityProviderApprovalIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderApprovalIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderApproval represents a Approval event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderApproval struct {
	Owner   common.Address
	Spender common.Address
	Value   *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterApproval is a free log retrieval operation binding the contract event 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925.
//
// Solidity: event Approval(address indexed owner, address indexed spender, uint256 value)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterApproval(opts *bind.FilterOpts, owner []common.Address, spender []common.Address) (*ERC4626LiquidityProviderApprovalIterator, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var spenderRule []interface{}
	for _, spenderItem := range spender {
		spenderRule = append(spenderRule, spenderItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "Approval", ownerRule, spenderRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderApprovalIterator{contract: _ERC4626LiquidityProvider.contract, event: "Approval", logs: logs, sub: sub}, nil
}

// WatchApproval is a free log subscription operation binding the contract event 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925.
//
// Solidity: event Approval(address indexed owner, address indexed spender, uint256 value)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchApproval(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderApproval, owner []common.Address, spender []common.Address) (event.Subscription, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var spenderRule []interface{}
	for _, spenderItem := range spender {
		spenderRule = append(spenderRule, spenderItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "Approval", ownerRule, spenderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderApproval)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Approval", log); err != nil {
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

// ParseApproval is a log parse operation binding the contract event 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925.
//
// Solidity: event Approval(address indexed owner, address indexed spender, uint256 value)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseApproval(log types.Log) (*ERC4626LiquidityProviderApproval, error) {
	event := new(ERC4626LiquidityProviderApproval)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Approval", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderDepositIterator is returned from FilterDeposit and is used to iterate over the raw logs and unpacked data for Deposit events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderDepositIterator struct {
	Event *ERC4626LiquidityProviderDeposit // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderDepositIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderDeposit)
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
		it.Event = new(ERC4626LiquidityProviderDeposit)
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
func (it *ERC4626LiquidityProviderDepositIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderDepositIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderDeposit represents a Deposit event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderDeposit struct {
	Sender common.Address
	Owner  common.Address
	Assets *big.Int
	Shares *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterDeposit is a free log retrieval operation binding the contract event 0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7.
//
// Solidity: event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterDeposit(opts *bind.FilterOpts, sender []common.Address, owner []common.Address) (*ERC4626LiquidityProviderDepositIterator, error) {

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "Deposit", senderRule, ownerRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderDepositIterator{contract: _ERC4626LiquidityProvider.contract, event: "Deposit", logs: logs, sub: sub}, nil
}

// WatchDeposit is a free log subscription operation binding the contract event 0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7.
//
// Solidity: event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchDeposit(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderDeposit, sender []common.Address, owner []common.Address) (event.Subscription, error) {

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "Deposit", senderRule, ownerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderDeposit)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Deposit", log); err != nil {
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

// ParseDeposit is a log parse operation binding the contract event 0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7.
//
// Solidity: event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseDeposit(log types.Log) (*ERC4626LiquidityProviderDeposit, error) {
	event := new(ERC4626LiquidityProviderDeposit)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Deposit", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderEmergencyWithdrawalIterator is returned from FilterEmergencyWithdrawal and is used to iterate over the raw logs and unpacked data for EmergencyWithdrawal events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderEmergencyWithdrawalIterator struct {
	Event *ERC4626LiquidityProviderEmergencyWithdrawal // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderEmergencyWithdrawalIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderEmergencyWithdrawal)
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
		it.Event = new(ERC4626LiquidityProviderEmergencyWithdrawal)
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
func (it *ERC4626LiquidityProviderEmergencyWithdrawalIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderEmergencyWithdrawalIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderEmergencyWithdrawal represents a EmergencyWithdrawal event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderEmergencyWithdrawal struct {
	Admin     common.Address
	Recipient common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterEmergencyWithdrawal is a free log retrieval operation binding the contract event 0x9495d03190a79a43e534c9e328ff322f6283261383f5f19c809564f6ad5a57b3.
//
// Solidity: event EmergencyWithdrawal(address indexed admin, address indexed recipient, uint256 amount)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterEmergencyWithdrawal(opts *bind.FilterOpts, admin []common.Address, recipient []common.Address) (*ERC4626LiquidityProviderEmergencyWithdrawalIterator, error) {

	var adminRule []interface{}
	for _, adminItem := range admin {
		adminRule = append(adminRule, adminItem)
	}
	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "EmergencyWithdrawal", adminRule, recipientRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderEmergencyWithdrawalIterator{contract: _ERC4626LiquidityProvider.contract, event: "EmergencyWithdrawal", logs: logs, sub: sub}, nil
}

// WatchEmergencyWithdrawal is a free log subscription operation binding the contract event 0x9495d03190a79a43e534c9e328ff322f6283261383f5f19c809564f6ad5a57b3.
//
// Solidity: event EmergencyWithdrawal(address indexed admin, address indexed recipient, uint256 amount)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchEmergencyWithdrawal(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderEmergencyWithdrawal, admin []common.Address, recipient []common.Address) (event.Subscription, error) {

	var adminRule []interface{}
	for _, adminItem := range admin {
		adminRule = append(adminRule, adminItem)
	}
	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "EmergencyWithdrawal", adminRule, recipientRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderEmergencyWithdrawal)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "EmergencyWithdrawal", log); err != nil {
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

// ParseEmergencyWithdrawal is a log parse operation binding the contract event 0x9495d03190a79a43e534c9e328ff322f6283261383f5f19c809564f6ad5a57b3.
//
// Solidity: event EmergencyWithdrawal(address indexed admin, address indexed recipient, uint256 amount)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseEmergencyWithdrawal(log types.Log) (*ERC4626LiquidityProviderEmergencyWithdrawal, error) {
	event := new(ERC4626LiquidityProviderEmergencyWithdrawal)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "EmergencyWithdrawal", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderLiquidityBorrowedIterator is returned from FilterLiquidityBorrowed and is used to iterate over the raw logs and unpacked data for LiquidityBorrowed events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderLiquidityBorrowedIterator struct {
	Event *ERC4626LiquidityProviderLiquidityBorrowed // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderLiquidityBorrowedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderLiquidityBorrowed)
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
		it.Event = new(ERC4626LiquidityProviderLiquidityBorrowed)
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
func (it *ERC4626LiquidityProviderLiquidityBorrowedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderLiquidityBorrowedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderLiquidityBorrowed represents a LiquidityBorrowed event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderLiquidityBorrowed struct {
	Market    common.Address
	Amount    *big.Int
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterLiquidityBorrowed is a free log retrieval operation binding the contract event 0x6eacc78bef5c94a765db80df145e01265f64fe8665e02370dd3fd1881ced38f0.
//
// Solidity: event LiquidityBorrowed(address indexed market, uint256 amount, uint256 timestamp)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterLiquidityBorrowed(opts *bind.FilterOpts, market []common.Address) (*ERC4626LiquidityProviderLiquidityBorrowedIterator, error) {

	var marketRule []interface{}
	for _, marketItem := range market {
		marketRule = append(marketRule, marketItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "LiquidityBorrowed", marketRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderLiquidityBorrowedIterator{contract: _ERC4626LiquidityProvider.contract, event: "LiquidityBorrowed", logs: logs, sub: sub}, nil
}

// WatchLiquidityBorrowed is a free log subscription operation binding the contract event 0x6eacc78bef5c94a765db80df145e01265f64fe8665e02370dd3fd1881ced38f0.
//
// Solidity: event LiquidityBorrowed(address indexed market, uint256 amount, uint256 timestamp)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchLiquidityBorrowed(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderLiquidityBorrowed, market []common.Address) (event.Subscription, error) {

	var marketRule []interface{}
	for _, marketItem := range market {
		marketRule = append(marketRule, marketItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "LiquidityBorrowed", marketRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderLiquidityBorrowed)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "LiquidityBorrowed", log); err != nil {
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

// ParseLiquidityBorrowed is a log parse operation binding the contract event 0x6eacc78bef5c94a765db80df145e01265f64fe8665e02370dd3fd1881ced38f0.
//
// Solidity: event LiquidityBorrowed(address indexed market, uint256 amount, uint256 timestamp)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseLiquidityBorrowed(log types.Log) (*ERC4626LiquidityProviderLiquidityBorrowed, error) {
	event := new(ERC4626LiquidityProviderLiquidityBorrowed)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "LiquidityBorrowed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderLiquidityRepaidIterator is returned from FilterLiquidityRepaid and is used to iterate over the raw logs and unpacked data for LiquidityRepaid events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderLiquidityRepaidIterator struct {
	Event *ERC4626LiquidityProviderLiquidityRepaid // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderLiquidityRepaidIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderLiquidityRepaid)
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
		it.Event = new(ERC4626LiquidityProviderLiquidityRepaid)
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
func (it *ERC4626LiquidityProviderLiquidityRepaidIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderLiquidityRepaidIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderLiquidityRepaid represents a LiquidityRepaid event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderLiquidityRepaid struct {
	Market    common.Address
	Principal *big.Int
	Revenue   *big.Int
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterLiquidityRepaid is a free log retrieval operation binding the contract event 0x366037aa71e6646e64ac900b7f46e1174dc8d4c3edc7556685d86a4b2768e64e.
//
// Solidity: event LiquidityRepaid(address indexed market, uint256 principal, uint256 revenue, uint256 timestamp)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterLiquidityRepaid(opts *bind.FilterOpts, market []common.Address) (*ERC4626LiquidityProviderLiquidityRepaidIterator, error) {

	var marketRule []interface{}
	for _, marketItem := range market {
		marketRule = append(marketRule, marketItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "LiquidityRepaid", marketRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderLiquidityRepaidIterator{contract: _ERC4626LiquidityProvider.contract, event: "LiquidityRepaid", logs: logs, sub: sub}, nil
}

// WatchLiquidityRepaid is a free log subscription operation binding the contract event 0x366037aa71e6646e64ac900b7f46e1174dc8d4c3edc7556685d86a4b2768e64e.
//
// Solidity: event LiquidityRepaid(address indexed market, uint256 principal, uint256 revenue, uint256 timestamp)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchLiquidityRepaid(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderLiquidityRepaid, market []common.Address) (event.Subscription, error) {

	var marketRule []interface{}
	for _, marketItem := range market {
		marketRule = append(marketRule, marketItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "LiquidityRepaid", marketRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderLiquidityRepaid)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "LiquidityRepaid", log); err != nil {
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

// ParseLiquidityRepaid is a log parse operation binding the contract event 0x366037aa71e6646e64ac900b7f46e1174dc8d4c3edc7556685d86a4b2768e64e.
//
// Solidity: event LiquidityRepaid(address indexed market, uint256 principal, uint256 revenue, uint256 timestamp)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseLiquidityRepaid(log types.Log) (*ERC4626LiquidityProviderLiquidityRepaid, error) {
	event := new(ERC4626LiquidityProviderLiquidityRepaid)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "LiquidityRepaid", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderMarketAuthorizationChangedIterator is returned from FilterMarketAuthorizationChanged and is used to iterate over the raw logs and unpacked data for MarketAuthorizationChanged events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderMarketAuthorizationChangedIterator struct {
	Event *ERC4626LiquidityProviderMarketAuthorizationChanged // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderMarketAuthorizationChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderMarketAuthorizationChanged)
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
		it.Event = new(ERC4626LiquidityProviderMarketAuthorizationChanged)
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
func (it *ERC4626LiquidityProviderMarketAuthorizationChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderMarketAuthorizationChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderMarketAuthorizationChanged represents a MarketAuthorizationChanged event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderMarketAuthorizationChanged struct {
	Market     common.Address
	Authorized bool
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterMarketAuthorizationChanged is a free log retrieval operation binding the contract event 0xc792d97102b92a6590521ee4ad4d0e32f4494d254832be13b9b600ae4ed4f662.
//
// Solidity: event MarketAuthorizationChanged(address indexed market, bool authorized)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterMarketAuthorizationChanged(opts *bind.FilterOpts, market []common.Address) (*ERC4626LiquidityProviderMarketAuthorizationChangedIterator, error) {

	var marketRule []interface{}
	for _, marketItem := range market {
		marketRule = append(marketRule, marketItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "MarketAuthorizationChanged", marketRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderMarketAuthorizationChangedIterator{contract: _ERC4626LiquidityProvider.contract, event: "MarketAuthorizationChanged", logs: logs, sub: sub}, nil
}

// WatchMarketAuthorizationChanged is a free log subscription operation binding the contract event 0xc792d97102b92a6590521ee4ad4d0e32f4494d254832be13b9b600ae4ed4f662.
//
// Solidity: event MarketAuthorizationChanged(address indexed market, bool authorized)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchMarketAuthorizationChanged(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderMarketAuthorizationChanged, market []common.Address) (event.Subscription, error) {

	var marketRule []interface{}
	for _, marketItem := range market {
		marketRule = append(marketRule, marketItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "MarketAuthorizationChanged", marketRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderMarketAuthorizationChanged)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "MarketAuthorizationChanged", log); err != nil {
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

// ParseMarketAuthorizationChanged is a log parse operation binding the contract event 0xc792d97102b92a6590521ee4ad4d0e32f4494d254832be13b9b600ae4ed4f662.
//
// Solidity: event MarketAuthorizationChanged(address indexed market, bool authorized)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseMarketAuthorizationChanged(log types.Log) (*ERC4626LiquidityProviderMarketAuthorizationChanged, error) {
	event := new(ERC4626LiquidityProviderMarketAuthorizationChanged)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "MarketAuthorizationChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderOwnershipTransferredIterator struct {
	Event *ERC4626LiquidityProviderOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderOwnershipTransferred)
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
		it.Event = new(ERC4626LiquidityProviderOwnershipTransferred)
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
func (it *ERC4626LiquidityProviderOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderOwnershipTransferred represents a OwnershipTransferred event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*ERC4626LiquidityProviderOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderOwnershipTransferredIterator{contract: _ERC4626LiquidityProvider.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderOwnershipTransferred)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseOwnershipTransferred(log types.Log) (*ERC4626LiquidityProviderOwnershipTransferred, error) {
	event := new(ERC4626LiquidityProviderOwnershipTransferred)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderPausedIterator is returned from FilterPaused and is used to iterate over the raw logs and unpacked data for Paused events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderPausedIterator struct {
	Event *ERC4626LiquidityProviderPaused // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderPausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderPaused)
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
		it.Event = new(ERC4626LiquidityProviderPaused)
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
func (it *ERC4626LiquidityProviderPausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderPausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderPaused represents a Paused event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderPaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterPaused is a free log retrieval operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterPaused(opts *bind.FilterOpts) (*ERC4626LiquidityProviderPausedIterator, error) {

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderPausedIterator{contract: _ERC4626LiquidityProvider.contract, event: "Paused", logs: logs, sub: sub}, nil
}

// WatchPaused is a free log subscription operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchPaused(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderPaused) (event.Subscription, error) {

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderPaused)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Paused", log); err != nil {
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
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParsePaused(log types.Log) (*ERC4626LiquidityProviderPaused, error) {
	event := new(ERC4626LiquidityProviderPaused)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Paused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderRevenueDistributedIterator is returned from FilterRevenueDistributed and is used to iterate over the raw logs and unpacked data for RevenueDistributed events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderRevenueDistributedIterator struct {
	Event *ERC4626LiquidityProviderRevenueDistributed // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderRevenueDistributedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderRevenueDistributed)
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
		it.Event = new(ERC4626LiquidityProviderRevenueDistributed)
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
func (it *ERC4626LiquidityProviderRevenueDistributedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderRevenueDistributedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderRevenueDistributed represents a RevenueDistributed event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderRevenueDistributed struct {
	Amount      *big.Int
	TotalAssets *big.Int
	TotalShares *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterRevenueDistributed is a free log retrieval operation binding the contract event 0x6215b003e186dbc79e3bd07b486dc69758f50dab026e5d485d4a945d56015447.
//
// Solidity: event RevenueDistributed(uint256 amount, uint256 totalAssets, uint256 totalShares)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterRevenueDistributed(opts *bind.FilterOpts) (*ERC4626LiquidityProviderRevenueDistributedIterator, error) {

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "RevenueDistributed")
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderRevenueDistributedIterator{contract: _ERC4626LiquidityProvider.contract, event: "RevenueDistributed", logs: logs, sub: sub}, nil
}

// WatchRevenueDistributed is a free log subscription operation binding the contract event 0x6215b003e186dbc79e3bd07b486dc69758f50dab026e5d485d4a945d56015447.
//
// Solidity: event RevenueDistributed(uint256 amount, uint256 totalAssets, uint256 totalShares)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchRevenueDistributed(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderRevenueDistributed) (event.Subscription, error) {

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "RevenueDistributed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderRevenueDistributed)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "RevenueDistributed", log); err != nil {
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

// ParseRevenueDistributed is a log parse operation binding the contract event 0x6215b003e186dbc79e3bd07b486dc69758f50dab026e5d485d4a945d56015447.
//
// Solidity: event RevenueDistributed(uint256 amount, uint256 totalAssets, uint256 totalShares)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseRevenueDistributed(log types.Log) (*ERC4626LiquidityProviderRevenueDistributed, error) {
	event := new(ERC4626LiquidityProviderRevenueDistributed)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "RevenueDistributed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderTransferIterator is returned from FilterTransfer and is used to iterate over the raw logs and unpacked data for Transfer events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderTransferIterator struct {
	Event *ERC4626LiquidityProviderTransfer // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderTransferIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderTransfer)
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
		it.Event = new(ERC4626LiquidityProviderTransfer)
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
func (it *ERC4626LiquidityProviderTransferIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderTransferIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderTransfer represents a Transfer event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderTransfer struct {
	From  common.Address
	To    common.Address
	Value *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterTransfer is a free log retrieval operation binding the contract event 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef.
//
// Solidity: event Transfer(address indexed from, address indexed to, uint256 value)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterTransfer(opts *bind.FilterOpts, from []common.Address, to []common.Address) (*ERC4626LiquidityProviderTransferIterator, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "Transfer", fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderTransferIterator{contract: _ERC4626LiquidityProvider.contract, event: "Transfer", logs: logs, sub: sub}, nil
}

// WatchTransfer is a free log subscription operation binding the contract event 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef.
//
// Solidity: event Transfer(address indexed from, address indexed to, uint256 value)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchTransfer(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderTransfer, from []common.Address, to []common.Address) (event.Subscription, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "Transfer", fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderTransfer)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Transfer", log); err != nil {
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

// ParseTransfer is a log parse operation binding the contract event 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef.
//
// Solidity: event Transfer(address indexed from, address indexed to, uint256 value)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseTransfer(log types.Log) (*ERC4626LiquidityProviderTransfer, error) {
	event := new(ERC4626LiquidityProviderTransfer)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Transfer", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderUnpausedIterator is returned from FilterUnpaused and is used to iterate over the raw logs and unpacked data for Unpaused events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderUnpausedIterator struct {
	Event *ERC4626LiquidityProviderUnpaused // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderUnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderUnpaused)
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
		it.Event = new(ERC4626LiquidityProviderUnpaused)
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
func (it *ERC4626LiquidityProviderUnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderUnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderUnpaused represents a Unpaused event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderUnpaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUnpaused is a free log retrieval operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterUnpaused(opts *bind.FilterOpts) (*ERC4626LiquidityProviderUnpausedIterator, error) {

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderUnpausedIterator{contract: _ERC4626LiquidityProvider.contract, event: "Unpaused", logs: logs, sub: sub}, nil
}

// WatchUnpaused is a free log subscription operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchUnpaused(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderUnpaused) (event.Subscription, error) {

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderUnpaused)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Unpaused", log); err != nil {
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
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseUnpaused(log types.Log) (*ERC4626LiquidityProviderUnpaused, error) {
	event := new(ERC4626LiquidityProviderUnpaused)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Unpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626LiquidityProviderWithdrawIterator is returned from FilterWithdraw and is used to iterate over the raw logs and unpacked data for Withdraw events raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderWithdrawIterator struct {
	Event *ERC4626LiquidityProviderWithdraw // Event containing the contract specifics and raw log

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
func (it *ERC4626LiquidityProviderWithdrawIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626LiquidityProviderWithdraw)
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
		it.Event = new(ERC4626LiquidityProviderWithdraw)
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
func (it *ERC4626LiquidityProviderWithdrawIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626LiquidityProviderWithdrawIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626LiquidityProviderWithdraw represents a Withdraw event raised by the ERC4626LiquidityProvider contract.
type ERC4626LiquidityProviderWithdraw struct {
	Sender   common.Address
	Receiver common.Address
	Owner    common.Address
	Assets   *big.Int
	Shares   *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterWithdraw is a free log retrieval operation binding the contract event 0xfbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db.
//
// Solidity: event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) FilterWithdraw(opts *bind.FilterOpts, sender []common.Address, receiver []common.Address, owner []common.Address) (*ERC4626LiquidityProviderWithdrawIterator, error) {

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}
	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.FilterLogs(opts, "Withdraw", senderRule, receiverRule, ownerRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626LiquidityProviderWithdrawIterator{contract: _ERC4626LiquidityProvider.contract, event: "Withdraw", logs: logs, sub: sub}, nil
}

// WatchWithdraw is a free log subscription operation binding the contract event 0xfbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db.
//
// Solidity: event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) WatchWithdraw(opts *bind.WatchOpts, sink chan<- *ERC4626LiquidityProviderWithdraw, sender []common.Address, receiver []common.Address, owner []common.Address) (event.Subscription, error) {

	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}
	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}

	logs, sub, err := _ERC4626LiquidityProvider.contract.WatchLogs(opts, "Withdraw", senderRule, receiverRule, ownerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626LiquidityProviderWithdraw)
				if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Withdraw", log); err != nil {
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

// ParseWithdraw is a log parse operation binding the contract event 0xfbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db.
//
// Solidity: event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares)
func (_ERC4626LiquidityProvider *ERC4626LiquidityProviderFilterer) ParseWithdraw(log types.Log) (*ERC4626LiquidityProviderWithdraw, error) {
	event := new(ERC4626LiquidityProviderWithdraw)
	if err := _ERC4626LiquidityProvider.contract.UnpackLog(event, "Withdraw", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
