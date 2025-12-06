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

// MarketFactoryV2TemplateInfo is an auto generated low-level Go binding around an user-defined struct.
type MarketFactoryV2TemplateInfo struct {
	Implementation common.Address
	Name           string
	Version        string
	Active         bool
	CreatedAt      *big.Int
	MarketCount    *big.Int
}

// MarketFactoryMetaData contains all meta data concerning the MarketFactory contract.
var MarketFactoryMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MARKET_CREATOR_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addMarketCreator\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addMarketCreators\",\"inputs\":[{\"name\":\"accounts\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"createMarket\",\"inputs\":[{\"name\":\"templateId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"initData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"createMarketDeterministic\",\"inputs\":[{\"name\":\"templateId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"salt\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"initData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAllTemplateIds\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMarket\",\"inputs\":[{\"name\":\"index\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMarketCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMarketOwners\",\"inputs\":[{\"name\":\"_markets\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[{\"name\":\"owners\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTemplateInfo\",\"inputs\":[{\"name\":\"templateId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structMarketFactory_v2.TemplateInfo\",\"components\":[{\"name\":\"implementation\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"version\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"active\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"marketCount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isMarket\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isMarketCreator\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isRegistered\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"marketOwner\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"marketTemplate\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"markets\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"predictMarketAddress\",\"inputs\":[{\"name\":\"templateId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"salt\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"recordMarket\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"templateId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"registerTemplate\",\"inputs\":[{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"version\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"implementation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"templateId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"removeMarketCreator\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setTemplateActive\",\"inputs\":[{\"name\":\"templateId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"active\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"templateIds\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"templates\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"implementation\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"version\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"active\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"createdAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"marketCount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferMarketOwnership\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateMarketOwnerRecord\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"MarketCreated\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"templateId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"creator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketCreatorAdded\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"admin\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketCreatorRemoved\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"admin\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketOwnershipTransferred\",\"inputs\":[{\"name\":\"market\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TemplateActiveStatusUpdated\",\"inputs\":[{\"name\":\"templateId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"active\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TemplateRegistered\",\"inputs\":[{\"name\":\"templateId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"implementation\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"name\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"version\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedDeployment\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InsufficientBalance\",\"inputs\":[{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}]",
}

// MarketFactoryABI is the input ABI used to generate the binding from.
// Deprecated: Use MarketFactoryMetaData.ABI instead.
var MarketFactoryABI = MarketFactoryMetaData.ABI

// MarketFactory is an auto generated Go binding around an Ethereum contract.
type MarketFactory struct {
	MarketFactoryCaller     // Read-only binding to the contract
	MarketFactoryTransactor // Write-only binding to the contract
	MarketFactoryFilterer   // Log filterer for contract events
}

// MarketFactoryCaller is an auto generated read-only Go binding around an Ethereum contract.
type MarketFactoryCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketFactoryTransactor is an auto generated write-only Go binding around an Ethereum contract.
type MarketFactoryTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketFactoryFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MarketFactoryFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MarketFactorySession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MarketFactorySession struct {
	Contract     *MarketFactory    // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// MarketFactoryCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MarketFactoryCallerSession struct {
	Contract *MarketFactoryCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts        // Call options to use throughout this session
}

// MarketFactoryTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MarketFactoryTransactorSession struct {
	Contract     *MarketFactoryTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts        // Transaction auth options to use throughout this session
}

// MarketFactoryRaw is an auto generated low-level Go binding around an Ethereum contract.
type MarketFactoryRaw struct {
	Contract *MarketFactory // Generic contract binding to access the raw methods on
}

// MarketFactoryCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MarketFactoryCallerRaw struct {
	Contract *MarketFactoryCaller // Generic read-only contract binding to access the raw methods on
}

// MarketFactoryTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MarketFactoryTransactorRaw struct {
	Contract *MarketFactoryTransactor // Generic write-only contract binding to access the raw methods on
}

