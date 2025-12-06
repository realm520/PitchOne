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

// ReferralRegistryMetaData contains all meta data concerning the ReferralRegistry contract.
var ReferralRegistryMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"initialOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"MAX_REFERRAL_DEPTH\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"accrueReferralReward\",\"inputs\":[{\"name\":\"_referrer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"authorizedCallers\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"bind\",\"inputs\":[{\"name\":\"_referrer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"campaignId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"boundAt\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"emergencyUnbind\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getReferrer\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getReferrerStats\",\"inputs\":[{\"name\":\"_referrer\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"count\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"rewards\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getReferrersBatch\",\"inputs\":[{\"name\":\"users\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[{\"name\":\"referrers\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUserVolume\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isReferralValid\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minValidVolume\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"referralCount\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"referralFeeBps\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"referrer\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setAuthorizedCaller\",\"inputs\":[{\"name\":\"caller\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"authorized\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMinValidVolume\",\"inputs\":[{\"name\":\"newMinVolume\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setReferralFeeBps\",\"inputs\":[{\"name\":\"newFeeBps\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setValidityWindow\",\"inputs\":[{\"name\":\"newWindow\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"totalReferralRewards\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateUserVolume\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"userTotalVolume\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"validityWindow\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"AuthorizedCallerUpdated\",\"inputs\":[{\"name\":\"caller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"authorized\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ParameterUpdated\",\"inputs\":[{\"name\":\"param\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ReferralAccrued\",\"inputs\":[{\"name\":\"referrer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ReferralBound\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"referrer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"campaignId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"UserVolumeUpdated\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"totalVolume\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AlreadyBound\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"existingReferrer\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"CircularReferral\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"referrer\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidFeeBps\",\"inputs\":[{\"name\":\"bps\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"InvalidReferrer\",\"inputs\":[{\"name\":\"referrer\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ReferralExpired\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"boundAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"validUntil\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"SelfReferral\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"UnauthorizedCaller\",\"inputs\":[{\"name\":\"caller\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
}

// ReferralRegistryABI is the input ABI used to generate the binding from.
// Deprecated: Use ReferralRegistryMetaData.ABI instead.
var ReferralRegistryABI = ReferralRegistryMetaData.ABI

// ReferralRegistry is an auto generated Go binding around an Ethereum contract.
type ReferralRegistry struct {
	ReferralRegistryCaller     // Read-only binding to the contract
	ReferralRegistryTransactor // Write-only binding to the contract
	ReferralRegistryFilterer   // Log filterer for contract events
}

// ReferralRegistryCaller is an auto generated read-only Go binding around an Ethereum contract.
type ReferralRegistryCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ReferralRegistryTransactor is an auto generated write-only Go binding around an Ethereum contract.
type ReferralRegistryTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ReferralRegistryFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type ReferralRegistryFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ReferralRegistrySession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type ReferralRegistrySession struct {
	Contract     *ReferralRegistry // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// ReferralRegistryCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type ReferralRegistryCallerSession struct {
	Contract *ReferralRegistryCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts           // Call options to use throughout this session
}

// ReferralRegistryTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type ReferralRegistryTransactorSession struct {
	Contract     *ReferralRegistryTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts           // Transaction auth options to use throughout this session
}

// ReferralRegistryRaw is an auto generated low-level Go binding around an Ethereum contract.
type ReferralRegistryRaw struct {
	Contract *ReferralRegistry // Generic contract binding to access the raw methods on
}

// ReferralRegistryCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type ReferralRegistryCallerRaw struct {
	Contract *ReferralRegistryCaller // Generic read-only contract binding to access the raw methods on
}

// ReferralRegistryTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type ReferralRegistryTransactorRaw struct {
	Contract *ReferralRegistryTransactor // Generic write-only contract binding to access the raw methods on
}

