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

// IResultOracleMatchFacts is an auto generated low-level Go binding around an user-defined struct.
type IResultOracleMatchFacts struct {
	Scope         [32]byte
	HomeGoals     uint8
	AwayGoals     uint8
	ExtraTime     bool
	PenaltiesHome uint8
	PenaltiesAway uint8
	ReportedAt    *big.Int
}

// MockOracleMetaData contains all meta data concerning the MockOracle contract.
var MockOracleMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"initialOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchProposeResults\",\"inputs\":[{\"name\":\"marketIds\",\"type\":\"bytes32[]\",\"internalType\":\"bytes32[]\"},{\"name\":\"factsArray\",\"type\":\"tuple[]\",\"internalType\":\"structIResultOracle.MatchFacts[]\",\"components\":[{\"name\":\"scope\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"homeGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"awayGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"extraTime\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"penaltiesHome\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"penaltiesAway\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"reportedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getResult\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"facts\",\"type\":\"tuple\",\"internalType\":\"structIResultOracle.MatchFacts\",\"components\":[{\"name\":\"scope\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"homeGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"awayGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"extraTime\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"penaltiesHome\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"penaltiesAway\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"reportedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"finalized\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getResultHash\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isFinalized\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proposeResult\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"facts\",\"type\":\"tuple\",\"internalType\":\"structIResultOracle.MatchFacts\",\"components\":[{\"name\":\"scope\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"homeGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"awayGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"extraTime\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"penaltiesHome\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"penaltiesAway\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"reportedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResultDisputed\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"factsHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"disputer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResultFinalized\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"factsHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"accepted\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResultProposed\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"facts\",\"type\":\"tuple\",\"indexed\":false,\"internalType\":\"structIResultOracle.MatchFacts\",\"components\":[{\"name\":\"scope\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"homeGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"awayGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"extraTime\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"penaltiesHome\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"penaltiesAway\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"reportedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"factsHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"proposer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"InvalidMatchFacts\",\"inputs\":[{\"name\":\"reason\",\"type\":\"string\",\"internalType\":\"string\"}]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ResultAlreadySubmitted\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"ResultNotFound\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]}]",
	Bin: "0x6080604052348015600e575f5ffd5b50604051610d70380380610d70833981016040819052602b9160b4565b806001600160a01b038116605857604051631e4fbdf760e01b81525f600482015260240160405180910390fd5b605f816065565b505060df565b5f80546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b5f6020828403121560c3575f5ffd5b81516001600160a01b038116811460d8575f5ffd5b9392505050565b610c84806100ec5f395ff3fe608060405234801561000f575f5ffd5b5060043610610085575f3560e01c80638da5cb5b116100585780638da5cb5b1461010a578063add4c78414610124578063c861161d14610145578063f2fde38b14610158575f5ffd5b80632ebcdb6e14610089578063495b77ec146100bb578063715018a6146100d05780637f8d429e146100d8575b5f5ffd5b6100a86100973660046108a2565b5f9081526003602052604090205490565b6040519081526020015b60405180910390f35b6100ce6100c9366004610901565b61016b565b005b6100ce61032b565b6100fa6100e63660046108a2565b5f9081526002602052604090205460ff1690565b60405190151581526020016100b2565b5f546040516001600160a01b0390911681526020016100b2565b6101376101323660046108a2565b61033e565b6040516100b292919061099c565b6100ce610153366004610a07565b61041f565b6100ce610166366004610a3d565b610546565b610173610583565b8281146101ba576040516303e2aef960e11b815260206004820152600f60248201526e098cadccee8d040dad2e6dac2e8c6d608b1b60448201526064015b60405180910390fd5b5f5b83811015610324575f8585838181106101d7576101d7610a63565b905060200201359050368484848181106101f3576101f3610a63565b5f8581526002602052604090205460e09091029290920192505060ff1615610231576040516348b32fb560e11b8152600481018390526024016101b1565b61023a816105af565b5f82815260016020526040902081906102538282610ab0565b50505f828152600260209081526040808320805460ff191660011790555161027d91849101610b97565b60408051601f1981840301815282825280516020918201205f878152600390925291902081905591503390829085907ff6cf8272543abecfdb5f9b23c9b35840bbfe239e36ff0294be5c9a989fb2e089906102d9908790610b97565b60405180910390a460405160018152819084907f4cb34067cc782b93372b2df0b774e841095666c2ec113563e41bc894b1bd836f9060200160405180910390a35050506001016101bc565b5050505050565b610333610583565b61033c5f610853565b565b6040805160e0810182525f80825260208201819052918101829052606081018290526080810182905260a0810182905260c08101919091525f8281526002602052604081205460ff166103a7576040516372fceee960e01b8152600481018490526024016101b1565b50505f90815260016020818152604092839020835160e081018552815481528184015460ff808216948301949094526101008104841695820195909552620100008504831615156060820152630100000085048316608082015264010000000090940490911660a08401526002015460c08301529091565b610427610583565b5f8281526002602052604090205460ff1615610459576040516348b32fb560e11b8152600481018390526024016101b1565b610462816105af565b5f828152600160205260409020819061047b8282610ab0565b50505f828152600260209081526040808320805460ff19166001179055516104a591849101610b97565b60408051601f1981840301815282825280516020918201205f878152600390925291902081905591503390829085907ff6cf8272543abecfdb5f9b23c9b35840bbfe239e36ff0294be5c9a989fb2e08990610501908790610b97565b60405180910390a460405160018152819084907f4cb34067cc782b93372b2df0b774e841095666c2ec113563e41bc894b1bd836f9060200160405180910390a3505050565b61054e610583565b6001600160a01b03811661057757604051631e4fbdf760e01b81525f60048201526024016101b1565b61058081610853565b50565b5f546001600160a01b0316331461033c5760405163118cdaa760e01b81523360048201526024016101b1565b803564046545f39360dc1b148015906105d25750803565046545f3132360d41b14155b80156105eb575080356850656e616c7469657360b81b14155b15610629576040516303e2aef960e11b815260206004820152600d60248201526c496e76616c69642073636f706560981b60448201526064016101b1565b603261063b6040830160208401610c18565b60ff16118061065c575060326106576060830160408401610c18565b60ff16115b1561069f576040516303e2aef960e11b815260206004820152601260248201527111dbd85b1cc8195e18d95959081b1a5b5a5d60721b60448201526064016101b1565b68af9a919e938b969a8d60b81b81350161078c576106c36080820160608301610c33565b610710576040516303e2aef960e11b815260206004820152601b60248201527f50656e616c74696573207265717569726520657874726154696d65000000000060448201526064016101b1565b61072060a0820160808301610c18565b60ff16158015610740575061073b60c0820160a08301610c18565b60ff16155b15610787576040516303e2aef960e11b815260206004820152601660248201527550656e616c746965732064617461206d697373696e6760501b60448201526064016101b1565b61080b565b61079c60a0820160808301610c18565b60ff161515806107bd57506107b760c0820160a08301610c18565b60ff1615155b1561080b576040516303e2aef960e11b815260206004820152601960248201527f556e65787065637465642070656e616c7469657320646174610000000000000060448201526064016101b1565b428160c001351115610580576040516303e2aef960e11b815260206004820152601060248201526f04675747572652074696d657374616d760841b60448201526064016101b1565b5f80546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b5f602082840312156108b2575f5ffd5b5035919050565b5f5f83601f8401126108c9575f5ffd5b50813567ffffffffffffffff8111156108e0575f5ffd5b60208301915083602060e0830285010111156108fa575f5ffd5b9250929050565b5f5f5f5f60408587031215610914575f5ffd5b843567ffffffffffffffff81111561092a575f5ffd5b8501601f8101871361093a575f5ffd5b803567ffffffffffffffff811115610950575f5ffd5b8760208260051b8401011115610964575f5ffd5b60209182019550935085013567ffffffffffffffff811115610984575f5ffd5b610990878288016108b9565b95989497509550505050565b5f610100820190508351825260ff602085015116602083015260ff604085015116604083015260608401511515606083015260ff608085015116608083015260ff60a08501511660a083015260c084015160c0830152610a0060e083018415159052565b9392505050565b5f5f828403610100811215610a1a575f5ffd5b8335925060e0601f1982011215610a2f575f5ffd5b506020830190509250929050565b5f60208284031215610a4d575f5ffd5b81356001600160a01b0381168114610a00575f5ffd5b634e487b7160e01b5f52603260045260245ffd5b60ff81168114610580575f5ffd5b5f8135610a9181610a77565b92915050565b8015158114610580575f5ffd5b5f8135610a9181610a97565b81358155600181016020830135610ac681610a77565b60ff811660ff19835416178255505f6040840135610ae381610a77565b825461ff00191660089190911b61ff001617825550610b23610b0760608501610aa4565b82805462ff0000191691151560101b62ff000016919091179055565b610b4c610b3260808501610a85565b825463ff000000191660189190911b63ff00000016178255565b610b77610b5b60a08501610a85565b825464ff00000000191660209190911b64ff0000000016178255565b5060c09190910135600290910155565b8035610b9281610a77565b919050565b8135815260e081016020830135610bad81610a77565b60ff1660208301526040830135610bc381610a77565b60ff1660408301526060830135610bd981610a97565b15156060830152610bec60808401610b87565b60ff166080830152610c0060a08401610b87565b60ff811660a08401525060c092830135919092015290565b5f60208284031215610c28575f5ffd5b8135610a0081610a77565b5f60208284031215610c43575f5ffd5b8135610a0081610a9756fea26469706673582212200be8ba19c9ff9463d73e4ecbd179133576fb8894b809c9247684e058dea0c6eb64736f6c634300081e0033",
}

