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

// MarketBaseMetaData contains all meta data concerning the MarketBase contract.
var MarketBaseMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfBatch\",\"inputs\":[{\"name\":\"accounts\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"calculateFee\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"fee\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"discountOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIFeeDiscountOracle\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"disputePeriod\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"feeRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"feeRecipient\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"finalize\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getUserPosition\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isApprovedForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"lock\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"lockTimestamp\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"outcomeCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"outcomeLiquidity\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"placeBet\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"redeem\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"payout\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resolve\",\"inputs\":[{\"name\":\"winningOutcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resolveFromOracle\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resultOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIResultOracle\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"safeBatchTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDiscountOracle\",\"inputs\":[{\"name\":\"_discountOracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setFeeRate\",\"inputs\":[{\"name\":\"_feeRate\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setFeeRecipient\",\"inputs\":[{\"name\":\"_feeRecipient\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setResultOracle\",\"inputs\":[{\"name\":\"_resultOracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"settlementToken\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIERC20\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"status\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumIMarket.MarketStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalLiquidity\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"uri\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"winningOutcome\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"ApprovalForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BetPlaced\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"fee\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DiscountOracleUpdated\",\"inputs\":[{\"name\":\"oldOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Finalized\",\"inputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Locked\",\"inputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Redeemed\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"payout\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Resolved\",\"inputs\":[{\"name\":\"winningOutcome\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResolvedWithOracle\",\"inputs\":[{\"name\":\"winningOutcome\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"resultHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResultOracleUpdated\",\"inputs\":[{\"name\":\"newOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferBatch\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferSingle\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"URI\",\"inputs\":[{\"name\":\"value\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ERC1155InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"tokenId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidArrayLength\",\"inputs\":[{\"name\":\"idsLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"valuesLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidOperator\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155MissingApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// MarketBaseABI is the input ABI used to generate the binding from.
// Deprecated: Use MarketBaseMetaData.ABI instead.
var MarketBaseABI = MarketBaseMetaData.ABI

// MarketBase is an auto generated Go binding around an Ethereum contract.
type MarketBase struct {
	MarketBaseCaller     // Read-only binding to the contract
	MarketBaseTransactor // Write-only binding to the contract
	MarketBaseFilterer   // Log filterer for contract events
}

// MarketBaseCaller is an auto generated read-only Go binding around an Ethereum contract.
type MarketBaseCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketBaseTransactor is an auto generated write-only Go binding around an Ethereum contract.
type MarketBaseTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketBaseFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MarketBaseFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketBaseSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MarketBaseSession struct {
	Contract     *MarketBase       // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// MarketBaseCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MarketBaseCallerSession struct {
	Contract *MarketBaseCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts     // Call options to use throughout this session
}

// MarketBaseTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MarketBaseTransactorSession struct {
	Contract     *MarketBaseTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts     // Transaction auth options to use throughout this session
}

// MarketBaseRaw is an auto generated low-level Go binding around an Ethereum contract.
type MarketBaseRaw struct {
	Contract *MarketBase // Generic contract binding to access the raw methods on
}

// MarketBaseCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MarketBaseCallerRaw struct {
	Contract *MarketBaseCaller // Generic read-only contract binding to access the raw methods on
}

// MarketBaseTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MarketBaseTransactorRaw struct {
	Contract *MarketBaseTransactor // Generic write-only contract binding to access the raw methods on
}

