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

// WDLTemplateMetaData contains all meta data concerning the WDLTemplate contract.
var WDLTemplateMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_matchId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"_homeTeam\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"_awayTeam\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"_kickoffTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_settlementToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_feeRecipient\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_feeRate\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_disputePeriod\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_pricingEngine\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_uri\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"autoLock\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"awayTeam\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfBatch\",\"inputs\":[{\"name\":\"accounts\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"calculateFee\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"fee\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"discountOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIFeeDiscountOracle\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"disputePeriod\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"feeRate\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"feeRecipient\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"finalize\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAllPrices\",\"inputs\":[],\"outputs\":[{\"name\":\"prices\",\"type\":\"uint256[3]\",\"internalType\":\"uint256[3]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getCurrentPrice\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"price\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMarketInfo\",\"inputs\":[],\"outputs\":[{\"name\":\"_matchId\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"_homeTeam\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"_awayTeam\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"_kickoffTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_status\",\"type\":\"uint8\",\"internalType\":\"enumIMarket.MarketStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getUserPosition\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"homeTeam\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isApprovedForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"kickoffTime\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"lock\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"lockTimestamp\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"matchId\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"outcomeCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"outcomeLiquidity\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"outcomeNames\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"paused\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"placeBet\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"pricingEngine\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIPricingEngine\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"redeem\",\"inputs\":[{\"name\":\"outcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"payout\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resolve\",\"inputs\":[{\"name\":\"winningOutcomeId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resolveFromOracle\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"resultOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIResultOracle\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"safeBatchTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDiscountOracle\",\"inputs\":[{\"name\":\"_discountOracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setFeeRate\",\"inputs\":[{\"name\":\"_feeRate\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setFeeRecipient\",\"inputs\":[{\"name\":\"_feeRecipient\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setPricingEngine\",\"inputs\":[{\"name\":\"_pricingEngine\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setResultOracle\",\"inputs\":[{\"name\":\"_resultOracle\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"settlementToken\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIERC20\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"shouldLock\",\"inputs\":[],\"outputs\":[{\"name\":\"_shouldLock\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"status\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumIMarket.MarketStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalLiquidity\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpause\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"uri\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"winningOutcome\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"ApprovalForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"BetPlaced\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"fee\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DiscountOracleUpdated\",\"inputs\":[{\"name\":\"oldOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Finalized\",\"inputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Locked\",\"inputs\":[{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MarketCreated\",\"inputs\":[{\"name\":\"matchId\",\"type\":\"string\",\"indexed\":true,\"internalType\":\"string\"},{\"name\":\"homeTeam\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"awayTeam\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"kickoffTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"pricingEngine\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Paused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PricingEngineUpdated\",\"inputs\":[{\"name\":\"oldEngine\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newEngine\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Redeemed\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"outcomeId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"shares\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"payout\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Resolved\",\"inputs\":[{\"name\":\"winningOutcome\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResolvedWithOracle\",\"inputs\":[{\"name\":\"winningOutcome\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"resultHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResultOracleUpdated\",\"inputs\":[{\"name\":\"newOracle\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferBatch\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferSingle\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"URI\",\"inputs\":[{\"name\":\"value\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Unpaused\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ERC1155InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"tokenId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidArrayLength\",\"inputs\":[{\"name\":\"idsLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"valuesLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidOperator\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155MissingApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"EnforcedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ExpectedPause\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
	Bin: "0x6003610160818152622bb4b760e91b6101805261010090815260046101a0818152634472617760e01b6101c052610120526102206040526101e0908152634c6f737360e01b610200526101405261005991600e9190610512565b50348015610065575f5ffd5b50604051613caa380380613caa8339810160408190526100849161067d565b600386868686853381610096816104b1565b506001600160a01b0381166100c557604051631e4fbdf760e01b81525f60048201526024015b60405180910390fd5b6100ce816104c1565b506001600455600286101561012f5760405162461bcd60e51b815260206004820152602160248201527f4d61726b6574426173653a20496e76616c6964206f7574636f6d6520636f756e6044820152601d60fa1b60648201526084016100bc565b6001600160a01b0385166101855760405162461bcd60e51b815260206004820152601960248201527f4d61726b6574426173653a20496e76616c696420746f6b656e0000000000000060448201526064016100bc565b6001600160a01b0384166101e55760405162461bcd60e51b815260206004820152602160248201527f4d61726b6574426173653a20496e76616c69642066656520726563697069656e6044820152601d60fa1b60648201526084016100bc565b6103e88311156102375760405162461bcd60e51b815260206004820152601d60248201527f4d61726b6574426173653a20466565207261746520746f6f206869676800000060448201526064016100bc565b506080949094526001600160a01b0392831660a052600a80546001600160a01b031916929093169190911790915560075560c0526005805460ff1916905589516102c35760405162461bcd60e51b815260206004820152601560248201527f57444c3a20496e76616c6964206d61746368204944000000000000000000000060448201526064016100bc565b5f8951116103135760405162461bcd60e51b815260206004820152601660248201527f57444c3a20496e76616c696420686f6d65207465616d0000000000000000000060448201526064016100bc565b5f8851116103635760405162461bcd60e51b815260206004820152601660248201527f57444c3a20496e76616c69642061776179207465616d0000000000000000000060448201526064016100bc565b4287116103b25760405162461bcd60e51b815260206004820152601960248201527f57444c3a204b69636b6f66662074696d6520696e20706173740000000000000060448201526064016100bc565b6001600160a01b0382166104085760405162461bcd60e51b815260206004820152601b60248201527f57444c3a20496e76616c69642070726963696e6720656e67696e65000000000060448201526064016100bc565b60126104148b8261080c565b5060136104218a8261080c565b50601461042e898261080c565b5060e0879052601180546001600160a01b0319166001600160a01b03841617905560405161045d908b906108c6565b60405180910390207f194b40fbafdecd402675e151ab37ebcb3be609fdeaa3a29a2c8e6ce0d11fc7798a8a8a8660405161049a949392919061090a565b60405180910390a250505050505050505050610950565b60026104bd828261080c565b5050565b600380546001600160a01b038381166001600160a01b0319831681179093556040519116919082907f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0905f90a35050565b826003810192821561054b579160200282015b8281111561054b578251829061053b908261080c565b5091602001919060010190610525565b5061055792915061055b565b5090565b80821115610557575f61056e8282610577565b5060010161055b565b50805461058390610788565b5f825580601f10610592575050565b601f0160209004905f5260205f20908101906105ae91906105b1565b50565b5b80821115610557575f81556001016105b2565b634e487b7160e01b5f52604160045260245ffd5b5f82601f8301126105e8575f5ffd5b81516001600160401b03811115610601576106016105c5565b604051601f8201601f19908116603f011681016001600160401b038111828210171561062f5761062f6105c5565b604052818152838201602001851015610646575f5ffd5b8160208501602083015e5f918101602001919091529392505050565b80516001600160a01b0381168114610678575f5ffd5b919050565b5f5f5f5f5f5f5f5f5f5f6101408b8d031215610697575f5ffd5b8a516001600160401b038111156106ac575f5ffd5b6106b88d828e016105d9565b60208d0151909b5090506001600160401b038111156106d5575f5ffd5b6106e18d828e016105d9565b60408d0151909a5090506001600160401b038111156106fe575f5ffd5b61070a8d828e016105d9565b60608d01519099509750610722905060808c01610662565b955061073060a08c01610662565b60c08c015160e08d01519196509450925061074e6101008c01610662565b6101208c01519092506001600160401b0381111561076a575f5ffd5b6107768d828e016105d9565b9150509295989b9194979a5092959850565b600181811c9082168061079c57607f821691505b6020821081036107ba57634e487b7160e01b5f52602260045260245ffd5b50919050565b601f82111561080757805f5260205f20601f840160051c810160208510156107e55750805b601f840160051c820191505b81811015610804575f81556001016107f1565b50505b505050565b81516001600160401b03811115610825576108256105c5565b610839816108338454610788565b846107c0565b6020601f82116001811461086b575f83156108545750848201515b5f19600385901b1c1916600184901b178455610804565b5f84815260208120601f198516915b8281101561089a578785015182556020948501946001909201910161087a565b50848210156108b757868401515f19600387901b60f8161c191681555b50505050600190811b01905550565b5f82518060208501845e5f920191825250919050565b5f81518084528060208401602086015e5f602082860101526020601f19601f83011685010191505092915050565b608081525f61091c60808301876108dc565b828103602084015261092e81876108dc565b604084019590955250506001600160a01b039190911660609091015292915050565b60805160a05160c05160e0516132e16109c95f395f8181610380015281816108d4015281816109300152611bde01525f81816104e3015261108001525f818161052401528181610f2701528181610f6601526114e501525f818161061101528181610e1f0152818161125701526116cd01526132e15ff3fe608060405234801561000f575f5ffd5b50600436106102ca575f3560e01c8063715018a61161017b578063a6ae4cfc116100e4578063d9a159651161009e578063e985e9c511610079578063e985e9c514610661578063f242432a14610674578063f2fde38b14610687578063f83d08ba1461069a575f5ffd5b8063d9a1596514610633578063dac790601461063b578063e74b981b1461064e575f5ffd5b8063a6ae4cfc146105c2578063ae989d36146105d5578063b544bf83146105dd578063c55d0f56146105e6578063c77e5042146105f9578063d300cb311461060c575f5ffd5b80638b28ab1e116101355780638b28ab1e146105715780638da5cb5b14610584578063978bbdb91461059557806399892e471461059e5780639b34ae03146105a6578063a22cb465146105af575f5ffd5b8063715018a6146105175780637b9e618d1461051f5780637cbc2373146105465780637d79c19214610559578063830ced86146105615780638456cb5914610569575f5ffd5b80632eb2c2d61161023757806346904840116101f15780634e1273f4116101cc5780634e1273f4146104ab5780634f896d4f146104cb5780635bf31d4d146104de5780635c975abb14610505575f5ffd5b8063469048401461047d5780634afe62b5146104905780634bb278f3146104a3575f5ffd5b80632eb2c2d6146103f05780632f04002b146104035780633c5996e01461042e5780633f4ba83a1461044d578063445df9d61461045557806345596e2e1461046a575f5ffd5b80631c88ef1e116102885780631c88ef1e146103685780631f5dca1a1461037b578063200d2ed2146103a25780632175d0d3146103bc57806323341a05146103c457806327acae74146103dd575f5ffd5b8062fdd58e146102ce57806301ffc9a7146102f45780630736251c146103175780630e89341c1461032c57806315770f921461034c57806317bc464814610355575b5f5ffd5b6102e16102dc3660046129ff565b6106a2565b6040519081526020015b60405180910390f35b610307610302366004612a3c565b6106c9565b60405190151581526020016102eb565b61032a610325366004612a57565b610718565b005b61033f61033a366004612a70565b61077b565b6040516102eb9190612ab5565b6102e1600c5481565b61032a610363366004612a57565b61080d565b6102e16103763660046129ff565b6108b9565b6102e17f000000000000000000000000000000000000000000000000000000000000000081565b6005546103af9060ff1681565b6040516102eb9190612afb565b6103076108cb565b6103cc610921565b6040516102eb959493929190612b09565b61033f6103eb366004612a70565b610b0d565b61032a6103fe366004612cc8565b610baa565b601154610416906001600160a01b031681565b6040516001600160a01b0390911681526020016102eb565b6102e161043c366004612a70565b600d6020525f908152604090205481565b61032a610c11565b61045d610c23565b6040516102eb9190612d77565b61032a610478366004612a70565b610d77565b600a54610416906001600160a01b031681565b6102e161049e366004612da7565b610dd6565b61032a61103f565b6104be6104b9366004612dc7565b61114b565b6040516102eb9190612ec4565b61032a6104d9366004612a70565b611216565b6102e17f000000000000000000000000000000000000000000000000000000000000000081565b600354600160a01b900460ff16610307565b61032a6112df565b6104167f000000000000000000000000000000000000000000000000000000000000000081565b6102e1610554366004612da7565b6112f0565b61033f61155b565b61032a611568565b61032a611804565b6102e161057f3660046129ff565b611814565b6003546001600160a01b0316610416565b6102e160075481565b61033f61194f565b6102e160065481565b61032a6105bd366004612ee3565b61195c565b61032a6105d0366004612a57565b61196b565b61033f611a5b565b6102e1600b5481565b6102e16105f4366004612a70565b611a68565b600954610416906001600160a01b031681565b6102e17f000000000000000000000000000000000000000000000000000000000000000081565b61032a611bd6565b600854610416906001600160a01b031681565b61032a61065c366004612a57565b611cef565b61030761066f366004612f18565b611d6f565b61032a610682366004612f49565b611d9c565b61032a610695366004612a57565b611dfb565b61032a611e38565b5f818152602081815260408083206001600160a01b03861684529091529020545b92915050565b5f6001600160e01b03198216636cdb3d1360e11b14806106f957506001600160e01b031982166303a24d0760e21b145b806106c357506301ffc9a760e01b6001600160e01b03198316146106c3565b610720611eb9565b6008546040516001600160a01b038084169216907fb0a21792e739b32d34f3928764f774f8b8702f15d4b00f2e688689d23050aaa6905f90a3600880546001600160a01b0319166001600160a01b0392909216919091179055565b60606002805461078a90612f9d565b80601f01602080910402602001604051908101604052809291908181526020018280546107b690612f9d565b80156108015780601f106107d857610100808354040283529160200191610801565b820191905f5260205f20905b8154815290600101906020018083116107e457829003601f168201915b50505050509050919050565b610815611eb9565b6001600160a01b0381166108705760405162461bcd60e51b815260206004820152601a60248201527f4d61726b6574426173653a20496e76616c6964206f7261636c6500000000000060448201526064015b60405180910390fd5b600980546001600160a01b0319166001600160a01b0383169081179091556040517ff4f6d8a1c53b96aaa54cac2192218b21030f6371f0b3e3a0fb15124fa1f08e8d905f90a250565b5f6108c483836106a2565b9392505050565b5f6108f861012c7f0000000000000000000000000000000000000000000000000000000000000000612fe9565b421015801561091c57505f60055460ff16600381111561091a5761091a612ac7565b145b905090565b60608060605f5f6012601360147f000000000000000000000000000000000000000000000000000000000000000060055f9054906101000a900460ff1684805461096a90612f9d565b80601f016020809104026020016040519081016040528092919081815260200182805461099690612f9d565b80156109e15780601f106109b8576101008083540402835291602001916109e1565b820191905f5260205f20905b8154815290600101906020018083116109c457829003601f168201915b505050505094508380546109f490612f9d565b80601f0160208091040260200160405190810160405280929190818152602001828054610a2090612f9d565b8015610a6b5780601f10610a4257610100808354040283529160200191610a6b565b820191905f5260205f20905b815481529060010190602001808311610a4e57829003601f168201915b50505050509350828054610a7e90612f9d565b80601f0160208091040260200160405190810160405280929190818152602001828054610aaa90612f9d565b8015610af55780601f10610acc57610100808354040283529160200191610af5565b820191905f5260205f20905b815481529060010190602001808311610ad857829003601f168201915b50505050509250945094509450945094509091929394565b600e8160038110610b1c575f80fd5b018054909150610b2b90612f9d565b80601f0160208091040260200160405190810160405280929190818152602001828054610b5790612f9d565b8015610ba25780601f10610b7957610100808354040283529160200191610ba2565b820191905f5260205f20905b815481529060010190602001808311610b8557829003601f168201915b505050505081565b336001600160a01b0386168114801590610bcb5750610bc98682611d6f565b155b15610bfc5760405163711bec9160e11b81526001600160a01b03808316600483015287166024820152604401610867565b610c098686868686611ee6565b505050505050565b610c19611eb9565b610c21611f4b565b565b610c2b6129cb565b604080516003808252608082019092525f91602082016060803683370190505090505f5b6003811015610cd6575f818152600d60205260409020548251839083908110610c7a57610c7a612ffc565b602002602001018181525050818181518110610c9857610c98612ffc565b60200260200101515f03610cce57670de0b6b3a7640000828281518110610cc157610cc1612ffc565b6020026020010181815250505b600101610c4f565b505f5b6003811015610d72576011546040516361e70e5f60e01b81526001600160a01b03909116906361e70e5f90610d149084908690600401613010565b602060405180830381865afa158015610d2f573d5f5f3e3d5ffd5b505050506040513d601f19601f82011682018060405250810190610d539190613028565b838260038110610d6557610d65612ffc565b6020020152600101610cd9565b505090565b610d7f611eb9565b6103e8811115610dd15760405162461bcd60e51b815260206004820152601d60248201527f4d61726b6574426173653a20466565207261746520746f6f20686967680000006044820152606401610867565b600755565b5f808060055460ff166003811115610df057610df0612ac7565b14610e0d5760405162461bcd60e51b81526004016108679061303f565b610e15611f9b565b610e1d611fc6565b7f00000000000000000000000000000000000000000000000000000000000000008410610e5c5760405162461bcd60e51b815260040161086790613076565b5f8311610eab5760405162461bcd60e51b815260206004820152601760248201527f4d61726b6574426173653a205a65726f20616d6f756e740000000000000000006044820152606401610867565b5f610eb63385611814565b90505f610ec38286612fe9565b9050610ecf8682611ff0565b93505f8411610f1a5760405162461bcd60e51b81526020600482015260176024820152764d61726b6574426173653a205a65726f2073686172657360481b6044820152606401610867565b610f4f6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001633308461211a565b8115610f9157600a54610f91906001600160a01b037f00000000000000000000000000000000000000000000000000000000000000008116913391168561211a565b5f868152600d602052604081208054839290610fae9084906130ad565b9250508190555080600c5f828254610fc691906130ad565b92505081905550610fe733878660405180602001604052805f815250612187565b6040805186815260208101869052908101839052869033907f935a8686694e2b5cc90f63054b327255f6fb92db3acd6d98c5a707d4987e93e19060600160405180910390a350506110386001600455565b5092915050565b611047611eb9565b60028060055460ff16600381111561106157611061612ac7565b1461107e5760405162461bcd60e51b81526004016108679061303f565b7f0000000000000000000000000000000000000000000000000000000000000000600b546110ac91906130ad565b4210156111075760405162461bcd60e51b8152602060048201526024808201527f4d61726b6574426173653a204469737075746520706572696f64206e6f7420656044820152631b99195960e21b6064820152608401610867565b6005805460ff191660031790556040514281527f839cf22e1ba87ce2f5b9bbf46cf0175a09eed52febdfaac8852478e68203c763906020015b60405180910390a150565b6060815183511461117c5781518351604051635b05999160e01b815260048101929092526024820152604401610867565b5f835167ffffffffffffffff81111561119757611197612b61565b6040519080825280602002602001820160405280156111c0578160200160208202803683370190505b5090505f5b845181101561120e576020808202860101516111e9906020808402870101516106a2565b8282815181106111fb576111fb612ffc565b60209081029190910101526001016111c5565b509392505050565b61121e611eb9565b60018060055460ff16600381111561123857611238612ac7565b146112555760405162461bcd60e51b81526004016108679061303f565b7f000000000000000000000000000000000000000000000000000000000000000082106112945760405162461bcd60e51b815260040161086790613076565b60068290556005805460ff1916600217905560405142815282907f8a1cc9089f9efc6450ff2639ff6d6b27f6aaaac01cccae1789c0a36dffc210419060200160405180910390a25050565b6112e7611eb9565b610c215f6121e2565b5f600260038160055460ff16600381111561130d5761130d612ac7565b148061133f575080600381111561132657611326612ac7565b60055460ff16600381111561133d5761133d612ac7565b145b61135b5760405162461bcd60e51b81526004016108679061303f565b611363611fc6565b60065485146113b45760405162461bcd60e51b815260206004820152601f60248201527f4d61726b6574426173653a204e6f742077696e6e696e67206f7574636f6d65006044820152606401610867565b5f84116113fd5760405162461bcd60e51b81526020600482015260176024820152764d61726b6574426173653a205a65726f2073686172657360481b6044820152606401610867565b8361140833876106a2565b10156114565760405162461bcd60e51b815260206004820181905260248201527f4d61726b6574426173653a20496e73756666696369656e742062616c616e63656044820152606401610867565b839250600c548311156114b65760405162461bcd60e51b815260206004820152602260248201527f4d61726b6574426173653a20496e73756666696369656e74206c697175696469604482015261747960f01b6064820152608401610867565b82600c5f8282546114c79190612fe9565b909155506114d89050338686612233565b61150c6001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000163385612299565b6040805185815260208101859052869133917f484c40561359f3e3b8be9101897f8680aa82fbe1df9fd9038e0dbc6284032646910160405180910390a36115536001600455565b505092915050565b60148054610b2b90612f9d565b611570611eb9565b60018060055460ff16600381111561158a5761158a612ac7565b146115a75760405162461bcd60e51b81526004016108679061303f565b6009546001600160a01b03166115ff5760405162461bcd60e51b815260206004820152601a60248201527f4d61726b6574426173653a204f7261636c65206e6f74207365740000000000006044820152606401610867565b600954604051632b7531e160e21b81523060048201525f9182916001600160a01b039091169063add4c7849060240161010060405180830381865afa15801561164a573d5f5f3e3d5ffd5b505050506040513d601f19601f8201168201806040525081019061166e91906130db565b91509150806116bf5760405162461bcd60e51b815260206004820181905260248201527f4d61726b6574426173653a20526573756c74206e6f742066696e616c697a65646044820152606401610867565b5f6116c9836122cf565b90507f0000000000000000000000000000000000000000000000000000000000000000811061170a5760405162461bcd60e51b815260040161086790613076565b60068190556005805460ff1916600217905560095460405163175e6db760e11b81523060048201525f916001600160a01b031690632ebcdb6e90602401602060405180830381865afa158015611762573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906117869190613028565b9050817f8a1cc9089f9efc6450ff2639ff6d6b27f6aaaac01cccae1789c0a36dffc21041426040516117ba91815260200190565b60405180910390a280827f483e2cc22780ed0b10a1da294bc4acc4d4b81340fdebab99bb0a346644b020b3426040516117f591815260200190565b60405180910390a35050505050565b61180c611eb9565b610c21612368565b6008545f906001600160a01b031661184857612710600754836118379190613177565b611841919061318e565b90506106c3565b6008546040516303793c8d60e11b81526001600160a01b0385811660048301525f9216906306f2791a90602401602060405180830381865afa158015611890573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906118b49190613028565b90506107d08111156119085760405162461bcd60e51b815260206004820152601d60248201527f4d61726b6574426173653a20446973636f756e7420746f6f20686967680000006044820152606401610867565b5f6127106119168382612fe9565b6007546119239190613177565b61192d919061318e565b905061271061193c8286613177565b611946919061318e565b95945050505050565b60128054610b2b90612f9d565b6119673383836123ab565b5050565b611973611eb9565b5f8060055460ff16600381111561198c5761198c612ac7565b146119a95760405162461bcd60e51b81526004016108679061303f565b6001600160a01b0382166119ff5760405162461bcd60e51b815260206004820152601b60248201527f57444c3a20496e76616c69642070726963696e6720656e67696e6500000000006044820152606401610867565b6011546040516001600160a01b038085169216907fa8b5bff31605557453985bec893496ac9ed67501629fca03b3ef08c39e0bf123905f90a350601180546001600160a01b0319166001600160a01b0392909216919091179055565b60138054610b2b90612f9d565b5f60038210611ab95760405162461bcd60e51b815260206004820152601760248201527f57444c3a20496e76616c6964206f7574636f6d652049440000000000000000006044820152606401610867565b604080516003808252608082019092525f91602082016060803683370190505090505f5b6003811015611b64575f818152600d60205260409020548251839083908110611b0857611b08612ffc565b602002602001018181525050818181518110611b2657611b26612ffc565b60200260200101515f03611b5c57670de0b6b3a7640000828281518110611b4f57611b4f612ffc565b6020026020010181815250505b600101611add565b506011546040516361e70e5f60e01b81526001600160a01b03909116906361e70e5f90611b979086908590600401613010565b602060405180830381865afa158015611bb2573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906108c49190613028565b611c0261012c7f0000000000000000000000000000000000000000000000000000000000000000612fe9565b421015611c4a5760405162461bcd60e51b815260206004820152601660248201527557444c3a20546f6f206561726c7920746f206c6f636b60501b6044820152606401610867565b5f60055460ff166003811115611c6257611c62612ac7565b14611ca65760405162461bcd60e51b81526020600482015260146024820152732ba2261d1026b0b935b2ba103737ba1037b832b760611b6044820152606401610867565b6005805460ff1916600117905542600b8190556040519081527f032bc66be43dbccb7487781d168eb7bda224628a3b2c3388bdf69b532a3a1611906020015b60405180910390a1565b611cf7611eb9565b6001600160a01b038116611d4d5760405162461bcd60e51b815260206004820152601b60248201527f4d61726b6574426173653a20496e76616c6964206164647265737300000000006044820152606401610867565b600a80546001600160a01b0319166001600160a01b0392909216919091179055565b6001600160a01b039182165f90815260016020908152604080832093909416825291909152205460ff1690565b336001600160a01b0386168114801590611dbd5750611dbb8682611d6f565b155b15611dee5760405163711bec9160e11b81526001600160a01b03808316600483015287166024820152604401610867565b610c09868686868661243f565b611e03611eb9565b6001600160a01b038116611e2c57604051631e4fbdf760e01b81525f6004820152602401610867565b611e35816121e2565b50565b611e40611eb9565b5f8060055460ff166003811115611e5957611e59612ac7565b14611e765760405162461bcd60e51b81526004016108679061303f565b6005805460ff1916600117905542600b8190556040519081527f032bc66be43dbccb7487781d168eb7bda224628a3b2c3388bdf69b532a3a161190602001611140565b6003546001600160a01b03163314610c215760405163118cdaa760e01b8152336004820152602401610867565b6001600160a01b038416611f0f57604051632bfa23e760e11b81525f6004820152602401610867565b6001600160a01b038516611f3757604051626a0d4560e21b81525f6004820152602401610867565b611f4485858585856124cb565b5050505050565b611f5361251e565b6003805460ff60a01b191690557f5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa335b6040516001600160a01b039091168152602001611ce5565b600354600160a01b900460ff1615610c215760405163d93c066560e01b815260040160405180910390fd5b600260045403611fe957604051633ee5aeb560e01b815260040160405180910390fd5b6002600455565b604080516003808252608082019092525f91829190602082016060803683370190505090505f5b600381101561209e575f818152600d6020526040902054825183908390811061204257612042612ffc565b60200260200101818152505081818151811061206057612060612ffc565b60200260200101515f0361209657670de0b6b3a764000082828151811061208957612089612ffc565b6020026020010181815250505b600101612017565b50601154604051637a201b8560e11b81526001600160a01b039091169063f440370a906120d3908790879086906004016131ad565b602060405180830381865afa1580156120ee573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906121129190613028565b949350505050565b6040516001600160a01b0384811660248301528381166044830152606482018390526121819186918216906323b872dd906084015b604051602081830303815290604052915060e01b6020820180516001600160e01b038381831617835250505050612548565b50505050565b6001600160a01b0384166121b057604051632bfa23e760e11b81525f6004820152602401610867565b60408051600180825260208201869052818301908152606082018590526080820190925290610c095f878484876124cb565b600380546001600160a01b038381166001600160a01b0319831681179093556040519116919082907f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0905f90a35050565b6001600160a01b03831661225b57604051626a0d4560e21b81525f6004820152602401610867565b604080516001808252602082018590528183019081526060820184905260a082019092525f60808201818152919291611f44918791859085906124cb565b6040516001600160a01b038381166024830152604482018390526122ca91859182169063a9059cbb9060640161214f565b505050565b80515f9068af9a919e938b969a8d60b81b01612328578160a0015160ff16826080015160ff16111561230257505f919050565b8160a0015160ff16826080015160ff16101561232057506002919050565b506001919050565b816040015160ff16826020015160ff16111561234557505f919050565b816040015160ff16826020015160ff16101561232057506002919050565b919050565b612370611f9b565b6003805460ff60a01b1916600160a01b1790557f62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258611f833390565b6001600160a01b0382166123d35760405162ced3e160e81b81525f6004820152602401610867565b6001600160a01b038381165f81815260016020908152604080832094871680845294825291829020805460ff191686151590811790915591519182527f17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31910160405180910390a3505050565b6001600160a01b03841661246857604051632bfa23e760e11b81525f6004820152602401610867565b6001600160a01b03851661249057604051626a0d4560e21b81525f6004820152602401610867565b604080516001808252602082018690528183019081526060820185905260808201909252906124c287878484876124cb565b50505050505050565b6124d7858585856125b4565b6001600160a01b03841615611f44578251339060010361251057602084810151908401516125098389898585896127c3565b5050610c09565b610c098187878787876128e4565b600354600160a01b900460ff16610c2157604051638dfc202b60e01b815260040160405180910390fd5b5f5f60205f8451602086015f885af180612567576040513d5f823e3d81fd5b50505f513d9150811561257e57806001141561258b565b6001600160a01b0384163b155b1561218157604051635274afe760e01b81526001600160a01b0385166004820152602401610867565b80518251146125e35781518151604051635b05999160e01b815260048101929092526024820152604401610867565b335f5b83518110156126e5576020818102858101820151908501909101516001600160a01b03881615612697575f828152602081815260408083206001600160a01b038c16845290915290205481811015612671576040516303dee4c560e01b81526001600160a01b038a166004820152602481018290526044810183905260648101849052608401610867565b5f838152602081815260408083206001600160a01b038d16845290915290209082900390555b6001600160a01b038716156126db575f828152602081815260408083206001600160a01b038b168452909152812080548392906126d59084906130ad565b90915550505b50506001016125e6565b5082516001036127655760208301515f906020840151909150856001600160a01b0316876001600160a01b0316846001600160a01b03167fc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f628585604051612756929190918252602082015260400190565b60405180910390a45050611f44565b836001600160a01b0316856001600160a01b0316826001600160a01b03167f4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb86866040516127b49291906131cb565b60405180910390a45050505050565b6001600160a01b0384163b15610c095760405163f23a6e6160e01b81526001600160a01b0385169063f23a6e619061280790899089908890889088906004016131ef565b6020604051808303815f875af1925050508015612841575060408051601f3d908101601f1916820190925261283e91810190613233565b60015b6128a8573d80801561286e576040519150601f19603f3d011682016040523d82523d5f602084013e612873565b606091505b5080515f036128a057604051632bfa23e760e11b81526001600160a01b0386166004820152602401610867565b805160208201fd5b6001600160e01b0319811663f23a6e6160e01b146124c257604051632bfa23e760e11b81526001600160a01b0386166004820152602401610867565b6001600160a01b0384163b15610c095760405163bc197c8160e01b81526001600160a01b0385169063bc197c8190612928908990899088908890889060040161324e565b6020604051808303815f875af1925050508015612962575060408051601f3d908101601f1916820190925261295f91810190613233565b60015b61298f573d80801561286e576040519150601f19603f3d011682016040523d82523d5f602084013e612873565b6001600160e01b0319811663bc197c8160e01b146124c257604051632bfa23e760e11b81526001600160a01b0386166004820152602401610867565b60405180606001604052806003906020820280368337509192915050565b80356001600160a01b0381168114612363575f5ffd5b5f5f60408385031215612a10575f5ffd5b612a19836129e9565b946020939093013593505050565b6001600160e01b031981168114611e35575f5ffd5b5f60208284031215612a4c575f5ffd5b81356108c481612a27565b5f60208284031215612a67575f5ffd5b6108c4826129e9565b5f60208284031215612a80575f5ffd5b5035919050565b5f81518084528060208401602086015e5f602082860101526020601f19601f83011685010191505092915050565b602081525f6108c46020830184612a87565b634e487b7160e01b5f52602160045260245ffd5b60048110612af757634e487b7160e01b5f52602160045260245ffd5b9052565b602081016106c38284612adb565b60a081525f612b1b60a0830188612a87565b8281036020840152612b2d8188612a87565b90508281036040840152612b418187612a87565b915050836060830152612b576080830184612adb565b9695505050505050565b634e487b7160e01b5f52604160045260245ffd5b60405160e0810167ffffffffffffffff81118282101715612b9857612b98612b61565b60405290565b604051601f8201601f1916810167ffffffffffffffff81118282101715612bc757612bc7612b61565b604052919050565b5f67ffffffffffffffff821115612be857612be8612b61565b5060051b60200190565b5f82601f830112612c01575f5ffd5b8135612c14612c0f82612bcf565b612b9e565b8082825260208201915060208360051b860101925085831115612c35575f5ffd5b602085015b83811015612c52578035835260209283019201612c3a565b5095945050505050565b5f82601f830112612c6b575f5ffd5b813567ffffffffffffffff811115612c8557612c85612b61565b612c98601f8201601f1916602001612b9e565b818152846020838601011115612cac575f5ffd5b816020850160208301375f918101602001919091529392505050565b5f5f5f5f5f60a08688031215612cdc575f5ffd5b612ce5866129e9565b9450612cf3602087016129e9565b9350604086013567ffffffffffffffff811115612d0e575f5ffd5b612d1a88828901612bf2565b935050606086013567ffffffffffffffff811115612d36575f5ffd5b612d4288828901612bf2565b925050608086013567ffffffffffffffff811115612d5e575f5ffd5b612d6a88828901612c5c565b9150509295509295909350565b6060810181835f5b6003811015612d9e578151835260209283019290910190600101612d7f565b50505092915050565b5f5f60408385031215612db8575f5ffd5b50508035926020909101359150565b5f5f60408385031215612dd8575f5ffd5b823567ffffffffffffffff811115612dee575f5ffd5b8301601f81018513612dfe575f5ffd5b8035612e0c612c0f82612bcf565b8082825260208201915060208360051b850101925087831115612e2d575f5ffd5b6020840193505b82841015612e5657612e45846129e9565b825260209384019390910190612e34565b9450505050602083013567ffffffffffffffff811115612e74575f5ffd5b612e8085828601612bf2565b9150509250929050565b5f8151808452602084019350602083015f5b82811015612eba578151865260209586019590910190600101612e9c565b5093949350505050565b602081525f6108c46020830184612e8a565b8015158114611e35575f5ffd5b5f5f60408385031215612ef4575f5ffd5b612efd836129e9565b91506020830135612f0d81612ed6565b809150509250929050565b5f5f60408385031215612f29575f5ffd5b612f32836129e9565b9150612f40602084016129e9565b90509250929050565b5f5f5f5f5f60a08688031215612f5d575f5ffd5b612f66866129e9565b9450612f74602087016129e9565b93506040860135925060608601359150608086013567ffffffffffffffff811115612d5e575f5ffd5b600181811c90821680612fb157607f821691505b602082108103612fcf57634e487b7160e01b5f52602260045260245ffd5b50919050565b634e487b7160e01b5f52601160045260245ffd5b818103818111156106c3576106c3612fd5565b634e487b7160e01b5f52603260045260245ffd5b828152604060208201525f6121126040830184612e8a565b5f60208284031215613038575f5ffd5b5051919050565b6020808252601a908201527f4d61726b6574426173653a20496e76616c696420737461747573000000000000604082015260600190565b6020808252601b908201527f4d61726b6574426173653a20496e76616c6964206f7574636f6d650000000000604082015260600190565b808201808211156106c3576106c3612fd5565b805160ff81168114612363575f5ffd5b805161236381612ed6565b5f5f8284036101008112156130ee575f5ffd5b60e08112156130fb575f5ffd5b50613104612b75565b83518152613114602085016130c0565b6020820152613125604085016130c0565b6040820152606084015161313881612ed6565b6060820152613149608085016130c0565b608082015261315a60a085016130c0565b60a082015260c084810151908201529150612f4060e084016130d0565b80820281158282048414176106c3576106c3612fd5565b5f826131a857634e487b7160e01b5f52601260045260245ffd5b500490565b838152826020820152606060408201525f6119466060830184612e8a565b604081525f6131dd6040830185612e8a565b82810360208401526119468185612e8a565b6001600160a01b03868116825285166020820152604081018490526060810183905260a0608082018190525f9061322890830184612a87565b979650505050505050565b5f60208284031215613243575f5ffd5b81516108c481612a27565b6001600160a01b0386811682528516602082015260a0604082018190525f9061327990830186612e8a565b828103606084015261328b8186612e8a565b9050828103608084015261329f8185612a87565b9897505050505050505056fea2646970667358221220548659f9635de2345846eaa97b94169016b9346eed601b6019ee1253250fd67564736f6c634300081e0033",
}