// MockOracleABI is the input ABI used to generate the binding from.
// Deprecated: Use MockOracleMetaData.ABI instead.
var MockOracleABI = MockOracleMetaData.ABI

// MockOracleBin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use MockOracleMetaData.Bin instead.
var MockOracleBin = MockOracleMetaData.Bin

// DeployMockOracle deploys a new Ethereum contract, binding an instance of MockOracle to it.
func DeployMockOracle(auth *bind.TransactOpts, backend bind.ContractBackend, initialOwner common.Address) (common.Address, *types.Transaction, *MockOracle, error) {
	parsed, err := MockOracleMetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(MockOracleBin), backend, initialOwner)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &MockOracle{MockOracleCaller: MockOracleCaller{contract: contract}, MockOracleTransactor: MockOracleTransactor{contract: contract}, MockOracleFilterer: MockOracleFilterer{contract: contract}}, nil
}

// MockOracle is an auto generated Go binding around an Ethereum contract.
type MockOracle struct {
	MockOracleCaller     // Read-only binding to the contract
	MockOracleTransactor // Write-only binding to the contract
	MockOracleFilterer   // Log filterer for contract events
}

// MockOracleCaller is an auto generated read-only Go binding around an Ethereum contract.
type MockOracleCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockOracleTransactor is an auto generated write-only Go binding around an Ethereum contract.
type MockOracleTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockOracleFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type MockOracleFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// MockOracleSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type MockOracleSession struct {
	Contract     *MockOracle       // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// MockOracleCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type MockOracleCallerSession struct {
	Contract *MockOracleCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts     // Call options to use throughout this session
}

// MockOracleTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type MockOracleTransactorSession struct {
	Contract     *MockOracleTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts     // Transaction auth options to use throughout this session
}

// MockOracleRaw is an auto generated low-level Go binding around an Ethereum contract.
type MockOracleRaw struct {
	Contract *MockOracle // Generic contract binding to access the raw methods on
}

// MockOracleCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type MockOracleCallerRaw struct {
	Contract *MockOracleCaller // Generic read-only contract binding to access the raw methods on
}

// MockOracleTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type MockOracleTransactorRaw struct {
	Contract *MockOracleTransactor // Generic write-only contract binding to access the raw methods on
}

// NewMockOracle creates a new instance of MockOracle, bound to a specific deployed contract.
func NewMockOracle(address common.Address, backend bind.ContractBackend) (*MockOracle, error) {
	contract, err := bindMockOracle(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &MockOracle{MockOracleCaller: MockOracleCaller{contract: contract}, MockOracleTransactor: MockOracleTransactor{contract: contract}, MockOracleFilterer: MockOracleFilterer{contract: contract}}, nil
}

// NewMockOracleCaller creates a new read-only instance of MockOracle, bound to a specific deployed contract.
func NewMockOracleCaller(address common.Address, caller bind.ContractCaller) (*MockOracleCaller, error) {
	contract, err := bindMockOracle(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &MockOracleCaller{contract: contract}, nil
}

// NewMockOracleTransactor creates a new write-only instance of MockOracle, bound to a specific deployed contract.
func NewMockOracleTransactor(address common.Address, transactor bind.ContractTransactor) (*MockOracleTransactor, error) {
	contract, err := bindMockOracle(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &MockOracleTransactor{contract: contract}, nil
}

// NewMockOracleFilterer creates a new log filterer instance of MockOracle, bound to a specific deployed contract.
func NewMockOracleFilterer(address common.Address, filterer bind.ContractFilterer) (*MockOracleFilterer, error) {
	contract, err := bindMockOracle(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &MockOracleFilterer{contract: contract}, nil
}

// bindMockOracle binds a generic wrapper to an already deployed contract.
func bindMockOracle(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := MockOracleMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockOracle *MockOracleRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockOracle.Contract.MockOracleCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockOracle *MockOracleRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockOracle.Contract.MockOracleTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockOracle *MockOracleRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockOracle.Contract.MockOracleTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_MockOracle *MockOracleCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _MockOracle.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_MockOracle *MockOracleTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockOracle.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_MockOracle *MockOracleTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _MockOracle.Contract.contract.Transact(opts, method, params...)
}

// GetResult is a free data retrieval call binding the contract method 0xadd4c784.
//
// Solidity: function getResult(bytes32 marketId) view returns((bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, bool finalized)
func (_MockOracle *MockOracleCaller) GetResult(opts *bind.CallOpts, marketId [32]byte) (struct {
	Facts     IResultOracleMatchFacts
	Finalized bool
}, error) {
	var out []interface{}
	err := _MockOracle.contract.Call(opts, &out, "getResult", marketId)

	outstruct := new(struct {
		Facts     IResultOracleMatchFacts
		Finalized bool
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Facts = *abi.ConvertType(out[0], new(IResultOracleMatchFacts)).(*IResultOracleMatchFacts)
	outstruct.Finalized = *abi.ConvertType(out[1], new(bool)).(*bool)

	return *outstruct, err

}

// GetResult is a free data retrieval call binding the contract method 0xadd4c784.
//
// Solidity: function getResult(bytes32 marketId) view returns((bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, bool finalized)
func (_MockOracle *MockOracleSession) GetResult(marketId [32]byte) (struct {
	Facts     IResultOracleMatchFacts
	Finalized bool
}, error) {
	return _MockOracle.Contract.GetResult(&_MockOracle.CallOpts, marketId)
}

// GetResult is a free data retrieval call binding the contract method 0xadd4c784.
//
// Solidity: function getResult(bytes32 marketId) view returns((bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, bool finalized)
func (_MockOracle *MockOracleCallerSession) GetResult(marketId [32]byte) (struct {
	Facts     IResultOracleMatchFacts
	Finalized bool
}, error) {
	return _MockOracle.Contract.GetResult(&_MockOracle.CallOpts, marketId)
}

// GetResultHash is a free data retrieval call binding the contract method 0x2ebcdb6e.
//
// Solidity: function getResultHash(bytes32 marketId) view returns(bytes32)
func (_MockOracle *MockOracleCaller) GetResultHash(opts *bind.CallOpts, marketId [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _MockOracle.contract.Call(opts, &out, "getResultHash", marketId)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetResultHash is a free data retrieval call binding the contract method 0x2ebcdb6e.
//
// Solidity: function getResultHash(bytes32 marketId) view returns(bytes32)
func (_MockOracle *MockOracleSession) GetResultHash(marketId [32]byte) ([32]byte, error) {
	return _MockOracle.Contract.GetResultHash(&_MockOracle.CallOpts, marketId)
}

// GetResultHash is a free data retrieval call binding the contract method 0x2ebcdb6e.
//
// Solidity: function getResultHash(bytes32 marketId) view returns(bytes32)
func (_MockOracle *MockOracleCallerSession) GetResultHash(marketId [32]byte) ([32]byte, error) {
	return _MockOracle.Contract.GetResultHash(&_MockOracle.CallOpts, marketId)
}

// IsFinalized is a free data retrieval call binding the contract method 0x7f8d429e.
//
// Solidity: function isFinalized(bytes32 marketId) view returns(bool)
func (_MockOracle *MockOracleCaller) IsFinalized(opts *bind.CallOpts, marketId [32]byte) (bool, error) {
	var out []interface{}
	err := _MockOracle.contract.Call(opts, &out, "isFinalized", marketId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsFinalized is a free data retrieval call binding the contract method 0x7f8d429e.
//
// Solidity: function isFinalized(bytes32 marketId) view returns(bool)
func (_MockOracle *MockOracleSession) IsFinalized(marketId [32]byte) (bool, error) {
	return _MockOracle.Contract.IsFinalized(&_MockOracle.CallOpts, marketId)
}

// IsFinalized is a free data retrieval call binding the contract method 0x7f8d429e.
//
// Solidity: function isFinalized(bytes32 marketId) view returns(bool)
func (_MockOracle *MockOracleCallerSession) IsFinalized(marketId [32]byte) (bool, error) {
	return _MockOracle.Contract.IsFinalized(&_MockOracle.CallOpts, marketId)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MockOracle *MockOracleCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _MockOracle.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MockOracle *MockOracleSession) Owner() (common.Address, error) {
	return _MockOracle.Contract.Owner(&_MockOracle.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_MockOracle *MockOracleCallerSession) Owner() (common.Address, error) {
	return _MockOracle.Contract.Owner(&_MockOracle.CallOpts)
}

// BatchProposeResults is a paid mutator transaction binding the contract method 0x495b77ec.
//
// Solidity: function batchProposeResults(bytes32[] marketIds, (bytes32,uint8,uint8,bool,uint8,uint8,uint256)[] factsArray) returns()
func (_MockOracle *MockOracleTransactor) BatchProposeResults(opts *bind.TransactOpts, marketIds [][32]byte, factsArray []IResultOracleMatchFacts) (*types.Transaction, error) {
	return _MockOracle.contract.Transact(opts, "batchProposeResults", marketIds, factsArray)
}

// BatchProposeResults is a paid mutator transaction binding the contract method 0x495b77ec.
//
// Solidity: function batchProposeResults(bytes32[] marketIds, (bytes32,uint8,uint8,bool,uint8,uint8,uint256)[] factsArray) returns()
func (_MockOracle *MockOracleSession) BatchProposeResults(marketIds [][32]byte, factsArray []IResultOracleMatchFacts) (*types.Transaction, error) {
	return _MockOracle.Contract.BatchProposeResults(&_MockOracle.TransactOpts, marketIds, factsArray)
}

// BatchProposeResults is a paid mutator transaction binding the contract method 0x495b77ec.
//
// Solidity: function batchProposeResults(bytes32[] marketIds, (bytes32,uint8,uint8,bool,uint8,uint8,uint256)[] factsArray) returns()
func (_MockOracle *MockOracleTransactorSession) BatchProposeResults(marketIds [][32]byte, factsArray []IResultOracleMatchFacts) (*types.Transaction, error) {
	return _MockOracle.Contract.BatchProposeResults(&_MockOracle.TransactOpts, marketIds, factsArray)
}

// ProposeResult is a paid mutator transaction binding the contract method 0xc861161d.
//
// Solidity: function proposeResult(bytes32 marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts) returns()
func (_MockOracle *MockOracleTransactor) ProposeResult(opts *bind.TransactOpts, marketId [32]byte, facts IResultOracleMatchFacts) (*types.Transaction, error) {
	return _MockOracle.contract.Transact(opts, "proposeResult", marketId, facts)
}

// ProposeResult is a paid mutator transaction binding the contract method 0xc861161d.
//
// Solidity: function proposeResult(bytes32 marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts) returns()
func (_MockOracle *MockOracleSession) ProposeResult(marketId [32]byte, facts IResultOracleMatchFacts) (*types.Transaction, error) {
	return _MockOracle.Contract.ProposeResult(&_MockOracle.TransactOpts, marketId, facts)
}

// ProposeResult is a paid mutator transaction binding the contract method 0xc861161d.
//
// Solidity: function proposeResult(bytes32 marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts) returns()
func (_MockOracle *MockOracleTransactorSession) ProposeResult(marketId [32]byte, facts IResultOracleMatchFacts) (*types.Transaction, error) {
	return _MockOracle.Contract.ProposeResult(&_MockOracle.TransactOpts, marketId, facts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_MockOracle *MockOracleTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _MockOracle.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_MockOracle *MockOracleSession) RenounceOwnership() (*types.Transaction, error) {
	return _MockOracle.Contract.RenounceOwnership(&_MockOracle.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_MockOracle *MockOracleTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _MockOracle.Contract.RenounceOwnership(&_MockOracle.TransactOpts)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MockOracle *MockOracleTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _MockOracle.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MockOracle *MockOracleSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _MockOracle.Contract.TransferOwnership(&_MockOracle.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_MockOracle *MockOracleTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _MockOracle.Contract.TransferOwnership(&_MockOracle.TransactOpts, newOwner)
}

// MockOracleOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the MockOracle contract.
type MockOracleOwnershipTransferredIterator struct {
	Event *MockOracleOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *MockOracleOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockOracleOwnershipTransferred)
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
		it.Event = new(MockOracleOwnershipTransferred)
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
func (it *MockOracleOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockOracleOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockOracleOwnershipTransferred represents a OwnershipTransferred event raised by the MockOracle contract.
type MockOracleOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_MockOracle *MockOracleFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*MockOracleOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _MockOracle.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &MockOracleOwnershipTransferredIterator{contract: _MockOracle.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_MockOracle *MockOracleFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *MockOracleOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _MockOracle.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockOracleOwnershipTransferred)
				if err := _MockOracle.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_MockOracle *MockOracleFilterer) ParseOwnershipTransferred(log types.Log) (*MockOracleOwnershipTransferred, error) {
	event := new(MockOracleOwnershipTransferred)
	if err := _MockOracle.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockOracleResultDisputedIterator is returned from FilterResultDisputed and is used to iterate over the raw logs and unpacked data for ResultDisputed events raised by the MockOracle contract.
type MockOracleResultDisputedIterator struct {
	Event *MockOracleResultDisputed // Event containing the contract specifics and raw log

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
func (it *MockOracleResultDisputedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockOracleResultDisputed)
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
		it.Event = new(MockOracleResultDisputed)
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
func (it *MockOracleResultDisputedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockOracleResultDisputedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockOracleResultDisputed represents a ResultDisputed event raised by the MockOracle contract.
type MockOracleResultDisputed struct {
	MarketId  [32]byte
	FactsHash [32]byte
	Disputer  common.Address
	Reason    string
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterResultDisputed is a free log retrieval operation binding the contract event 0xbbbeedae39b2d17885fef07ce783ed99615993552c345e864913d87403656502.
//
// Solidity: event ResultDisputed(bytes32 indexed marketId, bytes32 indexed factsHash, address indexed disputer, string reason)
func (_MockOracle *MockOracleFilterer) FilterResultDisputed(opts *bind.FilterOpts, marketId [][32]byte, factsHash [][32]byte, disputer []common.Address) (*MockOracleResultDisputedIterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var factsHashRule []interface{}
	for _, factsHashItem := range factsHash {
		factsHashRule = append(factsHashRule, factsHashItem)
	}
	var disputerRule []interface{}
	for _, disputerItem := range disputer {
		disputerRule = append(disputerRule, disputerItem)
	}

	logs, sub, err := _MockOracle.contract.FilterLogs(opts, "ResultDisputed", marketIdRule, factsHashRule, disputerRule)
	if err != nil {
		return nil, err
	}
	return &MockOracleResultDisputedIterator{contract: _MockOracle.contract, event: "ResultDisputed", logs: logs, sub: sub}, nil
}

// WatchResultDisputed is a free log subscription operation binding the contract event 0xbbbeedae39b2d17885fef07ce783ed99615993552c345e864913d87403656502.
//
// Solidity: event ResultDisputed(bytes32 indexed marketId, bytes32 indexed factsHash, address indexed disputer, string reason)
func (_MockOracle *MockOracleFilterer) WatchResultDisputed(opts *bind.WatchOpts, sink chan<- *MockOracleResultDisputed, marketId [][32]byte, factsHash [][32]byte, disputer []common.Address) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var factsHashRule []interface{}
	for _, factsHashItem := range factsHash {
		factsHashRule = append(factsHashRule, factsHashItem)
	}
	var disputerRule []interface{}
	for _, disputerItem := range disputer {
		disputerRule = append(disputerRule, disputerItem)
	}

	logs, sub, err := _MockOracle.contract.WatchLogs(opts, "ResultDisputed", marketIdRule, factsHashRule, disputerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockOracleResultDisputed)
				if err := _MockOracle.contract.UnpackLog(event, "ResultDisputed", log); err != nil {
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

// ParseResultDisputed is a log parse operation binding the contract event 0xbbbeedae39b2d17885fef07ce783ed99615993552c345e864913d87403656502.
//
// Solidity: event ResultDisputed(bytes32 indexed marketId, bytes32 indexed factsHash, address indexed disputer, string reason)
func (_MockOracle *MockOracleFilterer) ParseResultDisputed(log types.Log) (*MockOracleResultDisputed, error) {
	event := new(MockOracleResultDisputed)
	if err := _MockOracle.contract.UnpackLog(event, "ResultDisputed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockOracleResultFinalizedIterator is returned from FilterResultFinalized and is used to iterate over the raw logs and unpacked data for ResultFinalized events raised by the MockOracle contract.
type MockOracleResultFinalizedIterator struct {
	Event *MockOracleResultFinalized // Event containing the contract specifics and raw log

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
func (it *MockOracleResultFinalizedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockOracleResultFinalized)
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
		it.Event = new(MockOracleResultFinalized)
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
func (it *MockOracleResultFinalizedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockOracleResultFinalizedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockOracleResultFinalized represents a ResultFinalized event raised by the MockOracle contract.
type MockOracleResultFinalized struct {
	MarketId  [32]byte
	FactsHash [32]byte
	Accepted  bool
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterResultFinalized is a free log retrieval operation binding the contract event 0x4cb34067cc782b93372b2df0b774e841095666c2ec113563e41bc894b1bd836f.
//
// Solidity: event ResultFinalized(bytes32 indexed marketId, bytes32 indexed factsHash, bool accepted)
func (_MockOracle *MockOracleFilterer) FilterResultFinalized(opts *bind.FilterOpts, marketId [][32]byte, factsHash [][32]byte) (*MockOracleResultFinalizedIterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var factsHashRule []interface{}
	for _, factsHashItem := range factsHash {
		factsHashRule = append(factsHashRule, factsHashItem)
	}

	logs, sub, err := _MockOracle.contract.FilterLogs(opts, "ResultFinalized", marketIdRule, factsHashRule)
	if err != nil {
		return nil, err
	}
	return &MockOracleResultFinalizedIterator{contract: _MockOracle.contract, event: "ResultFinalized", logs: logs, sub: sub}, nil
}

// WatchResultFinalized is a free log subscription operation binding the contract event 0x4cb34067cc782b93372b2df0b774e841095666c2ec113563e41bc894b1bd836f.
//
// Solidity: event ResultFinalized(bytes32 indexed marketId, bytes32 indexed factsHash, bool accepted)
func (_MockOracle *MockOracleFilterer) WatchResultFinalized(opts *bind.WatchOpts, sink chan<- *MockOracleResultFinalized, marketId [][32]byte, factsHash [][32]byte) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var factsHashRule []interface{}
	for _, factsHashItem := range factsHash {
		factsHashRule = append(factsHashRule, factsHashItem)
	}

	logs, sub, err := _MockOracle.contract.WatchLogs(opts, "ResultFinalized", marketIdRule, factsHashRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockOracleResultFinalized)
				if err := _MockOracle.contract.UnpackLog(event, "ResultFinalized", log); err != nil {
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

// ParseResultFinalized is a log parse operation binding the contract event 0x4cb34067cc782b93372b2df0b774e841095666c2ec113563e41bc894b1bd836f.
//
// Solidity: event ResultFinalized(bytes32 indexed marketId, bytes32 indexed factsHash, bool accepted)
func (_MockOracle *MockOracleFilterer) ParseResultFinalized(log types.Log) (*MockOracleResultFinalized, error) {
	event := new(MockOracleResultFinalized)
	if err := _MockOracle.contract.UnpackLog(event, "ResultFinalized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// MockOracleResultProposedIterator is returned from FilterResultProposed and is used to iterate over the raw logs and unpacked data for ResultProposed events raised by the MockOracle contract.
type MockOracleResultProposedIterator struct {
	Event *MockOracleResultProposed // Event containing the contract specifics and raw log

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
func (it *MockOracleResultProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(MockOracleResultProposed)
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
		it.Event = new(MockOracleResultProposed)
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
func (it *MockOracleResultProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *MockOracleResultProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// MockOracleResultProposed represents a ResultProposed event raised by the MockOracle contract.
type MockOracleResultProposed struct {
	MarketId  [32]byte
	Facts     IResultOracleMatchFacts
	FactsHash [32]byte
	Proposer  common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterResultProposed is a free log retrieval operation binding the contract event 0xf6cf8272543abecfdb5f9b23c9b35840bbfe239e36ff0294be5c9a989fb2e089.
//
// Solidity: event ResultProposed(bytes32 indexed marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, bytes32 indexed factsHash, address indexed proposer)
func (_MockOracle *MockOracleFilterer) FilterResultProposed(opts *bind.FilterOpts, marketId [][32]byte, factsHash [][32]byte, proposer []common.Address) (*MockOracleResultProposedIterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	var factsHashRule []interface{}
	for _, factsHashItem := range factsHash {
		factsHashRule = append(factsHashRule, factsHashItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _MockOracle.contract.FilterLogs(opts, "ResultProposed", marketIdRule, factsHashRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return &MockOracleResultProposedIterator{contract: _MockOracle.contract, event: "ResultProposed", logs: logs, sub: sub}, nil
}

// WatchResultProposed is a free log subscription operation binding the contract event 0xf6cf8272543abecfdb5f9b23c9b35840bbfe239e36ff0294be5c9a989fb2e089.
//
// Solidity: event ResultProposed(bytes32 indexed marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, bytes32 indexed factsHash, address indexed proposer)
func (_MockOracle *MockOracleFilterer) WatchResultProposed(opts *bind.WatchOpts, sink chan<- *MockOracleResultProposed, marketId [][32]byte, factsHash [][32]byte, proposer []common.Address) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}

	var factsHashRule []interface{}
	for _, factsHashItem := range factsHash {
		factsHashRule = append(factsHashRule, factsHashItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _MockOracle.contract.WatchLogs(opts, "ResultProposed", marketIdRule, factsHashRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(MockOracleResultProposed)
				if err := _MockOracle.contract.UnpackLog(event, "ResultProposed", log); err != nil {
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

// ParseResultProposed is a log parse operation binding the contract event 0xf6cf8272543abecfdb5f9b23c9b35840bbfe239e36ff0294be5c9a989fb2e089.
//
// Solidity: event ResultProposed(bytes32 indexed marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, bytes32 indexed factsHash, address indexed proposer)
func (_MockOracle *MockOracleFilterer) ParseResultProposed(log types.Log) (*MockOracleResultProposed, error) {
	event := new(MockOracleResultProposed)
	if err := _MockOracle.contract.UnpackLog(event, "ResultProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