// NewReferralRegistry creates a new instance of ReferralRegistry, bound to a specific deployed contract.
func NewReferralRegistry(address common.Address, backend bind.ContractBackend) (*ReferralRegistry, error) {
	contract, err := bindReferralRegistry(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &ReferralRegistry{ReferralRegistryCaller: ReferralRegistryCaller{contract: contract}, ReferralRegistryTransactor: ReferralRegistryTransactor{contract: contract}, ReferralRegistryFilterer: ReferralRegistryFilterer{contract: contract}}, nil
}

// NewReferralRegistryCaller creates a new read-only instance of ReferralRegistry, bound to a specific deployed contract.
func NewReferralRegistryCaller(address common.Address, caller bind.ContractCaller) (*ReferralRegistryCaller, error) {
	contract, err := bindReferralRegistry(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryCaller{contract: contract}, nil
}

// NewReferralRegistryTransactor creates a new write-only instance of ReferralRegistry, bound to a specific deployed contract.
func NewReferralRegistryTransactor(address common.Address, transactor bind.ContractTransactor) (*ReferralRegistryTransactor, error) {
	contract, err := bindReferralRegistry(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryTransactor{contract: contract}, nil
}

// NewReferralRegistryFilterer creates a new log filterer instance of ReferralRegistry, bound to a specific deployed contract.
func NewReferralRegistryFilterer(address common.Address, filterer bind.ContractFilterer) (*ReferralRegistryFilterer, error) {
	contract, err := bindReferralRegistry(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryFilterer{contract: contract}, nil
}

// bindReferralRegistry binds a generic wrapper to an already deployed contract.
func bindReferralRegistry(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := ReferralRegistryMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ReferralRegistry *ReferralRegistryRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ReferralRegistry.Contract.ReferralRegistryCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ReferralRegistry *ReferralRegistryRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.ReferralRegistryTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ReferralRegistry *ReferralRegistryRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.ReferralRegistryTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ReferralRegistry *ReferralRegistryCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ReferralRegistry.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ReferralRegistry *ReferralRegistryTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ReferralRegistry *ReferralRegistryTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.contract.Transact(opts, method, params...)
}

// MAXREFERRALDEPTH is a free data retrieval call binding the contract method 0x89e59ea0.
//
// Solidity: function MAX_REFERRAL_DEPTH() view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCaller) MAXREFERRALDEPTH(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "MAX_REFERRAL_DEPTH")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXREFERRALDEPTH is a free data retrieval call binding the contract method 0x89e59ea0.
//
// Solidity: function MAX_REFERRAL_DEPTH() view returns(uint256)
func (_ReferralRegistry *ReferralRegistrySession) MAXREFERRALDEPTH() (*big.Int, error) {
	return _ReferralRegistry.Contract.MAXREFERRALDEPTH(&_ReferralRegistry.CallOpts)
}

// MAXREFERRALDEPTH is a free data retrieval call binding the contract method 0x89e59ea0.
//
// Solidity: function MAX_REFERRAL_DEPTH() view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCallerSession) MAXREFERRALDEPTH() (*big.Int, error) {
	return _ReferralRegistry.Contract.MAXREFERRALDEPTH(&_ReferralRegistry.CallOpts)
}

// AuthorizedCallers is a free data retrieval call binding the contract method 0x536fff6c.
//
// Solidity: function authorizedCallers(address ) view returns(bool)
func (_ReferralRegistry *ReferralRegistryCaller) AuthorizedCallers(opts *bind.CallOpts, arg0 common.Address) (bool, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "authorizedCallers", arg0)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AuthorizedCallers is a free data retrieval call binding the contract method 0x536fff6c.
//
// Solidity: function authorizedCallers(address ) view returns(bool)
func (_ReferralRegistry *ReferralRegistrySession) AuthorizedCallers(arg0 common.Address) (bool, error) {
	return _ReferralRegistry.Contract.AuthorizedCallers(&_ReferralRegistry.CallOpts, arg0)
}

// AuthorizedCallers is a free data retrieval call binding the contract method 0x536fff6c.
//
// Solidity: function authorizedCallers(address ) view returns(bool)
func (_ReferralRegistry *ReferralRegistryCallerSession) AuthorizedCallers(arg0 common.Address) (bool, error) {
	return _ReferralRegistry.Contract.AuthorizedCallers(&_ReferralRegistry.CallOpts, arg0)
}

// BoundAt is a free data retrieval call binding the contract method 0xffaaf553.
//
// Solidity: function boundAt(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCaller) BoundAt(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "boundAt", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BoundAt is a free data retrieval call binding the contract method 0xffaaf553.
//
// Solidity: function boundAt(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistrySession) BoundAt(arg0 common.Address) (*big.Int, error) {
	return _ReferralRegistry.Contract.BoundAt(&_ReferralRegistry.CallOpts, arg0)
}

// BoundAt is a free data retrieval call binding the contract method 0xffaaf553.
//
// Solidity: function boundAt(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCallerSession) BoundAt(arg0 common.Address) (*big.Int, error) {
	return _ReferralRegistry.Contract.BoundAt(&_ReferralRegistry.CallOpts, arg0)
}

// GetReferrer is a free data retrieval call binding the contract method 0x4a9fefc7.
//
// Solidity: function getReferrer(address user) view returns(address)
func (_ReferralRegistry *ReferralRegistryCaller) GetReferrer(opts *bind.CallOpts, user common.Address) (common.Address, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "getReferrer", user)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetReferrer is a free data retrieval call binding the contract method 0x4a9fefc7.
//
// Solidity: function getReferrer(address user) view returns(address)
func (_ReferralRegistry *ReferralRegistrySession) GetReferrer(user common.Address) (common.Address, error) {
	return _ReferralRegistry.Contract.GetReferrer(&_ReferralRegistry.CallOpts, user)
}

// GetReferrer is a free data retrieval call binding the contract method 0x4a9fefc7.
//
// Solidity: function getReferrer(address user) view returns(address)
func (_ReferralRegistry *ReferralRegistryCallerSession) GetReferrer(user common.Address) (common.Address, error) {
	return _ReferralRegistry.Contract.GetReferrer(&_ReferralRegistry.CallOpts, user)
}

// GetReferrerStats is a free data retrieval call binding the contract method 0x7e396110.
//
// Solidity: function getReferrerStats(address _referrer) view returns(uint256 count, uint256 rewards)
func (_ReferralRegistry *ReferralRegistryCaller) GetReferrerStats(opts *bind.CallOpts, _referrer common.Address) (struct {
	Count   *big.Int
	Rewards *big.Int
}, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "getReferrerStats", _referrer)

	outstruct := new(struct {
		Count   *big.Int
		Rewards *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Count = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.Rewards = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetReferrerStats is a free data retrieval call binding the contract method 0x7e396110.
//
// Solidity: function getReferrerStats(address _referrer) view returns(uint256 count, uint256 rewards)
func (_ReferralRegistry *ReferralRegistrySession) GetReferrerStats(_referrer common.Address) (struct {
	Count   *big.Int
	Rewards *big.Int
}, error) {
	return _ReferralRegistry.Contract.GetReferrerStats(&_ReferralRegistry.CallOpts, _referrer)
}

// GetReferrerStats is a free data retrieval call binding the contract method 0x7e396110.
//
// Solidity: function getReferrerStats(address _referrer) view returns(uint256 count, uint256 rewards)
func (_ReferralRegistry *ReferralRegistryCallerSession) GetReferrerStats(_referrer common.Address) (struct {
	Count   *big.Int
	Rewards *big.Int
}, error) {
	return _ReferralRegistry.Contract.GetReferrerStats(&_ReferralRegistry.CallOpts, _referrer)
}

// GetReferrersBatch is a free data retrieval call binding the contract method 0x2f31132f.
//
// Solidity: function getReferrersBatch(address[] users) view returns(address[] referrers)
func (_ReferralRegistry *ReferralRegistryCaller) GetReferrersBatch(opts *bind.CallOpts, users []common.Address) ([]common.Address, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "getReferrersBatch", users)

	if err != nil {
		return *new([]common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)

	return out0, err

}

// GetReferrersBatch is a free data retrieval call binding the contract method 0x2f31132f.
//
// Solidity: function getReferrersBatch(address[] users) view returns(address[] referrers)
func (_ReferralRegistry *ReferralRegistrySession) GetReferrersBatch(users []common.Address) ([]common.Address, error) {
	return _ReferralRegistry.Contract.GetReferrersBatch(&_ReferralRegistry.CallOpts, users)
}

// GetReferrersBatch is a free data retrieval call binding the contract method 0x2f31132f.
//
// Solidity: function getReferrersBatch(address[] users) view returns(address[] referrers)
func (_ReferralRegistry *ReferralRegistryCallerSession) GetReferrersBatch(users []common.Address) ([]common.Address, error) {
	return _ReferralRegistry.Contract.GetReferrersBatch(&_ReferralRegistry.CallOpts, users)
}

// GetUserVolume is a free data retrieval call binding the contract method 0xbbf84ee7.
//
// Solidity: function getUserVolume(address user) view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCaller) GetUserVolume(opts *bind.CallOpts, user common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "getUserVolume", user)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetUserVolume is a free data retrieval call binding the contract method 0xbbf84ee7.
//
// Solidity: function getUserVolume(address user) view returns(uint256)
func (_ReferralRegistry *ReferralRegistrySession) GetUserVolume(user common.Address) (*big.Int, error) {
	return _ReferralRegistry.Contract.GetUserVolume(&_ReferralRegistry.CallOpts, user)
}

// GetUserVolume is a free data retrieval call binding the contract method 0xbbf84ee7.
//
// Solidity: function getUserVolume(address user) view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCallerSession) GetUserVolume(user common.Address) (*big.Int, error) {
	return _ReferralRegistry.Contract.GetUserVolume(&_ReferralRegistry.CallOpts, user)
}

// IsReferralValid is a free data retrieval call binding the contract method 0x88ff22bb.
//
// Solidity: function isReferralValid(address user) view returns(bool)
func (_ReferralRegistry *ReferralRegistryCaller) IsReferralValid(opts *bind.CallOpts, user common.Address) (bool, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "isReferralValid", user)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsReferralValid is a free data retrieval call binding the contract method 0x88ff22bb.
//
// Solidity: function isReferralValid(address user) view returns(bool)
func (_ReferralRegistry *ReferralRegistrySession) IsReferralValid(user common.Address) (bool, error) {
	return _ReferralRegistry.Contract.IsReferralValid(&_ReferralRegistry.CallOpts, user)
}

// IsReferralValid is a free data retrieval call binding the contract method 0x88ff22bb.
//
// Solidity: function isReferralValid(address user) view returns(bool)
func (_ReferralRegistry *ReferralRegistryCallerSession) IsReferralValid(user common.Address) (bool, error) {
	return _ReferralRegistry.Contract.IsReferralValid(&_ReferralRegistry.CallOpts, user)
}

// MinValidVolume is a free data retrieval call binding the contract method 0x3cf3445d.
//
// Solidity: function minValidVolume() view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCaller) MinValidVolume(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "minValidVolume")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MinValidVolume is a free data retrieval call binding the contract method 0x3cf3445d.
//
// Solidity: function minValidVolume() view returns(uint256)
func (_ReferralRegistry *ReferralRegistrySession) MinValidVolume() (*big.Int, error) {
	return _ReferralRegistry.Contract.MinValidVolume(&_ReferralRegistry.CallOpts)
}

// MinValidVolume is a free data retrieval call binding the contract method 0x3cf3445d.
//
// Solidity: function minValidVolume() view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCallerSession) MinValidVolume() (*big.Int, error) {
	return _ReferralRegistry.Contract.MinValidVolume(&_ReferralRegistry.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_ReferralRegistry *ReferralRegistryCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_ReferralRegistry *ReferralRegistrySession) Owner() (common.Address, error) {
	return _ReferralRegistry.Contract.Owner(&_ReferralRegistry.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_ReferralRegistry *ReferralRegistryCallerSession) Owner() (common.Address, error) {
	return _ReferralRegistry.Contract.Owner(&_ReferralRegistry.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_ReferralRegistry *ReferralRegistryCaller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_ReferralRegistry *ReferralRegistrySession) Paused() (bool, error) {
	return _ReferralRegistry.Contract.Paused(&_ReferralRegistry.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_ReferralRegistry *ReferralRegistryCallerSession) Paused() (bool, error) {
	return _ReferralRegistry.Contract.Paused(&_ReferralRegistry.CallOpts)
}

// ReferralCount is a free data retrieval call binding the contract method 0xdb74559b.
//
// Solidity: function referralCount(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCaller) ReferralCount(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "referralCount", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ReferralCount is a free data retrieval call binding the contract method 0xdb74559b.
//
// Solidity: function referralCount(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistrySession) ReferralCount(arg0 common.Address) (*big.Int, error) {
	return _ReferralRegistry.Contract.ReferralCount(&_ReferralRegistry.CallOpts, arg0)
}

// ReferralCount is a free data retrieval call binding the contract method 0xdb74559b.
//
// Solidity: function referralCount(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCallerSession) ReferralCount(arg0 common.Address) (*big.Int, error) {
	return _ReferralRegistry.Contract.ReferralCount(&_ReferralRegistry.CallOpts, arg0)
}

// ReferralFeeBps is a free data retrieval call binding the contract method 0xd4bdb266.
//
// Solidity: function referralFeeBps() view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCaller) ReferralFeeBps(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "referralFeeBps")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ReferralFeeBps is a free data retrieval call binding the contract method 0xd4bdb266.
//
// Solidity: function referralFeeBps() view returns(uint256)
func (_ReferralRegistry *ReferralRegistrySession) ReferralFeeBps() (*big.Int, error) {
	return _ReferralRegistry.Contract.ReferralFeeBps(&_ReferralRegistry.CallOpts)
}

// ReferralFeeBps is a free data retrieval call binding the contract method 0xd4bdb266.
//
// Solidity: function referralFeeBps() view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCallerSession) ReferralFeeBps() (*big.Int, error) {
	return _ReferralRegistry.Contract.ReferralFeeBps(&_ReferralRegistry.CallOpts)
}

// Referrer is a free data retrieval call binding the contract method 0x2cf003c2.
//
// Solidity: function referrer(address ) view returns(address)
func (_ReferralRegistry *ReferralRegistryCaller) Referrer(opts *bind.CallOpts, arg0 common.Address) (common.Address, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "referrer", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Referrer is a free data retrieval call binding the contract method 0x2cf003c2.
//
// Solidity: function referrer(address ) view returns(address)
func (_ReferralRegistry *ReferralRegistrySession) Referrer(arg0 common.Address) (common.Address, error) {
	return _ReferralRegistry.Contract.Referrer(&_ReferralRegistry.CallOpts, arg0)
}

// Referrer is a free data retrieval call binding the contract method 0x2cf003c2.
//
// Solidity: function referrer(address ) view returns(address)
func (_ReferralRegistry *ReferralRegistryCallerSession) Referrer(arg0 common.Address) (common.Address, error) {
	return _ReferralRegistry.Contract.Referrer(&_ReferralRegistry.CallOpts, arg0)
}

// TotalReferralRewards is a free data retrieval call binding the contract method 0xd9b8f602.
//
// Solidity: function totalReferralRewards(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCaller) TotalReferralRewards(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "totalReferralRewards", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalReferralRewards is a free data retrieval call binding the contract method 0xd9b8f602.
//
// Solidity: function totalReferralRewards(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistrySession) TotalReferralRewards(arg0 common.Address) (*big.Int, error) {
	return _ReferralRegistry.Contract.TotalReferralRewards(&_ReferralRegistry.CallOpts, arg0)
}

// TotalReferralRewards is a free data retrieval call binding the contract method 0xd9b8f602.
//
// Solidity: function totalReferralRewards(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCallerSession) TotalReferralRewards(arg0 common.Address) (*big.Int, error) {
	return _ReferralRegistry.Contract.TotalReferralRewards(&_ReferralRegistry.CallOpts, arg0)
}

// UserTotalVolume is a free data retrieval call binding the contract method 0x8d9a54fa.
//
// Solidity: function userTotalVolume(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCaller) UserTotalVolume(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "userTotalVolume", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// UserTotalVolume is a free data retrieval call binding the contract method 0x8d9a54fa.
//
// Solidity: function userTotalVolume(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistrySession) UserTotalVolume(arg0 common.Address) (*big.Int, error) {
	return _ReferralRegistry.Contract.UserTotalVolume(&_ReferralRegistry.CallOpts, arg0)
}