// NewMarketBase creates a new instance of MarketBase, bound to a specific deployed contract.
func NewMarketBase(address common.Address, backend bind.ContractBackend) (*MarketBase, error) {
	contract, err := bindMarketBase(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MarketBase{MarketBaseCaller: MarketBaseCaller{contract: contract}, MarketBaseTransactor: MarketBaseTransactor{contract: contract}, MarketBaseFilterer: MarketBaseFilterer{contract: contract}}, nil
}

// NewMarketBaseCaller creates a new read-only instance of MarketBase, bound to a specific deployed contract.
func NewMarketBaseCaller(address common.Address, caller bind.ContractCaller) (*MarketBaseCaller, error) {
	contract, err := bindMarketBase(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MarketBaseCaller{contract: contract}, nil
}

// NewMarketBaseTransactor creates a new write-only instance of MarketBase, bound to a specific deployed contract.
func NewMarketBaseTransactor(address common.Address, transactor bind.ContractTransactor) (*MarketBaseTransactor, error) {
	contract, err := bindMarketBase(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MarketBaseTransactor{contract: contract}, nil
}

// NewMarketBaseFilterer creates a new log filterer instance of MarketBase, bound to a specific deployed contract.
func NewMarketBaseFilterer(address common.Address, filterer bind.ContractFilterer) (*MarketBaseFilterer, error) {
	contract, err := bindMarketBase(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MarketBaseFilterer{contract: contract}, nil
}

// bindMarketBase binds a generic wrapper to an already deployed contract.
func bindMarketBase(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := MarketBaseMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MarketBase *MarketBaseRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MarketBase.Contract.MarketBaseCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MarketBase *MarketBaseRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBase.Contract.MarketBaseTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MarketBase *MarketBaseRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MarketBase.Contract.MarketBaseTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MarketBase *MarketBaseCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MarketBase.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MarketBase *MarketBaseTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBase.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MarketBase *MarketBaseTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MarketBase.Contract.contract.Transact(opts, method, params...)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_MarketBase *MarketBaseCaller) BalanceOf(opts *bind.CallOpts, account common.Address, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "balanceOf", account, id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_MarketBase *MarketBaseSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _MarketBase.Contract.BalanceOf(&_MarketBase.CallOpts, account, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_MarketBase *MarketBaseCallerSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _MarketBase.Contract.BalanceOf(&_MarketBase.CallOpts, account, id)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_MarketBase *MarketBaseCaller) BalanceOfBatch(opts *bind.CallOpts, accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "balanceOfBatch", accounts, ids)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_MarketBase *MarketBaseSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _MarketBase.Contract.BalanceOfBatch(&_MarketBase.CallOpts, accounts, ids)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_MarketBase *MarketBaseCallerSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _MarketBase.Contract.BalanceOfBatch(&_MarketBase.CallOpts, accounts, ids)
}

// CalculateFee is a free data retrieval call binding the contract method 0x8b28ab1e.
//
// Solidity: function calculateFee(address user, uint256 amount) view returns(uint256 fee)
func (_MarketBase *MarketBaseCaller) CalculateFee(opts *bind.CallOpts, user common.Address, amount *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "calculateFee", user, amount)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// CalculateFee is a free data retrieval call binding the contract method 0x8b28ab1e.
//
// Solidity: function calculateFee(address user, uint256 amount) view returns(uint256 fee)
func (_MarketBase *MarketBaseSession) CalculateFee(user common.Address, amount *big.Int) (*big.Int, error) {
	return _MarketBase.Contract.CalculateFee(&_MarketBase.CallOpts, user, amount)
}

// CalculateFee is a free data retrieval call binding the contract method 0x8b28ab1e.
//
// Solidity: function calculateFee(address user, uint256 amount) view returns(uint256 fee)
func (_MarketBase *MarketBaseCallerSession) CalculateFee(user common.Address, amount *big.Int) (*big.Int, error) {
	return _MarketBase.Contract.CalculateFee(&_MarketBase.CallOpts, user, amount)
}

// DiscountOracle is a free data retrieval call binding the contract method 0xdac79060.
//
// Solidity: function discountOracle() view returns(address)
func (_MarketBase *MarketBaseCaller) DiscountOracle(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "discountOracle")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// DiscountOracle is a free data retrieval call binding the contract method 0xdac79060.
//
// Solidity: function discountOracle() view returns(address)
func (_MarketBase *MarketBaseSession) DiscountOracle() (common.Address, error) {
	return _MarketBase.Contract.DiscountOracle(&_MarketBase.CallOpts)
}

// DiscountOracle is a free data retrieval call binding the contract method 0xdac79060.
//
// Solidity: function discountOracle() view returns(address)
func (_MarketBase *MarketBaseCallerSession) DiscountOracle() (common.Address, error) {
	return _MarketBase.Contract.DiscountOracle(&_MarketBase.CallOpts)
}

// DisputePeriod is a free data retrieval call binding the contract method 0x5bf31d4d.
//
// Solidity: function disputePeriod() view returns(uint256)
func (_MarketBase *MarketBaseCaller) DisputePeriod(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "disputePeriod")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// DisputePeriod is a free data retrieval call binding the contract method 0x5bf31d4d.
//
// Solidity: function disputePeriod() view returns(uint256)
func (_MarketBase *MarketBaseSession) DisputePeriod() (*big.Int, error) {
	return _MarketBase.Contract.DisputePeriod(&_MarketBase.CallOpts)
}

// DisputePeriod is a free data retrieval call binding the contract method 0x5bf31d4d.
//
// Solidity: function disputePeriod() view returns(uint256)
func (_MarketBase *MarketBaseCallerSession) DisputePeriod() (*big.Int, error) {
	return _MarketBase.Contract.DisputePeriod(&_MarketBase.CallOpts)
}

// FeeRate is a free data retrieval call binding the contract method 0x978bbdb9.
//
// Solidity: function feeRate() view returns(uint256)
func (_MarketBase *MarketBaseCaller) FeeRate(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "feeRate")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// FeeRate is a free data retrieval call binding the contract method 0x978bbdb9.
//
// Solidity: function feeRate() view returns(uint256)
func (_MarketBase *MarketBaseSession) FeeRate() (*big.Int, error) {
	return _MarketBase.Contract.FeeRate(&_MarketBase.CallOpts)
}

// FeeRate is a free data retrieval call binding the contract method 0x978bbdb9.
//
// Solidity: function feeRate() view returns(uint256)
func (_MarketBase *MarketBaseCallerSession) FeeRate() (*big.Int, error) {
	return _MarketBase.Contract.FeeRate(&_MarketBase.CallOpts)
}

// FeeRecipient is a free data retrieval call binding the contract method 0x46904840.
//
// Solidity: function feeRecipient() view returns(address)
func (_MarketBase *MarketBaseCaller) FeeRecipient(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "feeRecipient")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// FeeRecipient is a free data retrieval call binding the contract method 0x46904840.
//
// Solidity: function feeRecipient() view returns(address)
func (_MarketBase *MarketBaseSession) FeeRecipient() (common.Address, error) {
	return _MarketBase.Contract.FeeRecipient(&_MarketBase.CallOpts)
}

// FeeRecipient is a free data retrieval call binding the contract method 0x46904840.
//
// Solidity: function feeRecipient() view returns(address)
func (_MarketBase *MarketBaseCallerSession) FeeRecipient() (common.Address, error) {
	return _MarketBase.Contract.FeeRecipient(&_MarketBase.CallOpts)
}

// GetUserPosition is a free data retrieval call binding the contract method 0x1c88ef1e.
//
// Solidity: function getUserPosition(address user, uint256 outcomeId) view returns(uint256)
func (_MarketBase *MarketBaseCaller) GetUserPosition(opts *bind.CallOpts, user common.Address, outcomeId *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "getUserPosition", user, outcomeId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetUserPosition is a free data retrieval call binding the contract method 0x1c88ef1e.
//
// Solidity: function getUserPosition(address user, uint256 outcomeId) view returns(uint256)
func (_MarketBase *MarketBaseSession) GetUserPosition(user common.Address, outcomeId *big.Int) (*big.Int, error) {
	return _MarketBase.Contract.GetUserPosition(&_MarketBase.CallOpts, user, outcomeId)
}

// GetUserPosition is a free data retrieval call binding the contract method 0x1c88ef1e.
//
// Solidity: function getUserPosition(address user, uint256 outcomeId) view returns(uint256)
func (_MarketBase *MarketBaseCallerSession) GetUserPosition(user common.Address, outcomeId *big.Int) (*big.Int, error) {
	return _MarketBase.Contract.GetUserPosition(&_MarketBase.CallOpts, user, outcomeId)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_MarketBase *MarketBaseCaller) IsApprovedForAll(opts *bind.CallOpts, account common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "isApprovedForAll", account, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_MarketBase *MarketBaseSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _MarketBase.Contract.IsApprovedForAll(&_MarketBase.CallOpts, account, operator)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_MarketBase *MarketBaseCallerSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _MarketBase.Contract.IsApprovedForAll(&_MarketBase.CallOpts, account, operator)
}

// LockTimestamp is a free data retrieval call binding the contract method 0xb544bf83.
//
// Solidity: function lockTimestamp() view returns(uint256)
func (_MarketBase *MarketBaseCaller) LockTimestamp(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "lockTimestamp")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LockTimestamp is a free data retrieval call binding the contract method 0xb544bf83.
//
// Solidity: function lockTimestamp() view returns(uint256)
func (_MarketBase *MarketBaseSession) LockTimestamp() (*big.Int, error) {
	return _MarketBase.Contract.LockTimestamp(&_MarketBase.CallOpts)
}

// LockTimestamp is a free data retrieval call binding the contract method 0xb544bf83.
//
// Solidity: function lockTimestamp() view returns(uint256)
func (_MarketBase *MarketBaseCallerSession) LockTimestamp() (*big.Int, error) {
	return _MarketBase.Contract.LockTimestamp(&_MarketBase.CallOpts)
}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256)
func (_MarketBase *MarketBaseCaller) OutcomeCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "outcomeCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256)
func (_MarketBase *MarketBaseSession) OutcomeCount() (*big.Int, error) {
	return _MarketBase.Contract.OutcomeCount(&_MarketBase.CallOpts)
}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256)
func (_MarketBase *MarketBaseCallerSession) OutcomeCount() (*big.Int, error) {
	return _MarketBase.Contract.OutcomeCount(&_MarketBase.CallOpts)
}

// OutcomeLiquidity is a free data retrieval call binding the contract method 0x3c5996e0.
//
// Solidity: function outcomeLiquidity(uint256 ) view returns(uint256)
func (_MarketBase *MarketBaseCaller) OutcomeLiquidity(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "outcomeLiquidity", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OutcomeLiquidity is a free data retrieval call binding the contract method 0x3c5996e0.
//
// Solidity: function outcomeLiquidity(uint256 ) view returns(uint256)
func (_MarketBase *MarketBaseSession) OutcomeLiquidity(arg0 *big.Int) (*big.Int, error) {
	return _MarketBase.Contract.OutcomeLiquidity(&_MarketBase.CallOpts, arg0)
}

// OutcomeLiquidity is a free data retrieval call binding the contract method 0x3c5996e0.
//
// Solidity: function outcomeLiquidity(uint256 ) view returns(uint256)
func (_MarketBase *MarketBaseCallerSession) OutcomeLiquidity(arg0 *big.Int) (*big.Int, error) {
	return _MarketBase.Contract.OutcomeLiquidity(&_MarketBase.CallOpts, arg0)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MarketBase *MarketBaseCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MarketBase *MarketBaseSession) Owner() (common.Address, error) {
	return _MarketBase.Contract.Owner(&_MarketBase.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MarketBase *MarketBaseCallerSession) Owner() (common.Address, error) {
	return _MarketBase.Contract.Owner(&_MarketBase.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketBase *MarketBaseCaller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketBase *MarketBaseSession) Paused() (bool, error) {
	return _MarketBase.Contract.Paused(&_MarketBase.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketBase *MarketBaseCallerSession) Paused() (bool, error) {
	return _MarketBase.Contract.Paused(&_MarketBase.CallOpts)
}

// ResultOracle is a free data retrieval call binding the contract method 0xc77e5042.
//
// Solidity: function resultOracle() view returns(address)
func (_MarketBase *MarketBaseCaller) ResultOracle(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "resultOracle")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ResultOracle is a free data retrieval call binding the contract method 0xc77e5042.
//
// Solidity: function resultOracle() view returns(address)
func (_MarketBase *MarketBaseSession) ResultOracle() (common.Address, error) {
	return _MarketBase.Contract.ResultOracle(&_MarketBase.CallOpts)
}

// ResultOracle is a free data retrieval call binding the contract method 0xc77e5042.
//
// Solidity: function resultOracle() view returns(address)
func (_MarketBase *MarketBaseCallerSession) ResultOracle() (common.Address, error) {
	return _MarketBase.Contract.ResultOracle(&_MarketBase.CallOpts)
}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_MarketBase *MarketBaseCaller) SettlementToken(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "settlementToken")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_MarketBase *MarketBaseSession) SettlementToken() (common.Address, error) {
	return _MarketBase.Contract.SettlementToken(&_MarketBase.CallOpts)
}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_MarketBase *MarketBaseCallerSession) SettlementToken() (common.Address, error) {
	return _MarketBase.Contract.SettlementToken(&_MarketBase.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_MarketBase *MarketBaseCaller) Status(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "status")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_MarketBase *MarketBaseSession) Status() (uint8, error) {
	return _MarketBase.Contract.Status(&_MarketBase.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_MarketBase *MarketBaseCallerSession) Status() (uint8, error) {
	return _MarketBase.Contract.Status(&_MarketBase.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketBase *MarketBaseCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketBase *MarketBaseSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _MarketBase.Contract.SupportsInterface(&_MarketBase.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketBase *MarketBaseCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _MarketBase.Contract.SupportsInterface(&_MarketBase.CallOpts, interfaceId)
}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_MarketBase *MarketBaseCaller) TotalLiquidity(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "totalLiquidity")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_MarketBase *MarketBaseSession) TotalLiquidity() (*big.Int, error) {
	return _MarketBase.Contract.TotalLiquidity(&_MarketBase.CallOpts)
}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_MarketBase *MarketBaseCallerSession) TotalLiquidity() (*big.Int, error) {
	return _MarketBase.Contract.TotalLiquidity(&_MarketBase.CallOpts)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_MarketBase *MarketBaseCaller) Uri(opts *bind.CallOpts, arg0 *big.Int) (string, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "uri", arg0)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_MarketBase *MarketBaseSession) Uri(arg0 *big.Int) (string, error) {
	return _MarketBase.Contract.Uri(&_MarketBase.CallOpts, arg0)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_MarketBase *MarketBaseCallerSession) Uri(arg0 *big.Int) (string, error) {
	return _MarketBase.Contract.Uri(&_MarketBase.CallOpts, arg0)
}

// WinningOutcome is a free data retrieval call binding the contract method 0x9b34ae03.
//
// Solidity: function winningOutcome() view returns(uint256)
func (_MarketBase *MarketBaseCaller) WinningOutcome(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketBase.contract.Call(opts, &out, "winningOutcome")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WinningOutcome is a free data retrieval call binding the contract method 0x9b34ae03.
//
// Solidity: function winningOutcome() view returns(uint256)
func (_MarketBase *MarketBaseSession) WinningOutcome() (*big.Int, error) {
	return _MarketBase.Contract.WinningOutcome(&_MarketBase.CallOpts)
}

// WinningOutcome is a free data retrieval call binding the contract method 0x9b34ae03.
//
// Solidity: function winningOutcome() view returns(uint256)
func (_MarketBase *MarketBaseCallerSession) WinningOutcome() (*big.Int, error) {
	return _MarketBase.Contract.WinningOutcome(&_MarketBase.CallOpts)
}

// Finalize is a paid mutator transaction binding the contract method 0x4bb278f3.
//
// Solidity: function finalize() returns()
func (_MarketBase *MarketBaseTransactor) Finalize(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "finalize")
}

// Finalize is a paid mutator transaction binding the contract method 0x4bb278f3.
//
// Solidity: function finalize() returns()
func (_MarketBase *MarketBaseSession) Finalize() (*types.Transaction, error) {
	return _MarketBase.Contract.Finalize(&_MarketBase.TransactOpts)
}

// Finalize is a paid mutator transaction binding the contract method 0x4bb278f3.
//
// Solidity: function finalize() returns()
func (_MarketBase *MarketBaseTransactorSession) Finalize() (*types.Transaction, error) {
	return _MarketBase.Contract.Finalize(&_MarketBase.TransactOpts)
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_MarketBase *MarketBaseTransactor) Lock(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "lock")
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_MarketBase *MarketBaseSession) Lock() (*types.Transaction, error) {
	return _MarketBase.Contract.Lock(&_MarketBase.TransactOpts)
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_MarketBase *MarketBaseTransactorSession) Lock() (*types.Transaction, error) {
	return _MarketBase.Contract.Lock(&_MarketBase.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketBase *MarketBaseTransactor) Pause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "pause")
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketBase *MarketBaseSession) Pause() (*types.Transaction, error) {
	return _MarketBase.Contract.Pause(&_MarketBase.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketBase *MarketBaseTransactorSession) Pause() (*types.Transaction, error) {
	return _MarketBase.Contract.Pause(&_MarketBase.TransactOpts)
}

// PlaceBet is a paid mutator transaction binding the contract method 0x4afe62b5.
//
// Solidity: function placeBet(uint256 outcomeId, uint256 amount) returns(uint256 shares)
func (_MarketBase *MarketBaseTransactor) PlaceBet(opts *bind.TransactOpts, outcomeId *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "placeBet", outcomeId, amount)
}

// PlaceBet is a paid mutator transaction binding the contract method 0x4afe62b5.
//
// Solidity: function placeBet(uint256 outcomeId, uint256 amount) returns(uint256 shares)
func (_MarketBase *MarketBaseSession) PlaceBet(outcomeId *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _MarketBase.Contract.PlaceBet(&_MarketBase.TransactOpts, outcomeId, amount)
}

// PlaceBet is a paid mutator transaction binding the contract method 0x4afe62b5.
//
// Solidity: function placeBet(uint256 outcomeId, uint256 amount) returns(uint256 shares)
func (_MarketBase *MarketBaseTransactorSession) PlaceBet(outcomeId *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _MarketBase.Contract.PlaceBet(&_MarketBase.TransactOpts, outcomeId, amount)
}

// Redeem is a paid mutator transaction binding the contract method 0x7cbc2373.
//
// Solidity: function redeem(uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_MarketBase *MarketBaseTransactor) Redeem(opts *bind.TransactOpts, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "redeem", outcomeId, shares)
}