// WDLTemplateABI is the input ABI used to generate the binding from.
// Deprecated: Use WDLTemplateMetaData.ABI instead.
var WDLTemplateABI = WDLTemplateMetaData.ABI

// WDLTemplateBin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use WDLTemplateMetaData.Bin instead.
var WDLTemplateBin = WDLTemplateMetaData.Bin

// DeployWDLTemplate deploys a new Ethereum contract, binding an instance of WDLTemplate to it.
func DeployWDLTemplate(auth *bind.TransactOpts, backend bind.ContractBackend, _matchId string, _homeTeam string, _awayTeam string, _kickoffTime *big.Int, _settlementToken common.Address, _feeRecipient common.Address, _feeRate *big.Int, _disputePeriod *big.Int, _pricingEngine common.Address, _uri string) (common.Address, *types.Transaction, *WDLTemplate, error) {
	parsed, err := WDLTemplateMetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(WDLTemplateBin), backend, _matchId, _homeTeam, _awayTeam, _kickoffTime, _settlementToken, _feeRecipient, _feeRate, _disputePeriod, _pricingEngine, _uri)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &WDLTemplate{WDLTemplateCaller: WDLTemplateCaller{contract: contract}, WDLTemplateTransactor: WDLTemplateTransactor{contract: contract}, WDLTemplateFilterer: WDLTemplateFilterer{contract: contract}}, nil
}