// UserTotalVolume is a free data retrieval call binding the contract method 0x8d9a54fa.
//
// Solidity: function userTotalVolume(address ) view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCallerSession) UserTotalVolume(arg0 common.Address) (*big.Int, error) {
	return _ReferralRegistry.Contract.UserTotalVolume(&_ReferralRegistry.CallOpts, arg0)
}

// ValidityWindow is a free data retrieval call binding the contract method 0x885ce835.
//
// Solidity: function validityWindow() view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCaller) ValidityWindow(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ReferralRegistry.contract.Call(opts, &out, "validityWindow")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ValidityWindow is a free data retrieval call binding the contract method 0x885ce835.
//
// Solidity: function validityWindow() view returns(uint256)
func (_ReferralRegistry *ReferralRegistrySession) ValidityWindow() (*big.Int, error) {
	return _ReferralRegistry.Contract.ValidityWindow(&_ReferralRegistry.CallOpts)
}

// ValidityWindow is a free data retrieval call binding the contract method 0x885ce835.
//
// Solidity: function validityWindow() view returns(uint256)
func (_ReferralRegistry *ReferralRegistryCallerSession) ValidityWindow() (*big.Int, error) {
	return _ReferralRegistry.Contract.ValidityWindow(&_ReferralRegistry.CallOpts)
}