// NewMarketFactory creates a new instance of MarketFactory, bound to a specific deployed contract.
func NewMarketFactory(address common.Address, backend bind.ContractBackend) (*MarketFactory, error) {
	contract, err := bindMarketFactory(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MarketFactory{MarketFactoryCaller: MarketFactoryCaller{contract: contract}, MarketFactoryTransactor: MarketFactoryTransactor{contract: contract}, MarketFactoryFilterer: MarketFactoryFilterer{contract: contract}}, nil
}

// NewMarketFactoryCaller creates a new read-only instance of MarketFactory, bound to a specific deployed contract.
func NewMarketFactoryCaller(address common.Address, caller bind.ContractCaller) (*MarketFactoryCaller, error) {
	contract, err := bindMarketFactory(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryCaller{contract: contract}, nil
}

// NewMarketFactoryTransactor creates a new write-only instance of MarketFactory, bound to a specific deployed contract.
func NewMarketFactoryTransactor(address common.Address, transactor bind.ContractTransactor) (*MarketFactoryTransactor, error) {
	contract, err := bindMarketFactory(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryTransactor{contract: contract}, nil
}

// NewMarketFactoryFilterer creates a new log filterer instance of MarketFactory, bound to a specific deployed contract.
func NewMarketFactoryFilterer(address common.Address, filterer bind.ContractFilterer) (*MarketFactoryFilterer, error) {
	contract, err := bindMarketFactory(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryFilterer{contract: contract}, nil
}

// bindMarketFactory binds a generic wrapper to an already deployed contract.
func bindMarketFactory(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := MarketFactoryMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MarketFactory *MarketFactoryRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MarketFactory.Contract.MarketFactoryCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MarketFactory *MarketFactoryRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketFactory.Contract.MarketFactoryTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MarketFactory *MarketFactoryRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MarketFactory.Contract.MarketFactoryTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MarketFactory *MarketFactoryCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MarketFactory.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MarketFactory *MarketFactoryTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketFactory.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MarketFactory *MarketFactoryTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MarketFactory.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_MarketFactory *MarketFactoryCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_MarketFactory *MarketFactorySession) DEFAULTADMINROLE() ([32]byte, error) {
	return _MarketFactory.Contract.DEFAULTADMINROLE(&_MarketFactory.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_MarketFactory *MarketFactoryCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _MarketFactory.Contract.DEFAULTADMINROLE(&_MarketFactory.CallOpts)
}

// MARKETCREATORROLE is a free data retrieval call binding the contract method 0xae42820c.
//
// Solidity: function MARKET_CREATOR_ROLE() view returns(bytes32)
func (_MarketFactory *MarketFactoryCaller) MARKETCREATORROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "MARKET_CREATOR_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// MARKETCREATORROLE is a free data retrieval call binding the contract method 0xae42820c.
//
// Solidity: function MARKET_CREATOR_ROLE() view returns(bytes32)
func (_MarketFactory *MarketFactorySession) MARKETCREATORROLE() ([32]byte, error) {
	return _MarketFactory.Contract.MARKETCREATORROLE(&_MarketFactory.CallOpts)
}

// MARKETCREATORROLE is a free data retrieval call binding the contract method 0xae42820c.
//
// Solidity: function MARKET_CREATOR_ROLE() view returns(bytes32)
func (_MarketFactory *MarketFactoryCallerSession) MARKETCREATORROLE() ([32]byte, error) {
	return _MarketFactory.Contract.MARKETCREATORROLE(&_MarketFactory.CallOpts)
}

// GetAllTemplateIds is a free data retrieval call binding the contract method 0xae24ccbc.
//
// Solidity: function getAllTemplateIds() view returns(bytes32[])
func (_MarketFactory *MarketFactoryCaller) GetAllTemplateIds(opts *bind.CallOpts) ([][32]byte, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "getAllTemplateIds")

	if err != nil {
		return *new([][32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([][32]byte)).(*[][32]byte)

	return out0, err

}

// GetAllTemplateIds is a free data retrieval call binding the contract method 0xae24ccbc.
//
// Solidity: function getAllTemplateIds() view returns(bytes32[])
func (_MarketFactory *MarketFactorySession) GetAllTemplateIds() ([][32]byte, error) {
	return _MarketFactory.Contract.GetAllTemplateIds(&_MarketFactory.CallOpts)
}

// GetAllTemplateIds is a free data retrieval call binding the contract method 0xae24ccbc.
//
// Solidity: function getAllTemplateIds() view returns(bytes32[])
func (_MarketFactory *MarketFactoryCallerSession) GetAllTemplateIds() ([][32]byte, error) {
	return _MarketFactory.Contract.GetAllTemplateIds(&_MarketFactory.CallOpts)
}

// GetMarket is a free data retrieval call binding the contract method 0xeb44fdd3.
//
// Solidity: function getMarket(uint256 index) view returns(address)
func (_MarketFactory *MarketFactoryCaller) GetMarket(opts *bind.CallOpts, index *big.Int) (common.Address, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "getMarket", index)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetMarket is a free data retrieval call binding the contract method 0xeb44fdd3.
//
// Solidity: function getMarket(uint256 index) view returns(address)
func (_MarketFactory *MarketFactorySession) GetMarket(index *big.Int) (common.Address, error) {
	return _MarketFactory.Contract.GetMarket(&_MarketFactory.CallOpts, index)
}

// GetMarket is a free data retrieval call binding the contract method 0xeb44fdd3.
//
// Solidity: function getMarket(uint256 index) view returns(address)
func (_MarketFactory *MarketFactoryCallerSession) GetMarket(index *big.Int) (common.Address, error) {
	return _MarketFactory.Contract.GetMarket(&_MarketFactory.CallOpts, index)
}

// GetMarketCount is a free data retrieval call binding the contract method 0xfd69f3c2.
//
// Solidity: function getMarketCount() view returns(uint256)
func (_MarketFactory *MarketFactoryCaller) GetMarketCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "getMarketCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetMarketCount is a free data retrieval call binding the contract method 0xfd69f3c2.
//
// Solidity: function getMarketCount() view returns(uint256)
func (_MarketFactory *MarketFactorySession) GetMarketCount() (*big.Int, error) {
	return _MarketFactory.Contract.GetMarketCount(&_MarketFactory.CallOpts)
}

// GetMarketCount is a free data retrieval call binding the contract method 0xfd69f3c2.
//
// Solidity: function getMarketCount() view returns(uint256)
func (_MarketFactory *MarketFactoryCallerSession) GetMarketCount() (*big.Int, error) {
	return _MarketFactory.Contract.GetMarketCount(&_MarketFactory.CallOpts)
}

// GetMarketOwners is a free data retrieval call binding the contract method 0xcb9ef74e.
//
// Solidity: function getMarketOwners(address[] _markets) view returns(address[] owners)
func (_MarketFactory *MarketFactoryCaller) GetMarketOwners(opts *bind.CallOpts, _markets []common.Address) ([]common.Address, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "getMarketOwners", _markets)

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetMarketOwners is a free data retrieval call binding the contract method 0xcb9ef74e.
//
// Solidity: function getMarketOwners(address[] _markets) view returns(address[] owners)
func (_MarketFactory *MarketFactorySession) GetMarketOwners(_markets []common.Address) ([]common.Address, error) {
	return _MarketFactory.Contract.GetMarketOwners(&_MarketFactory.CallOpts, _markets)
}

// GetMarketOwners is a free data retrieval call binding the contract method 0xcb9ef74e.
//
// Solidity: function getMarketOwners(address[] _markets) view returns(address[] owners)
func (_MarketFactory *MarketFactoryCallerSession) GetMarketOwners(_markets []common.Address) ([]common.Address, error) {
	return _MarketFactory.Contract.GetMarketOwners(&_MarketFactory.CallOpts, _markets)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_MarketFactory *MarketFactoryCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_MarketFactory *MarketFactorySession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _MarketFactory.Contract.GetRoleAdmin(&_MarketFactory.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_MarketFactory *MarketFactoryCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _MarketFactory.Contract.GetRoleAdmin(&_MarketFactory.CallOpts, role)
}

// GetTemplateInfo is a free data retrieval call binding the contract method 0x4632b0ec.
//
// Solidity: function getTemplateInfo(bytes32 templateId) view returns((address,string,string,bool,uint256,uint256))
func (_MarketFactory *MarketFactoryCaller) GetTemplateInfo(opts *bind.CallOpts, templateId [32]byte) (MarketFactoryV2TemplateInfo, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "getTemplateInfo", templateId)

	if err != nil {
		return *new(MarketFactoryV2TemplateInfo), err
	}

	out0 := *abi.ConvertType(out[0], new(MarketFactoryV2TemplateInfo)).(*MarketFactoryV2TemplateInfo)

	return out0, err

}

// GetTemplateInfo is a free data retrieval call binding the contract method 0x4632b0ec.
//
// Solidity: function getTemplateInfo(bytes32 templateId) view returns((address,string,string,bool,uint256,uint256))
func (_MarketFactory *MarketFactorySession) GetTemplateInfo(templateId [32]byte) (MarketFactoryV2TemplateInfo, error) {
	return _MarketFactory.Contract.GetTemplateInfo(&_MarketFactory.CallOpts, templateId)
}

// GetTemplateInfo is a free data retrieval call binding the contract method 0x4632b0ec.
//
// Solidity: function getTemplateInfo(bytes32 templateId) view returns((address,string,string,bool,uint256,uint256))
func (_MarketFactory *MarketFactoryCallerSession) GetTemplateInfo(templateId [32]byte) (MarketFactoryV2TemplateInfo, error) {
	return _MarketFactory.Contract.GetTemplateInfo(&_MarketFactory.CallOpts, templateId)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_MarketFactory *MarketFactoryCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_MarketFactory *MarketFactorySession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _MarketFactory.Contract.HasRole(&_MarketFactory.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_MarketFactory *MarketFactoryCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _MarketFactory.Contract.HasRole(&_MarketFactory.CallOpts, role, account)
}

// IsMarket is a free data retrieval call binding the contract method 0x6ec934da.
//
// Solidity: function isMarket(address ) view returns(bool)
func (_MarketFactory *MarketFactoryCaller) IsMarket(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "isMarket", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsMarket is a free data retrieval call binding the contract method 0x6ec934da.
//
// Solidity: function isMarket(address ) view returns(bool)
func (_MarketFactory *MarketFactorySession) IsMarket(arg0 common.Address) (bool, error) {
	return _MarketFactory.Contract.IsMarket(&_MarketFactory.CallOpts, arg0)
}

// IsMarket is a free data retrieval call binding the contract method 0x6ec934da.
//
// Solidity: function isMarket(address ) view returns(bool)
func (_MarketFactory *MarketFactoryCallerSession) IsMarket(arg0 common.Address) (bool, error) {
	return _MarketFactory.Contract.IsMarket(&_MarketFactory.CallOpts, arg0)
}

// IsMarketCreator is a free data retrieval call binding the contract method 0xf97b7a3b.
//
// Solidity: function isMarketCreator(address account) view returns(bool)
func (_MarketFactory *MarketFactoryCaller) IsMarketCreator(opts *bind.CallOpts, account common.Address) (bool, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "isMarketCreator", account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsMarketCreator is a free data retrieval call binding the contract method 0xf97b7a3b.
//
// Solidity: function isMarketCreator(address account) view returns(bool)
func (_MarketFactory *MarketFactorySession) IsMarketCreator(account common.Address) (bool, error) {
	return _MarketFactory.Contract.IsMarketCreator(&_MarketFactory.CallOpts, account)
}

// IsMarketCreator is a free data retrieval call binding the contract method 0xf97b7a3b.
//
// Solidity: function isMarketCreator(address account) view returns(bool)
func (_MarketFactory *MarketFactoryCallerSession) IsMarketCreator(account common.Address) (bool, error) {
	return _MarketFactory.Contract.IsMarketCreator(&_MarketFactory.CallOpts, account)
}

// IsRegistered is a free data retrieval call binding the contract method 0xc3c5a547.
//
// Solidity: function isRegistered(address ) view returns(bool)
func (_MarketFactory *MarketFactoryCaller) IsRegistered(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "isRegistered", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsRegistered is a free data retrieval call binding the contract method 0xc3c5a547.
//
// Solidity: function isRegistered(address ) view returns(bool)
func (_MarketFactory *MarketFactorySession) IsRegistered(arg0 common.Address) (bool, error) {
	return _MarketFactory.Contract.IsRegistered(&_MarketFactory.CallOpts, arg0)
}

// IsRegistered is a free data retrieval call binding the contract method 0xc3c5a547.
//
// Solidity: function isRegistered(address ) view returns(bool)
func (_MarketFactory *MarketFactoryCallerSession) IsRegistered(arg0 common.Address) (bool, error) {
	return _MarketFactory.Contract.IsRegistered(&_MarketFactory.CallOpts, arg0)
}

// MarketOwner is a free data retrieval call binding the contract method 0x7a11e331.
//
// Solidity: function marketOwner(address ) view returns(address)
func (_MarketFactory *MarketFactoryCaller) MarketOwner(opts *bind.CallOpts, arg0 common.Address) (common.Address, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "marketOwner", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// MarketOwner is a free data retrieval call binding the contract method 0x7a11e331.
//
// Solidity: function marketOwner(address ) view returns(address)
func (_MarketFactory *MarketFactorySession) MarketOwner(arg0 common.Address) (common.Address, error) {
	return _MarketFactory.Contract.MarketOwner(&_MarketFactory.CallOpts, arg0)
}

// MarketOwner is a free data retrieval call binding the contract method 0x7a11e331.
//
// Solidity: function marketOwner(address ) view returns(address)
func (_MarketFactory *MarketFactoryCallerSession) MarketOwner(arg0 common.Address) (common.Address, error) {
	return _MarketFactory.Contract.MarketOwner(&_MarketFactory.CallOpts, arg0)
}

// MarketTemplate is a free data retrieval call binding the contract method 0xf26da11e.
//
// Solidity: function marketTemplate(address ) view returns(bytes32)
func (_MarketFactory *MarketFactoryCaller) MarketTemplate(opts *bind.CallOpts, arg0 common.Address) ([32]byte, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "marketTemplate", arg0)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// MarketTemplate is a free data retrieval call binding the contract method 0xf26da11e.
//
// Solidity: function marketTemplate(address ) view returns(bytes32)
func (_MarketFactory *MarketFactorySession) MarketTemplate(arg0 common.Address) ([32]byte, error) {
	return _MarketFactory.Contract.MarketTemplate(&_MarketFactory.CallOpts, arg0)
}

// MarketTemplate is a free data retrieval call binding the contract method 0xf26da11e.
//
// Solidity: function marketTemplate(address ) view returns(bytes32)
func (_MarketFactory *MarketFactoryCallerSession) MarketTemplate(arg0 common.Address) ([32]byte, error) {
	return _MarketFactory.Contract.MarketTemplate(&_MarketFactory.CallOpts, arg0)
}

// Markets is a free data retrieval call binding the contract method 0xb1283e77.
//
// Solidity: function markets(uint256 ) view returns(address)
func (_MarketFactory *MarketFactoryCaller) Markets(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "markets", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Markets is a free data retrieval call binding the contract method 0xb1283e77.
//
// Solidity: function markets(uint256 ) view returns(address)
func (_MarketFactory *MarketFactorySession) Markets(arg0 *big.Int) (common.Address, error) {
	return _MarketFactory.Contract.Markets(&_MarketFactory.CallOpts, arg0)
}

// Markets is a free data retrieval call binding the contract method 0xb1283e77.
//
// Solidity: function markets(uint256 ) view returns(address)
func (_MarketFactory *MarketFactoryCallerSession) Markets(arg0 *big.Int) (common.Address, error) {
	return _MarketFactory.Contract.Markets(&_MarketFactory.CallOpts, arg0)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketFactory *MarketFactoryCaller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketFactory *MarketFactorySession) Paused() (bool, error) {
	return _MarketFactory.Contract.Paused(&_MarketFactory.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_MarketFactory *MarketFactoryCallerSession) Paused() (bool, error) {
	return _MarketFactory.Contract.Paused(&_MarketFactory.CallOpts)
}

// PredictMarketAddress is a free data retrieval call binding the contract method 0x91ef7a58.
//
// Solidity: function predictMarketAddress(bytes32 templateId, bytes32 salt) view returns(address)
func (_MarketFactory *MarketFactoryCaller) PredictMarketAddress(opts *bind.CallOpts, templateId [32]byte, salt [32]byte) (common.Address, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "predictMarketAddress", templateId, salt)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// PredictMarketAddress is a free data retrieval call binding the contract method 0x91ef7a58.
//
// Solidity: function predictMarketAddress(bytes32 templateId, bytes32 salt) view returns(address)
func (_MarketFactory *MarketFactorySession) PredictMarketAddress(templateId [32]byte, salt [32]byte) (common.Address, error) {
	return _MarketFactory.Contract.PredictMarketAddress(&_MarketFactory.CallOpts, templateId, salt)
}

// PredictMarketAddress is a free data retrieval call binding the contract method 0x91ef7a58.
//
// Solidity: function predictMarketAddress(bytes32 templateId, bytes32 salt) view returns(address)
func (_MarketFactory *MarketFactoryCallerSession) PredictMarketAddress(templateId [32]byte, salt [32]byte) (common.Address, error) {
	return _MarketFactory.Contract.PredictMarketAddress(&_MarketFactory.CallOpts, templateId, salt)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketFactory *MarketFactoryCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketFactory *MarketFactorySession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _MarketFactory.Contract.SupportsInterface(&_MarketFactory.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_MarketFactory *MarketFactoryCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _MarketFactory.Contract.SupportsInterface(&_MarketFactory.CallOpts, interfaceId)
}

// TemplateIds is a free data retrieval call binding the contract method 0xf36cb7a7.
//
// Solidity: function templateIds(uint256 ) view returns(bytes32)
func (_MarketFactory *MarketFactoryCaller) TemplateIds(opts *bind.CallOpts, arg0 *big.Int) ([32]byte, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "templateIds", arg0)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// TemplateIds is a free data retrieval call binding the contract method 0xf36cb7a7.
//
// Solidity: function templateIds(uint256 ) view returns(bytes32)
func (_MarketFactory *MarketFactorySession) TemplateIds(arg0 *big.Int) ([32]byte, error) {
	return _MarketFactory.Contract.TemplateIds(&_MarketFactory.CallOpts, arg0)
}

// TemplateIds is a free data retrieval call binding the contract method 0xf36cb7a7.
//
// Solidity: function templateIds(uint256 ) view returns(bytes32)
func (_MarketFactory *MarketFactoryCallerSession) TemplateIds(arg0 *big.Int) ([32]byte, error) {
	return _MarketFactory.Contract.TemplateIds(&_MarketFactory.CallOpts, arg0)
}

// Templates is a free data retrieval call binding the contract method 0x0a631576.
//
// Solidity: function templates(bytes32 ) view returns(address implementation, string name, string version, bool active, uint256 createdAt, uint256 marketCount)
func (_MarketFactory *MarketFactoryCaller) Templates(opts *bind.CallOpts, arg0 [32]byte) (struct {
	Implementation common.Address
	Name           string
	Version        string
	Active         bool
	CreatedAt      *big.Int
	MarketCount    *big.Int
}, error) {
	var out []interface{}
	err := _MarketFactory.contract.Call(opts, &out, "templates", arg0)

	outstruct := new(struct {
		Implementation common.Address
		Name           string
		Version        string
		Active         bool
		CreatedAt      *big.Int
		MarketCount    *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Implementation = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.Name = *abi.ConvertType(out[1], new(string)).(*string)
	outstruct.Version = *abi.ConvertType(out[2], new(string)).(*string)
	outstruct.Active = *abi.ConvertType(out[3], new(bool)).(*bool)
	outstruct.CreatedAt = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)
	outstruct.MarketCount = *abi.ConvertType(out[5], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// Templates is a free data retrieval call binding the contract method 0x0a631576.
//
// Solidity: function templates(bytes32 ) view returns(address implementation, string name, string version, bool active, uint256 createdAt, uint256 marketCount)
func (_MarketFactory *MarketFactorySession) Templates(arg0 [32]byte) (struct {
	Implementation common.Address
	Name           string
	Version        string
	Active         bool
	CreatedAt      *big.Int
	MarketCount    *big.Int
}, error) {
	return _MarketFactory.Contract.Templates(&_MarketFactory.CallOpts, arg0)
}

// Templates is a free data retrieval call binding the contract method 0x0a631576.
//
// Solidity: function templates(bytes32 ) view returns(address implementation, string name, string version, bool active, uint256 createdAt, uint256 marketCount)
func (_MarketFactory *MarketFactoryCallerSession) Templates(arg0 [32]byte) (struct {
	Implementation common.Address
	Name           string
	Version        string
	Active         bool
	CreatedAt      *big.Int
	MarketCount    *big.Int
}, error) {
	return _MarketFactory.Contract.Templates(&_MarketFactory.CallOpts, arg0)
}

// AddMarketCreator is a paid mutator transaction binding the contract method 0x355987cd.
//
// Solidity: function addMarketCreator(address account) returns()
func (_MarketFactory *MarketFactoryTransactor) AddMarketCreator(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "addMarketCreator", account)
}

// AddMarketCreator is a paid mutator transaction binding the contract method 0x355987cd.
//
// Solidity: function addMarketCreator(address account) returns()
func (_MarketFactory *MarketFactorySession) AddMarketCreator(account common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.AddMarketCreator(&_MarketFactory.TransactOpts, account)
}

// AddMarketCreator is a paid mutator transaction binding the contract method 0x355987cd.
//
// Solidity: function addMarketCreator(address account) returns()
func (_MarketFactory *MarketFactoryTransactorSession) AddMarketCreator(account common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.AddMarketCreator(&_MarketFactory.TransactOpts, account)
}

// AddMarketCreators is a paid mutator transaction binding the contract method 0x5c5f6798.
//
// Solidity: function addMarketCreators(address[] accounts) returns()
func (_MarketFactory *MarketFactoryTransactor) AddMarketCreators(opts *bind.TransactOpts, accounts []common.Address) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "addMarketCreators", accounts)
}

// AddMarketCreators is a paid mutator transaction binding the contract method 0x5c5f6798.
//
// Solidity: function addMarketCreators(address[] accounts) returns()
func (_MarketFactory *MarketFactorySession) AddMarketCreators(accounts []common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.AddMarketCreators(&_MarketFactory.TransactOpts, accounts)
}

// AddMarketCreators is a paid mutator transaction binding the contract method 0x5c5f6798.
//
// Solidity: function addMarketCreators(address[] accounts) returns()
func (_MarketFactory *MarketFactoryTransactorSession) AddMarketCreators(accounts []common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.AddMarketCreators(&_MarketFactory.TransactOpts, accounts)
}

// CreateMarket is a paid mutator transaction binding the contract method 0x5d5910c4.
//
// Solidity: function createMarket(bytes32 templateId, bytes initData) returns(address market)
func (_MarketFactory *MarketFactoryTransactor) CreateMarket(opts *bind.TransactOpts, templateId [32]byte, initData []byte) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "createMarket", templateId, initData)
}

// CreateMarket is a paid mutator transaction binding the contract method 0x5d5910c4.
//
// Solidity: function createMarket(bytes32 templateId, bytes initData) returns(address market)
func (_MarketFactory *MarketFactorySession) CreateMarket(templateId [32]byte, initData []byte) (*types.Transaction, error) {
	return _MarketFactory.Contract.CreateMarket(&_MarketFactory.TransactOpts, templateId, initData)
}

// CreateMarket is a paid mutator transaction binding the contract method 0x5d5910c4.
//
// Solidity: function createMarket(bytes32 templateId, bytes initData) returns(address market)
func (_MarketFactory *MarketFactoryTransactorSession) CreateMarket(templateId [32]byte, initData []byte) (*types.Transaction, error) {
	return _MarketFactory.Contract.CreateMarket(&_MarketFactory.TransactOpts, templateId, initData)
}

// CreateMarketDeterministic is a paid mutator transaction binding the contract method 0xb473c63b.
//
// Solidity: function createMarketDeterministic(bytes32 templateId, bytes32 salt, bytes initData) returns(address market)
func (_MarketFactory *MarketFactoryTransactor) CreateMarketDeterministic(opts *bind.TransactOpts, templateId [32]byte, salt [32]byte, initData []byte) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "createMarketDeterministic", templateId, salt, initData)
}

// CreateMarketDeterministic is a paid mutator transaction binding the contract method 0xb473c63b.
//
// Solidity: function createMarketDeterministic(bytes32 templateId, bytes32 salt, bytes initData) returns(address market)
func (_MarketFactory *MarketFactorySession) CreateMarketDeterministic(templateId [32]byte, salt [32]byte, initData []byte) (*types.Transaction, error) {
	return _MarketFactory.Contract.CreateMarketDeterministic(&_MarketFactory.TransactOpts, templateId, salt, initData)
}

// CreateMarketDeterministic is a paid mutator transaction binding the contract method 0xb473c63b.
//
// Solidity: function createMarketDeterministic(bytes32 templateId, bytes32 salt, bytes initData) returns(address market)
func (_MarketFactory *MarketFactoryTransactorSession) CreateMarketDeterministic(templateId [32]byte, salt [32]byte, initData []byte) (*types.Transaction, error) {
	return _MarketFactory.Contract.CreateMarketDeterministic(&_MarketFactory.TransactOpts, templateId, salt, initData)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_MarketFactory *MarketFactoryTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_MarketFactory *MarketFactorySession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.GrantRole(&_MarketFactory.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_MarketFactory *MarketFactoryTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.GrantRole(&_MarketFactory.TransactOpts, role, account)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketFactory *MarketFactoryTransactor) Pause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "pause")
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketFactory *MarketFactorySession) Pause() (*types.Transaction, error) {
	return _MarketFactory.Contract.Pause(&_MarketFactory.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_MarketFactory *MarketFactoryTransactorSession) Pause() (*types.Transaction, error) {
	return _MarketFactory.Contract.Pause(&_MarketFactory.TransactOpts)
}

// RecordMarket is a paid mutator transaction binding the contract method 0x7ae396ee.
//
// Solidity: function recordMarket(address market, bytes32 templateId) returns(bool)
func (_MarketFactory *MarketFactoryTransactor) RecordMarket(opts *bind.TransactOpts, market common.Address, templateId [32]byte) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "recordMarket", market, templateId)
}

// RecordMarket is a paid mutator transaction binding the contract method 0x7ae396ee.
//
// Solidity: function recordMarket(address market, bytes32 templateId) returns(bool)
func (_MarketFactory *MarketFactorySession) RecordMarket(market common.Address, templateId [32]byte) (*types.Transaction, error) {
	return _MarketFactory.Contract.RecordMarket(&_MarketFactory.TransactOpts, market, templateId)
}

// RecordMarket is a paid mutator transaction binding the contract method 0x7ae396ee.
//
// Solidity: function recordMarket(address market, bytes32 templateId) returns(bool)
func (_MarketFactory *MarketFactoryTransactorSession) RecordMarket(market common.Address, templateId [32]byte) (*types.Transaction, error) {
	return _MarketFactory.Contract.RecordMarket(&_MarketFactory.TransactOpts, market, templateId)
}

// RegisterTemplate is a paid mutator transaction binding the contract method 0x04d2721b.
//
// Solidity: function registerTemplate(string name, string version, address implementation) returns(bytes32 templateId)
func (_MarketFactory *MarketFactoryTransactor) RegisterTemplate(opts *bind.TransactOpts, name string, version string, implementation common.Address) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "registerTemplate", name, version, implementation)
}

// RegisterTemplate is a paid mutator transaction binding the contract method 0x04d2721b.
//
// Solidity: function registerTemplate(string name, string version, address implementation) returns(bytes32 templateId)
func (_MarketFactory *MarketFactorySession) RegisterTemplate(name string, version string, implementation common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.RegisterTemplate(&_MarketFactory.TransactOpts, name, version, implementation)
}

// RegisterTemplate is a paid mutator transaction binding the contract method 0x04d2721b.
//
// Solidity: function registerTemplate(string name, string version, address implementation) returns(bytes32 templateId)
func (_MarketFactory *MarketFactoryTransactorSession) RegisterTemplate(name string, version string, implementation common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.RegisterTemplate(&_MarketFactory.TransactOpts, name, version, implementation)
}

// RemoveMarketCreator is a paid mutator transaction binding the contract method 0xa15fd10f.
//
// Solidity: function removeMarketCreator(address account) returns()
func (_MarketFactory *MarketFactoryTransactor) RemoveMarketCreator(opts *bind.TransactOpts, account common.Address) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "removeMarketCreator", account)
}

// RemoveMarketCreator is a paid mutator transaction binding the contract method 0xa15fd10f.
//
// Solidity: function removeMarketCreator(address account) returns()
func (_MarketFactory *MarketFactorySession) RemoveMarketCreator(account common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.RemoveMarketCreator(&_MarketFactory.TransactOpts, account)
}

// RemoveMarketCreator is a paid mutator transaction binding the contract method 0xa15fd10f.
//
// Solidity: function removeMarketCreator(address account) returns()
func (_MarketFactory *MarketFactoryTransactorSession) RemoveMarketCreator(account common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.RemoveMarketCreator(&_MarketFactory.TransactOpts, account)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_MarketFactory *MarketFactoryTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_MarketFactory *MarketFactorySession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.RenounceRole(&_MarketFactory.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_MarketFactory *MarketFactoryTransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.RenounceRole(&_MarketFactory.TransactOpts, role, callerConfirmation)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_MarketFactory *MarketFactoryTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_MarketFactory *MarketFactorySession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.RevokeRole(&_MarketFactory.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_MarketFactory *MarketFactoryTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.RevokeRole(&_MarketFactory.TransactOpts, role, account)
}

// SetTemplateActive is a paid mutator transaction binding the contract method 0x310879a9.
//
// Solidity: function setTemplateActive(bytes32 templateId, bool active) returns()
func (_MarketFactory *MarketFactoryTransactor) SetTemplateActive(opts *bind.TransactOpts, templateId [32]byte, active bool) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "setTemplateActive", templateId, active)
}

// SetTemplateActive is a paid mutator transaction binding the contract method 0x310879a9.
//
// Solidity: function setTemplateActive(bytes32 templateId, bool active) returns()
func (_MarketFactory *MarketFactorySession) SetTemplateActive(templateId [32]byte, active bool) (*types.Transaction, error) {
	return _MarketFactory.Contract.SetTemplateActive(&_MarketFactory.TransactOpts, templateId, active)
}

// SetTemplateActive is a paid mutator transaction binding the contract method 0x310879a9.
//
// Solidity: function setTemplateActive(bytes32 templateId, bool active) returns()
func (_MarketFactory *MarketFactoryTransactorSession) SetTemplateActive(templateId [32]byte, active bool) (*types.Transaction, error) {
	return _MarketFactory.Contract.SetTemplateActive(&_MarketFactory.TransactOpts, templateId, active)
}

// TransferMarketOwnership is a paid mutator transaction binding the contract method 0x775d7a19.
//
// Solidity: function transferMarketOwnership(address market, address newOwner) returns()
func (_MarketFactory *MarketFactoryTransactor) TransferMarketOwnership(opts *bind.TransactOpts, market common.Address, newOwner common.Address) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "transferMarketOwnership", market, newOwner)
}

// TransferMarketOwnership is a paid mutator transaction binding the contract method 0x775d7a19.
//
// Solidity: function transferMarketOwnership(address market, address newOwner) returns()
func (_MarketFactory *MarketFactorySession) TransferMarketOwnership(market common.Address, newOwner common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.TransferMarketOwnership(&_MarketFactory.TransactOpts, market, newOwner)
}

// TransferMarketOwnership is a paid mutator transaction binding the contract method 0x775d7a19.
//
// Solidity: function transferMarketOwnership(address market, address newOwner) returns()
func (_MarketFactory *MarketFactoryTransactorSession) TransferMarketOwnership(market common.Address, newOwner common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.TransferMarketOwnership(&_MarketFactory.TransactOpts, market, newOwner)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketFactory *MarketFactoryTransactor) Unpause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "unpause")
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketFactory *MarketFactorySession) Unpause() (*types.Transaction, error) {
	return _MarketFactory.Contract.Unpause(&_MarketFactory.TransactOpts)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_MarketFactory *MarketFactoryTransactorSession) Unpause() (*types.Transaction, error) {
	return _MarketFactory.Contract.Unpause(&_MarketFactory.TransactOpts)
}