// WDLTemplate is an auto generated Go binding around an Ethereum contract.
type WDLTemplate struct {
	WDLTemplateCaller     // Read-only binding to the contract
	WDLTemplateTransactor // Write-only binding to the contract
	WDLTemplateFilterer   // Log filterer for contract events
}

// WDLTemplateCaller is an auto generated read-only Go binding around an Ethereum contract.
type WDLTemplateCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// WDLTemplateTransactor is an auto generated write-only Go binding around an Ethereum contract.
type WDLTemplateTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// WDLTemplateFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type WDLTemplateFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// WDLTemplateSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type WDLTemplateSession struct {
	Contract     *WDLTemplate      // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// WDLTemplateCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type WDLTemplateCallerSession struct {
	Contract *WDLTemplateCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts      // Call options to use throughout this session
}

// WDLTemplateTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type WDLTemplateTransactorSession struct {
	Contract     *WDLTemplateTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts      // Transaction auth options to use throughout this session
}

// WDLTemplateRaw is an auto generated low-level Go binding around an Ethereum contract.
type WDLTemplateRaw struct {
	Contract *WDLTemplate // Generic contract binding to access the raw methods on
}

// WDLTemplateCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type WDLTemplateCallerRaw struct {
	Contract *WDLTemplateCaller // Generic read-only contract binding to access the raw methods on
}

// WDLTemplateTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type WDLTemplateTransactorRaw struct {
	Contract *WDLTemplateTransactor // Generic write-only contract binding to access the raw methods on
}