// Redeem is a paid mutator transaction binding the contract method 0x7cbc2373.
//
// Solidity: function redeem(uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_MarketBase *MarketBaseSession) Redeem(outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketBase.Contract.Redeem(&_MarketBase.TransactOpts, outcomeId, shares)
}

// Redeem is a paid mutator transaction binding the contract method 0x7cbc2373.
//
// Solidity: function redeem(uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_MarketBase *MarketBaseTransactorSession) Redeem(outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _MarketBase.Contract.Redeem(&_MarketBase.TransactOpts, outcomeId, shares)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_MarketBase *MarketBaseTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_MarketBase *MarketBaseSession) RenounceOwnership() (*types.Transaction, error) {
	return _MarketBase.Contract.RenounceOwnership(&_MarketBase.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_MarketBase *MarketBaseTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _MarketBase.Contract.RenounceOwnership(&_MarketBase.TransactOpts)
}

// Resolve is a paid mutator transaction binding the contract method 0x4f896d4f.
//
// Solidity: function resolve(uint256 winningOutcomeId) returns()
func (_MarketBase *MarketBaseTransactor) Resolve(opts *bind.TransactOpts, winningOutcomeId *big.Int) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "resolve", winningOutcomeId)
}

// Resolve is a paid mutator transaction binding the contract method 0x4f896d4f.
//
// Solidity: function resolve(uint256 winningOutcomeId) returns()
func (_MarketBase *MarketBaseSession) Resolve(winningOutcomeId *big.Int) (*types.Transaction, error) {
	return _MarketBase.Contract.Resolve(&_MarketBase.TransactOpts, winningOutcomeId)
}