// UpdateMarketOwnerRecord is a paid mutator transaction binding the contract method 0xe8a9b933.
//
// Solidity: function updateMarketOwnerRecord(address market) returns()
func (_MarketFactory *MarketFactoryTransactor) UpdateMarketOwnerRecord(opts *bind.TransactOpts, market common.Address) (*types.Transaction, error) {
	return _MarketFactory.contract.Transact(opts, "updateMarketOwnerRecord", market)
}

// UpdateMarketOwnerRecord is a paid mutator transaction binding the contract method 0xe8a9b933.
//
// Solidity: function updateMarketOwnerRecord(address market) returns()
func (_MarketFactory *MarketFactorySession) UpdateMarketOwnerRecord(market common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.UpdateMarketOwnerRecord(&_MarketFactory.TransactOpts, market)
}

// UpdateMarketOwnerRecord is a paid mutator transaction binding the contract method 0xe8a9b933.
//
// Solidity: function updateMarketOwnerRecord(address market) returns()
func (_MarketFactory *MarketFactoryTransactorSession) UpdateMarketOwnerRecord(market common.Address) (*types.Transaction, error) {
	return _MarketFactory.Contract.UpdateMarketOwnerRecord(&_MarketFactory.TransactOpts, market)
}

// MarketFactoryMarketCreatedIterator is returned from FilterMarketCreated and is used to iterate over the raw logs and unpacked data for MarketCreated events raised by the MarketFactory contract.
type MarketFactoryMarketCreatedIterator struct {
	Event *MarketFactoryMarketCreated // Event containing the contract specifics and raw log

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
func (it *MarketFactoryMarketCreatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryMarketCreated)
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
		it.Event = new(MarketFactoryMarketCreated)
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
func (it *MarketFactoryMarketCreatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryMarketCreatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryMarketCreated represents a MarketCreated event raised by the MarketFactory contract.
type MarketFactoryMarketCreated struct {
	Market     common.Address
	TemplateId [32]byte
	Creator    common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterMarketCreated is a free log retrieval operation binding the contract event 0x108906fda116820aea305a6653ee01031831e497c9c93d9ab489fd83e1d82870.
//
// Solidity: event MarketCreated(address indexed market, bytes32 indexed templateId, address indexed creator)
func (_MarketFactory *MarketFactoryFilterer) FilterMarketCreated(opts *bind.FilterOpts, market []common.Address, templateId [][32]byte, creator []common.Address) (*MarketFactoryMarketCreatedIterator, error) {

	var marketRule []interface{}
	for _, marketItem := range market {
		marketRule = append(marketRule, marketItem)
	}
	var templateIdRule []interface{}
	for _, templateIdItem := range templateId {
		templateIdRule = append(templateIdRule, templateIdItem)
	}
	var creatorRule []interface{}
	for _, creatorItem := range creator {
		creatorRule = append(creatorRule, creatorItem)
	}

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "MarketCreated", marketRule, templateIdRule, creatorRule)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryMarketCreatedIterator{contract: _MarketFactory.contract, event: "MarketCreated", logs: logs, sub: sub}, nil
}

// WatchMarketCreated is a free log subscription operation binding the contract event 0x108906fda116820aea305a6653ee01031831e497c9c93d9ab489fd83e1d82870.
//
// Solidity: event MarketCreated(address indexed market, bytes32 indexed templateId, address indexed creator)
func (_MarketFactory *MarketFactoryFilterer) WatchMarketCreated(opts *bind.WatchOpts, sink chan<- *MarketFactoryMarketCreated, market []common.Address, templateId [][32]byte, creator []common.Address) (event.Subscription, error) {

	var marketRule []interface{}
	for _, marketItem := range market {
		marketRule = append(marketRule, marketItem)
	}
	var templateIdRule []interface{}
	for _, templateIdItem := range templateId {
		templateIdRule = append(templateIdRule, templateIdItem)
	}
	var creatorRule []interface{}
	for _, creatorItem := range creator {
		creatorRule = append(creatorRule, creatorItem)
	}

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "MarketCreated", marketRule, templateIdRule, creatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryMarketCreated)
				if err := _MarketFactory.contract.UnpackLog(event, "MarketCreated", log); err != nil {
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

// ParseMarketCreated is a log parse operation binding the contract event 0x108906fda116820aea305a6653ee01031831e497c9c93d9ab489fd83e1d82870.
//
// Solidity: event MarketCreated(address indexed market, bytes32 indexed templateId, address indexed creator)
func (_MarketFactory *MarketFactoryFilterer) ParseMarketCreated(log types.Log) (*MarketFactoryMarketCreated, error) {
	event := new(MarketFactoryMarketCreated)
	if err := _MarketFactory.contract.UnpackLog(event, "MarketCreated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketFactoryMarketCreatorAddedIterator is returned from FilterMarketCreatorAdded and is used to iterate over the raw logs and unpacked data for MarketCreatorAdded events raised by the MarketFactory contract.
type MarketFactoryMarketCreatorAddedIterator struct {
	Event *MarketFactoryMarketCreatorAdded // Event containing the contract specifics and raw log

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
func (it *MarketFactoryMarketCreatorAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryMarketCreatorAdded)
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
		it.Event = new(MarketFactoryMarketCreatorAdded)
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
func (it *MarketFactoryMarketCreatorAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryMarketCreatorAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryMarketCreatorAdded represents a MarketCreatorAdded event raised by the MarketFactory contract.
type MarketFactoryMarketCreatorAdded struct {
	Account common.Address
	Admin   common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterMarketCreatorAdded is a free log retrieval operation binding the contract event 0x899a2f2bd01cd69d320eea4190427202b7d406624682051addc239474bc8a626.
//
// Solidity: event MarketCreatorAdded(address indexed account, address indexed admin)
func (_MarketFactory *MarketFactoryFilterer) FilterMarketCreatorAdded(opts *bind.FilterOpts, account []common.Address, admin []common.Address) (*MarketFactoryMarketCreatorAddedIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var adminRule []interface{}
	for _, adminItem := range admin {
		adminRule = append(adminRule, adminItem)
	}

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "MarketCreatorAdded", accountRule, adminRule)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryMarketCreatorAddedIterator{contract: _MarketFactory.contract, event: "MarketCreatorAdded", logs: logs, sub: sub}, nil
}

// WatchMarketCreatorAdded is a free log subscription operation binding the contract event 0x899a2f2bd01cd69d320eea4190427202b7d406624682051addc239474bc8a626.
//
// Solidity: event MarketCreatorAdded(address indexed account, address indexed admin)
func (_MarketFactory *MarketFactoryFilterer) WatchMarketCreatorAdded(opts *bind.WatchOpts, sink chan<- *MarketFactoryMarketCreatorAdded, account []common.Address, admin []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var adminRule []interface{}
	for _, adminItem := range admin {
		adminRule = append(adminRule, adminItem)
	}

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "MarketCreatorAdded", accountRule, adminRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryMarketCreatorAdded)
				if err := _MarketFactory.contract.UnpackLog(event, "MarketCreatorAdded", log); err != nil {
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

// ParseMarketCreatorAdded is a log parse operation binding the contract event 0x899a2f2bd01cd69d320eea4190427202b7d406624682051addc239474bc8a626.
//
// Solidity: event MarketCreatorAdded(address indexed account, address indexed admin)
func (_MarketFactory *MarketFactoryFilterer) ParseMarketCreatorAdded(log types.Log) (*MarketFactoryMarketCreatorAdded, error) {
	event := new(MarketFactoryMarketCreatorAdded)
	if err := _MarketFactory.contract.UnpackLog(event, "MarketCreatorAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketFactoryMarketCreatorRemovedIterator is returned from FilterMarketCreatorRemoved and is used to iterate over the raw logs and unpacked data for MarketCreatorRemoved events raised by the MarketFactory contract.
type MarketFactoryMarketCreatorRemovedIterator struct {
	Event *MarketFactoryMarketCreatorRemoved // Event containing the contract specifics and raw log

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
func (it *MarketFactoryMarketCreatorRemovedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryMarketCreatorRemoved)
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
		it.Event = new(MarketFactoryMarketCreatorRemoved)
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
func (it *MarketFactoryMarketCreatorRemovedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryMarketCreatorRemovedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryMarketCreatorRemoved represents a MarketCreatorRemoved event raised by the MarketFactory contract.
type MarketFactoryMarketCreatorRemoved struct {
	Account common.Address
	Admin   common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterMarketCreatorRemoved is a free log retrieval operation binding the contract event 0xd87f8c56eba9270623213a761e8004e0a7eb68d5898ff393f8e2cb677252a5cf.
//
// Solidity: event MarketCreatorRemoved(address indexed account, address indexed admin)
func (_MarketFactory *MarketFactoryFilterer) FilterMarketCreatorRemoved(opts *bind.FilterOpts, account []common.Address, admin []common.Address) (*MarketFactoryMarketCreatorRemovedIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var adminRule []interface{}
	for _, adminItem := range admin {
		adminRule = append(adminRule, adminItem)
	}

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "MarketCreatorRemoved", accountRule, adminRule)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryMarketCreatorRemovedIterator{contract: _MarketFactory.contract, event: "MarketCreatorRemoved", logs: logs, sub: sub}, nil
}

// WatchMarketCreatorRemoved is a free log subscription operation binding the contract event 0xd87f8c56eba9270623213a761e8004e0a7eb68d5898ff393f8e2cb677252a5cf.
//
// Solidity: event MarketCreatorRemoved(address indexed account, address indexed admin)
func (_MarketFactory *MarketFactoryFilterer) WatchMarketCreatorRemoved(opts *bind.WatchOpts, sink chan<- *MarketFactoryMarketCreatorRemoved, account []common.Address, admin []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var adminRule []interface{}
	for _, adminItem := range admin {
		adminRule = append(adminRule, adminItem)
	}

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "MarketCreatorRemoved", accountRule, adminRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryMarketCreatorRemoved)
				if err := _MarketFactory.contract.UnpackLog(event, "MarketCreatorRemoved", log); err != nil {
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

// ParseMarketCreatorRemoved is a log parse operation binding the contract event 0xd87f8c56eba9270623213a761e8004e0a7eb68d5898ff393f8e2cb677252a5cf.
//
// Solidity: event MarketCreatorRemoved(address indexed account, address indexed admin)
func (_MarketFactory *MarketFactoryFilterer) ParseMarketCreatorRemoved(log types.Log) (*MarketFactoryMarketCreatorRemoved, error) {
	event := new(MarketFactoryMarketCreatorRemoved)
	if err := _MarketFactory.contract.UnpackLog(event, "MarketCreatorRemoved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketFactoryMarketOwnershipTransferredIterator is returned from FilterMarketOwnershipTransferred and is used to iterate over the raw logs and unpacked data for MarketOwnershipTransferred events raised by the MarketFactory contract.
type MarketFactoryMarketOwnershipTransferredIterator struct {
	Event *MarketFactoryMarketOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *MarketFactoryMarketOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryMarketOwnershipTransferred)
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
		it.Event = new(MarketFactoryMarketOwnershipTransferred)
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
func (it *MarketFactoryMarketOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryMarketOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryMarketOwnershipTransferred represents a MarketOwnershipTransferred event raised by the MarketFactory contract.
type MarketFactoryMarketOwnershipTransferred struct {
	Market        common.Address
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterMarketOwnershipTransferred is a free log retrieval operation binding the contract event 0xcaa8e4f28d518ce8c8ce3739b516a552596f407d4ae251548eeb166eef1b00b4.
//
// Solidity: event MarketOwnershipTransferred(address indexed market, address indexed previousOwner, address indexed newOwner)
func (_MarketFactory *MarketFactoryFilterer) FilterMarketOwnershipTransferred(opts *bind.FilterOpts, market []common.Address, previousOwner []common.Address, newOwner []common.Address) (*MarketFactoryMarketOwnershipTransferredIterator, error) {

	var marketRule []interface{}
	for _, marketItem := range market {
		marketRule = append(marketRule, marketItem)
	}
	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "MarketOwnershipTransferred", marketRule, previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryMarketOwnershipTransferredIterator{contract: _MarketFactory.contract, event: "MarketOwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchMarketOwnershipTransferred is a free log subscription operation binding the contract event 0xcaa8e4f28d518ce8c8ce3739b516a552596f407d4ae251548eeb166eef1b00b4.
//
// Solidity: event MarketOwnershipTransferred(address indexed market, address indexed previousOwner, address indexed newOwner)
func (_MarketFactory *MarketFactoryFilterer) WatchMarketOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *MarketFactoryMarketOwnershipTransferred, market []common.Address, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var marketRule []interface{}
	for _, marketItem := range market {
		marketRule = append(marketRule, marketItem)
	}
	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "MarketOwnershipTransferred", marketRule, previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryMarketOwnershipTransferred)
				if err := _MarketFactory.contract.UnpackLog(event, "MarketOwnershipTransferred", log); err != nil {
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

// ParseMarketOwnershipTransferred is a log parse operation binding the contract event 0xcaa8e4f28d518ce8c8ce3739b516a552596f407d4ae251548eeb166eef1b00b4.
//
// Solidity: event MarketOwnershipTransferred(address indexed market, address indexed previousOwner, address indexed newOwner)
func (_MarketFactory *MarketFactoryFilterer) ParseMarketOwnershipTransferred(log types.Log) (*MarketFactoryMarketOwnershipTransferred, error) {
	event := new(MarketFactoryMarketOwnershipTransferred)
	if err := _MarketFactory.contract.UnpackLog(event, "MarketOwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketFactoryPausedIterator is returned from FilterPaused and is used to iterate over the raw logs and unpacked data for Paused events raised by the MarketFactory contract.
type MarketFactoryPausedIterator struct {
	Event *MarketFactoryPaused // Event containing the contract specifics and raw log

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
func (it *MarketFactoryPausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryPaused)
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
		it.Event = new(MarketFactoryPaused)
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
func (it *MarketFactoryPausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryPausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryPaused represents a Paused event raised by the MarketFactory contract.
type MarketFactoryPaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterPaused is a free log retrieval operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_MarketFactory *MarketFactoryFilterer) FilterPaused(opts *bind.FilterOpts) (*MarketFactoryPausedIterator, error) {

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return &MarketFactoryPausedIterator{contract: _MarketFactory.contract, event: "Paused", logs: logs, sub: sub}, nil
}

// WatchPaused is a free log subscription operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_MarketFactory *MarketFactoryFilterer) WatchPaused(opts *bind.WatchOpts, sink chan<- *MarketFactoryPaused) (event.Subscription, error) {

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryPaused)
				if err := _MarketFactory.contract.UnpackLog(event, "Paused", log); err != nil {
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
func (_MarketFactory *MarketFactoryFilterer) ParsePaused(log types.Log) (*MarketFactoryPaused, error) {
	event := new(MarketFactoryPaused)
	if err := _MarketFactory.contract.UnpackLog(event, "Paused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketFactoryRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the MarketFactory contract.
type MarketFactoryRoleAdminChangedIterator struct {
	Event *MarketFactoryRoleAdminChanged // Event containing the contract specifics and raw log

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
func (it *MarketFactoryRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryRoleAdminChanged)
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
		it.Event = new(MarketFactoryRoleAdminChanged)
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
func (it *MarketFactoryRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryRoleAdminChanged represents a RoleAdminChanged event raised by the MarketFactory contract.
type MarketFactoryRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_MarketFactory *MarketFactoryFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*MarketFactoryRoleAdminChangedIterator, error) {

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

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryRoleAdminChangedIterator{contract: _MarketFactory.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_MarketFactory *MarketFactoryFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *MarketFactoryRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

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

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryRoleAdminChanged)
				if err := _MarketFactory.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
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
func (_MarketFactory *MarketFactoryFilterer) ParseRoleAdminChanged(log types.Log) (*MarketFactoryRoleAdminChanged, error) {
	event := new(MarketFactoryRoleAdminChanged)
	if err := _MarketFactory.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketFactoryRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the MarketFactory contract.
type MarketFactoryRoleGrantedIterator struct {
	Event *MarketFactoryRoleGranted // Event containing the contract specifics and raw log

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
func (it *MarketFactoryRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryRoleGranted)
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
		it.Event = new(MarketFactoryRoleGranted)
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
func (it *MarketFactoryRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryRoleGranted represents a RoleGranted event raised by the MarketFactory contract.
type MarketFactoryRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_MarketFactory *MarketFactoryFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*MarketFactoryRoleGrantedIterator, error) {

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

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryRoleGrantedIterator{contract: _MarketFactory.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_MarketFactory *MarketFactoryFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *MarketFactoryRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryRoleGranted)
				if err := _MarketFactory.contract.UnpackLog(event, "RoleGranted", log); err != nil {
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
func (_MarketFactory *MarketFactoryFilterer) ParseRoleGranted(log types.Log) (*MarketFactoryRoleGranted, error) {
	event := new(MarketFactoryRoleGranted)
	if err := _MarketFactory.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketFactoryRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the MarketFactory contract.
type MarketFactoryRoleRevokedIterator struct {
	Event *MarketFactoryRoleRevoked // Event containing the contract specifics and raw log

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
func (it *MarketFactoryRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryRoleRevoked)
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
		it.Event = new(MarketFactoryRoleRevoked)
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
func (it *MarketFactoryRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryRoleRevoked represents a RoleRevoked event raised by the MarketFactory contract.
type MarketFactoryRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_MarketFactory *MarketFactoryFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*MarketFactoryRoleRevokedIterator, error) {

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

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryRoleRevokedIterator{contract: _MarketFactory.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_MarketFactory *MarketFactoryFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *MarketFactoryRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryRoleRevoked)
				if err := _MarketFactory.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
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
func (_MarketFactory *MarketFactoryFilterer) ParseRoleRevoked(log types.Log) (*MarketFactoryRoleRevoked, error) {
	event := new(MarketFactoryRoleRevoked)
	if err := _MarketFactory.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketFactoryTemplateActiveStatusUpdatedIterator is returned from FilterTemplateActiveStatusUpdated and is used to iterate over the raw logs and unpacked data for TemplateActiveStatusUpdated events raised by the MarketFactory contract.
type MarketFactoryTemplateActiveStatusUpdatedIterator struct {
	Event *MarketFactoryTemplateActiveStatusUpdated // Event containing the contract specifics and raw log

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
func (it *MarketFactoryTemplateActiveStatusUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryTemplateActiveStatusUpdated)
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
		it.Event = new(MarketFactoryTemplateActiveStatusUpdated)
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
func (it *MarketFactoryTemplateActiveStatusUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryTemplateActiveStatusUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryTemplateActiveStatusUpdated represents a TemplateActiveStatusUpdated event raised by the MarketFactory contract.
type MarketFactoryTemplateActiveStatusUpdated struct {
	TemplateId [32]byte
	Active     bool
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterTemplateActiveStatusUpdated is a free log retrieval operation binding the contract event 0x37792f5a019d38e822495dc8b89b28bdfc2b42d70f63b4c7cdc06a95da99e1d8.
//
// Solidity: event TemplateActiveStatusUpdated(bytes32 indexed templateId, bool active)
func (_MarketFactory *MarketFactoryFilterer) FilterTemplateActiveStatusUpdated(opts *bind.FilterOpts, templateId [][32]byte) (*MarketFactoryTemplateActiveStatusUpdatedIterator, error) {

	var templateIdRule []interface{}
	for _, templateIdItem := range templateId {
		templateIdRule = append(templateIdRule, templateIdItem)
	}

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "TemplateActiveStatusUpdated", templateIdRule)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryTemplateActiveStatusUpdatedIterator{contract: _MarketFactory.contract, event: "TemplateActiveStatusUpdated", logs: logs, sub: sub}, nil
}

// WatchTemplateActiveStatusUpdated is a free log subscription operation binding the contract event 0x37792f5a019d38e822495dc8b89b28bdfc2b42d70f63b4c7cdc06a95da99e1d8.
//
// Solidity: event TemplateActiveStatusUpdated(bytes32 indexed templateId, bool active)
func (_MarketFactory *MarketFactoryFilterer) WatchTemplateActiveStatusUpdated(opts *bind.WatchOpts, sink chan<- *MarketFactoryTemplateActiveStatusUpdated, templateId [][32]byte) (event.Subscription, error) {

	var templateIdRule []interface{}
	for _, templateIdItem := range templateId {
		templateIdRule = append(templateIdRule, templateIdItem)
	}

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "TemplateActiveStatusUpdated", templateIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryTemplateActiveStatusUpdated)
				if err := _MarketFactory.contract.UnpackLog(event, "TemplateActiveStatusUpdated", log); err != nil {
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

// ParseTemplateActiveStatusUpdated is a log parse operation binding the contract event 0x37792f5a019d38e822495dc8b89b28bdfc2b42d70f63b4c7cdc06a95da99e1d8.
//
// Solidity: event TemplateActiveStatusUpdated(bytes32 indexed templateId, bool active)
func (_MarketFactory *MarketFactoryFilterer) ParseTemplateActiveStatusUpdated(log types.Log) (*MarketFactoryTemplateActiveStatusUpdated, error) {
	event := new(MarketFactoryTemplateActiveStatusUpdated)
	if err := _MarketFactory.contract.UnpackLog(event, "TemplateActiveStatusUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketFactoryTemplateRegisteredIterator is returned from FilterTemplateRegistered and is used to iterate over the raw logs and unpacked data for TemplateRegistered events raised by the MarketFactory contract.
type MarketFactoryTemplateRegisteredIterator struct {
	Event *MarketFactoryTemplateRegistered // Event containing the contract specifics and raw log

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
func (it *MarketFactoryTemplateRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryTemplateRegistered)
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
		it.Event = new(MarketFactoryTemplateRegistered)
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
func (it *MarketFactoryTemplateRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryTemplateRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryTemplateRegistered represents a TemplateRegistered event raised by the MarketFactory contract.
type MarketFactoryTemplateRegistered struct {
	TemplateId     [32]byte
	Implementation common.Address
	Name           string
	Version        string
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterTemplateRegistered is a free log retrieval operation binding the contract event 0x027fac908ae2521492f2c920b2c99fb0129a7dc19c33a593c8ad90f2a6a34be6.
//
// Solidity: event TemplateRegistered(bytes32 indexed templateId, address indexed implementation, string name, string version)
func (_MarketFactory *MarketFactoryFilterer) FilterTemplateRegistered(opts *bind.FilterOpts, templateId [][32]byte, implementation []common.Address) (*MarketFactoryTemplateRegisteredIterator, error) {

	var templateIdRule []interface{}
	for _, templateIdItem := range templateId {
		templateIdRule = append(templateIdRule, templateIdItem)
	}
	var implementationRule []interface{}
	for _, implementationItem := range implementation {
		implementationRule = append(implementationRule, implementationItem)
	}

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "TemplateRegistered", templateIdRule, implementationRule)
	if err != nil {
		return nil, err
	}
	return &MarketFactoryTemplateRegisteredIterator{contract: _MarketFactory.contract, event: "TemplateRegistered", logs: logs, sub: sub}, nil
}

// WatchTemplateRegistered is a free log subscription operation binding the contract event 0x027fac908ae2521492f2c920b2c99fb0129a7dc19c33a593c8ad90f2a6a34be6.
//
// Solidity: event TemplateRegistered(bytes32 indexed templateId, address indexed implementation, string name, string version)
func (_MarketFactory *MarketFactoryFilterer) WatchTemplateRegistered(opts *bind.WatchOpts, sink chan<- *MarketFactoryTemplateRegistered, templateId [][32]byte, implementation []common.Address) (event.Subscription, error) {

	var templateIdRule []interface{}
	for _, templateIdItem := range templateId {
		templateIdRule = append(templateIdRule, templateIdItem)
	}
	var implementationRule []interface{}
	for _, implementationItem := range implementation {
		implementationRule = append(implementationRule, implementationItem)
	}

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "TemplateRegistered", templateIdRule, implementationRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryTemplateRegistered)
				if err := _MarketFactory.contract.UnpackLog(event, "TemplateRegistered", log); err != nil {
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

// ParseTemplateRegistered is a log parse operation binding the contract event 0x027fac908ae2521492f2c920b2c99fb0129a7dc19c33a593c8ad90f2a6a34be6.
//
// Solidity: event TemplateRegistered(bytes32 indexed templateId, address indexed implementation, string name, string version)
func (_MarketFactory *MarketFactoryFilterer) ParseTemplateRegistered(log types.Log) (*MarketFactoryTemplateRegistered, error) {
	event := new(MarketFactoryTemplateRegistered)
	if err := _MarketFactory.contract.UnpackLog(event, "TemplateRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MarketFactoryUnpausedIterator is returned from FilterUnpaused and is used to iterate over the raw logs and unpacked data for Unpaused events raised by the MarketFactory contract.
type MarketFactoryUnpausedIterator struct {
	Event *MarketFactoryUnpaused // Event containing the contract specifics and raw log

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
func (it *MarketFactoryUnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MarketFactoryUnpaused)
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
		it.Event = new(MarketFactoryUnpaused)
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
func (it *MarketFactoryUnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MarketFactoryUnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MarketFactoryUnpaused represents a Unpaused event raised by the MarketFactory contract.
type MarketFactoryUnpaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUnpaused is a free log retrieval operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_MarketFactory *MarketFactoryFilterer) FilterUnpaused(opts *bind.FilterOpts) (*MarketFactoryUnpausedIterator, error) {

	logs, sub, err := _MarketFactory.contract.FilterLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return &MarketFactoryUnpausedIterator{contract: _MarketFactory.contract, event: "Unpaused", logs: logs, sub: sub}, nil
}

// WatchUnpaused is a free log subscription operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_MarketFactory *MarketFactoryFilterer) WatchUnpaused(opts *bind.WatchOpts, sink chan<- *MarketFactoryUnpaused) (event.Subscription, error) {

	logs, sub, err := _MarketFactory.contract.WatchLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MarketFactoryUnpaused)
				if err := _MarketFactory.contract.UnpackLog(event, "Unpaused", log); err != nil {
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
func (_MarketFactory *MarketFactoryFilterer) ParseUnpaused(log types.Log) (*MarketFactoryUnpaused, error) {
	event := new(MarketFactoryUnpaused)
	if err := _MarketFactory.contract.UnpackLog(event, "Unpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