// NewWDLTemplate creates a new instance of WDLTemplate, bound to a specific deployed contract.
func NewWDLTemplate(address common.Address, backend bind.ContractBackend) (*WDLTemplate, error) {
	contract, err := bindWDLTemplate(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &WDLTemplate{WDLTemplateCaller: WDLTemplateCaller{contract: contract}, WDLTemplateTransactor: WDLTemplateTransactor{contract: contract}, WDLTemplateFilterer: WDLTemplateFilterer{contract: contract}}, nil
}

// NewWDLTemplateCaller creates a new read-only instance of WDLTemplate, bound to a specific deployed contract.
func NewWDLTemplateCaller(address common.Address, caller bind.ContractCaller) (*WDLTemplateCaller, error) {
	contract, err := bindWDLTemplate(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateCaller{contract: contract}, nil
}

// NewWDLTemplateTransactor creates a new write-only instance of WDLTemplate, bound to a specific deployed contract.
func NewWDLTemplateTransactor(address common.Address, transactor bind.ContractTransactor) (*WDLTemplateTransactor, error) {
	contract, err := bindWDLTemplate(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateTransactor{contract: contract}, nil
}

// NewWDLTemplateFilterer creates a new log filterer instance of WDLTemplate, bound to a specific deployed contract.
func NewWDLTemplateFilterer(address common.Address, filterer bind.ContractFilterer) (*WDLTemplateFilterer, error) {
	contract, err := bindWDLTemplate(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateFilterer{contract: contract}, nil
}

// bindWDLTemplate binds a generic wrapper to an already deployed contract.
func bindWDLTemplate(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := WDLTemplateMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_WDLTemplate *WDLTemplateRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _WDLTemplate.Contract.WDLTemplateCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_WDLTemplate *WDLTemplateRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WDLTemplate.Contract.WDLTemplateTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_WDLTemplate *WDLTemplateRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _WDLTemplate.Contract.WDLTemplateTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_WDLTemplate *WDLTemplateCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _WDLTemplate.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_WDLTemplate *WDLTemplateTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WDLTemplate.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_WDLTemplate *WDLTemplateTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _WDLTemplate.Contract.contract.Transact(opts, method, params...)
}

// AwayTeam is a free data retrieval call binding the contract method 0x7d79c192.
//
// Solidity: function awayTeam() view returns(string)
func (_WDLTemplate *WDLTemplateCaller) AwayTeam(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "awayTeam")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// AwayTeam is a free data retrieval call binding the contract method 0x7d79c192.
//
// Solidity: function awayTeam() view returns(string)
func (_WDLTemplate *WDLTemplateSession) AwayTeam() (string, error) {
	return _WDLTemplate.Contract.AwayTeam(&_WDLTemplate.CallOpts)
}

// AwayTeam is a free data retrieval call binding the contract method 0x7d79c192.
//
// Solidity: function awayTeam() view returns(string)
func (_WDLTemplate *WDLTemplateCallerSession) AwayTeam() (string, error) {
	return _WDLTemplate.Contract.AwayTeam(&_WDLTemplate.CallOpts)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_WDLTemplate *WDLTemplateCaller) BalanceOf(opts *bind.CallOpts, account common.Address, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "balanceOf", account, id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_WDLTemplate *WDLTemplateSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _WDLTemplate.Contract.BalanceOf(&_WDLTemplate.CallOpts, account, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address account, uint256 id) view returns(uint256)
func (_WDLTemplate *WDLTemplateCallerSession) BalanceOf(account common.Address, id *big.Int) (*big.Int, error) {
	return _WDLTemplate.Contract.BalanceOf(&_WDLTemplate.CallOpts, account, id)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_WDLTemplate *WDLTemplateCaller) BalanceOfBatch(opts *bind.CallOpts, accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "balanceOfBatch", accounts, ids)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_WDLTemplate *WDLTemplateSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _WDLTemplate.Contract.BalanceOfBatch(&_WDLTemplate.CallOpts, accounts, ids)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] accounts, uint256[] ids) view returns(uint256[])
func (_WDLTemplate *WDLTemplateCallerSession) BalanceOfBatch(accounts []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _WDLTemplate.Contract.BalanceOfBatch(&_WDLTemplate.CallOpts, accounts, ids)
}

// CalculateFee is a free data retrieval call binding the contract method 0x8b28ab1e.
//
// Solidity: function calculateFee(address user, uint256 amount) view returns(uint256 fee)
func (_WDLTemplate *WDLTemplateCaller) CalculateFee(opts *bind.CallOpts, user common.Address, amount *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "calculateFee", user, amount)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// CalculateFee is a free data retrieval call binding the contract method 0x8b28ab1e.
//
// Solidity: function calculateFee(address user, uint256 amount) view returns(uint256 fee)
func (_WDLTemplate *WDLTemplateSession) CalculateFee(user common.Address, amount *big.Int) (*big.Int, error) {
	return _WDLTemplate.Contract.CalculateFee(&_WDLTemplate.CallOpts, user, amount)
}

// CalculateFee is a free data retrieval call binding the contract method 0x8b28ab1e.
//
// Solidity: function calculateFee(address user, uint256 amount) view returns(uint256 fee)
func (_WDLTemplate *WDLTemplateCallerSession) CalculateFee(user common.Address, amount *big.Int) (*big.Int, error) {
	return _WDLTemplate.Contract.CalculateFee(&_WDLTemplate.CallOpts, user, amount)
}

// DiscountOracle is a free data retrieval call binding the contract method 0xdac79060.
//
// Solidity: function discountOracle() view returns(address)
func (_WDLTemplate *WDLTemplateCaller) DiscountOracle(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "discountOracle")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// DiscountOracle is a free data retrieval call binding the contract method 0xdac79060.
//
// Solidity: function discountOracle() view returns(address)
func (_WDLTemplate *WDLTemplateSession) DiscountOracle() (common.Address, error) {
	return _WDLTemplate.Contract.DiscountOracle(&_WDLTemplate.CallOpts)
}

// DiscountOracle is a free data retrieval call binding the contract method 0xdac79060.
//
// Solidity: function discountOracle() view returns(address)
func (_WDLTemplate *WDLTemplateCallerSession) DiscountOracle() (common.Address, error) {
	return _WDLTemplate.Contract.DiscountOracle(&_WDLTemplate.CallOpts)
}

// DisputePeriod is a free data retrieval call binding the contract method 0x5bf31d4d.
//
// Solidity: function disputePeriod() view returns(uint256)
func (_WDLTemplate *WDLTemplateCaller) DisputePeriod(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "disputePeriod")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// DisputePeriod is a free data retrieval call binding the contract method 0x5bf31d4d.
//
// Solidity: function disputePeriod() view returns(uint256)
func (_WDLTemplate *WDLTemplateSession) DisputePeriod() (*big.Int, error) {
	return _WDLTemplate.Contract.DisputePeriod(&_WDLTemplate.CallOpts)
}

// DisputePeriod is a free data retrieval call binding the contract method 0x5bf31d4d.
//
// Solidity: function disputePeriod() view returns(uint256)
func (_WDLTemplate *WDLTemplateCallerSession) DisputePeriod() (*big.Int, error) {
	return _WDLTemplate.Contract.DisputePeriod(&_WDLTemplate.CallOpts)
}

// FeeRate is a free data retrieval call binding the contract method 0x978bbdb9.
//
// Solidity: function feeRate() view returns(uint256)
func (_WDLTemplate *WDLTemplateCaller) FeeRate(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "feeRate")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// FeeRate is a free data retrieval call binding the contract method 0x978bbdb9.
//
// Solidity: function feeRate() view returns(uint256)
func (_WDLTemplate *WDLTemplateSession) FeeRate() (*big.Int, error) {
	return _WDLTemplate.Contract.FeeRate(&_WDLTemplate.CallOpts)
}

// FeeRate is a free data retrieval call binding the contract method 0x978bbdb9.
//
// Solidity: function feeRate() view returns(uint256)
func (_WDLTemplate *WDLTemplateCallerSession) FeeRate() (*big.Int, error) {
	return _WDLTemplate.Contract.FeeRate(&_WDLTemplate.CallOpts)
}

// FeeRecipient is a free data retrieval call binding the contract method 0x46904840.
//
// Solidity: function feeRecipient() view returns(address)
func (_WDLTemplate *WDLTemplateCaller) FeeRecipient(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "feeRecipient")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// FeeRecipient is a free data retrieval call binding the contract method 0x46904840.
//
// Solidity: function feeRecipient() view returns(address)
func (_WDLTemplate *WDLTemplateSession) FeeRecipient() (common.Address, error) {
	return _WDLTemplate.Contract.FeeRecipient(&_WDLTemplate.CallOpts)
}

// FeeRecipient is a free data retrieval call binding the contract method 0x46904840.
//
// Solidity: function feeRecipient() view returns(address)
func (_WDLTemplate *WDLTemplateCallerSession) FeeRecipient() (common.Address, error) {
	return _WDLTemplate.Contract.FeeRecipient(&_WDLTemplate.CallOpts)
}

// GetAllPrices is a free data retrieval call binding the contract method 0x445df9d6.
//
// Solidity: function getAllPrices() view returns(uint256[3] prices)
func (_WDLTemplate *WDLTemplateCaller) GetAllPrices(opts *bind.CallOpts) ([3]*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "getAllPrices")

	if err != nil {
		return *new([3]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([3]*big.Int)).(*[3]*big.Int)

	return out0, err

}

// GetAllPrices is a free data retrieval call binding the contract method 0x445df9d6.
//
// Solidity: function getAllPrices() view returns(uint256[3] prices)
func (_WDLTemplate *WDLTemplateSession) GetAllPrices() ([3]*big.Int, error) {
	return _WDLTemplate.Contract.GetAllPrices(&_WDLTemplate.CallOpts)
}

// GetAllPrices is a free data retrieval call binding the contract method 0x445df9d6.
//
// Solidity: function getAllPrices() view returns(uint256[3] prices)
func (_WDLTemplate *WDLTemplateCallerSession) GetAllPrices() ([3]*big.Int, error) {
	return _WDLTemplate.Contract.GetAllPrices(&_WDLTemplate.CallOpts)
}

// GetCurrentPrice is a free data retrieval call binding the contract method 0xc55d0f56.
//
// Solidity: function getCurrentPrice(uint256 outcomeId) view returns(uint256 price)
func (_WDLTemplate *WDLTemplateCaller) GetCurrentPrice(opts *bind.CallOpts, outcomeId *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "getCurrentPrice", outcomeId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCurrentPrice is a free data retrieval call binding the contract method 0xc55d0f56.
//
// Solidity: function getCurrentPrice(uint256 outcomeId) view returns(uint256 price)
func (_WDLTemplate *WDLTemplateSession) GetCurrentPrice(outcomeId *big.Int) (*big.Int, error) {
	return _WDLTemplate.Contract.GetCurrentPrice(&_WDLTemplate.CallOpts, outcomeId)
}

// GetCurrentPrice is a free data retrieval call binding the contract method 0xc55d0f56.
//
// Solidity: function getCurrentPrice(uint256 outcomeId) view returns(uint256 price)
func (_WDLTemplate *WDLTemplateCallerSession) GetCurrentPrice(outcomeId *big.Int) (*big.Int, error) {
	return _WDLTemplate.Contract.GetCurrentPrice(&_WDLTemplate.CallOpts, outcomeId)
}

// GetMarketInfo is a free data retrieval call binding the contract method 0x23341a05.
//
// Solidity: function getMarketInfo() view returns(string _matchId, string _homeTeam, string _awayTeam, uint256 _kickoffTime, uint8 _status)
func (_WDLTemplate *WDLTemplateCaller) GetMarketInfo(opts *bind.CallOpts) (struct {
	MatchId     string
	HomeTeam    string
	AwayTeam    string
	KickoffTime *big.Int
	Status      uint8
}, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "getMarketInfo")

	outstruct := new(struct {
		MatchId     string
		HomeTeam    string
		AwayTeam    string
		KickoffTime *big.Int
		Status      uint8
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.MatchId = *abi.ConvertType(out[0], new(string)).(*string)
	outstruct.HomeTeam = *abi.ConvertType(out[1], new(string)).(*string)
	outstruct.AwayTeam = *abi.ConvertType(out[2], new(string)).(*string)
	outstruct.KickoffTime = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.Status = *abi.ConvertType(out[4], new(uint8)).(*uint8)

	return *outstruct, err

}

// GetMarketInfo is a free data retrieval call binding the contract method 0x23341a05.
//
// Solidity: function getMarketInfo() view returns(string _matchId, string _homeTeam, string _awayTeam, uint256 _kickoffTime, uint8 _status)
func (_WDLTemplate *WDLTemplateSession) GetMarketInfo() (struct {
	MatchId     string
	HomeTeam    string
	AwayTeam    string
	KickoffTime *big.Int
	Status      uint8
}, error) {
	return _WDLTemplate.Contract.GetMarketInfo(&_WDLTemplate.CallOpts)
}

// GetMarketInfo is a free data retrieval call binding the contract method 0x23341a05.
//
// Solidity: function getMarketInfo() view returns(string _matchId, string _homeTeam, string _awayTeam, uint256 _kickoffTime, uint8 _status)
func (_WDLTemplate *WDLTemplateCallerSession) GetMarketInfo() (struct {
	MatchId     string
	HomeTeam    string
	AwayTeam    string
	KickoffTime *big.Int
	Status      uint8
}, error) {
	return _WDLTemplate.Contract.GetMarketInfo(&_WDLTemplate.CallOpts)
}

// GetUserPosition is a free data retrieval call binding the contract method 0x1c88ef1e.
//
// Solidity: function getUserPosition(address user, uint256 outcomeId) view returns(uint256)
func (_WDLTemplate *WDLTemplateCaller) GetUserPosition(opts *bind.CallOpts, user common.Address, outcomeId *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "getUserPosition", user, outcomeId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetUserPosition is a free data retrieval call binding the contract method 0x1c88ef1e.
//
// Solidity: function getUserPosition(address user, uint256 outcomeId) view returns(uint256)
func (_WDLTemplate *WDLTemplateSession) GetUserPosition(user common.Address, outcomeId *big.Int) (*big.Int, error) {
	return _WDLTemplate.Contract.GetUserPosition(&_WDLTemplate.CallOpts, user, outcomeId)
}

// GetUserPosition is a free data retrieval call binding the contract method 0x1c88ef1e.
//
// Solidity: function getUserPosition(address user, uint256 outcomeId) view returns(uint256)
func (_WDLTemplate *WDLTemplateCallerSession) GetUserPosition(user common.Address, outcomeId *big.Int) (*big.Int, error) {
	return _WDLTemplate.Contract.GetUserPosition(&_WDLTemplate.CallOpts, user, outcomeId)
}

// HomeTeam is a free data retrieval call binding the contract method 0xae989d36.
//
// Solidity: function homeTeam() view returns(string)
func (_WDLTemplate *WDLTemplateCaller) HomeTeam(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "homeTeam")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// HomeTeam is a free data retrieval call binding the contract method 0xae989d36.
//
// Solidity: function homeTeam() view returns(string)
func (_WDLTemplate *WDLTemplateSession) HomeTeam() (string, error) {
	return _WDLTemplate.Contract.HomeTeam(&_WDLTemplate.CallOpts)
}

// HomeTeam is a free data retrieval call binding the contract method 0xae989d36.
//
// Solidity: function homeTeam() view returns(string)
func (_WDLTemplate *WDLTemplateCallerSession) HomeTeam() (string, error) {
	return _WDLTemplate.Contract.HomeTeam(&_WDLTemplate.CallOpts)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_WDLTemplate *WDLTemplateCaller) IsApprovedForAll(opts *bind.CallOpts, account common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "isApprovedForAll", account, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_WDLTemplate *WDLTemplateSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _WDLTemplate.Contract.IsApprovedForAll(&_WDLTemplate.CallOpts, account, operator)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address account, address operator) view returns(bool)
func (_WDLTemplate *WDLTemplateCallerSession) IsApprovedForAll(account common.Address, operator common.Address) (bool, error) {
	return _WDLTemplate.Contract.IsApprovedForAll(&_WDLTemplate.CallOpts, account, operator)
}

// KickoffTime is a free data retrieval call binding the contract method 0x1f5dca1a.
//
// Solidity: function kickoffTime() view returns(uint256)
func (_WDLTemplate *WDLTemplateCaller) KickoffTime(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "kickoffTime")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// KickoffTime is a free data retrieval call binding the contract method 0x1f5dca1a.
//
// Solidity: function kickoffTime() view returns(uint256)
func (_WDLTemplate *WDLTemplateSession) KickoffTime() (*big.Int, error) {
	return _WDLTemplate.Contract.KickoffTime(&_WDLTemplate.CallOpts)
}

// KickoffTime is a free data retrieval call binding the contract method 0x1f5dca1a.
//
// Solidity: function kickoffTime() view returns(uint256)
func (_WDLTemplate *WDLTemplateCallerSession) KickoffTime() (*big.Int, error) {
	return _WDLTemplate.Contract.KickoffTime(&_WDLTemplate.CallOpts)
}

// LockTimestamp is a free data retrieval call binding the contract method 0xb544bf83.
//
// Solidity: function lockTimestamp() view returns(uint256)
func (_WDLTemplate *WDLTemplateCaller) LockTimestamp(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "lockTimestamp")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LockTimestamp is a free data retrieval call binding the contract method 0xb544bf83.
//
// Solidity: function lockTimestamp() view returns(uint256)
func (_WDLTemplate *WDLTemplateSession) LockTimestamp() (*big.Int, error) {
	return _WDLTemplate.Contract.LockTimestamp(&_WDLTemplate.CallOpts)
}

// LockTimestamp is a free data retrieval call binding the contract method 0xb544bf83.
//
// Solidity: function lockTimestamp() view returns(uint256)
func (_WDLTemplate *WDLTemplateCallerSession) LockTimestamp() (*big.Int, error) {
	return _WDLTemplate.Contract.LockTimestamp(&_WDLTemplate.CallOpts)
}

// MatchId is a free data retrieval call binding the contract method 0x99892e47.
//
// Solidity: function matchId() view returns(string)
func (_WDLTemplate *WDLTemplateCaller) MatchId(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "matchId")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// MatchId is a free data retrieval call binding the contract method 0x99892e47.
//
// Solidity: function matchId() view returns(string)
func (_WDLTemplate *WDLTemplateSession) MatchId() (string, error) {
	return _WDLTemplate.Contract.MatchId(&_WDLTemplate.CallOpts)
}

// MatchId is a free data retrieval call binding the contract method 0x99892e47.
//
// Solidity: function matchId() view returns(string)
func (_WDLTemplate *WDLTemplateCallerSession) MatchId() (string, error) {
	return _WDLTemplate.Contract.MatchId(&_WDLTemplate.CallOpts)
}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256)
func (_WDLTemplate *WDLTemplateCaller) OutcomeCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "outcomeCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256)
func (_WDLTemplate *WDLTemplateSession) OutcomeCount() (*big.Int, error) {
	return _WDLTemplate.Contract.OutcomeCount(&_WDLTemplate.CallOpts)
}

// OutcomeCount is a free data retrieval call binding the contract method 0xd300cb31.
//
// Solidity: function outcomeCount() view returns(uint256)
func (_WDLTemplate *WDLTemplateCallerSession) OutcomeCount() (*big.Int, error) {
	return _WDLTemplate.Contract.OutcomeCount(&_WDLTemplate.CallOpts)
}

// OutcomeLiquidity is a free data retrieval call binding the contract method 0x3c5996e0.
//
// Solidity: function outcomeLiquidity(uint256 ) view returns(uint256)
func (_WDLTemplate *WDLTemplateCaller) OutcomeLiquidity(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "outcomeLiquidity", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// OutcomeLiquidity is a free data retrieval call binding the contract method 0x3c5996e0.
//
// Solidity: function outcomeLiquidity(uint256 ) view returns(uint256)
func (_WDLTemplate *WDLTemplateSession) OutcomeLiquidity(arg0 *big.Int) (*big.Int, error) {
	return _WDLTemplate.Contract.OutcomeLiquidity(&_WDLTemplate.CallOpts, arg0)
}

// OutcomeLiquidity is a free data retrieval call binding the contract method 0x3c5996e0.
//
// Solidity: function outcomeLiquidity(uint256 ) view returns(uint256)
func (_WDLTemplate *WDLTemplateCallerSession) OutcomeLiquidity(arg0 *big.Int) (*big.Int, error) {
	return _WDLTemplate.Contract.OutcomeLiquidity(&_WDLTemplate.CallOpts, arg0)
}

// OutcomeNames is a free data retrieval call binding the contract method 0x27acae74.
//
// Solidity: function outcomeNames(uint256 ) view returns(string)
func (_WDLTemplate *WDLTemplateCaller) OutcomeNames(opts *bind.CallOpts, arg0 *big.Int) (string, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "outcomeNames", arg0)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// OutcomeNames is a free data retrieval call binding the contract method 0x27acae74.
//
// Solidity: function outcomeNames(uint256 ) view returns(string)
func (_WDLTemplate *WDLTemplateSession) OutcomeNames(arg0 *big.Int) (string, error) {
	return _WDLTemplate.Contract.OutcomeNames(&_WDLTemplate.CallOpts, arg0)
}

// OutcomeNames is a free data retrieval call binding the contract method 0x27acae74.
//
// Solidity: function outcomeNames(uint256 ) view returns(string)
func (_WDLTemplate *WDLTemplateCallerSession) OutcomeNames(arg0 *big.Int) (string, error) {
	return _WDLTemplate.Contract.OutcomeNames(&_WDLTemplate.CallOpts, arg0)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_WDLTemplate *WDLTemplateCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_WDLTemplate *WDLTemplateSession) Owner() (common.Address, error) {
	return _WDLTemplate.Contract.Owner(&_WDLTemplate.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_WDLTemplate *WDLTemplateCallerSession) Owner() (common.Address, error) {
	return _WDLTemplate.Contract.Owner(&_WDLTemplate.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_WDLTemplate *WDLTemplateCaller) Paused(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "paused")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_WDLTemplate *WDLTemplateSession) Paused() (bool, error) {
	return _WDLTemplate.Contract.Paused(&_WDLTemplate.CallOpts)
}

// Paused is a free data retrieval call binding the contract method 0x5c975abb.
//
// Solidity: function paused() view returns(bool)
func (_WDLTemplate *WDLTemplateCallerSession) Paused() (bool, error) {
	return _WDLTemplate.Contract.Paused(&_WDLTemplate.CallOpts)
}

// PricingEngine is a free data retrieval call binding the contract method 0x2f04002b.
//
// Solidity: function pricingEngine() view returns(address)
func (_WDLTemplate *WDLTemplateCaller) PricingEngine(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "pricingEngine")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// PricingEngine is a free data retrieval call binding the contract method 0x2f04002b.
//
// Solidity: function pricingEngine() view returns(address)
func (_WDLTemplate *WDLTemplateSession) PricingEngine() (common.Address, error) {
	return _WDLTemplate.Contract.PricingEngine(&_WDLTemplate.CallOpts)
}

// PricingEngine is a free data retrieval call binding the contract method 0x2f04002b.
//
// Solidity: function pricingEngine() view returns(address)
func (_WDLTemplate *WDLTemplateCallerSession) PricingEngine() (common.Address, error) {
	return _WDLTemplate.Contract.PricingEngine(&_WDLTemplate.CallOpts)
}

// ResultOracle is a free data retrieval call binding the contract method 0xc77e5042.
//
// Solidity: function resultOracle() view returns(address)
func (_WDLTemplate *WDLTemplateCaller) ResultOracle(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "resultOracle")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ResultOracle is a free data retrieval call binding the contract method 0xc77e5042.
//
// Solidity: function resultOracle() view returns(address)
func (_WDLTemplate *WDLTemplateSession) ResultOracle() (common.Address, error) {
	return _WDLTemplate.Contract.ResultOracle(&_WDLTemplate.CallOpts)
}

// ResultOracle is a free data retrieval call binding the contract method 0xc77e5042.
//
// Solidity: function resultOracle() view returns(address)
func (_WDLTemplate *WDLTemplateCallerSession) ResultOracle() (common.Address, error) {
	return _WDLTemplate.Contract.ResultOracle(&_WDLTemplate.CallOpts)
}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_WDLTemplate *WDLTemplateCaller) SettlementToken(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "settlementToken")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_WDLTemplate *WDLTemplateSession) SettlementToken() (common.Address, error) {
	return _WDLTemplate.Contract.SettlementToken(&_WDLTemplate.CallOpts)
}

// SettlementToken is a free data retrieval call binding the contract method 0x7b9e618d.
//
// Solidity: function settlementToken() view returns(address)
func (_WDLTemplate *WDLTemplateCallerSession) SettlementToken() (common.Address, error) {
	return _WDLTemplate.Contract.SettlementToken(&_WDLTemplate.CallOpts)
}

// ShouldLock is a free data retrieval call binding the contract method 0x2175d0d3.
//
// Solidity: function shouldLock() view returns(bool _shouldLock)
func (_WDLTemplate *WDLTemplateCaller) ShouldLock(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "shouldLock")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ShouldLock is a free data retrieval call binding the contract method 0x2175d0d3.
//
// Solidity: function shouldLock() view returns(bool _shouldLock)
func (_WDLTemplate *WDLTemplateSession) ShouldLock() (bool, error) {
	return _WDLTemplate.Contract.ShouldLock(&_WDLTemplate.CallOpts)
}

// ShouldLock is a free data retrieval call binding the contract method 0x2175d0d3.
//
// Solidity: function shouldLock() view returns(bool _shouldLock)
func (_WDLTemplate *WDLTemplateCallerSession) ShouldLock() (bool, error) {
	return _WDLTemplate.Contract.ShouldLock(&_WDLTemplate.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_WDLTemplate *WDLTemplateCaller) Status(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "status")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_WDLTemplate *WDLTemplateSession) Status() (uint8, error) {
	return _WDLTemplate.Contract.Status(&_WDLTemplate.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint8)
func (_WDLTemplate *WDLTemplateCallerSession) Status() (uint8, error) {
	return _WDLTemplate.Contract.Status(&_WDLTemplate.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_WDLTemplate *WDLTemplateCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_WDLTemplate *WDLTemplateSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _WDLTemplate.Contract.SupportsInterface(&_WDLTemplate.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_WDLTemplate *WDLTemplateCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _WDLTemplate.Contract.SupportsInterface(&_WDLTemplate.CallOpts, interfaceId)
}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_WDLTemplate *WDLTemplateCaller) TotalLiquidity(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "totalLiquidity")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_WDLTemplate *WDLTemplateSession) TotalLiquidity() (*big.Int, error) {
	return _WDLTemplate.Contract.TotalLiquidity(&_WDLTemplate.CallOpts)
}

// TotalLiquidity is a free data retrieval call binding the contract method 0x15770f92.
//
// Solidity: function totalLiquidity() view returns(uint256)
func (_WDLTemplate *WDLTemplateCallerSession) TotalLiquidity() (*big.Int, error) {
	return _WDLTemplate.Contract.TotalLiquidity(&_WDLTemplate.CallOpts)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_WDLTemplate *WDLTemplateCaller) Uri(opts *bind.CallOpts, arg0 *big.Int) (string, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "uri", arg0)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_WDLTemplate *WDLTemplateSession) Uri(arg0 *big.Int) (string, error) {
	return _WDLTemplate.Contract.Uri(&_WDLTemplate.CallOpts, arg0)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 ) view returns(string)
func (_WDLTemplate *WDLTemplateCallerSession) Uri(arg0 *big.Int) (string, error) {
	return _WDLTemplate.Contract.Uri(&_WDLTemplate.CallOpts, arg0)
}

// WinningOutcome is a free data retrieval call binding the contract method 0x9b34ae03.
//
// Solidity: function winningOutcome() view returns(uint256)
func (_WDLTemplate *WDLTemplateCaller) WinningOutcome(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _WDLTemplate.contract.Call(opts, &out, "winningOutcome")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WinningOutcome is a free data retrieval call binding the contract method 0x9b34ae03.
//
// Solidity: function winningOutcome() view returns(uint256)
func (_WDLTemplate *WDLTemplateSession) WinningOutcome() (*big.Int, error) {
	return _WDLTemplate.Contract.WinningOutcome(&_WDLTemplate.CallOpts)
}

// WinningOutcome is a free data retrieval call binding the contract method 0x9b34ae03.
//
// Solidity: function winningOutcome() view returns(uint256)
func (_WDLTemplate *WDLTemplateCallerSession) WinningOutcome() (*big.Int, error) {
	return _WDLTemplate.Contract.WinningOutcome(&_WDLTemplate.CallOpts)
}

// AutoLock is a paid mutator transaction binding the contract method 0xd9a15965.
//
// Solidity: function autoLock() returns()
func (_WDLTemplate *WDLTemplateTransactor) AutoLock(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "autoLock")
}

// AutoLock is a paid mutator transaction binding the contract method 0xd9a15965.
//
// Solidity: function autoLock() returns()
func (_WDLTemplate *WDLTemplateSession) AutoLock() (*types.Transaction, error) {
	return _WDLTemplate.Contract.AutoLock(&_WDLTemplate.TransactOpts)
}

// AutoLock is a paid mutator transaction binding the contract method 0xd9a15965.
//
// Solidity: function autoLock() returns()
func (_WDLTemplate *WDLTemplateTransactorSession) AutoLock() (*types.Transaction, error) {
	return _WDLTemplate.Contract.AutoLock(&_WDLTemplate.TransactOpts)
}

// Finalize is a paid mutator transaction binding the contract method 0x4bb278f3.
//
// Solidity: function finalize() returns()
func (_WDLTemplate *WDLTemplateTransactor) Finalize(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "finalize")
}

// Finalize is a paid mutator transaction binding the contract method 0x4bb278f3.
//
// Solidity: function finalize() returns()
func (_WDLTemplate *WDLTemplateSession) Finalize() (*types.Transaction, error) {
	return _WDLTemplate.Contract.Finalize(&_WDLTemplate.TransactOpts)
}

// Finalize is a paid mutator transaction binding the contract method 0x4bb278f3.
//
// Solidity: function finalize() returns()
func (_WDLTemplate *WDLTemplateTransactorSession) Finalize() (*types.Transaction, error) {
	return _WDLTemplate.Contract.Finalize(&_WDLTemplate.TransactOpts)
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_WDLTemplate *WDLTemplateTransactor) Lock(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "lock")
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_WDLTemplate *WDLTemplateSession) Lock() (*types.Transaction, error) {
	return _WDLTemplate.Contract.Lock(&_WDLTemplate.TransactOpts)
}

// Lock is a paid mutator transaction binding the contract method 0xf83d08ba.
//
// Solidity: function lock() returns()
func (_WDLTemplate *WDLTemplateTransactorSession) Lock() (*types.Transaction, error) {
	return _WDLTemplate.Contract.Lock(&_WDLTemplate.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_WDLTemplate *WDLTemplateTransactor) Pause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "pause")
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_WDLTemplate *WDLTemplateSession) Pause() (*types.Transaction, error) {
	return _WDLTemplate.Contract.Pause(&_WDLTemplate.TransactOpts)
}

// Pause is a paid mutator transaction binding the contract method 0x8456cb59.
//
// Solidity: function pause() returns()
func (_WDLTemplate *WDLTemplateTransactorSession) Pause() (*types.Transaction, error) {
	return _WDLTemplate.Contract.Pause(&_WDLTemplate.TransactOpts)
}

// PlaceBet is a paid mutator transaction binding the contract method 0x4afe62b5.
//
// Solidity: function placeBet(uint256 outcomeId, uint256 amount) returns(uint256 shares)
func (_WDLTemplate *WDLTemplateTransactor) PlaceBet(opts *bind.TransactOpts, outcomeId *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "placeBet", outcomeId, amount)
}

// PlaceBet is a paid mutator transaction binding the contract method 0x4afe62b5.
//
// Solidity: function placeBet(uint256 outcomeId, uint256 amount) returns(uint256 shares)
func (_WDLTemplate *WDLTemplateSession) PlaceBet(outcomeId *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.Contract.PlaceBet(&_WDLTemplate.TransactOpts, outcomeId, amount)
}

// PlaceBet is a paid mutator transaction binding the contract method 0x4afe62b5.
//
// Solidity: function placeBet(uint256 outcomeId, uint256 amount) returns(uint256 shares)
func (_WDLTemplate *WDLTemplateTransactorSession) PlaceBet(outcomeId *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.Contract.PlaceBet(&_WDLTemplate.TransactOpts, outcomeId, amount)
}

// Redeem is a paid mutator transaction binding the contract method 0x7cbc2373.
//
// Solidity: function redeem(uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_WDLTemplate *WDLTemplateTransactor) Redeem(opts *bind.TransactOpts, outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "redeem", outcomeId, shares)
}