// Resolve is a paid mutator transaction binding the contract method 0x4f896d4f.
//
// Solidity: function resolve(uint256 winningOutcomeId) returns()
func (_MarketBase *MarketBaseTransactorSession) Resolve(winningOutcomeId *big.Int) (*types.Transaction, error) {
	return _MarketBase.Contract.Resolve(&_MarketBase.TransactOpts, winningOutcomeId)
}

// ResolveFromOracle is a paid mutator transaction binding the contract method 0x830ced86.
//
// Solidity: function resolveFromOracle() returns()
func (_MarketBase *MarketBaseTransactor) ResolveFromOracle(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "resolveFromOracle")
}

// ResolveFromOracle is a paid mutator transaction binding the contract method 0x830ced86.
//
// Solidity: function resolveFromOracle() returns()
func (_MarketBase *MarketBaseSession) ResolveFromOracle() (*types.Transaction, error) {
	return _MarketBase.Contract.ResolveFromOracle(&_MarketBase.TransactOpts)
}

// ResolveFromOracle is a paid mutator transaction binding the contract method 0x830ced86.
//
// Solidity: function resolveFromOracle() returns()
func (_MarketBase *MarketBaseTransactorSession) ResolveFromOracle() (*types.Transaction, error) {
	return _MarketBase.Contract.ResolveFromOracle(&_MarketBase.TransactOpts)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_MarketBase *MarketBaseTransactor) SafeBatchTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "safeBatchTransferFrom", from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_MarketBase *MarketBaseSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBase.Contract.SafeBatchTransferFrom(&_MarketBase.TransactOpts, from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_MarketBase *MarketBaseTransactorSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBase.Contract.SafeBatchTransferFrom(&_MarketBase.TransactOpts, from, to, ids, values, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_MarketBase *MarketBaseTransactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "safeTransferFrom", from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_MarketBase *MarketBaseSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBase.Contract.SafeTransferFrom(&_MarketBase.TransactOpts, from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_MarketBase *MarketBaseTransactorSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _MarketBase.Contract.SafeTransferFrom(&_MarketBase.TransactOpts, from, to, id, value, data)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_MarketBase *MarketBaseTransactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_MarketBase *MarketBaseSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _MarketBase.Contract.SetApprovalForAll(&_MarketBase.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_MarketBase *MarketBaseTransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _MarketBase.Contract.SetApprovalForAll(&_MarketBase.TransactOpts, operator, approved)
}

// SetDiscountOracle is a paid mutator transaction binding the contract method 0x0736251c.
//
// Solidity: function setDiscountOracle(address _discountOracle) returns()
func (_MarketBase *MarketBaseTransactor) SetDiscountOracle(opts *bind.TransactOpts, _discountOracle common.Address) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "setDiscountOracle", _discountOracle)
}

// SetDiscountOracle is a paid mutator transaction binding the contract method 0x0736251c.
//
// Solidity: function setDiscountOracle(address _discountOracle) returns()
func (_MarketBase *MarketBaseSession) SetDiscountOracle(_discountOracle common.Address) (*types.Transaction, error) {
	return _MarketBase.Contract.SetDiscountOracle(&_MarketBase.TransactOpts, _discountOracle)
}

// SetDiscountOracle is a paid mutator transaction binding the contract method 0x0736251c.
//
// Solidity: function setDiscountOracle(address _discountOracle) returns()
func (_MarketBase *MarketBaseTransactorSession) SetDiscountOracle(_discountOracle common.Address) (*types.Transaction, error) {
	return _MarketBase.Contract.SetDiscountOracle(&_MarketBase.TransactOpts, _discountOracle)
}

// SetFeeRate is a paid mutator transaction binding the contract method 0x45596e2e.
//
// Solidity: function setFeeRate(uint256 _feeRate) returns()
func (_MarketBase *MarketBaseTransactor) SetFeeRate(opts *bind.TransactOpts, _feeRate *big.Int) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "setFeeRate", _feeRate)
}

// SetFeeRate is a paid mutator transaction binding the contract method 0x45596e2e.
//
// Solidity: function setFeeRate(uint256 _feeRate) returns()
func (_MarketBase *MarketBaseSession) SetFeeRate(_feeRate *big.Int) (*types.Transaction, error) {
	return _MarketBase.Contract.SetFeeRate(&_MarketBase.TransactOpts, _feeRate)
}

// SetFeeRate is a paid mutator transaction binding the contract method 0x45596e2e.
//
// Solidity: function setFeeRate(uint256 _feeRate) returns()
func (_MarketBase *MarketBaseTransactorSession) SetFeeRate(_feeRate *big.Int) (*types.Transaction, error) {
	return _MarketBase.Contract.SetFeeRate(&_MarketBase.TransactOpts, _feeRate)
}