// AccrueReferralReward is a paid mutator transaction binding the contract method 0xef7c2fa9.
//
// Solidity: function accrueReferralReward(address _referrer, address user, uint256 amount) returns()
func (_ReferralRegistry *ReferralRegistryTransactor) AccrueReferralReward(opts *bind.TransactOpts, _referrer common.Address, user common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "accrueReferralReward", _referrer, user, amount)
}

// AccrueReferralReward is a paid mutator transaction binding the contract method 0xef7c2fa9.
//
// Solidity: function accrueReferralReward(address _referrer, address user, uint256 amount) returns()
func (_ReferralRegistry *ReferralRegistrySession) AccrueReferralReward(_referrer common.Address, user common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.AccrueReferralReward(&_ReferralRegistry.TransactOpts, _referrer, user, amount)
}

// AccrueReferralReward is a paid mutator transaction binding the contract method 0xef7c2fa9.
//
// Solidity: function accrueReferralReward(address _referrer, address user, uint256 amount) returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) AccrueReferralReward(_referrer common.Address, user common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.AccrueReferralReward(&_ReferralRegistry.TransactOpts, _referrer, user, amount)
}

// Bind is a paid mutator transaction binding the contract method 0x9c649fee.
//
// Solidity: function bind(address _referrer, uint256 campaignId) returns()
func (_ReferralRegistry *ReferralRegistryTransactor) Bind(opts *bind.TransactOpts, _referrer common.Address, campaignId *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "bind", _referrer, campaignId)
}

// Bind is a paid mutator transaction binding the contract method 0x9c649fee.
//
// Solidity: function bind(address _referrer, uint256 campaignId) returns()
func (_ReferralRegistry *ReferralRegistrySession) Bind(_referrer common.Address, campaignId *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.Bind(&_ReferralRegistry.TransactOpts, _referrer, campaignId)
}

// Bind is a paid mutator transaction binding the contract method 0x9c649fee.
//
// Solidity: function bind(address _referrer, uint256 campaignId) returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) Bind(_referrer common.Address, campaignId *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.Bind(&_ReferralRegistry.TransactOpts, _referrer, campaignId)
}

// EmergencyUnbind is a paid mutator transaction binding the contract method 0x7b0cf99c.
//
// Solidity: function emergencyUnbind(address user) returns()
func (_ReferralRegistry *ReferralRegistryTransactor) EmergencyUnbind(opts *bind.TransactOpts, user common.Address) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "emergencyUnbind", user)
}

// EmergencyUnbind is a paid mutator transaction binding the contract method 0x7b0cf99c.
//
// Solidity: function emergencyUnbind(address user) returns()
func (_ReferralRegistry *ReferralRegistrySession) EmergencyUnbind(user common.Address) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.EmergencyUnbind(&_ReferralRegistry.TransactOpts, user)
}

// EmergencyUnbind is a paid mutator transaction binding the contract method 0x7b0cf99c.
//
// Solidity: function emergencyUnbind(address user) returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) EmergencyUnbind(user common.Address) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.EmergencyUnbind(&_ReferralRegistry.TransactOpts, user)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_ReferralRegistry *ReferralRegistryTransactor) Pause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "pause")
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_ReferralRegistry *ReferralRegistrySession) Pause() (*types.Transaction, error) {
	return _ReferralRegistry.Contract.Pause(&_ReferralRegistry.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) Pause() (*types.Transaction, error) {
	return _ReferralRegistry.Contract.Pause(&_ReferralRegistry.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_ReferralRegistry *ReferralRegistryTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_ReferralRegistry *ReferralRegistrySession) RenounceOwnership() (*types.Transaction, error) {
	return _ReferralRegistry.Contract.RenounceOwnership(&_ReferralRegistry.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _ReferralRegistry.Contract.RenounceOwnership(&_ReferralRegistry.TransactOpts)
}

// SetAuthorizedCaller is a paid mutator transaction binding the contract method 0x454bbd29.
//
// Solidity: function setAuthorizedCaller(address caller, bool authorized) returns()
func (_ReferralRegistry *ReferralRegistryTransactor) SetAuthorizedCaller(opts *bind.TransactOpts, caller common.Address, authorized bool) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "setAuthorizedCaller", caller, authorized)
}

// SetAuthorizedCaller is a paid mutator transaction binding the contract method 0x454bbd29.
//
// Solidity: function setAuthorizedCaller(address caller, bool authorized) returns()
func (_ReferralRegistry *ReferralRegistrySession) SetAuthorizedCaller(caller common.Address, authorized bool) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.SetAuthorizedCaller(&_ReferralRegistry.TransactOpts, caller, authorized)
}