// Redeem is a paid mutator transaction binding the contract method 0x7cbc2373.
//
// Solidity: function redeem(uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_WDLTemplate *WDLTemplateSession) Redeem(outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.Contract.Redeem(&_WDLTemplate.TransactOpts, outcomeId, shares)
}

// Redeem is a paid mutator transaction binding the contract method 0x7cbc2373.
//
// Solidity: function redeem(uint256 outcomeId, uint256 shares) returns(uint256 payout)
func (_WDLTemplate *WDLTemplateTransactorSession) Redeem(outcomeId *big.Int, shares *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.Contract.Redeem(&_WDLTemplate.TransactOpts, outcomeId, shares)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_WDLTemplate *WDLTemplateTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_WDLTemplate *WDLTemplateSession) RenounceOwnership() (*types.Transaction, error) {
	return _WDLTemplate.Contract.RenounceOwnership(&_WDLTemplate.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_WDLTemplate *WDLTemplateTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _WDLTemplate.Contract.RenounceOwnership(&_WDLTemplate.TransactOpts)
}

// Resolve is a paid mutator transaction binding the contract method 0x4f896d4f.
//
// Solidity: function resolve(uint256 winningOutcomeId) returns()
func (_WDLTemplate *WDLTemplateTransactor) Resolve(opts *bind.TransactOpts, winningOutcomeId *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "resolve", winningOutcomeId)
}