// SetFeeRecipient is a paid mutator transaction binding the contract method 0xe74b981b.
//
// Solidity: function setFeeRecipient(address _feeRecipient) returns()
func (_MarketBase *MarketBaseTransactor) SetFeeRecipient(opts *bind.TransactOpts, _feeRecipient common.Address) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "setFeeRecipient", _feeRecipient)
}

// SetFeeRecipient is a paid mutator transaction binding the contract method 0xe74b981b.
//
// Solidity: function setFeeRecipient(address _feeRecipient) returns()
func (_MarketBase *MarketBaseSession) SetFeeRecipient(_feeRecipient common.Address) (*types.Transaction, error) {
	return _MarketBase.Contract.SetFeeRecipient(&_MarketBase.TransactOpts, _feeRecipient)
}

// SetFeeRecipient is a paid mutator transaction binding the contract method 0xe74b981b.
//
// Solidity: function setFeeRecipient(address _feeRecipient) returns()
func (_MarketBase *MarketBaseTransactorSession) SetFeeRecipient(_feeRecipient common.Address) (*types.Transaction, error) {
	return _MarketBase.Contract.SetFeeRecipient(&_MarketBase.TransactOpts, _feeRecipient)
}

// SetResultOracle is a paid mutator transaction binding the contract method 0x17bc4648.
//
// Solidity: function setResultOracle(address _resultOracle) returns()
func (_MarketBase *MarketBaseTransactor) SetResultOracle(opts *bind.TransactOpts, _resultOracle common.Address) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "setResultOracle", _resultOracle)
}

// SetResultOracle is a paid mutator transaction binding the contract method 0x17bc4648.
//
// Solidity: function setResultOracle(address _resultOracle) returns()
func (_MarketBase *MarketBaseSession) SetResultOracle(_resultOracle common.Address) (*types.Transaction, error) {
	return _MarketBase.Contract.SetResultOracle(&_MarketBase.TransactOpts, _resultOracle)
}

// SetResultOracle is a paid mutator transaction binding the contract method 0x17bc4648.
//
// Solidity: function setResultOracle(address _resultOracle) returns()
func (_MarketBase *MarketBaseTransactorSession) SetResultOracle(_resultOracle common.Address) (*types.Transaction, error) {
	return _MarketBase.Contract.SetResultOracle(&_MarketBase.TransactOpts, _resultOracle)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MarketBase *MarketBaseTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MarketBase *MarketBaseSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _MarketBase.Contract.TransferOwnership(&_MarketBase.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MarketBase *MarketBaseTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _MarketBase.Contract.TransferOwnership(&_MarketBase.TransactOpts, newOwner)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketBase *MarketBaseTransactor) Unpause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketBase.contract.Transact(opts, "unpause")
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketBase *MarketBaseSession) Unpause() (*types.Transaction, error) {
	return _MarketBase.Contract.Unpause(&_MarketBase.TransactOpts)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketBase *MarketBaseTransactorSession) Unpause() (*types.Transaction, error) {
	return _MarketBase.Contract.Unpause(&_MarketBase.TransactOpts)
}

// MarketBaseApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the MarketBase contract.
type MarketBaseApprovalForAllIterator struct {
	Event *MarketBaseApprovalForAll // Event containing the contract specifics and raw log

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
func (it *MarketBaseApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseApprovalForAll)
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
		it.Event = new(MarketBaseApprovalForAll)
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
func (it *MarketBaseApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseApprovalForAll represents a ApprovalForAll event raised by the MarketBase contract.
type MarketBaseApprovalForAll struct {
	Account  common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_MarketBase *MarketBaseFilterer) FilterApprovalForAll(opts *bind.FilterOpts, account []common.Address, operator []common.Address) (*MarketBaseApprovalForAllIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseApprovalForAllIterator{contract: _MarketBase.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_MarketBase *MarketBaseFilterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *MarketBaseApprovalForAll, account []common.Address, operator []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseApprovalForAll)
				if err := _MarketBase.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseApprovalForAll(log types.Log) (*MarketBaseApprovalForAll, error) {
	event := new(MarketBaseApprovalForAll)
	if err := _MarketBase.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseBetPlacedIterator is returned from FilterBetPlaced and is used to iterate over the raw logs and unpacked data for BetPlaced events raised by the MarketBase contract.
type MarketBaseBetPlacedIterator struct {
	Event *MarketBaseBetPlaced // Event containing the contract specifics and raw log

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
func (it *MarketBaseBetPlacedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseBetPlaced)
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
		it.Event = new(MarketBaseBetPlaced)
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
func (it *MarketBaseBetPlacedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseBetPlacedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseBetPlaced represents a BetPlaced event raised by the MarketBase contract.
type MarketBaseBetPlaced struct {
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
func (_MarketBase *MarketBaseFilterer) FilterBetPlaced(opts *bind.FilterOpts, user []common.Address, outcomeId []*big.Int) (*MarketBaseBetPlacedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "BetPlaced", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseBetPlacedIterator{contract: _MarketBase.contract, event: "BetPlaced", logs: logs, sub: sub}, nil
}

// WatchBetPlaced is a free log subscription operation binding the contract event 0x935a8686694e2b5cc90f63054b327255f6fb92db3acd6d98c5a707d4987e93e1.
//
// Solidity: event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares, uint256 fee)
func (_MarketBase *MarketBaseFilterer) WatchBetPlaced(opts *bind.WatchOpts, sink chan<- *MarketBaseBetPlaced, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "BetPlaced", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseBetPlaced)
				if err := _MarketBase.contract.UnpackLog(event, "BetPlaced", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseBetPlaced(log types.Log) (*MarketBaseBetPlaced, error) {
	event := new(MarketBaseBetPlaced)
	if err := _MarketBase.contract.UnpackLog(event, "BetPlaced", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseDiscountOracleUpdatedIterator is returned from FilterDiscountOracleUpdated and is used to iterate over the raw logs and unpacked data for DiscountOracleUpdated events raised by the MarketBase contract.
type MarketBaseDiscountOracleUpdatedIterator struct {
	Event *MarketBaseDiscountOracleUpdated // Event containing the contract specifics and raw log

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
func (it *MarketBaseDiscountOracleUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseDiscountOracleUpdated)
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
		it.Event = new(MarketBaseDiscountOracleUpdated)
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
func (it *MarketBaseDiscountOracleUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseDiscountOracleUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseDiscountOracleUpdated represents a DiscountOracleUpdated event raised by the MarketBase contract.
type MarketBaseDiscountOracleUpdated struct {
	OldOracle common.Address
	NewOracle common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterDiscountOracleUpdated is a free log retrieval operation binding the contract event 0xb0a21792e739b32d34f3928764f774f8b8702f15d4b00f2e688689d23050aaa6.
//
// Solidity: event DiscountOracleUpdated(address indexed oldOracle, address indexed newOracle)
func (_MarketBase *MarketBaseFilterer) FilterDiscountOracleUpdated(opts *bind.FilterOpts, oldOracle []common.Address, newOracle []common.Address) (*MarketBaseDiscountOracleUpdatedIterator, error) {

	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "DiscountOracleUpdated", oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseDiscountOracleUpdatedIterator{contract: _MarketBase.contract, event: "DiscountOracleUpdated", logs: logs, sub: sub}, nil
}

// WatchDiscountOracleUpdated is a free log subscription operation binding the contract event 0xb0a21792e739b32d34f3928764f774f8b8702f15d4b00f2e688689d23050aaa6.
//
// Solidity: event DiscountOracleUpdated(address indexed oldOracle, address indexed newOracle)
func (_MarketBase *MarketBaseFilterer) WatchDiscountOracleUpdated(opts *bind.WatchOpts, sink chan<- *MarketBaseDiscountOracleUpdated, oldOracle []common.Address, newOracle []common.Address) (event.Subscription, error) {

	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "DiscountOracleUpdated", oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseDiscountOracleUpdated)
				if err := _MarketBase.contract.UnpackLog(event, "DiscountOracleUpdated", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseDiscountOracleUpdated(log types.Log) (*MarketBaseDiscountOracleUpdated, error) {
	event := new(MarketBaseDiscountOracleUpdated)
	if err := _MarketBase.contract.UnpackLog(event, "DiscountOracleUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseFinalizedIterator is returned from FilterFinalized and is used to iterate over the raw logs and unpacked data for Finalized events raised by the MarketBase contract.
type MarketBaseFinalizedIterator struct {
	Event *MarketBaseFinalized // Event containing the contract specifics and raw log

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
func (it *MarketBaseFinalizedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseFinalized)
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
		it.Event = new(MarketBaseFinalized)
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
func (it *MarketBaseFinalizedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseFinalizedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseFinalized represents a Finalized event raised by the MarketBase contract.
type MarketBaseFinalized struct {
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterFinalized is a free log retrieval operation binding the contract event 0x839cf22e1ba87ce2f5b9bbf46cf0175a09eed52febdfaac8852478e68203c763.
//
// Solidity: event Finalized(uint256 timestamp)
func (_MarketBase *MarketBaseFilterer) FilterFinalized(opts *bind.FilterOpts) (*MarketBaseFinalizedIterator, error) {

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "Finalized")
	if err != nil {
		return nil, err
	}
	return &MarketBaseFinalizedIterator{contract: _MarketBase.contract, event: "Finalized", logs: logs, sub: sub}, nil
}

// WatchFinalized is a free log subscription operation binding the contract event 0x839cf22e1ba87ce2f5b9bbf46cf0175a09eed52febdfaac8852478e68203c763.
//
// Solidity: event Finalized(uint256 timestamp)
func (_MarketBase *MarketBaseFilterer) WatchFinalized(opts *bind.WatchOpts, sink chan<- *MarketBaseFinalized) (event.Subscription, error) {

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "Finalized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseFinalized)
				if err := _MarketBase.contract.UnpackLog(event, "Finalized", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseFinalized(log types.Log) (*MarketBaseFinalized, error) {
	event := new(MarketBaseFinalized)
	if err := _MarketBase.contract.UnpackLog(event, "Finalized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseLockedIterator is returned from FilterLocked and is used to iterate over the raw logs and unpacked data for Locked events raised by the MarketBase contract.
type MarketBaseLockedIterator struct {
	Event *MarketBaseLocked // Event containing the contract specifics and raw log

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
func (it *MarketBaseLockedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseLocked)
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
		it.Event = new(MarketBaseLocked)
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
func (it *MarketBaseLockedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseLockedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseLocked represents a Locked event raised by the MarketBase contract.
type MarketBaseLocked struct {
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterLocked is a free log retrieval operation binding the contract event 0x032bc66be43dbccb7487781d168eb7bda224628a3b2c3388bdf69b532a3a1611.
//
// Solidity: event Locked(uint256 timestamp)
func (_MarketBase *MarketBaseFilterer) FilterLocked(opts *bind.FilterOpts) (*MarketBaseLockedIterator, error) {

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "Locked")
	if err != nil {
		return nil, err
	}
	return &MarketBaseLockedIterator{contract: _MarketBase.contract, event: "Locked", logs: logs, sub: sub}, nil
}

// WatchLocked is a free log subscription operation binding the contract event 0x032bc66be43dbccb7487781d168eb7bda224628a3b2c3388bdf69b532a3a1611.
//
// Solidity: event Locked(uint256 timestamp)
func (_MarketBase *MarketBaseFilterer) WatchLocked(opts *bind.WatchOpts, sink chan<- *MarketBaseLocked) (event.Subscription, error) {

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "Locked")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseLocked)
				if err := _MarketBase.contract.UnpackLog(event, "Locked", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseLocked(log types.Log) (*MarketBaseLocked, error) {
	event := new(MarketBaseLocked)
	if err := _MarketBase.contract.UnpackLog(event, "Locked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the MarketBase contract.
type MarketBaseOwnershipTransferredIterator struct {
	Event *MarketBaseOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *MarketBaseOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseOwnershipTransferred)
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
		it.Event = new(MarketBaseOwnershipTransferred)
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
func (it *MarketBaseOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseOwnershipTransferred represents a OwnershipTransferred event raised by the MarketBase contract.
type MarketBaseOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_MarketBase *MarketBaseFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*MarketBaseOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseOwnershipTransferredIterator{contract: _MarketBase.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_MarketBase *MarketBaseFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *MarketBaseOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseOwnershipTransferred)
				if err := _MarketBase.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseOwnershipTransferred(log types.Log) (*MarketBaseOwnershipTransferred, error) {
	event := new(MarketBaseOwnershipTransferred)
	if err := _MarketBase.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBasePausedIterator is returned from FilterPaused and is used to iterate over the raw logs and unpacked data for Paused events raised by the MarketBase contract.
type MarketBasePausedIterator struct {
	Event *MarketBasePaused // Event containing the contract specifics and raw log

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
func (it *MarketBasePausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBasePaused)
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
		it.Event = new(MarketBasePaused)
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
func (it *MarketBasePausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBasePausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBasePaused represents a Paused event raised by the MarketBase contract.
type MarketBasePaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterPaused is a free log retrieval operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_MarketBase *MarketBaseFilterer) FilterPaused(opts *bind.FilterOpts) (*MarketBasePausedIterator, error) {

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return &MarketBasePausedIterator{contract: _MarketBase.contract, event: "Paused", logs: logs, sub: sub}, nil
}

// WatchPaused is a free log subscription operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_MarketBase *MarketBaseFilterer) WatchPaused(opts *bind.WatchOpts, sink chan<- *MarketBasePaused) (event.Subscription, error) {

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBasePaused)
				if err := _MarketBase.contract.UnpackLog(event, "Paused", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParsePaused(log types.Log) (*MarketBasePaused, error) {
	event := new(MarketBasePaused)
	if err := _MarketBase.contract.UnpackLog(event, "Paused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseRedeemedIterator is returned from FilterRedeemed and is used to iterate over the raw logs and unpacked data for Redeemed events raised by the MarketBase contract.
type MarketBaseRedeemedIterator struct {
	Event *MarketBaseRedeemed // Event containing the contract specifics and raw log

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
func (it *MarketBaseRedeemedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseRedeemed)
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
		it.Event = new(MarketBaseRedeemed)
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
func (it *MarketBaseRedeemedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseRedeemedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseRedeemed represents a Redeemed event raised by the MarketBase contract.
type MarketBaseRedeemed struct {
	User      common.Address
	OutcomeId *big.Int
	Shares    *big.Int
	Payout    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterRedeemed is a free log retrieval operation binding the contract event 0x484c40561359f3e3b8be9101897f8680aa82fbe1df9fd9038e0dbc6284032646.
//
// Solidity: event Redeemed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketBase *MarketBaseFilterer) FilterRedeemed(opts *bind.FilterOpts, user []common.Address, outcomeId []*big.Int) (*MarketBaseRedeemedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "Redeemed", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseRedeemedIterator{contract: _MarketBase.contract, event: "Redeemed", logs: logs, sub: sub}, nil
}

// WatchRedeemed is a free log subscription operation binding the contract event 0x484c40561359f3e3b8be9101897f8680aa82fbe1df9fd9038e0dbc6284032646.
//
// Solidity: event Redeemed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_MarketBase *MarketBaseFilterer) WatchRedeemed(opts *bind.WatchOpts, sink chan<- *MarketBaseRedeemed, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "Redeemed", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseRedeemed)
				if err := _MarketBase.contract.UnpackLog(event, "Redeemed", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseRedeemed(log types.Log) (*MarketBaseRedeemed, error) {
	event := new(MarketBaseRedeemed)
	if err := _MarketBase.contract.UnpackLog(event, "Redeemed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseResolvedIterator is returned from FilterResolved and is used to iterate over the raw logs and unpacked data for Resolved events raised by the MarketBase contract.
type MarketBaseResolvedIterator struct {
	Event *MarketBaseResolved // Event containing the contract specifics and raw log

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
func (it *MarketBaseResolvedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseResolved)
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
		it.Event = new(MarketBaseResolved)
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
func (it *MarketBaseResolvedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseResolvedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseResolved represents a Resolved event raised by the MarketBase contract.
type MarketBaseResolved struct {
	WinningOutcome *big.Int
	Timestamp      *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterResolved is a free log retrieval operation binding the contract event 0x8a1cc9089f9efc6450ff2639ff6d6b27f6aaaac01cccae1789c0a36dffc21041.
//
// Solidity: event Resolved(uint256 indexed winningOutcome, uint256 timestamp)
func (_MarketBase *MarketBaseFilterer) FilterResolved(opts *bind.FilterOpts, winningOutcome []*big.Int) (*MarketBaseResolvedIterator, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "Resolved", winningOutcomeRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseResolvedIterator{contract: _MarketBase.contract, event: "Resolved", logs: logs, sub: sub}, nil
}

// WatchResolved is a free log subscription operation binding the contract event 0x8a1cc9089f9efc6450ff2639ff6d6b27f6aaaac01cccae1789c0a36dffc21041.
//
// Solidity: event Resolved(uint256 indexed winningOutcome, uint256 timestamp)
func (_MarketBase *MarketBaseFilterer) WatchResolved(opts *bind.WatchOpts, sink chan<- *MarketBaseResolved, winningOutcome []*big.Int) (event.Subscription, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "Resolved", winningOutcomeRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseResolved)
				if err := _MarketBase.contract.UnpackLog(event, "Resolved", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseResolved(log types.Log) (*MarketBaseResolved, error) {
	event := new(MarketBaseResolved)
	if err := _MarketBase.contract.UnpackLog(event, "Resolved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseResolvedWithOracleIterator is returned from FilterResolvedWithOracle and is used to iterate over the raw logs and unpacked data for ResolvedWithOracle events raised by the MarketBase contract.
type MarketBaseResolvedWithOracleIterator struct {
	Event *MarketBaseResolvedWithOracle // Event containing the contract specifics and raw log

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
func (it *MarketBaseResolvedWithOracleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseResolvedWithOracle)
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
		it.Event = new(MarketBaseResolvedWithOracle)
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
func (it *MarketBaseResolvedWithOracleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseResolvedWithOracleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseResolvedWithOracle represents a ResolvedWithOracle event raised by the MarketBase contract.
type MarketBaseResolvedWithOracle struct {
	WinningOutcome *big.Int
	ResultHash     [32]byte
	Timestamp      *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterResolvedWithOracle is a free log retrieval operation binding the contract event 0x483e2cc22780ed0b10a1da294bc4acc4d4b81340fdebab99bb0a346644b020b3.
//
// Solidity: event ResolvedWithOracle(uint256 indexed winningOutcome, bytes32 indexed resultHash, uint256 timestamp)
func (_MarketBase *MarketBaseFilterer) FilterResolvedWithOracle(opts *bind.FilterOpts, winningOutcome []*big.Int, resultHash [][32]byte) (*MarketBaseResolvedWithOracleIterator, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}
	var resultHashRule []interface{}
	for _, resultHashItem := range resultHash {
		resultHashRule = append(resultHashRule, resultHashItem)
	}

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "ResolvedWithOracle", winningOutcomeRule, resultHashRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseResolvedWithOracleIterator{contract: _MarketBase.contract, event: "ResolvedWithOracle", logs: logs, sub: sub}, nil
}

// WatchResolvedWithOracle is a free log subscription operation binding the contract event 0x483e2cc22780ed0b10a1da294bc4acc4d4b81340fdebab99bb0a346644b020b3.
//
// Solidity: event ResolvedWithOracle(uint256 indexed winningOutcome, bytes32 indexed resultHash, uint256 timestamp)
func (_MarketBase *MarketBaseFilterer) WatchResolvedWithOracle(opts *bind.WatchOpts, sink chan<- *MarketBaseResolvedWithOracle, winningOutcome []*big.Int, resultHash [][32]byte) (event.Subscription, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}
	var resultHashRule []interface{}
	for _, resultHashItem := range resultHash {
		resultHashRule = append(resultHashRule, resultHashItem)
	}

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "ResolvedWithOracle", winningOutcomeRule, resultHashRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseResolvedWithOracle)
				if err := _MarketBase.contract.UnpackLog(event, "ResolvedWithOracle", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseResolvedWithOracle(log types.Log) (*MarketBaseResolvedWithOracle, error) {
	event := new(MarketBaseResolvedWithOracle)
	if err := _MarketBase.contract.UnpackLog(event, "ResolvedWithOracle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseResultOracleUpdatedIterator is returned from FilterResultOracleUpdated and is used to iterate over the raw logs and unpacked data for ResultOracleUpdated events raised by the MarketBase contract.
type MarketBaseResultOracleUpdatedIterator struct {
	Event *MarketBaseResultOracleUpdated // Event containing the contract specifics and raw log

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
func (it *MarketBaseResultOracleUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseResultOracleUpdated)
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
		it.Event = new(MarketBaseResultOracleUpdated)
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
func (it *MarketBaseResultOracleUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseResultOracleUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseResultOracleUpdated represents a ResultOracleUpdated event raised by the MarketBase contract.
type MarketBaseResultOracleUpdated struct {
	NewOracle common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterResultOracleUpdated is a free log retrieval operation binding the contract event 0xf4f6d8a1c53b96aaa54cac2192218b21030f6371f0b3e3a0fb15124fa1f08e8d.
//
// Solidity: event ResultOracleUpdated(address indexed newOracle)
func (_MarketBase *MarketBaseFilterer) FilterResultOracleUpdated(opts *bind.FilterOpts, newOracle []common.Address) (*MarketBaseResultOracleUpdatedIterator, error) {

	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "ResultOracleUpdated", newOracleRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseResultOracleUpdatedIterator{contract: _MarketBase.contract, event: "ResultOracleUpdated", logs: logs, sub: sub}, nil
}

// WatchResultOracleUpdated is a free log subscription operation binding the contract event 0xf4f6d8a1c53b96aaa54cac2192218b21030f6371f0b3e3a0fb15124fa1f08e8d.
//
// Solidity: event ResultOracleUpdated(address indexed newOracle)
func (_MarketBase *MarketBaseFilterer) WatchResultOracleUpdated(opts *bind.WatchOpts, sink chan<- *MarketBaseResultOracleUpdated, newOracle []common.Address) (event.Subscription, error) {

	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "ResultOracleUpdated", newOracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseResultOracleUpdated)
				if err := _MarketBase.contract.UnpackLog(event, "ResultOracleUpdated", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseResultOracleUpdated(log types.Log) (*MarketBaseResultOracleUpdated, error) {
	event := new(MarketBaseResultOracleUpdated)
	if err := _MarketBase.contract.UnpackLog(event, "ResultOracleUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseTransferBatchIterator is returned from FilterTransferBatch and is used to iterate over the raw logs and unpacked data for TransferBatch events raised by the MarketBase contract.
type MarketBaseTransferBatchIterator struct {
	Event *MarketBaseTransferBatch // Event containing the contract specifics and raw log

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
func (it *MarketBaseTransferBatchIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseTransferBatch)
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
		it.Event = new(MarketBaseTransferBatch)
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
func (it *MarketBaseTransferBatchIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseTransferBatchIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseTransferBatch represents a TransferBatch event raised by the MarketBase contract.
type MarketBaseTransferBatch struct {
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
func (_MarketBase *MarketBaseFilterer) FilterTransferBatch(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*MarketBaseTransferBatchIterator, error) {

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

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseTransferBatchIterator{contract: _MarketBase.contract, event: "TransferBatch", logs: logs, sub: sub}, nil
}

// WatchTransferBatch is a free log subscription operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_MarketBase *MarketBaseFilterer) WatchTransferBatch(opts *bind.WatchOpts, sink chan<- *MarketBaseTransferBatch, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseTransferBatch)
				if err := _MarketBase.contract.UnpackLog(event, "TransferBatch", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseTransferBatch(log types.Log) (*MarketBaseTransferBatch, error) {
	event := new(MarketBaseTransferBatch)
	if err := _MarketBase.contract.UnpackLog(event, "TransferBatch", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseTransferSingleIterator is returned from FilterTransferSingle and is used to iterate over the raw logs and unpacked data for TransferSingle events raised by the MarketBase contract.
type MarketBaseTransferSingleIterator struct {
	Event *MarketBaseTransferSingle // Event containing the contract specifics and raw log

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
func (it *MarketBaseTransferSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseTransferSingle)
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
		it.Event = new(MarketBaseTransferSingle)
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
func (it *MarketBaseTransferSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseTransferSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseTransferSingle represents a TransferSingle event raised by the MarketBase contract.
type MarketBaseTransferSingle struct {
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
func (_MarketBase *MarketBaseFilterer) FilterTransferSingle(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*MarketBaseTransferSingleIterator, error) {

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

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseTransferSingleIterator{contract: _MarketBase.contract, event: "TransferSingle", logs: logs, sub: sub}, nil
}

// WatchTransferSingle is a free log subscription operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_MarketBase *MarketBaseFilterer) WatchTransferSingle(opts *bind.WatchOpts, sink chan<- *MarketBaseTransferSingle, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseTransferSingle)
				if err := _MarketBase.contract.UnpackLog(event, "TransferSingle", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseTransferSingle(log types.Log) (*MarketBaseTransferSingle, error) {
	event := new(MarketBaseTransferSingle)
	if err := _MarketBase.contract.UnpackLog(event, "TransferSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseURIIterator is returned from FilterURI and is used to iterate over the raw logs and unpacked data for URI events raised by the MarketBase contract.
type MarketBaseURIIterator struct {
	Event *MarketBaseURI // Event containing the contract specifics and raw log

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
func (it *MarketBaseURIIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseURI)
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
		it.Event = new(MarketBaseURI)
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
func (it *MarketBaseURIIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseURIIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseURI represents a URI event raised by the MarketBase contract.
type MarketBaseURI struct {
	Value string
	Id    *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterURI is a free log retrieval operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_MarketBase *MarketBaseFilterer) FilterURI(opts *bind.FilterOpts, id []*big.Int) (*MarketBaseURIIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return &MarketBaseURIIterator{contract: _MarketBase.contract, event: "URI", logs: logs, sub: sub}, nil
}

// WatchURI is a free log subscription operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_MarketBase *MarketBaseFilterer) WatchURI(opts *bind.WatchOpts, sink chan<- *MarketBaseURI, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseURI)
				if err := _MarketBase.contract.UnpackLog(event, "URI", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseURI(log types.Log) (*MarketBaseURI, error) {
	event := new(MarketBaseURI)
	if err := _MarketBase.contract.UnpackLog(event, "URI", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketBaseUnpausedIterator is returned from FilterUnpaused and is used to iterate over the raw logs and unpacked data for Unpaused events raised by the MarketBase contract.
type MarketBaseUnpausedIterator struct {
	Event *MarketBaseUnpaused // Event containing the contract specifics and raw log

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
func (it *MarketBaseUnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketBaseUnpaused)
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
		it.Event = new(MarketBaseUnpaused)
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
func (it *MarketBaseUnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketBaseUnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketBaseUnpaused represents a Unpaused event raised by the MarketBase contract.
type MarketBaseUnpaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUnpaused is a free log retrieval operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_MarketBase *MarketBaseFilterer) FilterUnpaused(opts *bind.FilterOpts) (*MarketBaseUnpausedIterator, error) {

	logs, sub, err := _MarketBase.contract.FilterLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return &MarketBaseUnpausedIterator{contract: _MarketBase.contract, event: "Unpaused", logs: logs, sub: sub}, nil
}

// WatchUnpaused is a free log subscription operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_MarketBase *MarketBaseFilterer) WatchUnpaused(opts *bind.WatchOpts, sink chan<- *MarketBaseUnpaused) (event.Subscription, error) {

	logs, sub, err := _MarketBase.contract.WatchLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketBaseUnpaused)
				if err := _MarketBase.contract.UnpackLog(event, "Unpaused", log); err != nil {
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
func (_MarketBase *MarketBaseFilterer) ParseUnpaused(log types.Log) (*MarketBaseUnpaused, error) {
	event := new(MarketBaseUnpaused)
	if err := _MarketBase.contract.UnpackLog(event, "Unpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