// SetAuthorizedCaller is a paid mutator transaction binding the contract method 0x454bbd29.
//
// Solidity: function setAuthorizedCaller(address caller, bool authorized) returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) SetAuthorizedCaller(caller common.Address, authorized bool) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.SetAuthorizedCaller(&_ReferralRegistry.TransactOpts, caller, authorized)
}

// SetMinValidVolume is a paid mutator transaction binding the contract method 0xb8dde392.
//
// Solidity: function setMinValidVolume(uint256 newMinVolume) returns()
func (_ReferralRegistry *ReferralRegistryTransactor) SetMinValidVolume(opts *bind.TransactOpts, newMinVolume *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "setMinValidVolume", newMinVolume)
}

// SetMinValidVolume is a paid mutator transaction binding the contract method 0xb8dde392.
//
// Solidity: function setMinValidVolume(uint256 newMinVolume) returns()
func (_ReferralRegistry *ReferralRegistrySession) SetMinValidVolume(newMinVolume *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.SetMinValidVolume(&_ReferralRegistry.TransactOpts, newMinVolume)
}

// SetMinValidVolume is a paid mutator transaction binding the contract method 0xb8dde392.
//
// Solidity: function setMinValidVolume(uint256 newMinVolume) returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) SetMinValidVolume(newMinVolume *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.SetMinValidVolume(&_ReferralRegistry.TransactOpts, newMinVolume)
}

// SetReferralFeeBps is a paid mutator transaction binding the contract method 0xc9cec0ab.
//
// Solidity: function setReferralFeeBps(uint256 newFeeBps) returns()
func (_ReferralRegistry *ReferralRegistryTransactor) SetReferralFeeBps(opts *bind.TransactOpts, newFeeBps *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "setReferralFeeBps", newFeeBps)
}

// SetReferralFeeBps is a paid mutator transaction binding the contract method 0xc9cec0ab.
//
// Solidity: function setReferralFeeBps(uint256 newFeeBps) returns()
func (_ReferralRegistry *ReferralRegistrySession) SetReferralFeeBps(newFeeBps *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.SetReferralFeeBps(&_ReferralRegistry.TransactOpts, newFeeBps)
}

// SetReferralFeeBps is a paid mutator transaction binding the contract method 0xc9cec0ab.
//
// Solidity: function setReferralFeeBps(uint256 newFeeBps) returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) SetReferralFeeBps(newFeeBps *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.SetReferralFeeBps(&_ReferralRegistry.TransactOpts, newFeeBps)
}

// SetValidityWindow is a paid mutator transaction binding the contract method 0xbd5582a9.
//
// Solidity: function setValidityWindow(uint256 newWindow) returns()
func (_ReferralRegistry *ReferralRegistryTransactor) SetValidityWindow(opts *bind.TransactOpts, newWindow *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "setValidityWindow", newWindow)
}

// SetValidityWindow is a paid mutator transaction binding the contract method 0xbd5582a9.
//
// Solidity: function setValidityWindow(uint256 newWindow) returns()
func (_ReferralRegistry *ReferralRegistrySession) SetValidityWindow(newWindow *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.SetValidityWindow(&_ReferralRegistry.TransactOpts, newWindow)
}

// SetValidityWindow is a paid mutator transaction binding the contract method 0xbd5582a9.
//
// Solidity: function setValidityWindow(uint256 newWindow) returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) SetValidityWindow(newWindow *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.SetValidityWindow(&_ReferralRegistry.TransactOpts, newWindow)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_ReferralRegistry *ReferralRegistryTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_ReferralRegistry *ReferralRegistrySession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.TransferOwnership(&_ReferralRegistry.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.TransferOwnership(&_ReferralRegistry.TransactOpts, newOwner)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_ReferralRegistry *ReferralRegistryTransactor) Unpause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "unpause")
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_ReferralRegistry *ReferralRegistrySession) Unpause() (*types.Transaction, error) {
	return _ReferralRegistry.Contract.Unpause(&_ReferralRegistry.TransactOpts)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) Unpause() (*types.Transaction, error) {
	return _ReferralRegistry.Contract.Unpause(&_ReferralRegistry.TransactOpts)
}

// UpdateUserVolume is a paid mutator transaction binding the contract method 0xb5f666f9.
//
// Solidity: function updateUserVolume(address user, uint256 amount) returns()
func (_ReferralRegistry *ReferralRegistryTransactor) UpdateUserVolume(opts *bind.TransactOpts, user common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.contract.Transact(opts, "updateUserVolume", user, amount)
}

// UpdateUserVolume is a paid mutator transaction binding the contract method 0xb5f666f9.
//
// Solidity: function updateUserVolume(address user, uint256 amount) returns()
func (_ReferralRegistry *ReferralRegistrySession) UpdateUserVolume(user common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.UpdateUserVolume(&_ReferralRegistry.TransactOpts, user, amount)
}

// UpdateUserVolume is a paid mutator transaction binding the contract method 0xb5f666f9.
//
// Solidity: function updateUserVolume(address user, uint256 amount) returns()
func (_ReferralRegistry *ReferralRegistryTransactorSession) UpdateUserVolume(user common.Address, amount *big.Int) (*types.Transaction, error) {
	return _ReferralRegistry.Contract.UpdateUserVolume(&_ReferralRegistry.TransactOpts, user, amount)
}

