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

// FeeRouterFeeRecipients is an auto generated low-level Go binding around an user-defined struct.
type FeeRouterFeeRecipients struct {
	LpVault       common.Address
	PromoPool     common.Address
	InsuranceFund common.Address
	Treasury      common.Address
}

// FeeRouterMetaData contains all meta data concerning the FeeRouter contract.
var FeeRouterMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_recipients\",\"type\":\"tuple\",\"internalType\":\"structFeeRouter.FeeRecipients\",\"components\":[{\"name\":\"lpVault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"promoPool\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"insuranceFund\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"name\":\"_referralRegistry\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"BPS_DENOMINATOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MAX_REFERRAL_BPS\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"_processSingleFee\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchRouteFee\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"users\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"successCount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"failedIndices\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"emergencyWithdraw\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"feeSplit\",\"inputs\":[],\"outputs\":[{\"name\":\"lpBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"promoBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"insuranceBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"treasuryBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getFeeStats\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"totalReceived\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalReferral\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalLP\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalPromo\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalInsurance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalTreasury\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getReferralBps\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewFeeSplit\",\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"hasReferrer\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"referralAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"lpAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"promoAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"insuranceAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"treasuryAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"recipients\",\"inputs\":[],\"outputs\":[{\"name\":\"lpVault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"promoPool\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"insuranceFund\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"referralRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractReferralRegistry\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"routeFee\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"feeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"betAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setFeeSplit\",\"inputs\":[{\"name\":\"_lpBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_promoBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_insuranceBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_treasuryBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setRecipients\",\"inputs\":[{\"name\":\"_recipients\",\"type\":\"tuple\",\"internalType\":\"structFeeRouter.FeeRecipients\",\"components\":[{\"name\":\"lpVault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"promoPool\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"insuranceFund\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"treasury\",\"type\":\"address\",\"internalType\":\"address\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setReferralRegistry\",\"inputs\":[{\"name\":\"_registry\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"totalFeesDistributed\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalFeesReceived\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"BatchProcessed\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"totalCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"successCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"failedCount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"failedTotalAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeReceived\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeRouted\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"totalAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"referrer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"referralAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"lpAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"promoAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"insuranceAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"treasuryAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FeeSplitUpdated\",\"inputs\":[{\"name\":\"lpBps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"promoBps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"insuranceBps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"treasuryBps\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RecipientsUpdated\",\"inputs\":[{\"name\":\"lpVault\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"promoPool\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"insuranceFund\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"treasury\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ReferralRegistryUpdated\",\"inputs\":[{\"name\":\"newRegistry\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidFeeSplit\",\"inputs\":[{\"name\":\"total\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"InvalidReferralBps\",\"inputs\":[{\"name\":\"provided\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"max\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"NoFeesToDistribute\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ZeroAddress\",\"inputs\":[{\"name\":\"param\",\"type\":\"string\",\"internalType\":\"string\"}]}]",
}

// FeeRouterABI is the input ABI used to generate the binding from.
// Deprecated: Use FeeRouterMetaData.ABI instead.
var FeeRouterABI = FeeRouterMetaData.ABI

// FeeRouter is an auto generated Go binding around an Ethereum contract.
type FeeRouter struct {
	FeeRouterCaller     // Read-only binding to the contract
	FeeRouterTransactor // Write-only binding to the contract
	FeeRouterFilterer   // Log filterer for contract events
}

// FeeRouterCaller is an auto generated read-only Go binding around an Ethereum contract.
type FeeRouterCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FeeRouterTransactor is an auto generated write-only Go binding around an Ethereum contract.
type FeeRouterTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FeeRouterFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type FeeRouterFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FeeRouterSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type FeeRouterSession struct {
	Contract     *FeeRouter        // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// FeeRouterCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type FeeRouterCallerSession struct {
	Contract *FeeRouterCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts    // Call options to use throughout this session
}

// FeeRouterTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type FeeRouterTransactorSession struct {
	Contract     *FeeRouterTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts    // Transaction auth options to use throughout this session
}

// FeeRouterRaw is an auto generated low-level Go binding around an Ethereum contract.
type FeeRouterRaw struct {
	Contract *FeeRouter // Generic contract binding to access the raw methods on
}

// FeeRouterCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type FeeRouterCallerRaw struct {
	Contract *FeeRouterCaller // Generic read-only contract binding to access the raw methods on
}

// FeeRouterTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type FeeRouterTransactorRaw struct {
	Contract *FeeRouterTransactor // Generic write-only contract binding to access the raw methods on
}