// Resolve is a paid mutator transaction binding the contract method 0x4f896d4f.
//
// Solidity: function resolve(uint256 winningOutcomeId) returns()
func (_WDLTemplate *WDLTemplateSession) Resolve(winningOutcomeId *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.Contract.Resolve(&_WDLTemplate.TransactOpts, winningOutcomeId)
}

// Resolve is a paid mutator transaction binding the contract method 0x4f896d4f.
//
// Solidity: function resolve(uint256 winningOutcomeId) returns()
func (_WDLTemplate *WDLTemplateTransactorSession) Resolve(winningOutcomeId *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.Contract.Resolve(&_WDLTemplate.TransactOpts, winningOutcomeId)
}

// ResolveFromOracle is a paid mutator transaction binding the contract method 0x830ced86.
//
// Solidity: function resolveFromOracle() returns()
func (_WDLTemplate *WDLTemplateTransactor) ResolveFromOracle(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "resolveFromOracle")
}

// ResolveFromOracle is a paid mutator transaction binding the contract method 0x830ced86.
//
// Solidity: function resolveFromOracle() returns()
func (_WDLTemplate *WDLTemplateSession) ResolveFromOracle() (*types.Transaction, error) {
	return _WDLTemplate.Contract.ResolveFromOracle(&_WDLTemplate.TransactOpts)
}

// ResolveFromOracle is a paid mutator transaction binding the contract method 0x830ced86.
//
// Solidity: function resolveFromOracle() returns()
func (_WDLTemplate *WDLTemplateTransactorSession) ResolveFromOracle() (*types.Transaction, error) {
	return _WDLTemplate.Contract.ResolveFromOracle(&_WDLTemplate.TransactOpts)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_WDLTemplate *WDLTemplateTransactor) SafeBatchTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "safeBatchTransferFrom", from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_WDLTemplate *WDLTemplateSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SafeBatchTransferFrom(&_WDLTemplate.TransactOpts, from, to, ids, values, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] values, bytes data) returns()
func (_WDLTemplate *WDLTemplateTransactorSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, values []*big.Int, data []byte) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SafeBatchTransferFrom(&_WDLTemplate.TransactOpts, from, to, ids, values, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_WDLTemplate *WDLTemplateTransactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "safeTransferFrom", from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_WDLTemplate *WDLTemplateSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SafeTransferFrom(&_WDLTemplate.TransactOpts, from, to, id, value, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes data) returns()
func (_WDLTemplate *WDLTemplateTransactorSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, value *big.Int, data []byte) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SafeTransferFrom(&_WDLTemplate.TransactOpts, from, to, id, value, data)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_WDLTemplate *WDLTemplateTransactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_WDLTemplate *WDLTemplateSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetApprovalForAll(&_WDLTemplate.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_WDLTemplate *WDLTemplateTransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetApprovalForAll(&_WDLTemplate.TransactOpts, operator, approved)
}

// SetDiscountOracle is a paid mutator transaction binding the contract method 0x0736251c.
//
// Solidity: function setDiscountOracle(address _discountOracle) returns()
func (_WDLTemplate *WDLTemplateTransactor) SetDiscountOracle(opts *bind.TransactOpts, _discountOracle common.Address) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "setDiscountOracle", _discountOracle)
}

// SetDiscountOracle is a paid mutator transaction binding the contract method 0x0736251c.
//
// Solidity: function setDiscountOracle(address _discountOracle) returns()
func (_WDLTemplate *WDLTemplateSession) SetDiscountOracle(_discountOracle common.Address) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetDiscountOracle(&_WDLTemplate.TransactOpts, _discountOracle)
}

// SetDiscountOracle is a paid mutator transaction binding the contract method 0x0736251c.
//
// Solidity: function setDiscountOracle(address _discountOracle) returns()
func (_WDLTemplate *WDLTemplateTransactorSession) SetDiscountOracle(_discountOracle common.Address) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetDiscountOracle(&_WDLTemplate.TransactOpts, _discountOracle)
}

// SetFeeRate is a paid mutator transaction binding the contract method 0x45596e2e.
//
// Solidity: function setFeeRate(uint256 _feeRate) returns()
func (_WDLTemplate *WDLTemplateTransactor) SetFeeRate(opts *bind.TransactOpts, _feeRate *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "setFeeRate", _feeRate)
}

// SetFeeRate is a paid mutator transaction binding the contract method 0x45596e2e.
//
// Solidity: function setFeeRate(uint256 _feeRate) returns()
func (_WDLTemplate *WDLTemplateSession) SetFeeRate(_feeRate *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetFeeRate(&_WDLTemplate.TransactOpts, _feeRate)
}

// SetFeeRate is a paid mutator transaction binding the contract method 0x45596e2e.
//
// Solidity: function setFeeRate(uint256 _feeRate) returns()
func (_WDLTemplate *WDLTemplateTransactorSession) SetFeeRate(_feeRate *big.Int) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetFeeRate(&_WDLTemplate.TransactOpts, _feeRate)
}

// SetFeeRecipient is a paid mutator transaction binding the contract method 0xe74b981b.
//
// Solidity: function setFeeRecipient(address _feeRecipient) returns()
func (_WDLTemplate *WDLTemplateTransactor) SetFeeRecipient(opts *bind.TransactOpts, _feeRecipient common.Address) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "setFeeRecipient", _feeRecipient)
}

// SetFeeRecipient is a paid mutator transaction binding the contract method 0xe74b981b.
//
// Solidity: function setFeeRecipient(address _feeRecipient) returns()
func (_WDLTemplate *WDLTemplateSession) SetFeeRecipient(_feeRecipient common.Address) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetFeeRecipient(&_WDLTemplate.TransactOpts, _feeRecipient)
}

// SetFeeRecipient is a paid mutator transaction binding the contract method 0xe74b981b.
//
// Solidity: function setFeeRecipient(address _feeRecipient) returns()
func (_WDLTemplate *WDLTemplateTransactorSession) SetFeeRecipient(_feeRecipient common.Address) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetFeeRecipient(&_WDLTemplate.TransactOpts, _feeRecipient)
}

// SetPricingEngine is a paid mutator transaction binding the contract method 0xa6ae4cfc.
//
// Solidity: function setPricingEngine(address _pricingEngine) returns()
func (_WDLTemplate *WDLTemplateTransactor) SetPricingEngine(opts *bind.TransactOpts, _pricingEngine common.Address) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "setPricingEngine", _pricingEngine)
}

// SetPricingEngine is a paid mutator transaction binding the contract method 0xa6ae4cfc.
//
// Solidity: function setPricingEngine(address _pricingEngine) returns()
func (_WDLTemplate *WDLTemplateSession) SetPricingEngine(_pricingEngine common.Address) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetPricingEngine(&_WDLTemplate.TransactOpts, _pricingEngine)
}

// SetPricingEngine is a paid mutator transaction binding the contract method 0xa6ae4cfc.
//
// Solidity: function setPricingEngine(address _pricingEngine) returns()
func (_WDLTemplate *WDLTemplateTransactorSession) SetPricingEngine(_pricingEngine common.Address) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetPricingEngine(&_WDLTemplate.TransactOpts, _pricingEngine)
}

// SetResultOracle is a paid mutator transaction binding the contract method 0x17bc4648.
//
// Solidity: function setResultOracle(address _resultOracle) returns()
func (_WDLTemplate *WDLTemplateTransactor) SetResultOracle(opts *bind.TransactOpts, _resultOracle common.Address) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "setResultOracle", _resultOracle)
}

// SetResultOracle is a paid mutator transaction binding the contract method 0x17bc4648.
//
// Solidity: function setResultOracle(address _resultOracle) returns()
func (_WDLTemplate *WDLTemplateSession) SetResultOracle(_resultOracle common.Address) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetResultOracle(&_WDLTemplate.TransactOpts, _resultOracle)
}