// ReferralRegistryAuthorizedCallerUpdatedIterator is returned from FilterAuthorizedCallerUpdated and is used to iterate over the raw logs and unpacked data for AuthorizedCallerUpdated events raised by the ReferralRegistry contract.
type ReferralRegistryAuthorizedCallerUpdatedIterator struct {
	Event *ReferralRegistryAuthorizedCallerUpdated // Event containing the contract specifics and raw log

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
func (it *ReferralRegistryAuthorizedCallerUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ReferralRegistryAuthorizedCallerUpdated)
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
		it.Event = new(ReferralRegistryAuthorizedCallerUpdated)
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
func (it *ReferralRegistryAuthorizedCallerUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ReferralRegistryAuthorizedCallerUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ReferralRegistryAuthorizedCallerUpdated represents a AuthorizedCallerUpdated event raised by the ReferralRegistry contract.
type ReferralRegistryAuthorizedCallerUpdated struct {
	Caller     common.Address
	Authorized bool
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterAuthorizedCallerUpdated is a free log retrieval operation binding the contract event 0xad857fa38c9319cb80848f1ef2f924383b90297eb5d71755738ff037d100faa1.
//
// Solidity: event AuthorizedCallerUpdated(address indexed caller, bool authorized)
func (_ReferralRegistry *ReferralRegistryFilterer) FilterAuthorizedCallerUpdated(opts *bind.FilterOpts, caller []common.Address) (*ReferralRegistryAuthorizedCallerUpdatedIterator, error) {

	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _ReferralRegistry.contract.FilterLogs(opts, "AuthorizedCallerUpdated", callerRule)
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryAuthorizedCallerUpdatedIterator{contract: _ReferralRegistry.contract, event: "AuthorizedCallerUpdated", logs: logs, sub: sub}, nil
}

// WatchAuthorizedCallerUpdated is a free log subscription operation binding the contract event 0xad857fa38c9319cb80848f1ef2f924383b90297eb5d71755738ff037d100faa1.
//
// Solidity: event AuthorizedCallerUpdated(address indexed caller, bool authorized)
func (_ReferralRegistry *ReferralRegistryFilterer) WatchAuthorizedCallerUpdated(opts *bind.WatchOpts, sink chan<- *ReferralRegistryAuthorizedCallerUpdated, caller []common.Address) (event.Subscription, error) {

	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _ReferralRegistry.contract.WatchLogs(opts, "AuthorizedCallerUpdated", callerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ReferralRegistryAuthorizedCallerUpdated)
				if err := _ReferralRegistry.contract.UnpackLog(event, "AuthorizedCallerUpdated", log); err != nil {
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

// ParseAuthorizedCallerUpdated is a log parse operation binding the contract event 0xad857fa38c9319cb80848f1ef2f924383b90297eb5d71755738ff037d100faa1.
//
// Solidity: event AuthorizedCallerUpdated(address indexed caller, bool authorized)
func (_ReferralRegistry *ReferralRegistryFilterer) ParseAuthorizedCallerUpdated(log types.Log) (*ReferralRegistryAuthorizedCallerUpdated, error) {
	event := new(ReferralRegistryAuthorizedCallerUpdated)
	if err := _ReferralRegistry.contract.UnpackLog(event, "AuthorizedCallerUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ReferralRegistryOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the ReferralRegistry contract.
type ReferralRegistryOwnershipTransferredIterator struct {
	Event *ReferralRegistryOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *ReferralRegistryOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ReferralRegistryOwnershipTransferred)
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
		it.Event = new(ReferralRegistryOwnershipTransferred)
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
func (it *ReferralRegistryOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ReferralRegistryOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ReferralRegistryOwnershipTransferred represents a OwnershipTransferred event raised by the ReferralRegistry contract.
type ReferralRegistryOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_ReferralRegistry *ReferralRegistryFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*ReferralRegistryOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _ReferralRegistry.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryOwnershipTransferredIterator{contract: _ReferralRegistry.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_ReferralRegistry *ReferralRegistryFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *ReferralRegistryOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _ReferralRegistry.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ReferralRegistryOwnershipTransferred)
				if err := _ReferralRegistry.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_ReferralRegistry *ReferralRegistryFilterer) ParseOwnershipTransferred(log types.Log) (*ReferralRegistryOwnershipTransferred, error) {
	event := new(ReferralRegistryOwnershipTransferred)
	if err := _ReferralRegistry.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ReferralRegistryParameterUpdatedIterator is returned from FilterParameterUpdated and is used to iterate over the raw logs and unpacked data for ParameterUpdated events raised by the ReferralRegistry contract.
type ReferralRegistryParameterUpdatedIterator struct {
	Event *ReferralRegistryParameterUpdated // Event containing the contract specifics and raw log

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
func (it *ReferralRegistryParameterUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ReferralRegistryParameterUpdated)
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
		it.Event = new(ReferralRegistryParameterUpdated)
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
func (it *ReferralRegistryParameterUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ReferralRegistryParameterUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ReferralRegistryParameterUpdated represents a ParameterUpdated event raised by the ReferralRegistry contract.
type ReferralRegistryParameterUpdated struct {
	Param string
	Value *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterParameterUpdated is a free log retrieval operation binding the contract event 0x3a64504f0bc0c335e2aecb78638a257e0351a3fe0370861fd54ee4190b920933.
//
// Solidity: event ParameterUpdated(string param, uint256 value)
func (_ReferralRegistry *ReferralRegistryFilterer) FilterParameterUpdated(opts *bind.FilterOpts) (*ReferralRegistryParameterUpdatedIterator, error) {

	logs, sub, err := _ReferralRegistry.contract.FilterLogs(opts, "ParameterUpdated")
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryParameterUpdatedIterator{contract: _ReferralRegistry.contract, event: "ParameterUpdated", logs: logs, sub: sub}, nil
}

// WatchParameterUpdated is a free log subscription operation binding the contract event 0x3a64504f0bc0c335e2aecb78638a257e0351a3fe0370861fd54ee4190b920933.
//
// Solidity: event ParameterUpdated(string param, uint256 value)
func (_ReferralRegistry *ReferralRegistryFilterer) WatchParameterUpdated(opts *bind.WatchOpts, sink chan<- *ReferralRegistryParameterUpdated) (event.Subscription, error) {

	logs, sub, err := _ReferralRegistry.contract.WatchLogs(opts, "ParameterUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ReferralRegistryParameterUpdated)
				if err := _ReferralRegistry.contract.UnpackLog(event, "ParameterUpdated", log); err != nil {
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

// ParseParameterUpdated is a log parse operation binding the contract event 0x3a64504f0bc0c335e2aecb78638a257e0351a3fe0370861fd54ee4190b920933.
//
// Solidity: event ParameterUpdated(string param, uint256 value)
func (_ReferralRegistry *ReferralRegistryFilterer) ParseParameterUpdated(log types.Log) (*ReferralRegistryParameterUpdated, error) {
	event := new(ReferralRegistryParameterUpdated)
	if err := _ReferralRegistry.contract.UnpackLog(event, "ParameterUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ReferralRegistryPausedIterator is returned from FilterPaused and is used to iterate over the raw logs and unpacked data for Paused events raised by the ReferralRegistry contract.
type ReferralRegistryPausedIterator struct {
	Event *ReferralRegistryPaused // Event containing the contract specifics and raw log

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
func (it *ReferralRegistryPausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ReferralRegistryPaused)
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
		it.Event = new(ReferralRegistryPaused)
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
func (it *ReferralRegistryPausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ReferralRegistryPausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ReferralRegistryPaused represents a Paused event raised by the ReferralRegistry contract.
type ReferralRegistryPaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterPaused is a free log retrieval operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_ReferralRegistry *ReferralRegistryFilterer) FilterPaused(opts *bind.FilterOpts) (*ReferralRegistryPausedIterator, error) {

	logs, sub, err := _ReferralRegistry.contract.FilterLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryPausedIterator{contract: _ReferralRegistry.contract, event: "Paused", logs: logs, sub: sub}, nil
}

// WatchPaused is a free log subscription operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_ReferralRegistry *ReferralRegistryFilterer) WatchPaused(opts *bind.WatchOpts, sink chan<- *ReferralRegistryPaused) (event.Subscription, error) {

	logs, sub, err := _ReferralRegistry.contract.WatchLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ReferralRegistryPaused)
				if err := _ReferralRegistry.contract.UnpackLog(event, "Paused", log); err != nil {
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
func (_ReferralRegistry *ReferralRegistryFilterer) ParsePaused(log types.Log) (*ReferralRegistryPaused, error) {
	event := new(ReferralRegistryPaused)
	if err := _ReferralRegistry.contract.UnpackLog(event, "Paused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ReferralRegistryReferralAccruedIterator is returned from FilterReferralAccrued and is used to iterate over the raw logs and unpacked data for ReferralAccrued events raised by the ReferralRegistry contract.
type ReferralRegistryReferralAccruedIterator struct {
	Event *ReferralRegistryReferralAccrued // Event containing the contract specifics and raw log

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
func (it *ReferralRegistryReferralAccruedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ReferralRegistryReferralAccrued)
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
		it.Event = new(ReferralRegistryReferralAccrued)
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
func (it *ReferralRegistryReferralAccruedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ReferralRegistryReferralAccruedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ReferralRegistryReferralAccrued represents a ReferralAccrued event raised by the ReferralRegistry contract.
type ReferralRegistryReferralAccrued struct {
	Referrer  common.Address
	User      common.Address
	Amount    *big.Int
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterReferralAccrued is a free log retrieval operation binding the contract event 0x2cebb4472b8c39bf7c562b26c887d0e824269fdbb071767adf81b9efd11a91dc.
//
// Solidity: event ReferralAccrued(address indexed referrer, address indexed user, uint256 amount, uint256 timestamp)
func (_ReferralRegistry *ReferralRegistryFilterer) FilterReferralAccrued(opts *bind.FilterOpts, referrer []common.Address, user []common.Address) (*ReferralRegistryReferralAccruedIterator, error) {

	var referrerRule []interface{}
	for _, referrerItem := range referrer {
		referrerRule = append(referrerRule, referrerItem)
	}
	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	logs, sub, err := _ReferralRegistry.contract.FilterLogs(opts, "ReferralAccrued", referrerRule, userRule)
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryReferralAccruedIterator{contract: _ReferralRegistry.contract, event: "ReferralAccrued", logs: logs, sub: sub}, nil
}

// WatchReferralAccrued is a free log subscription operation binding the contract event 0x2cebb4472b8c39bf7c562b26c887d0e824269fdbb071767adf81b9efd11a91dc.
//
// Solidity: event ReferralAccrued(address indexed referrer, address indexed user, uint256 amount, uint256 timestamp)
func (_ReferralRegistry *ReferralRegistryFilterer) WatchReferralAccrued(opts *bind.WatchOpts, sink chan<- *ReferralRegistryReferralAccrued, referrer []common.Address, user []common.Address) (event.Subscription, error) {

	var referrerRule []interface{}
	for _, referrerItem := range referrer {
		referrerRule = append(referrerRule, referrerItem)
	}
	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	logs, sub, err := _ReferralRegistry.contract.WatchLogs(opts, "ReferralAccrued", referrerRule, userRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ReferralRegistryReferralAccrued)
				if err := _ReferralRegistry.contract.UnpackLog(event, "ReferralAccrued", log); err != nil {
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

// ParseReferralAccrued is a log parse operation binding the contract event 0x2cebb4472b8c39bf7c562b26c887d0e824269fdbb071767adf81b9efd11a91dc.
//
// Solidity: event ReferralAccrued(address indexed referrer, address indexed user, uint256 amount, uint256 timestamp)
func (_ReferralRegistry *ReferralRegistryFilterer) ParseReferralAccrued(log types.Log) (*ReferralRegistryReferralAccrued, error) {
	event := new(ReferralRegistryReferralAccrued)
	if err := _ReferralRegistry.contract.UnpackLog(event, "ReferralAccrued", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ReferralRegistryReferralBoundIterator is returned from FilterReferralBound and is used to iterate over the raw logs and unpacked data for ReferralBound events raised by the ReferralRegistry contract.
type ReferralRegistryReferralBoundIterator struct {
	Event *ReferralRegistryReferralBound // Event containing the contract specifics and raw log

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
func (it *ReferralRegistryReferralBoundIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ReferralRegistryReferralBound)
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
		it.Event = new(ReferralRegistryReferralBound)
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
func (it *ReferralRegistryReferralBoundIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ReferralRegistryReferralBoundIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ReferralRegistryReferralBound represents a ReferralBound event raised by the ReferralRegistry contract.
type ReferralRegistryReferralBound struct {
	User       common.Address
	Referrer   common.Address
	CampaignId *big.Int
	Timestamp  *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterReferralBound is a free log retrieval operation binding the contract event 0x2d74bdc87332610f6fa6f53ac406b8e1f1db1b5ddd7d3289938241bfb5aab251.
//
// Solidity: event ReferralBound(address indexed user, address indexed referrer, uint256 indexed campaignId, uint256 timestamp)
func (_ReferralRegistry *ReferralRegistryFilterer) FilterReferralBound(opts *bind.FilterOpts, user []common.Address, referrer []common.Address, campaignId []*big.Int) (*ReferralRegistryReferralBoundIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var referrerRule []interface{}
	for _, referrerItem := range referrer {
		referrerRule = append(referrerRule, referrerItem)
	}
	var campaignIdRule []interface{}
	for _, campaignIdItem := range campaignId {
		campaignIdRule = append(campaignIdRule, campaignIdItem)
	}

	logs, sub, err := _ReferralRegistry.contract.FilterLogs(opts, "ReferralBound", userRule, referrerRule, campaignIdRule)
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryReferralBoundIterator{contract: _ReferralRegistry.contract, event: "ReferralBound", logs: logs, sub: sub}, nil
}

// WatchReferralBound is a free log subscription operation binding the contract event 0x2d74bdc87332610f6fa6f53ac406b8e1f1db1b5ddd7d3289938241bfb5aab251.
//
// Solidity: event ReferralBound(address indexed user, address indexed referrer, uint256 indexed campaignId, uint256 timestamp)
func (_ReferralRegistry *ReferralRegistryFilterer) WatchReferralBound(opts *bind.WatchOpts, sink chan<- *ReferralRegistryReferralBound, user []common.Address, referrer []common.Address, campaignId []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var referrerRule []interface{}
	for _, referrerItem := range referrer {
		referrerRule = append(referrerRule, referrerItem)
	}
	var campaignIdRule []interface{}
	for _, campaignIdItem := range campaignId {
		campaignIdRule = append(campaignIdRule, campaignIdItem)
	}

	logs, sub, err := _ReferralRegistry.contract.WatchLogs(opts, "ReferralBound", userRule, referrerRule, campaignIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ReferralRegistryReferralBound)
				if err := _ReferralRegistry.contract.UnpackLog(event, "ReferralBound", log); err != nil {
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

// ParseReferralBound is a log parse operation binding the contract event 0x2d74bdc87332610f6fa6f53ac406b8e1f1db1b5ddd7d3289938241bfb5aab251.
//
// Solidity: event ReferralBound(address indexed user, address indexed referrer, uint256 indexed campaignId, uint256 timestamp)
func (_ReferralRegistry *ReferralRegistryFilterer) ParseReferralBound(log types.Log) (*ReferralRegistryReferralBound, error) {
	event := new(ReferralRegistryReferralBound)
	if err := _ReferralRegistry.contract.UnpackLog(event, "ReferralBound", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ReferralRegistryUnpausedIterator is returned from FilterUnpaused and is used to iterate over the raw logs and unpacked data for Unpaused events raised by the ReferralRegistry contract.
type ReferralRegistryUnpausedIterator struct {
	Event *ReferralRegistryUnpaused // Event containing the contract specifics and raw log

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
func (it *ReferralRegistryUnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ReferralRegistryUnpaused)
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
		it.Event = new(ReferralRegistryUnpaused)
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
func (it *ReferralRegistryUnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ReferralRegistryUnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ReferralRegistryUnpaused represents a Unpaused event raised by the ReferralRegistry contract.
type ReferralRegistryUnpaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUnpaused is a free log retrieval operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_ReferralRegistry *ReferralRegistryFilterer) FilterUnpaused(opts *bind.FilterOpts) (*ReferralRegistryUnpausedIterator, error) {

	logs, sub, err := _ReferralRegistry.contract.FilterLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryUnpausedIterator{contract: _ReferralRegistry.contract, event: "Unpaused", logs: logs, sub: sub}, nil
}

// WatchUnpaused is a free log subscription operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_ReferralRegistry *ReferralRegistryFilterer) WatchUnpaused(opts *bind.WatchOpts, sink chan<- *ReferralRegistryUnpaused) (event.Subscription, error) {

	logs, sub, err := _ReferralRegistry.contract.WatchLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ReferralRegistryUnpaused)
				if err := _ReferralRegistry.contract.UnpackLog(event, "Unpaused", log); err != nil {
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
func (_ReferralRegistry *ReferralRegistryFilterer) ParseUnpaused(log types.Log) (*ReferralRegistryUnpaused, error) {
	event := new(ReferralRegistryUnpaused)
	if err := _ReferralRegistry.contract.UnpackLog(event, "Unpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ReferralRegistryUserVolumeUpdatedIterator is returned from FilterUserVolumeUpdated and is used to iterate over the raw logs and unpacked data for UserVolumeUpdated events raised by the ReferralRegistry contract.
type ReferralRegistryUserVolumeUpdatedIterator struct {
	Event *ReferralRegistryUserVolumeUpdated // Event containing the contract specifics and raw log

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
func (it *ReferralRegistryUserVolumeUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ReferralRegistryUserVolumeUpdated)
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
		it.Event = new(ReferralRegistryUserVolumeUpdated)
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
func (it *ReferralRegistryUserVolumeUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ReferralRegistryUserVolumeUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ReferralRegistryUserVolumeUpdated represents a UserVolumeUpdated event raised by the ReferralRegistry contract.
type ReferralRegistryUserVolumeUpdated struct {
	User        common.Address
	Amount      *big.Int
	TotalVolume *big.Int
	Timestamp   *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterUserVolumeUpdated is a free log retrieval operation binding the contract event 0x26289c4896ff72e686a457fc7584fc76bea0fdc419a1de0181c496280e0de121.
//
// Solidity: event UserVolumeUpdated(address indexed user, uint256 amount, uint256 totalVolume, uint256 timestamp)
func (_ReferralRegistry *ReferralRegistryFilterer) FilterUserVolumeUpdated(opts *bind.FilterOpts, user []common.Address) (*ReferralRegistryUserVolumeUpdatedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	logs, sub, err := _ReferralRegistry.contract.FilterLogs(opts, "UserVolumeUpdated", userRule)
	if err != nil {
		return nil, err
	}
	return &ReferralRegistryUserVolumeUpdatedIterator{contract: _ReferralRegistry.contract, event: "UserVolumeUpdated", logs: logs, sub: sub}, nil
}

// WatchUserVolumeUpdated is a free log subscription operation binding the contract event 0x26289c4896ff72e686a457fc7584fc76bea0fdc419a1de0181c496280e0de121.
//
// Solidity: event UserVolumeUpdated(address indexed user, uint256 amount, uint256 totalVolume, uint256 timestamp)
func (_ReferralRegistry *ReferralRegistryFilterer) WatchUserVolumeUpdated(opts *bind.WatchOpts, sink chan<- *ReferralRegistryUserVolumeUpdated, user []common.Address) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	logs, sub, err := _ReferralRegistry.contract.WatchLogs(opts, "UserVolumeUpdated", userRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ReferralRegistryUserVolumeUpdated)
				if err := _ReferralRegistry.contract.UnpackLog(event, "UserVolumeUpdated", log); err != nil {
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

// ParseUserVolumeUpdated is a log parse operation binding the contract event 0x26289c4896ff72e686a457fc7584fc76bea0fdc419a1de0181c496280e0de121.
//
// Solidity: event UserVolumeUpdated(address indexed user, uint256 amount, uint256 totalVolume, uint256 timestamp)
func (_ReferralRegistry *ReferralRegistryFilterer) ParseUserVolumeUpdated(log types.Log) (*ReferralRegistryUserVolumeUpdated, error) {
	event := new(ReferralRegistryUserVolumeUpdated)
	if err := _ReferralRegistry.contract.UnpackLog(event, "UserVolumeUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