// NewFeeRouter creates a new instance of FeeRouter, bound to a specific deployed contract.
func NewFeeRouter(address common.Address, backend bind.ContractBackend) (*FeeRouter, error) {
	contract, err := bindFeeRouter(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &FeeRouter{FeeRouterCaller: FeeRouterCaller{contract: contract}, FeeRouterTransactor: FeeRouterTransactor{contract: contract}, FeeRouterFilterer: FeeRouterFilterer{contract: contract}}, nil
}

// NewFeeRouterCaller creates a new read-only instance of FeeRouter, bound to a specific deployed contract.
func NewFeeRouterCaller(address common.Address, caller bind.ContractCaller) (*FeeRouterCaller, error) {
	contract, err := bindFeeRouter(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &FeeRouterCaller{contract: contract}, nil
}

// NewFeeRouterTransactor creates a new write-only instance of FeeRouter, bound to a specific deployed contract.
func NewFeeRouterTransactor(address common.Address, transactor bind.ContractTransactor) (*FeeRouterTransactor, error) {
	contract, err := bindFeeRouter(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &FeeRouterTransactor{contract: contract}, nil
}

// NewFeeRouterFilterer creates a new log filterer instance of FeeRouter, bound to a specific deployed contract.
func NewFeeRouterFilterer(address common.Address, filterer bind.ContractFilterer) (*FeeRouterFilterer, error) {
	contract, err := bindFeeRouter(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &FeeRouterFilterer{contract: contract}, nil
}

// bindFeeRouter binds a generic wrapper to an already deployed contract.
func bindFeeRouter(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := FeeRouterMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_FeeRouter *FeeRouterRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _FeeRouter.Contract.FeeRouterCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_FeeRouter *FeeRouterRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FeeRouter.Contract.FeeRouterTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_FeeRouter *FeeRouterRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _FeeRouter.Contract.FeeRouterTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_FeeRouter *FeeRouterCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _FeeRouter.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_FeeRouter *FeeRouterTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FeeRouter.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_FeeRouter *FeeRouterTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _FeeRouter.Contract.contract.Transact(opts, method, params...)
}

// BPSDENOMINATOR is a free data retrieval call binding the contract method 0xe1a45218.
//
// Solidity: function BPS_DENOMINATOR() view returns(uint256)
func (_FeeRouter *FeeRouterCaller) BPSDENOMINATOR(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "BPS_DENOMINATOR")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BPSDENOMINATOR is a free data retrieval call binding the contract method 0xe1a45218.
//
// Solidity: function BPS_DENOMINATOR() view returns(uint256)
func (_FeeRouter *FeeRouterSession) BPSDENOMINATOR() (*big.Int, error) {
	return _FeeRouter.Contract.BPSDENOMINATOR(&_FeeRouter.CallOpts)
}

// BPSDENOMINATOR is a free data retrieval call binding the contract method 0xe1a45218.
//
// Solidity: function BPS_DENOMINATOR() view returns(uint256)
func (_FeeRouter *FeeRouterCallerSession) BPSDENOMINATOR() (*big.Int, error) {
	return _FeeRouter.Contract.BPSDENOMINATOR(&_FeeRouter.CallOpts)
}

// MAXREFERRALBPS is a free data retrieval call binding the contract method 0x62959a6e.
//
// Solidity: function MAX_REFERRAL_BPS() view returns(uint256)
func (_FeeRouter *FeeRouterCaller) MAXREFERRALBPS(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "MAX_REFERRAL_BPS")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXREFERRALBPS is a free data retrieval call binding the contract method 0x62959a6e.
//
// Solidity: function MAX_REFERRAL_BPS() view returns(uint256)
func (_FeeRouter *FeeRouterSession) MAXREFERRALBPS() (*big.Int, error) {
	return _FeeRouter.Contract.MAXREFERRALBPS(&_FeeRouter.CallOpts)
}

// MAXREFERRALBPS is a free data retrieval call binding the contract method 0x62959a6e.
//
// Solidity: function MAX_REFERRAL_BPS() view returns(uint256)
func (_FeeRouter *FeeRouterCallerSession) MAXREFERRALBPS() (*big.Int, error) {
	return _FeeRouter.Contract.MAXREFERRALBPS(&_FeeRouter.CallOpts)
}

// FeeSplit is a free data retrieval call binding the contract method 0x6373ea69.
//
// Solidity: function feeSplit() view returns(uint256 lpBps, uint256 promoBps, uint256 insuranceBps, uint256 treasuryBps)
func (_FeeRouter *FeeRouterCaller) FeeSplit(opts *bind.CallOpts) (struct {
	LpBps        *big.Int
	PromoBps     *big.Int
	InsuranceBps *big.Int
	TreasuryBps  *big.Int
}, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "feeSplit")

	outstruct := new(struct {
		LpBps        *big.Int
		PromoBps     *big.Int
		InsuranceBps *big.Int
		TreasuryBps  *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.LpBps = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.PromoBps = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.InsuranceBps = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.TreasuryBps = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// FeeSplit is a free data retrieval call binding the contract method 0x6373ea69.
//
// Solidity: function feeSplit() view returns(uint256 lpBps, uint256 promoBps, uint256 insuranceBps, uint256 treasuryBps)
func (_FeeRouter *FeeRouterSession) FeeSplit() (struct {
	LpBps        *big.Int
	PromoBps     *big.Int
	InsuranceBps *big.Int
	TreasuryBps  *big.Int
}, error) {
	return _FeeRouter.Contract.FeeSplit(&_FeeRouter.CallOpts)
}

// FeeSplit is a free data retrieval call binding the contract method 0x6373ea69.
//
// Solidity: function feeSplit() view returns(uint256 lpBps, uint256 promoBps, uint256 insuranceBps, uint256 treasuryBps)
func (_FeeRouter *FeeRouterCallerSession) FeeSplit() (struct {
	LpBps        *big.Int
	PromoBps     *big.Int
	InsuranceBps *big.Int
	TreasuryBps  *big.Int
}, error) {
	return _FeeRouter.Contract.FeeSplit(&_FeeRouter.CallOpts)
}

// GetFeeStats is a free data retrieval call binding the contract method 0x2a1c5342.
//
// Solidity: function getFeeStats(address token) view returns(uint256 totalReceived, uint256 totalReferral, uint256 totalLP, uint256 totalPromo, uint256 totalInsurance, uint256 totalTreasury)
func (_FeeRouter *FeeRouterCaller) GetFeeStats(opts *bind.CallOpts, token common.Address) (struct {
	TotalReceived  *big.Int
	TotalReferral  *big.Int
	TotalLP        *big.Int
	TotalPromo     *big.Int
	TotalInsurance *big.Int
	TotalTreasury  *big.Int
}, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "getFeeStats", token)

	outstruct := new(struct {
		TotalReceived  *big.Int
		TotalReferral  *big.Int
		TotalLP        *big.Int
		TotalPromo     *big.Int
		TotalInsurance *big.Int
		TotalTreasury  *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.TotalReceived = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.TotalReferral = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.TotalLP = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.TotalPromo = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.TotalInsurance = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)
	outstruct.TotalTreasury = *abi.ConvertType(out[5], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetFeeStats is a free data retrieval call binding the contract method 0x2a1c5342.
//
// Solidity: function getFeeStats(address token) view returns(uint256 totalReceived, uint256 totalReferral, uint256 totalLP, uint256 totalPromo, uint256 totalInsurance, uint256 totalTreasury)
func (_FeeRouter *FeeRouterSession) GetFeeStats(token common.Address) (struct {
	TotalReceived  *big.Int
	TotalReferral  *big.Int
	TotalLP        *big.Int
	TotalPromo     *big.Int
	TotalInsurance *big.Int
	TotalTreasury  *big.Int
}, error) {
	return _FeeRouter.Contract.GetFeeStats(&_FeeRouter.CallOpts, token)
}

// GetFeeStats is a free data retrieval call binding the contract method 0x2a1c5342.
//
// Solidity: function getFeeStats(address token) view returns(uint256 totalReceived, uint256 totalReferral, uint256 totalLP, uint256 totalPromo, uint256 totalInsurance, uint256 totalTreasury)
func (_FeeRouter *FeeRouterCallerSession) GetFeeStats(token common.Address) (struct {
	TotalReceived  *big.Int
	TotalReferral  *big.Int
	TotalLP        *big.Int
	TotalPromo     *big.Int
	TotalInsurance *big.Int
	TotalTreasury  *big.Int
}, error) {
	return _FeeRouter.Contract.GetFeeStats(&_FeeRouter.CallOpts, token)
}

// GetReferralBps is a free data retrieval call binding the contract method 0x481e68e7.
//
// Solidity: function getReferralBps(address user) view returns(uint256)
func (_FeeRouter *FeeRouterCaller) GetReferralBps(opts *bind.CallOpts, user common.Address) (*big.Int, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "getReferralBps", user)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetReferralBps is a free data retrieval call binding the contract method 0x481e68e7.
//
// Solidity: function getReferralBps(address user) view returns(uint256)
func (_FeeRouter *FeeRouterSession) GetReferralBps(user common.Address) (*big.Int, error) {
	return _FeeRouter.Contract.GetReferralBps(&_FeeRouter.CallOpts, user)
}

// GetReferralBps is a free data retrieval call binding the contract method 0x481e68e7.
//
// Solidity: function getReferralBps(address user) view returns(uint256)
func (_FeeRouter *FeeRouterCallerSession) GetReferralBps(user common.Address) (*big.Int, error) {
	return _FeeRouter.Contract.GetReferralBps(&_FeeRouter.CallOpts, user)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_FeeRouter *FeeRouterCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_FeeRouter *FeeRouterSession) Owner() (common.Address, error) {
	return _FeeRouter.Contract.Owner(&_FeeRouter.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_FeeRouter *FeeRouterCallerSession) Owner() (common.Address, error) {
	return _FeeRouter.Contract.Owner(&_FeeRouter.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_FeeRouter *FeeRouterCaller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_FeeRouter *FeeRouterSession) Paused() (bool, error) {
	return _FeeRouter.Contract.Paused(&_FeeRouter.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_FeeRouter *FeeRouterCallerSession) Paused() (bool, error) {
	return _FeeRouter.Contract.Paused(&_FeeRouter.CallOpts)
}

// PreviewFeeSplit is a free data retrieval call binding the contract method 0x1f25fac1.
//
// Solidity: function previewFeeSplit(uint256 amount, bool hasReferrer) view returns(uint256 referralAmount, uint256 lpAmount, uint256 promoAmount, uint256 insuranceAmount, uint256 treasuryAmount)
func (_FeeRouter *FeeRouterCaller) PreviewFeeSplit(opts *bind.CallOpts, amount *big.Int, hasReferrer bool) (struct {
	ReferralAmount  *big.Int
	LpAmount        *big.Int
	PromoAmount     *big.Int
	InsuranceAmount *big.Int
	TreasuryAmount  *big.Int
}, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "previewFeeSplit", amount, hasReferrer)

	outstruct := new(struct {
		ReferralAmount  *big.Int
		LpAmount        *big.Int
		PromoAmount     *big.Int
		InsuranceAmount *big.Int
		TreasuryAmount  *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.ReferralAmount = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.LpAmount = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.PromoAmount = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.InsuranceAmount = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.TreasuryAmount = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// PreviewFeeSplit is a free data retrieval call binding the contract method 0x1f25fac1.
//
// Solidity: function previewFeeSplit(uint256 amount, bool hasReferrer) view returns(uint256 referralAmount, uint256 lpAmount, uint256 promoAmount, uint256 insuranceAmount, uint256 treasuryAmount)
func (_FeeRouter *FeeRouterSession) PreviewFeeSplit(amount *big.Int, hasReferrer bool) (struct {
	ReferralAmount  *big.Int
	LpAmount        *big.Int
	PromoAmount     *big.Int
	InsuranceAmount *big.Int
	TreasuryAmount  *big.Int
}, error) {
	return _FeeRouter.Contract.PreviewFeeSplit(&_FeeRouter.CallOpts, amount, hasReferrer)
}

// PreviewFeeSplit is a free data retrieval call binding the contract method 0x1f25fac1.
//
// Solidity: function previewFeeSplit(uint256 amount, bool hasReferrer) view returns(uint256 referralAmount, uint256 lpAmount, uint256 promoAmount, uint256 insuranceAmount, uint256 treasuryAmount)
func (_FeeRouter *FeeRouterCallerSession) PreviewFeeSplit(amount *big.Int, hasReferrer bool) (struct {
	ReferralAmount  *big.Int
	LpAmount        *big.Int
	PromoAmount     *big.Int
	InsuranceAmount *big.Int
	TreasuryAmount  *big.Int
}, error) {
	return _FeeRouter.Contract.PreviewFeeSplit(&_FeeRouter.CallOpts, amount, hasReferrer)
}

// Recipients is a free data retrieval call binding the contract method 0x0e57d4ce.
//
// Solidity: function recipients() view returns(address lpVault, address promoPool, address insuranceFund, address treasury)
func (_FeeRouter *FeeRouterCaller) Recipients(opts *bind.CallOpts) (struct {
	LpVault       common.Address
	PromoPool     common.Address
	InsuranceFund common.Address
	Treasury      common.Address
}, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "recipients")

	outstruct := new(struct {
		LpVault       common.Address
		PromoPool     common.Address
		InsuranceFund common.Address
		Treasury      common.Address
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.LpVault = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.PromoPool = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	outstruct.InsuranceFund = *abi.ConvertType(out[2], new(common.Address)).(*common.Address)
	outstruct.Treasury = *abi.ConvertType(out[3], new(common.Address)).(*common.Address)

	return *outstruct, err

}

// Recipients is a free data retrieval call binding the contract method 0x0e57d4ce.
//
// Solidity: function recipients() view returns(address lpVault, address promoPool, address insuranceFund, address treasury)
func (_FeeRouter *FeeRouterSession) Recipients() (struct {
	LpVault       common.Address
	PromoPool     common.Address
	InsuranceFund common.Address
	Treasury      common.Address
}, error) {
	return _FeeRouter.Contract.Recipients(&_FeeRouter.CallOpts)
}

// Recipients is a free data retrieval call binding the contract method 0x0e57d4ce.
//
// Solidity: function recipients() view returns(address lpVault, address promoPool, address insuranceFund, address treasury)
func (_FeeRouter *FeeRouterCallerSession) Recipients() (struct {
	LpVault       common.Address
	PromoPool     common.Address
	InsuranceFund common.Address
	Treasury      common.Address
}, error) {
	return _FeeRouter.Contract.Recipients(&_FeeRouter.CallOpts)
}

// ReferralRegistry is a free data retrieval call binding the contract method 0x4e627e62.
//
// Solidity: function referralRegistry() view returns(address)
func (_FeeRouter *FeeRouterCaller) ReferralRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "referralRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ReferralRegistry is a free data retrieval call binding the contract method 0x4e627e62.
//
// Solidity: function referralRegistry() view returns(address)
func (_FeeRouter *FeeRouterSession) ReferralRegistry() (common.Address, error) {
	return _FeeRouter.Contract.ReferralRegistry(&_FeeRouter.CallOpts)
}

// ReferralRegistry is a free data retrieval call binding the contract method 0x4e627e62.
//
// Solidity: function referralRegistry() view returns(address)
func (_FeeRouter *FeeRouterCallerSession) ReferralRegistry() (common.Address, error) {
	return _FeeRouter.Contract.ReferralRegistry(&_FeeRouter.CallOpts)
}

// TotalFeesDistributed is a free data retrieval call binding the contract method 0x0497368d.
//
// Solidity: function totalFeesDistributed(address , string ) view returns(uint256)
func (_FeeRouter *FeeRouterCaller) TotalFeesDistributed(opts *bind.CallOpts, arg0 common.Address, arg1 string) (*big.Int, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "totalFeesDistributed", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalFeesDistributed is a free data retrieval call binding the contract method 0x0497368d.
//
// Solidity: function totalFeesDistributed(address , string ) view returns(uint256)
func (_FeeRouter *FeeRouterSession) TotalFeesDistributed(arg0 common.Address, arg1 string) (*big.Int, error) {
	return _FeeRouter.Contract.TotalFeesDistributed(&_FeeRouter.CallOpts, arg0, arg1)
}

// TotalFeesDistributed is a free data retrieval call binding the contract method 0x0497368d.
//
// Solidity: function totalFeesDistributed(address , string ) view returns(uint256)
func (_FeeRouter *FeeRouterCallerSession) TotalFeesDistributed(arg0 common.Address, arg1 string) (*big.Int, error) {
	return _FeeRouter.Contract.TotalFeesDistributed(&_FeeRouter.CallOpts, arg0, arg1)
}

// TotalFeesReceived is a free data retrieval call binding the contract method 0xa886ec37.
//
// Solidity: function totalFeesReceived(address ) view returns(uint256)
func (_FeeRouter *FeeRouterCaller) TotalFeesReceived(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _FeeRouter.contract.Call(opts, &out, "totalFeesReceived", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalFeesReceived is a free data retrieval call binding the contract method 0xa886ec37.
//
// Solidity: function totalFeesReceived(address ) view returns(uint256)
func (_FeeRouter *FeeRouterSession) TotalFeesReceived(arg0 common.Address) (*big.Int, error) {
	return _FeeRouter.Contract.TotalFeesReceived(&_FeeRouter.CallOpts, arg0)
}

// TotalFeesReceived is a free data retrieval call binding the contract method 0xa886ec37.
//
// Solidity: function totalFeesReceived(address ) view returns(uint256)
func (_FeeRouter *FeeRouterCallerSession) TotalFeesReceived(arg0 common.Address) (*big.Int, error) {
	return _FeeRouter.Contract.TotalFeesReceived(&_FeeRouter.CallOpts, arg0)
}

// ProcessSingleFee is a paid mutator transaction binding the contract method 0x40e3170a.
//
// Solidity: function _processSingleFee(address token, address user, uint256 amount) returns()
func (_FeeRouter *FeeRouterTransactor) ProcessSingleFee(opts *bind.TransactOpts, token common.Address, user common.Address, amount *big.Int) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "_processSingleFee", token, user, amount)
}

// ProcessSingleFee is a paid mutator transaction binding the contract method 0x40e3170a.
//
// Solidity: function _processSingleFee(address token, address user, uint256 amount) returns()
func (_FeeRouter *FeeRouterSession) ProcessSingleFee(token common.Address, user common.Address, amount *big.Int) (*types.Transaction, error) {
	return _FeeRouter.Contract.ProcessSingleFee(&_FeeRouter.TransactOpts, token, user, amount)
}

// ProcessSingleFee is a paid mutator transaction binding the contract method 0x40e3170a.
//
// Solidity: function _processSingleFee(address token, address user, uint256 amount) returns()
func (_FeeRouter *FeeRouterTransactorSession) ProcessSingleFee(token common.Address, user common.Address, amount *big.Int) (*types.Transaction, error) {
	return _FeeRouter.Contract.ProcessSingleFee(&_FeeRouter.TransactOpts, token, user, amount)
}

// BatchRouteFee is a paid mutator transaction binding the contract method 0x6677b4ac.
//
// Solidity: function batchRouteFee(address token, address[] users, uint256[] amounts) returns(uint256 successCount, uint256[] failedIndices)
func (_FeeRouter *FeeRouterTransactor) BatchRouteFee(opts *bind.TransactOpts, token common.Address, users []common.Address, amounts []*big.Int) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "batchRouteFee", token, users, amounts)
}

// BatchRouteFee is a paid mutator transaction binding the contract method 0x6677b4ac.
//
// Solidity: function batchRouteFee(address token, address[] users, uint256[] amounts) returns(uint256 successCount, uint256[] failedIndices)
func (_FeeRouter *FeeRouterSession) BatchRouteFee(token common.Address, users []common.Address, amounts []*big.Int) (*types.Transaction, error) {
	return _FeeRouter.Contract.BatchRouteFee(&_FeeRouter.TransactOpts, token, users, amounts)
}

// BatchRouteFee is a paid mutator transaction binding the contract method 0x6677b4ac.
//
// Solidity: function batchRouteFee(address token, address[] users, uint256[] amounts) returns(uint256 successCount, uint256[] failedIndices)
func (_FeeRouter *FeeRouterTransactorSession) BatchRouteFee(token common.Address, users []common.Address, amounts []*big.Int) (*types.Transaction, error) {
	return _FeeRouter.Contract.BatchRouteFee(&_FeeRouter.TransactOpts, token, users, amounts)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0xe63ea408.
//
// Solidity: function emergencyWithdraw(address token, address to, uint256 amount) returns()
func (_FeeRouter *FeeRouterTransactor) EmergencyWithdraw(opts *bind.TransactOpts, token common.Address, to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "emergencyWithdraw", token, to, amount)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0xe63ea408.
//
// Solidity: function emergencyWithdraw(address token, address to, uint256 amount) returns()
func (_FeeRouter *FeeRouterSession) EmergencyWithdraw(token common.Address, to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _FeeRouter.Contract.EmergencyWithdraw(&_FeeRouter.TransactOpts, token, to, amount)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0xe63ea408.
//
// Solidity: function emergencyWithdraw(address token, address to, uint256 amount) returns()
func (_FeeRouter *FeeRouterTransactorSession) EmergencyWithdraw(token common.Address, to common.Address, amount *big.Int) (*types.Transaction, error) {
	return _FeeRouter.Contract.EmergencyWithdraw(&_FeeRouter.TransactOpts, token, to, amount)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_FeeRouter *FeeRouterTransactor) Pause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "pause")
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_FeeRouter *FeeRouterSession) Pause() (*types.Transaction, error) {
	return _FeeRouter.Contract.Pause(&_FeeRouter.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_FeeRouter *FeeRouterTransactorSession) Pause() (*types.Transaction, error) {
	return _FeeRouter.Contract.Pause(&_FeeRouter.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_FeeRouter *FeeRouterTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_FeeRouter *FeeRouterSession) RenounceOwnership() (*types.Transaction, error) {
	return _FeeRouter.Contract.RenounceOwnership(&_FeeRouter.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_FeeRouter *FeeRouterTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _FeeRouter.Contract.RenounceOwnership(&_FeeRouter.TransactOpts)
}

// RouteFee is a paid mutator transaction binding the contract method 0x39cfe0fb.
//
// Solidity: function routeFee(address token, address from, uint256 feeAmount, uint256 betAmount) returns()
func (_FeeRouter *FeeRouterTransactor) RouteFee(opts *bind.TransactOpts, token common.Address, from common.Address, feeAmount *big.Int, betAmount *big.Int) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "routeFee", token, from, feeAmount, betAmount)
}

// RouteFee is a paid mutator transaction binding the contract method 0x39cfe0fb.
//
// Solidity: function routeFee(address token, address from, uint256 feeAmount, uint256 betAmount) returns()
func (_FeeRouter *FeeRouterSession) RouteFee(token common.Address, from common.Address, feeAmount *big.Int, betAmount *big.Int) (*types.Transaction, error) {
	return _FeeRouter.Contract.RouteFee(&_FeeRouter.TransactOpts, token, from, feeAmount, betAmount)
}

// RouteFee is a paid mutator transaction binding the contract method 0x39cfe0fb.
//
// Solidity: function routeFee(address token, address from, uint256 feeAmount, uint256 betAmount) returns()
func (_FeeRouter *FeeRouterTransactorSession) RouteFee(token common.Address, from common.Address, feeAmount *big.Int, betAmount *big.Int) (*types.Transaction, error) {
	return _FeeRouter.Contract.RouteFee(&_FeeRouter.TransactOpts, token, from, feeAmount, betAmount)
}

// SetFeeSplit is a paid mutator transaction binding the contract method 0x337b8359.
//
// Solidity: function setFeeSplit(uint256 _lpBps, uint256 _promoBps, uint256 _insuranceBps, uint256 _treasuryBps) returns()
func (_FeeRouter *FeeRouterTransactor) SetFeeSplit(opts *bind.TransactOpts, _lpBps *big.Int, _promoBps *big.Int, _insuranceBps *big.Int, _treasuryBps *big.Int) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "setFeeSplit", _lpBps, _promoBps, _insuranceBps, _treasuryBps)
}

// SetFeeSplit is a paid mutator transaction binding the contract method 0x337b8359.
//
// Solidity: function setFeeSplit(uint256 _lpBps, uint256 _promoBps, uint256 _insuranceBps, uint256 _treasuryBps) returns()
func (_FeeRouter *FeeRouterSession) SetFeeSplit(_lpBps *big.Int, _promoBps *big.Int, _insuranceBps *big.Int, _treasuryBps *big.Int) (*types.Transaction, error) {
	return _FeeRouter.Contract.SetFeeSplit(&_FeeRouter.TransactOpts, _lpBps, _promoBps, _insuranceBps, _treasuryBps)
}

// SetFeeSplit is a paid mutator transaction binding the contract method 0x337b8359.
//
// Solidity: function setFeeSplit(uint256 _lpBps, uint256 _promoBps, uint256 _insuranceBps, uint256 _treasuryBps) returns()
func (_FeeRouter *FeeRouterTransactorSession) SetFeeSplit(_lpBps *big.Int, _promoBps *big.Int, _insuranceBps *big.Int, _treasuryBps *big.Int) (*types.Transaction, error) {
	return _FeeRouter.Contract.SetFeeSplit(&_FeeRouter.TransactOpts, _lpBps, _promoBps, _insuranceBps, _treasuryBps)
}

// SetRecipients is a paid mutator transaction binding the contract method 0xf855803a.
//
// Solidity: function setRecipients((address,address,address,address) _recipients) returns()
func (_FeeRouter *FeeRouterTransactor) SetRecipients(opts *bind.TransactOpts, _recipients FeeRouterFeeRecipients) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "setRecipients", _recipients)
}

// SetRecipients is a paid mutator transaction binding the contract method 0xf855803a.
//
// Solidity: function setRecipients((address,address,address,address) _recipients) returns()
func (_FeeRouter *FeeRouterSession) SetRecipients(_recipients FeeRouterFeeRecipients) (*types.Transaction, error) {
	return _FeeRouter.Contract.SetRecipients(&_FeeRouter.TransactOpts, _recipients)
}

// SetRecipients is a paid mutator transaction binding the contract method 0xf855803a.
//
// Solidity: function setRecipients((address,address,address,address) _recipients) returns()
func (_FeeRouter *FeeRouterTransactorSession) SetRecipients(_recipients FeeRouterFeeRecipients) (*types.Transaction, error) {
	return _FeeRouter.Contract.SetRecipients(&_FeeRouter.TransactOpts, _recipients)
}

// SetReferralRegistry is a paid mutator transaction binding the contract method 0x6a79115f.
//
// Solidity: function setReferralRegistry(address _registry) returns()
func (_FeeRouter *FeeRouterTransactor) SetReferralRegistry(opts *bind.TransactOpts, _registry common.Address) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "setReferralRegistry", _registry)
}

// SetReferralRegistry is a paid mutator transaction binding the contract method 0x6a79115f.
//
// Solidity: function setReferralRegistry(address _registry) returns()
func (_FeeRouter *FeeRouterSession) SetReferralRegistry(_registry common.Address) (*types.Transaction, error) {
	return _FeeRouter.Contract.SetReferralRegistry(&_FeeRouter.TransactOpts, _registry)
}

// SetReferralRegistry is a paid mutator transaction binding the contract method 0x6a79115f.
//
// Solidity: function setReferralRegistry(address _registry) returns()
func (_FeeRouter *FeeRouterTransactorSession) SetReferralRegistry(_registry common.Address) (*types.Transaction, error) {
	return _FeeRouter.Contract.SetReferralRegistry(&_FeeRouter.TransactOpts, _registry)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_FeeRouter *FeeRouterTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_FeeRouter *FeeRouterSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _FeeRouter.Contract.TransferOwnership(&_FeeRouter.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_FeeRouter *FeeRouterTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _FeeRouter.Contract.TransferOwnership(&_FeeRouter.TransactOpts, newOwner)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_FeeRouter *FeeRouterTransactor) Unpause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FeeRouter.contract.Transact(opts, "unpause")
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_FeeRouter *FeeRouterSession) Unpause() (*types.Transaction, error) {
	return _FeeRouter.Contract.Unpause(&_FeeRouter.TransactOpts)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_FeeRouter *FeeRouterTransactorSession) Unpause() (*types.Transaction, error) {
	return _FeeRouter.Contract.Unpause(&_FeeRouter.TransactOpts)
}

// FeeRouterBatchProcessedIterator is returned from FilterBatchProcessed and is used to iterate over the raw logs and unpacked data for BatchProcessed events raised by the FeeRouter contract.
type FeeRouterBatchProcessedIterator struct {
	Event *FeeRouterBatchProcessed // Event containing the contract specifics and raw log

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
func (it *FeeRouterBatchProcessedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeRouterBatchProcessed)
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
		it.Event = new(FeeRouterBatchProcessed)
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
func (it *FeeRouterBatchProcessedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeRouterBatchProcessedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeRouterBatchProcessed represents a BatchProcessed event raised by the FeeRouter contract.
type FeeRouterBatchProcessed struct {
	Token             common.Address
	TotalCount        *big.Int
	SuccessCount      *big.Int
	FailedCount       *big.Int
	FailedTotalAmount *big.Int
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterBatchProcessed is a free log retrieval operation binding the contract event 0x0cd68c9cd70f349d237b58d4feedc317704b55ea758c98d20a81a6b624df0d85.
//
// Solidity: event BatchProcessed(address indexed token, uint256 totalCount, uint256 successCount, uint256 failedCount, uint256 failedTotalAmount)
func (_FeeRouter *FeeRouterFilterer) FilterBatchProcessed(opts *bind.FilterOpts, token []common.Address) (*FeeRouterBatchProcessedIterator, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}

	logs, sub, err := _FeeRouter.contract.FilterLogs(opts, "BatchProcessed", tokenRule)
	if err != nil {
		return nil, err
	}
	return &FeeRouterBatchProcessedIterator{contract: _FeeRouter.contract, event: "BatchProcessed", logs: logs, sub: sub}, nil
}

// WatchBatchProcessed is a free log subscription operation binding the contract event 0x0cd68c9cd70f349d237b58d4feedc317704b55ea758c98d20a81a6b624df0d85.
//
// Solidity: event BatchProcessed(address indexed token, uint256 totalCount, uint256 successCount, uint256 failedCount, uint256 failedTotalAmount)
func (_FeeRouter *FeeRouterFilterer) WatchBatchProcessed(opts *bind.WatchOpts, sink chan<- *FeeRouterBatchProcessed, token []common.Address) (event.Subscription, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}

	logs, sub, err := _FeeRouter.contract.WatchLogs(opts, "BatchProcessed", tokenRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeRouterBatchProcessed)
				if err := _FeeRouter.contract.UnpackLog(event, "BatchProcessed", log); err != nil {
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

// ParseBatchProcessed is a log parse operation binding the contract event 0x0cd68c9cd70f349d237b58d4feedc317704b55ea758c98d20a81a6b624df0d85.
//
// Solidity: event BatchProcessed(address indexed token, uint256 totalCount, uint256 successCount, uint256 failedCount, uint256 failedTotalAmount)
func (_FeeRouter *FeeRouterFilterer) ParseBatchProcessed(log types.Log) (*FeeRouterBatchProcessed, error) {
	event := new(FeeRouterBatchProcessed)
	if err := _FeeRouter.contract.UnpackLog(event, "BatchProcessed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FeeRouterFeeReceivedIterator is returned from FilterFeeReceived and is used to iterate over the raw logs and unpacked data for FeeReceived events raised by the FeeRouter contract.
type FeeRouterFeeReceivedIterator struct {
	Event *FeeRouterFeeReceived // Event containing the contract specifics and raw log

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
func (it *FeeRouterFeeReceivedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeRouterFeeReceived)
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
		it.Event = new(FeeRouterFeeReceived)
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
func (it *FeeRouterFeeReceivedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeRouterFeeReceivedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeRouterFeeReceived represents a FeeReceived event raised by the FeeRouter contract.
type FeeRouterFeeReceived struct {
	Token  common.Address
	From   common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterFeeReceived is a free log retrieval operation binding the contract event 0xb976ce971d9fe55f355fa5ff14a6ad1f520b70b700c7dcc5921ca0a64a2da26a.
//
// Solidity: event FeeReceived(address indexed token, address indexed from, uint256 amount)
func (_FeeRouter *FeeRouterFilterer) FilterFeeReceived(opts *bind.FilterOpts, token []common.Address, from []common.Address) (*FeeRouterFeeReceivedIterator, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}

	logs, sub, err := _FeeRouter.contract.FilterLogs(opts, "FeeReceived", tokenRule, fromRule)
	if err != nil {
		return nil, err
	}
	return &FeeRouterFeeReceivedIterator{contract: _FeeRouter.contract, event: "FeeReceived", logs: logs, sub: sub}, nil
}

// WatchFeeReceived is a free log subscription operation binding the contract event 0xb976ce971d9fe55f355fa5ff14a6ad1f520b70b700c7dcc5921ca0a64a2da26a.
//
// Solidity: event FeeReceived(address indexed token, address indexed from, uint256 amount)
func (_FeeRouter *FeeRouterFilterer) WatchFeeReceived(opts *bind.WatchOpts, sink chan<- *FeeRouterFeeReceived, token []common.Address, from []common.Address) (event.Subscription, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}

	logs, sub, err := _FeeRouter.contract.WatchLogs(opts, "FeeReceived", tokenRule, fromRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeRouterFeeReceived)
				if err := _FeeRouter.contract.UnpackLog(event, "FeeReceived", log); err != nil {
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

// ParseFeeReceived is a log parse operation binding the contract event 0xb976ce971d9fe55f355fa5ff14a6ad1f520b70b700c7dcc5921ca0a64a2da26a.
//
// Solidity: event FeeReceived(address indexed token, address indexed from, uint256 amount)
func (_FeeRouter *FeeRouterFilterer) ParseFeeReceived(log types.Log) (*FeeRouterFeeReceived, error) {
	event := new(FeeRouterFeeReceived)
	if err := _FeeRouter.contract.UnpackLog(event, "FeeReceived", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FeeRouterFeeRoutedIterator is returned from FilterFeeRouted and is used to iterate over the raw logs and unpacked data for FeeRouted events raised by the FeeRouter contract.
type FeeRouterFeeRoutedIterator struct {
	Event *FeeRouterFeeRouted // Event containing the contract specifics and raw log

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
func (it *FeeRouterFeeRoutedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeRouterFeeRouted)
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
		it.Event = new(FeeRouterFeeRouted)
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
func (it *FeeRouterFeeRoutedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeRouterFeeRoutedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeRouterFeeRouted represents a FeeRouted event raised by the FeeRouter contract.
type FeeRouterFeeRouted struct {
	Token           common.Address
	TotalAmount     *big.Int
	Referrer        common.Address
	ReferralAmount  *big.Int
	LpAmount        *big.Int
	PromoAmount     *big.Int
	InsuranceAmount *big.Int
	TreasuryAmount  *big.Int
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterFeeRouted is a free log retrieval operation binding the contract event 0x1fc620251935ccc479c1907fafda90d2fbe6cceb3aaa693c39e5616893803b54.
//
// Solidity: event FeeRouted(address indexed token, uint256 totalAmount, address indexed referrer, uint256 referralAmount, uint256 lpAmount, uint256 promoAmount, uint256 insuranceAmount, uint256 treasuryAmount)
func (_FeeRouter *FeeRouterFilterer) FilterFeeRouted(opts *bind.FilterOpts, token []common.Address, referrer []common.Address) (*FeeRouterFeeRoutedIterator, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}

	var referrerRule []interface{}
	for _, referrerItem := range referrer {
		referrerRule = append(referrerRule, referrerItem)
	}

	logs, sub, err := _FeeRouter.contract.FilterLogs(opts, "FeeRouted", tokenRule, referrerRule)
	if err != nil {
		return nil, err
	}
	return &FeeRouterFeeRoutedIterator{contract: _FeeRouter.contract, event: "FeeRouted", logs: logs, sub: sub}, nil
}

// WatchFeeRouted is a free log subscription operation binding the contract event 0x1fc620251935ccc479c1907fafda90d2fbe6cceb3aaa693c39e5616893803b54.
//
// Solidity: event FeeRouted(address indexed token, uint256 totalAmount, address indexed referrer, uint256 referralAmount, uint256 lpAmount, uint256 promoAmount, uint256 insuranceAmount, uint256 treasuryAmount)
func (_FeeRouter *FeeRouterFilterer) WatchFeeRouted(opts *bind.WatchOpts, sink chan<- *FeeRouterFeeRouted, token []common.Address, referrer []common.Address) (event.Subscription, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}

	var referrerRule []interface{}
	for _, referrerItem := range referrer {
		referrerRule = append(referrerRule, referrerItem)
	}

	logs, sub, err := _FeeRouter.contract.WatchLogs(opts, "FeeRouted", tokenRule, referrerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeRouterFeeRouted)
				if err := _FeeRouter.contract.UnpackLog(event, "FeeRouted", log); err != nil {
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

// ParseFeeRouted is a log parse operation binding the contract event 0x1fc620251935ccc479c1907fafda90d2fbe6cceb3aaa693c39e5616893803b54.
//
// Solidity: event FeeRouted(address indexed token, uint256 totalAmount, address indexed referrer, uint256 referralAmount, uint256 lpAmount, uint256 promoAmount, uint256 insuranceAmount, uint256 treasuryAmount)
func (_FeeRouter *FeeRouterFilterer) ParseFeeRouted(log types.Log) (*FeeRouterFeeRouted, error) {
	event := new(FeeRouterFeeRouted)
	if err := _FeeRouter.contract.UnpackLog(event, "FeeRouted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FeeRouterFeeSplitUpdatedIterator is returned from FilterFeeSplitUpdated and is used to iterate over the raw logs and unpacked data for FeeSplitUpdated events raised by the FeeRouter contract.
type FeeRouterFeeSplitUpdatedIterator struct {
	Event *FeeRouterFeeSplitUpdated // Event containing the contract specifics and raw log

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
func (it *FeeRouterFeeSplitUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeRouterFeeSplitUpdated)
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
		it.Event = new(FeeRouterFeeSplitUpdated)
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
func (it *FeeRouterFeeSplitUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeRouterFeeSplitUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeRouterFeeSplitUpdated represents a FeeSplitUpdated event raised by the FeeRouter contract.
type FeeRouterFeeSplitUpdated struct {
	LpBps        *big.Int
	PromoBps     *big.Int
	InsuranceBps *big.Int
	TreasuryBps  *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterFeeSplitUpdated is a free log retrieval operation binding the contract event 0x3e06464b95ceefb7b040944739b512f3d4fd2eaf9036b59773dfe9829b2b90c1.
//
// Solidity: event FeeSplitUpdated(uint256 lpBps, uint256 promoBps, uint256 insuranceBps, uint256 treasuryBps)
func (_FeeRouter *FeeRouterFilterer) FilterFeeSplitUpdated(opts *bind.FilterOpts) (*FeeRouterFeeSplitUpdatedIterator, error) {

	logs, sub, err := _FeeRouter.contract.FilterLogs(opts, "FeeSplitUpdated")
	if err != nil {
		return nil, err
	}
	return &FeeRouterFeeSplitUpdatedIterator{contract: _FeeRouter.contract, event: "FeeSplitUpdated", logs: logs, sub: sub}, nil
}

// WatchFeeSplitUpdated is a free log subscription operation binding the contract event 0x3e06464b95ceefb7b040944739b512f3d4fd2eaf9036b59773dfe9829b2b90c1.
//
// Solidity: event FeeSplitUpdated(uint256 lpBps, uint256 promoBps, uint256 insuranceBps, uint256 treasuryBps)
func (_FeeRouter *FeeRouterFilterer) WatchFeeSplitUpdated(opts *bind.WatchOpts, sink chan<- *FeeRouterFeeSplitUpdated) (event.Subscription, error) {

	logs, sub, err := _FeeRouter.contract.WatchLogs(opts, "FeeSplitUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeRouterFeeSplitUpdated)
				if err := _FeeRouter.contract.UnpackLog(event, "FeeSplitUpdated", log); err != nil {
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

// ParseFeeSplitUpdated is a log parse operation binding the contract event 0x3e06464b95ceefb7b040944739b512f3d4fd2eaf9036b59773dfe9829b2b90c1.
//
// Solidity: event FeeSplitUpdated(uint256 lpBps, uint256 promoBps, uint256 insuranceBps, uint256 treasuryBps)
func (_FeeRouter *FeeRouterFilterer) ParseFeeSplitUpdated(log types.Log) (*FeeRouterFeeSplitUpdated, error) {
	event := new(FeeRouterFeeSplitUpdated)
	if err := _FeeRouter.contract.UnpackLog(event, "FeeSplitUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FeeRouterOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the FeeRouter contract.
type FeeRouterOwnershipTransferredIterator struct {
	Event *FeeRouterOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *FeeRouterOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeRouterOwnershipTransferred)
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
		it.Event = new(FeeRouterOwnershipTransferred)
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
func (it *FeeRouterOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeRouterOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeRouterOwnershipTransferred represents a OwnershipTransferred event raised by the FeeRouter contract.
type FeeRouterOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_FeeRouter *FeeRouterFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*FeeRouterOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _FeeRouter.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &FeeRouterOwnershipTransferredIterator{contract: _FeeRouter.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_FeeRouter *FeeRouterFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *FeeRouterOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _FeeRouter.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeRouterOwnershipTransferred)
				if err := _FeeRouter.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_FeeRouter *FeeRouterFilterer) ParseOwnershipTransferred(log types.Log) (*FeeRouterOwnershipTransferred, error) {
	event := new(FeeRouterOwnershipTransferred)
	if err := _FeeRouter.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FeeRouterPausedIterator is returned from FilterPaused and is used to iterate over the raw logs and unpacked data for Paused events raised by the FeeRouter contract.
type FeeRouterPausedIterator struct {
	Event *FeeRouterPaused // Event containing the contract specifics and raw log

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
func (it *FeeRouterPausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeRouterPaused)
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
		it.Event = new(FeeRouterPaused)
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
func (it *FeeRouterPausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeRouterPausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeRouterPaused represents a Paused event raised by the FeeRouter contract.
type FeeRouterPaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterPaused is a free log retrieval operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_FeeRouter *FeeRouterFilterer) FilterPaused(opts *bind.FilterOpts) (*FeeRouterPausedIterator, error) {

	logs, sub, err := _FeeRouter.contract.FilterLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return &FeeRouterPausedIterator{contract: _FeeRouter.contract, event: "Paused", logs: logs, sub: sub}, nil
}

// WatchPaused is a free log subscription operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_FeeRouter *FeeRouterFilterer) WatchPaused(opts *bind.WatchOpts, sink chan<- *FeeRouterPaused) (event.Subscription, error) {

	logs, sub, err := _FeeRouter.contract.WatchLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeRouterPaused)
				if err := _FeeRouter.contract.UnpackLog(event, "Paused", log); err != nil {
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
func (_FeeRouter *FeeRouterFilterer) ParsePaused(log types.Log) (*FeeRouterPaused, error) {
	event := new(FeeRouterPaused)
	if err := _FeeRouter.contract.UnpackLog(event, "Paused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FeeRouterRecipientsUpdatedIterator is returned from FilterRecipientsUpdated and is used to iterate over the raw logs and unpacked data for RecipientsUpdated events raised by the FeeRouter contract.
type FeeRouterRecipientsUpdatedIterator struct {
	Event *FeeRouterRecipientsUpdated // Event containing the contract specifics and raw log

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
func (it *FeeRouterRecipientsUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeRouterRecipientsUpdated)
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
		it.Event = new(FeeRouterRecipientsUpdated)
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
func (it *FeeRouterRecipientsUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeRouterRecipientsUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeRouterRecipientsUpdated represents a RecipientsUpdated event raised by the FeeRouter contract.
type FeeRouterRecipientsUpdated struct {
	LpVault       common.Address
	PromoPool     common.Address
	InsuranceFund common.Address
	Treasury      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterRecipientsUpdated is a free log retrieval operation binding the contract event 0x682f8dc4331d4e55b1ef6b5af96b69fff0b19eeb08ca4a4f51e1cd56d9ab7951.
//
// Solidity: event RecipientsUpdated(address lpVault, address promoPool, address insuranceFund, address treasury)
func (_FeeRouter *FeeRouterFilterer) FilterRecipientsUpdated(opts *bind.FilterOpts) (*FeeRouterRecipientsUpdatedIterator, error) {

	logs, sub, err := _FeeRouter.contract.FilterLogs(opts, "RecipientsUpdated")
	if err != nil {
		return nil, err
	}
	return &FeeRouterRecipientsUpdatedIterator{contract: _FeeRouter.contract, event: "RecipientsUpdated", logs: logs, sub: sub}, nil
}

// WatchRecipientsUpdated is a free log subscription operation binding the contract event 0x682f8dc4331d4e55b1ef6b5af96b69fff0b19eeb08ca4a4f51e1cd56d9ab7951.
//
// Solidity: event RecipientsUpdated(address lpVault, address promoPool, address insuranceFund, address treasury)
func (_FeeRouter *FeeRouterFilterer) WatchRecipientsUpdated(opts *bind.WatchOpts, sink chan<- *FeeRouterRecipientsUpdated) (event.Subscription, error) {

	logs, sub, err := _FeeRouter.contract.WatchLogs(opts, "RecipientsUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeRouterRecipientsUpdated)
				if err := _FeeRouter.contract.UnpackLog(event, "RecipientsUpdated", log); err != nil {
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

// ParseRecipientsUpdated is a log parse operation binding the contract event 0x682f8dc4331d4e55b1ef6b5af96b69fff0b19eeb08ca4a4f51e1cd56d9ab7951.
//
// Solidity: event RecipientsUpdated(address lpVault, address promoPool, address insuranceFund, address treasury)
func (_FeeRouter *FeeRouterFilterer) ParseRecipientsUpdated(log types.Log) (*FeeRouterRecipientsUpdated, error) {
	event := new(FeeRouterRecipientsUpdated)
	if err := _FeeRouter.contract.UnpackLog(event, "RecipientsUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FeeRouterReferralRegistryUpdatedIterator is returned from FilterReferralRegistryUpdated and is used to iterate over the raw logs and unpacked data for ReferralRegistryUpdated events raised by the FeeRouter contract.
type FeeRouterReferralRegistryUpdatedIterator struct {
	Event *FeeRouterReferralRegistryUpdated // Event containing the contract specifics and raw log

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
func (it *FeeRouterReferralRegistryUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeRouterReferralRegistryUpdated)
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
		it.Event = new(FeeRouterReferralRegistryUpdated)
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
func (it *FeeRouterReferralRegistryUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeRouterReferralRegistryUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeRouterReferralRegistryUpdated represents a ReferralRegistryUpdated event raised by the FeeRouter contract.
type FeeRouterReferralRegistryUpdated struct {
	NewRegistry common.Address
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterReferralRegistryUpdated is a free log retrieval operation binding the contract event 0x9d4414af8d61d821c1ad25f0aadfa28aa386c452716a31fc1f7fdbd9b9d364dc.
//
// Solidity: event ReferralRegistryUpdated(address indexed newRegistry)
func (_FeeRouter *FeeRouterFilterer) FilterReferralRegistryUpdated(opts *bind.FilterOpts, newRegistry []common.Address) (*FeeRouterReferralRegistryUpdatedIterator, error) {

	var newRegistryRule []interface{}
	for _, newRegistryItem := range newRegistry {
		newRegistryRule = append(newRegistryRule, newRegistryItem)
	}

	logs, sub, err := _FeeRouter.contract.FilterLogs(opts, "ReferralRegistryUpdated", newRegistryRule)
	if err != nil {
		return nil, err
	}
	return &FeeRouterReferralRegistryUpdatedIterator{contract: _FeeRouter.contract, event: "ReferralRegistryUpdated", logs: logs, sub: sub}, nil
}

// WatchReferralRegistryUpdated is a free log subscription operation binding the contract event 0x9d4414af8d61d821c1ad25f0aadfa28aa386c452716a31fc1f7fdbd9b9d364dc.
//
// Solidity: event ReferralRegistryUpdated(address indexed newRegistry)
func (_FeeRouter *FeeRouterFilterer) WatchReferralRegistryUpdated(opts *bind.WatchOpts, sink chan<- *FeeRouterReferralRegistryUpdated, newRegistry []common.Address) (event.Subscription, error) {

	var newRegistryRule []interface{}
	for _, newRegistryItem := range newRegistry {
		newRegistryRule = append(newRegistryRule, newRegistryItem)
	}

	logs, sub, err := _FeeRouter.contract.WatchLogs(opts, "ReferralRegistryUpdated", newRegistryRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeRouterReferralRegistryUpdated)
				if err := _FeeRouter.contract.UnpackLog(event, "ReferralRegistryUpdated", log); err != nil {
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

// ParseReferralRegistryUpdated is a log parse operation binding the contract event 0x9d4414af8d61d821c1ad25f0aadfa28aa386c452716a31fc1f7fdbd9b9d364dc.
//
// Solidity: event ReferralRegistryUpdated(address indexed newRegistry)
func (_FeeRouter *FeeRouterFilterer) ParseReferralRegistryUpdated(log types.Log) (*FeeRouterReferralRegistryUpdated, error) {
	event := new(FeeRouterReferralRegistryUpdated)
	if err := _FeeRouter.contract.UnpackLog(event, "ReferralRegistryUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// FeeRouterUnpausedIterator is returned from FilterUnpaused and is used to iterate over the raw logs and unpacked data for Unpaused events raised by the FeeRouter contract.
type FeeRouterUnpausedIterator struct {
	Event *FeeRouterUnpaused // Event containing the contract specifics and raw log

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
func (it *FeeRouterUnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FeeRouterUnpaused)
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
		it.Event = new(FeeRouterUnpaused)
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
func (it *FeeRouterUnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FeeRouterUnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FeeRouterUnpaused represents a Unpaused event raised by the FeeRouter contract.
type FeeRouterUnpaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUnpaused is a free log retrieval operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_FeeRouter *FeeRouterFilterer) FilterUnpaused(opts *bind.FilterOpts) (*FeeRouterUnpausedIterator, error) {

	logs, sub, err := _FeeRouter.contract.FilterLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return &FeeRouterUnpausedIterator{contract: _FeeRouter.contract, event: "Unpaused", logs: logs, sub: sub}, nil
}

// WatchUnpaused is a free log subscription operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_FeeRouter *FeeRouterFilterer) WatchUnpaused(opts *bind.WatchOpts, sink chan<- *FeeRouterUnpaused) (event.Subscription, error) {

	logs, sub, err := _FeeRouter.contract.WatchLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FeeRouterUnpaused)
				if err := _FeeRouter.contract.UnpackLog(event, "Unpaused", log); err != nil {
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
func (_FeeRouter *FeeRouterFilterer) ParseUnpaused(log types.Log) (*FeeRouterUnpaused, error) {
	event := new(FeeRouterUnpaused)
	if err := _FeeRouter.contract.UnpackLog(event, "Unpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