// SetResultOracle is a paid mutator transaction binding the contract method 0x17bc4648.
//
// Solidity: function setResultOracle(address _resultOracle) returns()
func (_WDLTemplate *WDLTemplateTransactorSession) SetResultOracle(_resultOracle common.Address) (*types.Transaction, error) {
	return _WDLTemplate.Contract.SetResultOracle(&_WDLTemplate.TransactOpts, _resultOracle)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_WDLTemplate *WDLTemplateTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_WDLTemplate *WDLTemplateSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _WDLTemplate.Contract.TransferOwnership(&_WDLTemplate.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_WDLTemplate *WDLTemplateTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _WDLTemplate.Contract.TransferOwnership(&_WDLTemplate.TransactOpts, newOwner)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_WDLTemplate *WDLTemplateTransactor) Unpause(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _WDLTemplate.contract.Transact(opts, "unpause")
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_WDLTemplate *WDLTemplateSession) Unpause() (*types.Transaction, error) {
	return _WDLTemplate.Contract.Unpause(&_WDLTemplate.TransactOpts)
}

// Unpause is a paid mutator transaction binding the contract method 0x3f4ba83a.
//
// Solidity: function unpause() returns()
func (_WDLTemplate *WDLTemplateTransactorSession) Unpause() (*types.Transaction, error) {
	return _WDLTemplate.Contract.Unpause(&_WDLTemplate.TransactOpts)
}

// WDLTemplateApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the WDLTemplate contract.
type WDLTemplateApprovalForAllIterator struct {
	Event *WDLTemplateApprovalForAll // Event containing the contract specifics and raw log

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
func (it *WDLTemplateApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateApprovalForAll)
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
		it.Event = new(WDLTemplateApprovalForAll)
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
func (it *WDLTemplateApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateApprovalForAll represents a ApprovalForAll event raised by the WDLTemplate contract.
type WDLTemplateApprovalForAll struct {
	Account  common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_WDLTemplate *WDLTemplateFilterer) FilterApprovalForAll(opts *bind.FilterOpts, account []common.Address, operator []common.Address) (*WDLTemplateApprovalForAllIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateApprovalForAllIterator{contract: _WDLTemplate.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_WDLTemplate *WDLTemplateFilterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *WDLTemplateApprovalForAll, account []common.Address, operator []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateApprovalForAll)
				if err := _WDLTemplate.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseApprovalForAll(log types.Log) (*WDLTemplateApprovalForAll, error) {
	event := new(WDLTemplateApprovalForAll)
	if err := _WDLTemplate.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateBetPlacedIterator is returned from FilterBetPlaced and is used to iterate over the raw logs and unpacked data for BetPlaced events raised by the WDLTemplate contract.
type WDLTemplateBetPlacedIterator struct {
	Event *WDLTemplateBetPlaced // Event containing the contract specifics and raw log

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
func (it *WDLTemplateBetPlacedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateBetPlaced)
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
		it.Event = new(WDLTemplateBetPlaced)
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
func (it *WDLTemplateBetPlacedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateBetPlacedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateBetPlaced represents a BetPlaced event raised by the WDLTemplate contract.
type WDLTemplateBetPlaced struct {
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
func (_WDLTemplate *WDLTemplateFilterer) FilterBetPlaced(opts *bind.FilterOpts, user []common.Address, outcomeId []*big.Int) (*WDLTemplateBetPlacedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "BetPlaced", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateBetPlacedIterator{contract: _WDLTemplate.contract, event: "BetPlaced", logs: logs, sub: sub}, nil
}

// WatchBetPlaced is a free log subscription operation binding the contract event 0x935a8686694e2b5cc90f63054b327255f6fb92db3acd6d98c5a707d4987e93e1.
//
// Solidity: event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares, uint256 fee)
func (_WDLTemplate *WDLTemplateFilterer) WatchBetPlaced(opts *bind.WatchOpts, sink chan<- *WDLTemplateBetPlaced, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "BetPlaced", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateBetPlaced)
				if err := _WDLTemplate.contract.UnpackLog(event, "BetPlaced", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseBetPlaced(log types.Log) (*WDLTemplateBetPlaced, error) {
	event := new(WDLTemplateBetPlaced)
	if err := _WDLTemplate.contract.UnpackLog(event, "BetPlaced", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateDiscountOracleUpdatedIterator is returned from FilterDiscountOracleUpdated and is used to iterate over the raw logs and unpacked data for DiscountOracleUpdated events raised by the WDLTemplate contract.
type WDLTemplateDiscountOracleUpdatedIterator struct {
	Event *WDLTemplateDiscountOracleUpdated // Event containing the contract specifics and raw log

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
func (it *WDLTemplateDiscountOracleUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateDiscountOracleUpdated)
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
		it.Event = new(WDLTemplateDiscountOracleUpdated)
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
func (it *WDLTemplateDiscountOracleUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateDiscountOracleUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateDiscountOracleUpdated represents a DiscountOracleUpdated event raised by the WDLTemplate contract.
type WDLTemplateDiscountOracleUpdated struct {
	OldOracle common.Address
	NewOracle common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterDiscountOracleUpdated is a free log retrieval operation binding the contract event 0xb0a21792e739b32d34f3928764f774f8b8702f15d4b00f2e688689d23050aaa6.
//
// Solidity: event DiscountOracleUpdated(address indexed oldOracle, address indexed newOracle)
func (_WDLTemplate *WDLTemplateFilterer) FilterDiscountOracleUpdated(opts *bind.FilterOpts, oldOracle []common.Address, newOracle []common.Address) (*WDLTemplateDiscountOracleUpdatedIterator, error) {

	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "DiscountOracleUpdated", oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateDiscountOracleUpdatedIterator{contract: _WDLTemplate.contract, event: "DiscountOracleUpdated", logs: logs, sub: sub}, nil
}

// WatchDiscountOracleUpdated is a free log subscription operation binding the contract event 0xb0a21792e739b32d34f3928764f774f8b8702f15d4b00f2e688689d23050aaa6.
//
// Solidity: event DiscountOracleUpdated(address indexed oldOracle, address indexed newOracle)
func (_WDLTemplate *WDLTemplateFilterer) WatchDiscountOracleUpdated(opts *bind.WatchOpts, sink chan<- *WDLTemplateDiscountOracleUpdated, oldOracle []common.Address, newOracle []common.Address) (event.Subscription, error) {

	var oldOracleRule []interface{}
	for _, oldOracleItem := range oldOracle {
		oldOracleRule = append(oldOracleRule, oldOracleItem)
	}
	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "DiscountOracleUpdated", oldOracleRule, newOracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateDiscountOracleUpdated)
				if err := _WDLTemplate.contract.UnpackLog(event, "DiscountOracleUpdated", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseDiscountOracleUpdated(log types.Log) (*WDLTemplateDiscountOracleUpdated, error) {
	event := new(WDLTemplateDiscountOracleUpdated)
	if err := _WDLTemplate.contract.UnpackLog(event, "DiscountOracleUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateFinalizedIterator is returned from FilterFinalized and is used to iterate over the raw logs and unpacked data for Finalized events raised by the WDLTemplate contract.
type WDLTemplateFinalizedIterator struct {
	Event *WDLTemplateFinalized // Event containing the contract specifics and raw log

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
func (it *WDLTemplateFinalizedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateFinalized)
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
		it.Event = new(WDLTemplateFinalized)
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
func (it *WDLTemplateFinalizedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateFinalizedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateFinalized represents a Finalized event raised by the WDLTemplate contract.
type WDLTemplateFinalized struct {
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterFinalized is a free log retrieval operation binding the contract event 0x839cf22e1ba87ce2f5b9bbf46cf0175a09eed52febdfaac8852478e68203c763.
//
// Solidity: event Finalized(uint256 timestamp)
func (_WDLTemplate *WDLTemplateFilterer) FilterFinalized(opts *bind.FilterOpts) (*WDLTemplateFinalizedIterator, error) {

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "Finalized")
	if err != nil {
		return nil, err
	}
	return &WDLTemplateFinalizedIterator{contract: _WDLTemplate.contract, event: "Finalized", logs: logs, sub: sub}, nil
}

// WatchFinalized is a free log subscription operation binding the contract event 0x839cf22e1ba87ce2f5b9bbf46cf0175a09eed52febdfaac8852478e68203c763.
//
// Solidity: event Finalized(uint256 timestamp)
func (_WDLTemplate *WDLTemplateFilterer) WatchFinalized(opts *bind.WatchOpts, sink chan<- *WDLTemplateFinalized) (event.Subscription, error) {

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "Finalized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateFinalized)
				if err := _WDLTemplate.contract.UnpackLog(event, "Finalized", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseFinalized(log types.Log) (*WDLTemplateFinalized, error) {
	event := new(WDLTemplateFinalized)
	if err := _WDLTemplate.contract.UnpackLog(event, "Finalized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateLockedIterator is returned from FilterLocked and is used to iterate over the raw logs and unpacked data for Locked events raised by the WDLTemplate contract.
type WDLTemplateLockedIterator struct {
	Event *WDLTemplateLocked // Event containing the contract specifics and raw log

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
func (it *WDLTemplateLockedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateLocked)
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
		it.Event = new(WDLTemplateLocked)
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
func (it *WDLTemplateLockedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateLockedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateLocked represents a Locked event raised by the WDLTemplate contract.
type WDLTemplateLocked struct {
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterLocked is a free log retrieval operation binding the contract event 0x032bc66be43dbccb7487781d168eb7bda224628a3b2c3388bdf69b532a3a1611.
//
// Solidity: event Locked(uint256 timestamp)
func (_WDLTemplate *WDLTemplateFilterer) FilterLocked(opts *bind.FilterOpts) (*WDLTemplateLockedIterator, error) {

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "Locked")
	if err != nil {
		return nil, err
	}
	return &WDLTemplateLockedIterator{contract: _WDLTemplate.contract, event: "Locked", logs: logs, sub: sub}, nil
}

// WatchLocked is a free log subscription operation binding the contract event 0x032bc66be43dbccb7487781d168eb7bda224628a3b2c3388bdf69b532a3a1611.
//
// Solidity: event Locked(uint256 timestamp)
func (_WDLTemplate *WDLTemplateFilterer) WatchLocked(opts *bind.WatchOpts, sink chan<- *WDLTemplateLocked) (event.Subscription, error) {

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "Locked")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateLocked)
				if err := _WDLTemplate.contract.UnpackLog(event, "Locked", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseLocked(log types.Log) (*WDLTemplateLocked, error) {
	event := new(WDLTemplateLocked)
	if err := _WDLTemplate.contract.UnpackLog(event, "Locked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateMarketCreatedIterator is returned from FilterMarketCreated and is used to iterate over the raw logs and unpacked data for MarketCreated events raised by the WDLTemplate contract.
type WDLTemplateMarketCreatedIterator struct {
	Event *WDLTemplateMarketCreated // Event containing the contract specifics and raw log

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
func (it *WDLTemplateMarketCreatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateMarketCreated)
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
		it.Event = new(WDLTemplateMarketCreated)
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
func (it *WDLTemplateMarketCreatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateMarketCreatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateMarketCreated represents a MarketCreated event raised by the WDLTemplate contract.
type WDLTemplateMarketCreated struct {
	MatchId       common.Hash
	HomeTeam      string
	AwayTeam      string
	KickoffTime   *big.Int
	PricingEngine common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterMarketCreated is a free log retrieval operation binding the contract event 0x194b40fbafdecd402675e151ab37ebcb3be609fdeaa3a29a2c8e6ce0d11fc779.
//
// Solidity: event MarketCreated(string indexed matchId, string homeTeam, string awayTeam, uint256 kickoffTime, address pricingEngine)
func (_WDLTemplate *WDLTemplateFilterer) FilterMarketCreated(opts *bind.FilterOpts, matchId []string) (*WDLTemplateMarketCreatedIterator, error) {

	var matchIdRule []interface{}
	for _, matchIdItem := range matchId {
		matchIdRule = append(matchIdRule, matchIdItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "MarketCreated", matchIdRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateMarketCreatedIterator{contract: _WDLTemplate.contract, event: "MarketCreated", logs: logs, sub: sub}, nil
}

// WatchMarketCreated is a free log subscription operation binding the contract event 0x194b40fbafdecd402675e151ab37ebcb3be609fdeaa3a29a2c8e6ce0d11fc779.
//
// Solidity: event MarketCreated(string indexed matchId, string homeTeam, string awayTeam, uint256 kickoffTime, address pricingEngine)
func (_WDLTemplate *WDLTemplateFilterer) WatchMarketCreated(opts *bind.WatchOpts, sink chan<- *WDLTemplateMarketCreated, matchId []string) (event.Subscription, error) {

	var matchIdRule []interface{}
	for _, matchIdItem := range matchId {
		matchIdRule = append(matchIdRule, matchIdItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "MarketCreated", matchIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateMarketCreated)
				if err := _WDLTemplate.contract.UnpackLog(event, "MarketCreated", log); err != nil {
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

// ParseMarketCreated is a log parse operation binding the contract event 0x194b40fbafdecd402675e151ab37ebcb3be609fdeaa3a29a2c8e6ce0d11fc779.
//
// Solidity: event MarketCreated(string indexed matchId, string homeTeam, string awayTeam, uint256 kickoffTime, address pricingEngine)
func (_WDLTemplate *WDLTemplateFilterer) ParseMarketCreated(log types.Log) (*WDLTemplateMarketCreated, error) {
	event := new(WDLTemplateMarketCreated)
	if err := _WDLTemplate.contract.UnpackLog(event, "MarketCreated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the WDLTemplate contract.
type WDLTemplateOwnershipTransferredIterator struct {
	Event *WDLTemplateOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *WDLTemplateOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateOwnershipTransferred)
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
		it.Event = new(WDLTemplateOwnershipTransferred)
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
func (it *WDLTemplateOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateOwnershipTransferred represents a OwnershipTransferred event raised by the WDLTemplate contract.
type WDLTemplateOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_WDLTemplate *WDLTemplateFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*WDLTemplateOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateOwnershipTransferredIterator{contract: _WDLTemplate.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_WDLTemplate *WDLTemplateFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *WDLTemplateOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateOwnershipTransferred)
				if err := _WDLTemplate.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseOwnershipTransferred(log types.Log) (*WDLTemplateOwnershipTransferred, error) {
	event := new(WDLTemplateOwnershipTransferred)
	if err := _WDLTemplate.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplatePausedIterator is returned from FilterPaused and is used to iterate over the raw logs and unpacked data for Paused events raised by the WDLTemplate contract.
type WDLTemplatePausedIterator struct {
	Event *WDLTemplatePaused // Event containing the contract specifics and raw log

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
func (it *WDLTemplatePausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplatePaused)
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
		it.Event = new(WDLTemplatePaused)
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
func (it *WDLTemplatePausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplatePausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplatePaused represents a Paused event raised by the WDLTemplate contract.
type WDLTemplatePaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterPaused is a free log retrieval operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_WDLTemplate *WDLTemplateFilterer) FilterPaused(opts *bind.FilterOpts) (*WDLTemplatePausedIterator, error) {

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return &WDLTemplatePausedIterator{contract: _WDLTemplate.contract, event: "Paused", logs: logs, sub: sub}, nil
}

// WatchPaused is a free log subscription operation binding the contract event 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258.
//
// Solidity: event Paused(address account)
func (_WDLTemplate *WDLTemplateFilterer) WatchPaused(opts *bind.WatchOpts, sink chan<- *WDLTemplatePaused) (event.Subscription, error) {

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "Paused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplatePaused)
				if err := _WDLTemplate.contract.UnpackLog(event, "Paused", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParsePaused(log types.Log) (*WDLTemplatePaused, error) {
	event := new(WDLTemplatePaused)
	if err := _WDLTemplate.contract.UnpackLog(event, "Paused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplatePricingEngineUpdatedIterator is returned from FilterPricingEngineUpdated and is used to iterate over the raw logs and unpacked data for PricingEngineUpdated events raised by the WDLTemplate contract.
type WDLTemplatePricingEngineUpdatedIterator struct {
	Event *WDLTemplatePricingEngineUpdated // Event containing the contract specifics and raw log

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
func (it *WDLTemplatePricingEngineUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplatePricingEngineUpdated)
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
		it.Event = new(WDLTemplatePricingEngineUpdated)
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
func (it *WDLTemplatePricingEngineUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplatePricingEngineUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplatePricingEngineUpdated represents a PricingEngineUpdated event raised by the WDLTemplate contract.
type WDLTemplatePricingEngineUpdated struct {
	OldEngine common.Address
	NewEngine common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterPricingEngineUpdated is a free log retrieval operation binding the contract event 0xa8b5bff31605557453985bec893496ac9ed67501629fca03b3ef08c39e0bf123.
//
// Solidity: event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine)
func (_WDLTemplate *WDLTemplateFilterer) FilterPricingEngineUpdated(opts *bind.FilterOpts, oldEngine []common.Address, newEngine []common.Address) (*WDLTemplatePricingEngineUpdatedIterator, error) {

	var oldEngineRule []interface{}
	for _, oldEngineItem := range oldEngine {
		oldEngineRule = append(oldEngineRule, oldEngineItem)
	}
	var newEngineRule []interface{}
	for _, newEngineItem := range newEngine {
		newEngineRule = append(newEngineRule, newEngineItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "PricingEngineUpdated", oldEngineRule, newEngineRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplatePricingEngineUpdatedIterator{contract: _WDLTemplate.contract, event: "PricingEngineUpdated", logs: logs, sub: sub}, nil
}

// WatchPricingEngineUpdated is a free log subscription operation binding the contract event 0xa8b5bff31605557453985bec893496ac9ed67501629fca03b3ef08c39e0bf123.
//
// Solidity: event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine)
func (_WDLTemplate *WDLTemplateFilterer) WatchPricingEngineUpdated(opts *bind.WatchOpts, sink chan<- *WDLTemplatePricingEngineUpdated, oldEngine []common.Address, newEngine []common.Address) (event.Subscription, error) {

	var oldEngineRule []interface{}
	for _, oldEngineItem := range oldEngine {
		oldEngineRule = append(oldEngineRule, oldEngineItem)
	}
	var newEngineRule []interface{}
	for _, newEngineItem := range newEngine {
		newEngineRule = append(newEngineRule, newEngineItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "PricingEngineUpdated", oldEngineRule, newEngineRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplatePricingEngineUpdated)
				if err := _WDLTemplate.contract.UnpackLog(event, "PricingEngineUpdated", log); err != nil {
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

// ParsePricingEngineUpdated is a log parse operation binding the contract event 0xa8b5bff31605557453985bec893496ac9ed67501629fca03b3ef08c39e0bf123.
//
// Solidity: event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine)
func (_WDLTemplate *WDLTemplateFilterer) ParsePricingEngineUpdated(log types.Log) (*WDLTemplatePricingEngineUpdated, error) {
	event := new(WDLTemplatePricingEngineUpdated)
	if err := _WDLTemplate.contract.UnpackLog(event, "PricingEngineUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateRedeemedIterator is returned from FilterRedeemed and is used to iterate over the raw logs and unpacked data for Redeemed events raised by the WDLTemplate contract.
type WDLTemplateRedeemedIterator struct {
	Event *WDLTemplateRedeemed // Event containing the contract specifics and raw log

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
func (it *WDLTemplateRedeemedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateRedeemed)
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
		it.Event = new(WDLTemplateRedeemed)
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
func (it *WDLTemplateRedeemedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateRedeemedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateRedeemed represents a Redeemed event raised by the WDLTemplate contract.
type WDLTemplateRedeemed struct {
	User      common.Address
	OutcomeId *big.Int
	Shares    *big.Int
	Payout    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterRedeemed is a free log retrieval operation binding the contract event 0x484c40561359f3e3b8be9101897f8680aa82fbe1df9fd9038e0dbc6284032646.
//
// Solidity: event Redeemed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_WDLTemplate *WDLTemplateFilterer) FilterRedeemed(opts *bind.FilterOpts, user []common.Address, outcomeId []*big.Int) (*WDLTemplateRedeemedIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "Redeemed", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateRedeemedIterator{contract: _WDLTemplate.contract, event: "Redeemed", logs: logs, sub: sub}, nil
}

// WatchRedeemed is a free log subscription operation binding the contract event 0x484c40561359f3e3b8be9101897f8680aa82fbe1df9fd9038e0dbc6284032646.
//
// Solidity: event Redeemed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
func (_WDLTemplate *WDLTemplateFilterer) WatchRedeemed(opts *bind.WatchOpts, sink chan<- *WDLTemplateRedeemed, user []common.Address, outcomeId []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var outcomeIdRule []interface{}
	for _, outcomeIdItem := range outcomeId {
		outcomeIdRule = append(outcomeIdRule, outcomeIdItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "Redeemed", userRule, outcomeIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateRedeemed)
				if err := _WDLTemplate.contract.UnpackLog(event, "Redeemed", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseRedeemed(log types.Log) (*WDLTemplateRedeemed, error) {
	event := new(WDLTemplateRedeemed)
	if err := _WDLTemplate.contract.UnpackLog(event, "Redeemed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateResolvedIterator is returned from FilterResolved and is used to iterate over the raw logs and unpacked data for Resolved events raised by the WDLTemplate contract.
type WDLTemplateResolvedIterator struct {
	Event *WDLTemplateResolved // Event containing the contract specifics and raw log

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
func (it *WDLTemplateResolvedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateResolved)
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
		it.Event = new(WDLTemplateResolved)
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
func (it *WDLTemplateResolvedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateResolvedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateResolved represents a Resolved event raised by the WDLTemplate contract.
type WDLTemplateResolved struct {
	WinningOutcome *big.Int
	Timestamp      *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterResolved is a free log retrieval operation binding the contract event 0x8a1cc9089f9efc6450ff2639ff6d6b27f6aaaac01cccae1789c0a36dffc21041.
//
// Solidity: event Resolved(uint256 indexed winningOutcome, uint256 timestamp)
func (_WDLTemplate *WDLTemplateFilterer) FilterResolved(opts *bind.FilterOpts, winningOutcome []*big.Int) (*WDLTemplateResolvedIterator, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "Resolved", winningOutcomeRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateResolvedIterator{contract: _WDLTemplate.contract, event: "Resolved", logs: logs, sub: sub}, nil
}

// WatchResolved is a free log subscription operation binding the contract event 0x8a1cc9089f9efc6450ff2639ff6d6b27f6aaaac01cccae1789c0a36dffc21041.
//
// Solidity: event Resolved(uint256 indexed winningOutcome, uint256 timestamp)
func (_WDLTemplate *WDLTemplateFilterer) WatchResolved(opts *bind.WatchOpts, sink chan<- *WDLTemplateResolved, winningOutcome []*big.Int) (event.Subscription, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "Resolved", winningOutcomeRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateResolved)
				if err := _WDLTemplate.contract.UnpackLog(event, "Resolved", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseResolved(log types.Log) (*WDLTemplateResolved, error) {
	event := new(WDLTemplateResolved)
	if err := _WDLTemplate.contract.UnpackLog(event, "Resolved", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateResolvedWithOracleIterator is returned from FilterResolvedWithOracle and is used to iterate over the raw logs and unpacked data for ResolvedWithOracle events raised by the WDLTemplate contract.
type WDLTemplateResolvedWithOracleIterator struct {
	Event *WDLTemplateResolvedWithOracle // Event containing the contract specifics and raw log

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
func (it *WDLTemplateResolvedWithOracleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateResolvedWithOracle)
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
		it.Event = new(WDLTemplateResolvedWithOracle)
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
func (it *WDLTemplateResolvedWithOracleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateResolvedWithOracleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateResolvedWithOracle represents a ResolvedWithOracle event raised by the WDLTemplate contract.
type WDLTemplateResolvedWithOracle struct {
	WinningOutcome *big.Int
	ResultHash     [32]byte
	Timestamp      *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterResolvedWithOracle is a free log retrieval operation binding the contract event 0x483e2cc22780ed0b10a1da294bc4acc4d4b81340fdebab99bb0a346644b020b3.
//
// Solidity: event ResolvedWithOracle(uint256 indexed winningOutcome, bytes32 indexed resultHash, uint256 timestamp)
func (_WDLTemplate *WDLTemplateFilterer) FilterResolvedWithOracle(opts *bind.FilterOpts, winningOutcome []*big.Int, resultHash [][32]byte) (*WDLTemplateResolvedWithOracleIterator, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}
	var resultHashRule []interface{}
	for _, resultHashItem := range resultHash {
		resultHashRule = append(resultHashRule, resultHashItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "ResolvedWithOracle", winningOutcomeRule, resultHashRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateResolvedWithOracleIterator{contract: _WDLTemplate.contract, event: "ResolvedWithOracle", logs: logs, sub: sub}, nil
}

// WatchResolvedWithOracle is a free log subscription operation binding the contract event 0x483e2cc22780ed0b10a1da294bc4acc4d4b81340fdebab99bb0a346644b020b3.
//
// Solidity: event ResolvedWithOracle(uint256 indexed winningOutcome, bytes32 indexed resultHash, uint256 timestamp)
func (_WDLTemplate *WDLTemplateFilterer) WatchResolvedWithOracle(opts *bind.WatchOpts, sink chan<- *WDLTemplateResolvedWithOracle, winningOutcome []*big.Int, resultHash [][32]byte) (event.Subscription, error) {

	var winningOutcomeRule []interface{}
	for _, winningOutcomeItem := range winningOutcome {
		winningOutcomeRule = append(winningOutcomeRule, winningOutcomeItem)
	}
	var resultHashRule []interface{}
	for _, resultHashItem := range resultHash {
		resultHashRule = append(resultHashRule, resultHashItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "ResolvedWithOracle", winningOutcomeRule, resultHashRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateResolvedWithOracle)
				if err := _WDLTemplate.contract.UnpackLog(event, "ResolvedWithOracle", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseResolvedWithOracle(log types.Log) (*WDLTemplateResolvedWithOracle, error) {
	event := new(WDLTemplateResolvedWithOracle)
	if err := _WDLTemplate.contract.UnpackLog(event, "ResolvedWithOracle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateResultOracleUpdatedIterator is returned from FilterResultOracleUpdated and is used to iterate over the raw logs and unpacked data for ResultOracleUpdated events raised by the WDLTemplate contract.
type WDLTemplateResultOracleUpdatedIterator struct {
	Event *WDLTemplateResultOracleUpdated // Event containing the contract specifics and raw log

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
func (it *WDLTemplateResultOracleUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateResultOracleUpdated)
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
		it.Event = new(WDLTemplateResultOracleUpdated)
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
func (it *WDLTemplateResultOracleUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateResultOracleUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateResultOracleUpdated represents a ResultOracleUpdated event raised by the WDLTemplate contract.
type WDLTemplateResultOracleUpdated struct {
	NewOracle common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterResultOracleUpdated is a free log retrieval operation binding the contract event 0xf4f6d8a1c53b96aaa54cac2192218b21030f6371f0b3e3a0fb15124fa1f08e8d.
//
// Solidity: event ResultOracleUpdated(address indexed newOracle)
func (_WDLTemplate *WDLTemplateFilterer) FilterResultOracleUpdated(opts *bind.FilterOpts, newOracle []common.Address) (*WDLTemplateResultOracleUpdatedIterator, error) {

	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "ResultOracleUpdated", newOracleRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateResultOracleUpdatedIterator{contract: _WDLTemplate.contract, event: "ResultOracleUpdated", logs: logs, sub: sub}, nil
}

// WatchResultOracleUpdated is a free log subscription operation binding the contract event 0xf4f6d8a1c53b96aaa54cac2192218b21030f6371f0b3e3a0fb15124fa1f08e8d.
//
// Solidity: event ResultOracleUpdated(address indexed newOracle)
func (_WDLTemplate *WDLTemplateFilterer) WatchResultOracleUpdated(opts *bind.WatchOpts, sink chan<- *WDLTemplateResultOracleUpdated, newOracle []common.Address) (event.Subscription, error) {

	var newOracleRule []interface{}
	for _, newOracleItem := range newOracle {
		newOracleRule = append(newOracleRule, newOracleItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "ResultOracleUpdated", newOracleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateResultOracleUpdated)
				if err := _WDLTemplate.contract.UnpackLog(event, "ResultOracleUpdated", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseResultOracleUpdated(log types.Log) (*WDLTemplateResultOracleUpdated, error) {
	event := new(WDLTemplateResultOracleUpdated)
	if err := _WDLTemplate.contract.UnpackLog(event, "ResultOracleUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateTransferBatchIterator is returned from FilterTransferBatch and is used to iterate over the raw logs and unpacked data for TransferBatch events raised by the WDLTemplate contract.
type WDLTemplateTransferBatchIterator struct {
	Event *WDLTemplateTransferBatch // Event containing the contract specifics and raw log

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
func (it *WDLTemplateTransferBatchIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateTransferBatch)
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
		it.Event = new(WDLTemplateTransferBatch)
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
func (it *WDLTemplateTransferBatchIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateTransferBatchIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateTransferBatch represents a TransferBatch event raised by the WDLTemplate contract.
type WDLTemplateTransferBatch struct {
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
func (_WDLTemplate *WDLTemplateFilterer) FilterTransferBatch(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*WDLTemplateTransferBatchIterator, error) {

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

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateTransferBatchIterator{contract: _WDLTemplate.contract, event: "TransferBatch", logs: logs, sub: sub}, nil
}

// WatchTransferBatch is a free log subscription operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_WDLTemplate *WDLTemplateFilterer) WatchTransferBatch(opts *bind.WatchOpts, sink chan<- *WDLTemplateTransferBatch, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateTransferBatch)
				if err := _WDLTemplate.contract.UnpackLog(event, "TransferBatch", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseTransferBatch(log types.Log) (*WDLTemplateTransferBatch, error) {
	event := new(WDLTemplateTransferBatch)
	if err := _WDLTemplate.contract.UnpackLog(event, "TransferBatch", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateTransferSingleIterator is returned from FilterTransferSingle and is used to iterate over the raw logs and unpacked data for TransferSingle events raised by the WDLTemplate contract.
type WDLTemplateTransferSingleIterator struct {
	Event *WDLTemplateTransferSingle // Event containing the contract specifics and raw log

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
func (it *WDLTemplateTransferSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateTransferSingle)
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
		it.Event = new(WDLTemplateTransferSingle)
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
func (it *WDLTemplateTransferSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateTransferSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateTransferSingle represents a TransferSingle event raised by the WDLTemplate contract.
type WDLTemplateTransferSingle struct {
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
func (_WDLTemplate *WDLTemplateFilterer) FilterTransferSingle(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*WDLTemplateTransferSingleIterator, error) {

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

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateTransferSingleIterator{contract: _WDLTemplate.contract, event: "TransferSingle", logs: logs, sub: sub}, nil
}

// WatchTransferSingle is a free log subscription operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_WDLTemplate *WDLTemplateFilterer) WatchTransferSingle(opts *bind.WatchOpts, sink chan<- *WDLTemplateTransferSingle, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateTransferSingle)
				if err := _WDLTemplate.contract.UnpackLog(event, "TransferSingle", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseTransferSingle(log types.Log) (*WDLTemplateTransferSingle, error) {
	event := new(WDLTemplateTransferSingle)
	if err := _WDLTemplate.contract.UnpackLog(event, "TransferSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateURIIterator is returned from FilterURI and is used to iterate over the raw logs and unpacked data for URI events raised by the WDLTemplate contract.
type WDLTemplateURIIterator struct {
	Event *WDLTemplateURI // Event containing the contract specifics and raw log

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
func (it *WDLTemplateURIIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateURI)
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
		it.Event = new(WDLTemplateURI)
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
func (it *WDLTemplateURIIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateURIIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateURI represents a URI event raised by the WDLTemplate contract.
type WDLTemplateURI struct {
	Value string
	Id    *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterURI is a free log retrieval operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_WDLTemplate *WDLTemplateFilterer) FilterURI(opts *bind.FilterOpts, id []*big.Int) (*WDLTemplateURIIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return &WDLTemplateURIIterator{contract: _WDLTemplate.contract, event: "URI", logs: logs, sub: sub}, nil
}

// WatchURI is a free log subscription operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_WDLTemplate *WDLTemplateFilterer) WatchURI(opts *bind.WatchOpts, sink chan<- *WDLTemplateURI, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateURI)
				if err := _WDLTemplate.contract.UnpackLog(event, "URI", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseURI(log types.Log) (*WDLTemplateURI, error) {
	event := new(WDLTemplateURI)
	if err := _WDLTemplate.contract.UnpackLog(event, "URI", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// WDLTemplateUnpausedIterator is returned from FilterUnpaused and is used to iterate over the raw logs and unpacked data for Unpaused events raised by the WDLTemplate contract.
type WDLTemplateUnpausedIterator struct {
	Event *WDLTemplateUnpaused // Event containing the contract specifics and raw log

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
func (it *WDLTemplateUnpausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(WDLTemplateUnpaused)
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
		it.Event = new(WDLTemplateUnpaused)
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
func (it *WDLTemplateUnpausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *WDLTemplateUnpausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// WDLTemplateUnpaused represents a Unpaused event raised by the WDLTemplate contract.
type WDLTemplateUnpaused struct {
	Account common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterUnpaused is a free log retrieval operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_WDLTemplate *WDLTemplateFilterer) FilterUnpaused(opts *bind.FilterOpts) (*WDLTemplateUnpausedIterator, error) {

	logs, sub, err := _WDLTemplate.contract.FilterLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return &WDLTemplateUnpausedIterator{contract: _WDLTemplate.contract, event: "Unpaused", logs: logs, sub: sub}, nil
}

// WatchUnpaused is a free log subscription operation binding the contract event 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa.
//
// Solidity: event Unpaused(address account)
func (_WDLTemplate *WDLTemplateFilterer) WatchUnpaused(opts *bind.WatchOpts, sink chan<- *WDLTemplateUnpaused) (event.Subscription, error) {

	logs, sub, err := _WDLTemplate.contract.WatchLogs(opts, "Unpaused")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(WDLTemplateUnpaused)
				if err := _WDLTemplate.contract.UnpackLog(event, "Unpaused", log); err != nil {
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
func (_WDLTemplate *WDLTemplateFilterer) ParseUnpaused(log types.Log) (*WDLTemplateUnpaused, error) {
	event := new(WDLTemplateUnpaused)
	if err := _WDLTemplate.contract.UnpackLog(event, "Unpaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
