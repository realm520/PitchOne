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

// IOptimisticOracleV3Assertion is an auto generated low-level Go binding around an user-defined struct.
type IOptimisticOracleV3Assertion struct {
	Resolved             bool
	Disputed             bool
	SettlementResolution bool
	Asserter             common.Address
	Disputer             common.Address
	CallbackRecipient    common.Address
	Currency             common.Address
	ExpirationTime       uint64
	Bond                 *big.Int
	Identifier           [32]byte
	DomainId             [32]byte
}

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

// UMAAdapterMetaData contains all meta data concerning the UMAAdapter contract.
var UMAAdapterMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_optimisticOracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_bondCurrency\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"_bondAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_liveness\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"_identifier\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"initialOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"assertionMarkets\",\"inputs\":[{\"name\":\"assertionId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"bondAmount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"bondCurrency\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIERC20\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"canSettle\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"disputeAssertion\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"reason\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"emergencyWithdraw\",\"inputs\":[{\"name\":\"recipient\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getAssertionDetails\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structIOptimisticOracleV3.Assertion\",\"components\":[{\"name\":\"resolved\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"disputed\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"settlementResolution\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"asserter\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"disputer\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"callbackRecipient\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"currency\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"expirationTime\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"bond\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"identifier\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"domainId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getResult\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"facts\",\"type\":\"tuple\",\"internalType\":\"structIResultOracle.MatchFacts\",\"components\":[{\"name\":\"scope\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"homeGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"awayGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"extraTime\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"penaltiesHome\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"penaltiesAway\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"reportedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"finalized\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getResultHash\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"identifier\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isFinalized\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"liveness\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"marketAssertions\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"assertionId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"optimisticOracle\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractIOptimisticOracleV3\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proposeResult\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"facts\",\"type\":\"tuple\",\"internalType\":\"structIResultOracle.MatchFacts\",\"components\":[{\"name\":\"scope\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"homeGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"awayGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"extraTime\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"penaltiesHome\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"penaltiesAway\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"reportedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceOwnership\",\"inputs\":[],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"settleAssertion\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"AssertionCreated\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"assertionId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"proposer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"facts\",\"type\":\"tuple\",\"indexed\":false,\"internalType\":\"structIResultOracle.MatchFacts\",\"components\":[{\"name\":\"scope\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"homeGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"awayGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"extraTime\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"penaltiesHome\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"penaltiesAway\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"reportedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"bondAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"AssertionSettledSuccessfully\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"assertionId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"accepted\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResultDisputed\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"factsHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"disputer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"reason\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResultFinalized\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"factsHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"accepted\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ResultProposed\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"facts\",\"type\":\"tuple\",\"indexed\":false,\"internalType\":\"structIResultOracle.MatchFacts\",\"components\":[{\"name\":\"scope\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"homeGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"awayGoals\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"extraTime\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"penaltiesHome\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"penaltiesAway\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"reportedAt\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"factsHash\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"proposer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AssertionAlreadyExists\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"assertionId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"AssertionNotSettled\",\"inputs\":[{\"name\":\"assertionId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"InsufficientBondAllowance\",\"inputs\":[{\"name\":\"required\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"current\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"InvalidMatchFacts\",\"inputs\":[{\"name\":\"reason\",\"type\":\"string\",\"internalType\":\"string\"}]},{\"type\":\"error\",\"name\":\"NoAssertionFound\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"OwnableInvalidOwner\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"OwnableUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ResultNotFinalized\",\"inputs\":[{\"name\":\"marketId\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]}]",
	Bin: "0x610120604052348015610010575f5ffd5b506040516121b43803806121b483398101604081905261002f91610243565b806001600160a01b03811661005e57604051631e4fbdf760e01b81525f60048201526024015b60405180910390fd5b610067816101d9565b506001600160a01b0386166100bf576040516303e2aef960e11b815260206004820152601360248201527f5a65726f206f7261636c652061646472657373000000000000000000000000006044820152606401610055565b6001600160a01b038516610116576040516303e2aef960e11b815260206004820152601560248201527f5a65726f2063757272656e6379206164647265737300000000000000000000006044820152606401610055565b835f03610159576040516303e2aef960e11b815260206004820152601060248201526f16995c9bc8189bdb9908185b5bdd5b9d60821b6044820152606401610055565b603c836001600160401b031610156101a9576040516303e2aef960e11b8152602060048201526012602482015271131a5d995b995cdcc81d1bdbc81cda1bdc9d60721b6044820152606401610055565b506001600160a01b039485166080529290931660a05260c0526001600160401b0390911660e052610100526102b4565b5f80546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b80516001600160a01b038116811461023e575f5ffd5b919050565b5f5f5f5f5f5f60c08789031215610258575f5ffd5b61026187610228565b955061026f60208801610228565b6040880151606089015191965094506001600160401b0381168114610292575f5ffd5b608088015190935091506102a860a08801610228565b90509295509295509295565b60805160a05160c05160e05161010051611e2961038b5f395f8181610241015261119301525f81816101f9015261112d01525f818161028b015281816109570152818161098c015281816110550152818161108a0152818161117101526112c901525f8181610125015281816108e801528181610bb501528181610fe6015261114f01525f81816101690152818161045d015281816104f2015281816107f9015281816108be015281816109db01528181610b2501528181610c1301528181610dd101528181610fbc01526110f80152611e295ff3fe608060405234801561000f575f5ffd5b506004361061011c575f3560e01c80637f8d429e116100a9578063add4c7841161006e578063add4c784146102e3578063c65ac2b514610304578063c861161d14610323578063e1f2274f14610336578063f2fde38b14610355575f5ffd5b80637f8d429e1461026357806380f323a7146102865780638da5cb5b146102ad57806395ccea67146102bd578063ad379089146102d0575f5ffd5b806355da5539116100ef57806355da5539146101c15780635e309398146101e15780636ad0690a146101f4578063715018a6146102345780637998a1c41461023c575f5ffd5b80630484d5421461012057806322302922146101645780632ebcdb6e1461018b5780634124beef146101ac575b5f5ffd5b6101477f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b0390911681526020015b60405180910390f35b6101477f000000000000000000000000000000000000000000000000000000000000000081565b61019e61019936600461172a565b610368565b60405190815260200161015b565b6101bf6101ba36600461172a565b610411565b005b6101d46101cf36600461172a565b61075c565b60405161015b9190611741565b6101bf6101ef366004611826565b610872565b61021b7f000000000000000000000000000000000000000000000000000000000000000081565b60405167ffffffffffffffff909116815260200161015b565b6101bf610ac1565b61019e7f000000000000000000000000000000000000000000000000000000000000000081565b61027661027136600461172a565b610ad4565b604051901515815260200161015b565b61019e7f000000000000000000000000000000000000000000000000000000000000000081565b5f546001600160a01b0316610147565b6101bf6102cb3660046118b1565b610ba0565b6102766102de36600461172a565b610be0565b6102f66102f136600461172a565b610cc3565b60405161015b9291906118db565b61019e61031236600461172a565b60016020525f908152604090205481565b6101bf61033136600461193f565b610f50565b61019e61034436600461172a565b60026020525f908152604090205481565b6101bf610363366004611975565b611305565b5f8181526005602052604081205460ff16156103b9575f82815260046020908152604091829020915161039c929101611990565b604051602081830303815290604052805190602001209050919050565b5f828152600160205260409020548015610409575f8381526003602090815260409182902091516103eb929101611990565b60405160208183030381529060405280519060200120915050919050565b505f92915050565b5f8181526001602052604090205480610445576040516362ebfb7360e11b8152600481018390526024015b60405180910390fd5b604051638ea2f2ab60e01b8152600481018290525f907f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031690638ea2f2ab906024016020604051808303815f875af11580156104ab573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906104cf9190611a05565b60405163220c0a2160e21b8152600481018490529091505f906001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169063883028849060240161016060405180830381865afa158015610538573d5f5f3e3d5ffd5b505050506040513d601f19601f8201168201806040525081019061055c9190611a78565b805190915061058157604051633a2e069760e01b81526004810184905260240161043c565b8115610645575f84815260036020908152604080832060049092529091208154815560018083018054918301805460ff19811660ff948516908117835583546101009081900486160261ffff19909216171780825582546201000090819004851615150262ff000019821681178355835463010000009081900486160263ff0000001990911663ffff000019909216919091171780825591546401000000009081900490931690920264ff000000001990911617905560029182015491015561068e565b6040516303e2aef960e11b815260206004820152601d60248201527f417373657274696f6e2072656a65637465642062792064697370757465000000604482015260640161043c565b5f8481526005602052604090819020805460ff1916600117905551839085907fcb510e6fc9c8f5747fd8a66fb2cbe64bdc8ae7da1dee4eb498f0cb97cecade82906106de90861515815260200190565b60405180910390a35f848152600460209081526040918290209151610704929101611990565b60405160208183030381529060405280519060200120847f4cb34067cc782b93372b2df0b774e841095666c2ec113563e41bc894b1bd836f8460405161074e911515815260200190565b60405180910390a350505050565b60408051610160810182525f80825260208201819052918101829052606081018290526080810182905260a0810182905260c0810182905260e08101829052610100810182905261012081018290526101408101919091525f82815260016020526040902054806107e3576040516362ebfb7360e11b81526004810184905260240161043c565b60405163220c0a2160e21b8152600481018290527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169063883028849060240161016060405180830381865afa158015610847573d5f5f3e3d5ffd5b505050506040513d601f19601f8201168201806040525081019061086b9190611a78565b9392505050565b5f83815260016020526040902054806108a1576040516362ebfb7360e11b81526004810185905260240161043c565b604051636eb1769f60e11b81523360048201526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000811660248301525f917f00000000000000000000000000000000000000000000000000000000000000009091169063dd62ed3e90604401602060405180830381865afa15801561092f573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906109539190611b3f565b90507f00000000000000000000000000000000000000000000000000000000000000008110156109bf5760405163572f73d160e01b81527f000000000000000000000000000000000000000000000000000000000000000060048201526024810182905260440161043c565b60405163a6a22b4360e01b8152600481018390523360248201527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169063a6a22b43906044015f604051808303815f87803b158015610a24575f5ffd5b505af1158015610a36573d5f5f3e3d5ffd5b505050505f60035f8781526020019081526020015f20604051602001610a5c9190611990565b604051602081830303815290604052805190602001209050336001600160a01b031681877fbbbeedae39b2d17885fef07ce783ed99615993552c345e864913d874036565028888604051610ab1929190611b56565b60405180910390a4505050505050565b610ac9611342565b610ad25f61136e565b565b5f8181526005602052604081205460ff1615610af257506001919050565b5f8281526001602052604090205480610b0d57505f92915050565b60405163220c0a2160e21b8152600481018290525f907f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169063883028849060240161016060405180830381865afa158015610b73573d5f5f3e3d5ffd5b505050506040513d601f19601f82011682018060405250810190610b979190611a78565b51949350505050565b610ba8611342565b610bdc6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001683836113bd565b5050565b5f8181526001602052604081205480610bfb57505f92915050565b60405163220c0a2160e21b8152600481018290525f907f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169063883028849060240161016060405180830381865afa158015610c61573d5f5f3e3d5ffd5b505050506040513d601f19601f82011682018060405250810190610c859190611a78565b805190915015610c9857505f9392505050565b806020015115610cab57505f9392505050565b60e0015167ffffffffffffffff164210159392505050565b6040805160e0810182525f80825260208201819052918101829052606081018290526080810182905260a0810182905260c08101919091525f8281526005602052604081205460ff1615610d8a5750505f90815260046020908152604091829020825160e0810184528154815260018083015460ff808216958401959095526101008104851695830195909552620100008504841615156060830152630100000085048416608083015264010000000090940490921660a08301526002015460c082015291565b5f8381526001602052604090205480610db9576040516362ebfb7360e11b81526004810185905260240161043c565b60405163220c0a2160e21b8152600481018290525f907f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169063883028849060240161016060405180830381865afa158015610e1f573d5f5f3e3d5ffd5b505050506040513d601f19601f82011682018060405250810190610e439190611a78565b80519091508015610e55575080604001515b15610ed5575050505f9182525060036020908152604091829020825160e0810184528154815260018083015460ff808216958401959095526101008104851695830195909552620100008504841615156060830152630100000085048416608083015264010000000090940490921660a08301526002015460c082015291565b5050505f91825250600360209081526040808320815160e08101835281548152600182015460ff808216958301959095526101008104851693820193909352620100008304841615156060820152630100000083048416608082015264010000000090920490921660a082015260029091015460c082015291565b5f8281526001602052604090205415610f96575f828152600160205260409081902054905163324b1e8760e01b815261043c918491600401918252602082015260400190565b610f9f81611414565b604051636eb1769f60e11b81523360048201526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000811660248301525f917f00000000000000000000000000000000000000000000000000000000000000009091169063dd62ed3e90604401602060405180830381865afa15801561102d573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906110519190611b3f565b90507f00000000000000000000000000000000000000000000000000000000000000008110156110bd5760405163572f73d160e01b81527f000000000000000000000000000000000000000000000000000000000000000060048201526024810182905260440161043c565b5f826040516020016110cf9190611c15565b60408051601f1981840301815290829052636457c97960e01b825291505f906001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001690636457c979906111bd9085903390309087907f0000000000000000000000000000000000000000000000000000000000000000907f0000000000000000000000000000000000000000000000000000000000000000907f0000000000000000000000000000000000000000000000000000000000000000907f0000000000000000000000000000000000000000000000000000000000000000908590600401611c29565b6020604051808303815f875af11580156111d9573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906111fd9190611b3f565b5f868152600160209081526040808320849055838352600282528083208990558883526003909152902090915084906112368282611cca565b5050604051339061124b908690602001611c15565b60405160208183030381529060405280519060200120867ff6cf8272543abecfdb5f9b23c9b35840bbfe239e36ff0294be5c9a989fb2e089876040516112919190611c15565b60405180910390a4336001600160a01b031681867f309face407a5a9f5edcd1ce1ea6fd7167f8a7b48276487f15041106f237bc80a877f00000000000000000000000000000000000000000000000000000000000000006040516112f6929190611da1565b60405180910390a45050505050565b61130d611342565b6001600160a01b03811661133657604051631e4fbdf760e01b81525f600482015260240161043c565b61133f8161136e565b50565b5f546001600160a01b03163314610ad25760405163118cdaa760e01b815233600482015260240161043c565b5f80546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b604080516001600160a01b038416602482015260448082018490528251808303909101815260649091019091526020810180516001600160e01b031663a9059cbb60e01b17905261140f9084906116b8565b505050565b803564046545f39360dc1b148015906114375750803565046545f3132360d41b14155b8015611450575080356850656e616c7469657360b81b14155b1561148e576040516303e2aef960e11b815260206004820152600d60248201526c496e76616c69642073636f706560981b604482015260640161043c565b60326114a06040830160208401611dbd565b60ff1611806114c1575060326114bc6060830160408401611dbd565b60ff16115b15611504576040516303e2aef960e11b815260206004820152601260248201527111dbd85b1cc8195e18d95959081b1a5b5a5d60721b604482015260640161043c565b68af9a919e938b969a8d60b81b8135016115f1576115286080820160608301611dd8565b611575576040516303e2aef960e11b815260206004820152601b60248201527f50656e616c74696573207265717569726520657874726154696d650000000000604482015260640161043c565b61158560a0820160808301611dbd565b60ff161580156115a557506115a060c0820160a08301611dbd565b60ff16155b156115ec576040516303e2aef960e11b815260206004820152601660248201527550656e616c746965732064617461206d697373696e6760501b604482015260640161043c565b611670565b61160160a0820160808301611dbd565b60ff16151580611622575061161c60c0820160a08301611dbd565b60ff1615155b15611670576040516303e2aef960e11b815260206004820152601960248201527f556e65787065637465642070656e616c74696573206461746100000000000000604482015260640161043c565b428160c00135111561133f576040516303e2aef960e11b815260206004820152601060248201526f04675747572652074696d657374616d760841b604482015260640161043c565b5f5f60205f8451602086015f885af1806116d7576040513d5f823e3d81fd5b50505f513d915081156116ee5780600114156116fb565b6001600160a01b0384163b155b1561172457604051635274afe760e01b81526001600160a01b038516600482015260240161043c565b50505050565b5f6020828403121561173a575f5ffd5b5035919050565b8151151581526101608101602083015161175f602084018215159052565b506040830151611773604084018215159052565b50606083015161178e60608401826001600160a01b03169052565b5060808301516117a960808401826001600160a01b03169052565b5060a08301516117c460a08401826001600160a01b03169052565b5060c08301516117df60c08401826001600160a01b03169052565b5060e08301516117fb60e084018267ffffffffffffffff169052565b5061010083015161010083015261012083015161012083015261014083015161014083015292915050565b5f5f5f60408486031215611838575f5ffd5b83359250602084013567ffffffffffffffff811115611855575f5ffd5b8401601f81018613611865575f5ffd5b803567ffffffffffffffff81111561187b575f5ffd5b86602082840101111561188c575f5ffd5b939660209190910195509293505050565b6001600160a01b038116811461133f575f5ffd5b5f5f604083850312156118c2575f5ffd5b82356118cd8161189d565b946020939093013593505050565b5f610100820190508351825260ff602085015116602083015260ff604085015116604083015260608401511515606083015260ff608085015116608083015260ff60a08501511660a083015260c084015160c083015261086b60e083018415159052565b5f5f828403610100811215611952575f5ffd5b8335925060e0601f1982011215611967575f5ffd5b506020830190509250929050565b5f60208284031215611985575f5ffd5b813561086b8161189d565b81548152600182015460ff808216602080850191909152600883901c82166040850152601083901c821615156060850152601883901c821660808501529190911c1660a082015260029091015460c082015260e00190565b801515811461133f575f5ffd5b8051611a00816119e8565b919050565b5f60208284031215611a15575f5ffd5b815161086b816119e8565b604051610160810167ffffffffffffffff81118282101715611a5057634e487b7160e01b5f52604160045260245ffd5b60405290565b8051611a008161189d565b805167ffffffffffffffff81168114611a00575f5ffd5b5f610160828403128015611a8a575f5ffd5b50611a93611a20565b611a9c836119f5565b8152611aaa602084016119f5565b6020820152611abb604084016119f5565b6040820152611acc60608401611a56565b6060820152611add60808401611a56565b6080820152611aee60a08401611a56565b60a0820152611aff60c08401611a56565b60c0820152611b1060e08401611a61565b60e082015261010083810151908201526101208084015190820152610140928301519281019290925250919050565b5f60208284031215611b4f575f5ffd5b5051919050565b60208152816020820152818360408301375f818301604090810191909152601f909201601f19160101919050565b60ff8116811461133f575f5ffd5b8035611a0081611b84565b803582526020810135611baf81611b84565b60ff1660208301526040810135611bc581611b84565b60ff1660408301526060810135611bdb816119e8565b15156060830152611bee60808201611b92565b60ff166080830152611c0260a08201611b92565b60ff1660a083015260c090810135910152565b60e08101611c238284611b9d565b92915050565b61012081525f8a51806101208401528060208d0161014085015e5f6101408285018101919091526001600160a01b039b8c166020850152998b166040840152978a1660608301525067ffffffffffffffff9590951660808601529290961660a084015260c083015260e0820194909452610100810193909352601f01601f191690910101919050565b5f8135611c2381611b84565b5f8135611c23816119e8565b81358155600181016020830135611ce081611b84565b60ff811660ff19835416178255505f6040840135611cfd81611b84565b825461ff00191660089190911b61ff001617825550611d3d611d2160608501611cbe565b82805462ff0000191691151560101b62ff000016919091179055565b611d66611d4c60808501611cb2565b825463ff000000191660189190911b63ff00000016178255565b611d91611d7560a08501611cb2565b825464ff00000000191660209190911b64ff0000000016178255565b5060c09190910135600290910155565b6101008101611db08285611b9d565b8260e08301529392505050565b5f60208284031215611dcd575f5ffd5b813561086b81611b84565b5f60208284031215611de8575f5ffd5b813561086b816119e856fea26469706673582212209b222806ca976e67d33b43c6adf1a6d5863e3fc103d3ad66d30f10a6cfc4249f64736f6c634300081e0033",
}

// UMAAdapterABI is the input ABI used to generate the binding from.
// Deprecated: Use UMAAdapterMetaData.ABI instead.
var UMAAdapterABI = UMAAdapterMetaData.ABI

// UMAAdapterBin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use UMAAdapterMetaData.Bin instead.
var UMAAdapterBin = UMAAdapterMetaData.Bin

// DeployUMAAdapter deploys a new Ethereum contract, binding an instance of UMAAdapter to it.
func DeployUMAAdapter(auth *bind.TransactOpts, backend bind.ContractBackend, _optimisticOracle common.Address, _bondCurrency common.Address, _bondAmount *big.Int, _liveness uint64, _identifier [32]byte, initialOwner common.Address) (common.Address, *types.Transaction, *UMAAdapter, error) {
	parsed, err := UMAAdapterMetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(UMAAdapterBin), backend, _optimisticOracle, _bondCurrency, _bondAmount, _liveness, _identifier, initialOwner)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &UMAAdapter{UMAAdapterCaller: UMAAdapterCaller{contract: contract}, UMAAdapterTransactor: UMAAdapterTransactor{contract: contract}, UMAAdapterFilterer: UMAAdapterFilterer{contract: contract}}, nil
}

// UMAAdapter is an auto generated Go binding around an Ethereum contract.
type UMAAdapter struct {
	UMAAdapterCaller     // Read-only binding to the contract
	UMAAdapterTransactor // Write-only binding to the contract
	UMAAdapterFilterer   // Log filterer for contract events
}

// UMAAdapterCaller is an auto generated read-only Go binding around an Ethereum contract.
type UMAAdapterCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// UMAAdapterTransactor is an auto generated write-only Go binding around an Ethereum contract.
type UMAAdapterTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// UMAAdapterFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type UMAAdapterFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// UMAAdapterSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type UMAAdapterSession struct {
	Contract     *UMAAdapter       // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// UMAAdapterCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type UMAAdapterCallerSession struct {
	Contract *UMAAdapterCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts     // Call options to use throughout this session
}

// UMAAdapterTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type UMAAdapterTransactorSession struct {
	Contract     *UMAAdapterTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts     // Transaction auth options to use throughout this session
}

// UMAAdapterRaw is an auto generated low-level Go binding around an Ethereum contract.
type UMAAdapterRaw struct {
	Contract *UMAAdapter // Generic contract binding to access the raw methods on
}

// UMAAdapterCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type UMAAdapterCallerRaw struct {
	Contract *UMAAdapterCaller // Generic read-only contract binding to access the raw methods on
}

// UMAAdapterTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type UMAAdapterTransactorRaw struct {
	Contract *UMAAdapterTransactor // Generic write-only contract binding to access the raw methods on
}

// NewUMAAdapter creates a new instance of UMAAdapter, bound to a specific deployed contract.
func NewUMAAdapter(address common.Address, backend bind.ContractBackend) (*UMAAdapter, error) {
	contract, err := bindUMAAdapter(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &UMAAdapter{UMAAdapterCaller: UMAAdapterCaller{contract: contract}, UMAAdapterTransactor: UMAAdapterTransactor{contract: contract}, UMAAdapterFilterer: UMAAdapterFilterer{contract: contract}}, nil
}

// NewUMAAdapterCaller creates a new read-only instance of UMAAdapter, bound to a specific deployed contract.
func NewUMAAdapterCaller(address common.Address, caller bind.ContractCaller) (*UMAAdapterCaller, error) {
	contract, err := bindUMAAdapter(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &UMAAdapterCaller{contract: contract}, nil
}

// NewUMAAdapterTransactor creates a new write-only instance of UMAAdapter, bound to a specific deployed contract.
func NewUMAAdapterTransactor(address common.Address, transactor bind.ContractTransactor) (*UMAAdapterTransactor, error) {
	contract, err := bindUMAAdapter(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &UMAAdapterTransactor{contract: contract}, nil
}

// NewUMAAdapterFilterer creates a new log filterer instance of UMAAdapter, bound to a specific deployed contract.
func NewUMAAdapterFilterer(address common.Address, filterer bind.ContractFilterer) (*UMAAdapterFilterer, error) {
	contract, err := bindUMAAdapter(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &UMAAdapterFilterer{contract: contract}, nil
}

// bindUMAAdapter binds a generic wrapper to an already deployed contract.
func bindUMAAdapter(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := UMAAdapterMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_UMAAdapter *UMAAdapterRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _UMAAdapter.Contract.UMAAdapterCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_UMAAdapter *UMAAdapterRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _UMAAdapter.Contract.UMAAdapterTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_UMAAdapter *UMAAdapterRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _UMAAdapter.Contract.UMAAdapterTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_UMAAdapter *UMAAdapterCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _UMAAdapter.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_UMAAdapter *UMAAdapterTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _UMAAdapter.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_UMAAdapter *UMAAdapterTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _UMAAdapter.Contract.contract.Transact(opts, method, params...)
}

// AssertionMarkets is a free data retrieval call binding the contract method 0xe1f2274f.
//
// Solidity: function assertionMarkets(bytes32 assertionId) view returns(bytes32 marketId)
func (_UMAAdapter *UMAAdapterCaller) AssertionMarkets(opts *bind.CallOpts, assertionId [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "assertionMarkets", assertionId)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// AssertionMarkets is a free data retrieval call binding the contract method 0xe1f2274f.
//
// Solidity: function assertionMarkets(bytes32 assertionId) view returns(bytes32 marketId)
func (_UMAAdapter *UMAAdapterSession) AssertionMarkets(assertionId [32]byte) ([32]byte, error) {
	return _UMAAdapter.Contract.AssertionMarkets(&_UMAAdapter.CallOpts, assertionId)
}

// AssertionMarkets is a free data retrieval call binding the contract method 0xe1f2274f.
//
// Solidity: function assertionMarkets(bytes32 assertionId) view returns(bytes32 marketId)
func (_UMAAdapter *UMAAdapterCallerSession) AssertionMarkets(assertionId [32]byte) ([32]byte, error) {
	return _UMAAdapter.Contract.AssertionMarkets(&_UMAAdapter.CallOpts, assertionId)
}

// BondAmount is a free data retrieval call binding the contract method 0x80f323a7.
//
// Solidity: function bondAmount() view returns(uint256)
func (_UMAAdapter *UMAAdapterCaller) BondAmount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "bondAmount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BondAmount is a free data retrieval call binding the contract method 0x80f323a7.
//
// Solidity: function bondAmount() view returns(uint256)
func (_UMAAdapter *UMAAdapterSession) BondAmount() (*big.Int, error) {
	return _UMAAdapter.Contract.BondAmount(&_UMAAdapter.CallOpts)
}

// BondAmount is a free data retrieval call binding the contract method 0x80f323a7.
//
// Solidity: function bondAmount() view returns(uint256)
func (_UMAAdapter *UMAAdapterCallerSession) BondAmount() (*big.Int, error) {
	return _UMAAdapter.Contract.BondAmount(&_UMAAdapter.CallOpts)
}

// BondCurrency is a free data retrieval call binding the contract method 0x0484d542.
//
// Solidity: function bondCurrency() view returns(address)
func (_UMAAdapter *UMAAdapterCaller) BondCurrency(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "bondCurrency")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// BondCurrency is a free data retrieval call binding the contract method 0x0484d542.
//
// Solidity: function bondCurrency() view returns(address)
func (_UMAAdapter *UMAAdapterSession) BondCurrency() (common.Address, error) {
	return _UMAAdapter.Contract.BondCurrency(&_UMAAdapter.CallOpts)
}

// BondCurrency is a free data retrieval call binding the contract method 0x0484d542.
//
// Solidity: function bondCurrency() view returns(address)
func (_UMAAdapter *UMAAdapterCallerSession) BondCurrency() (common.Address, error) {
	return _UMAAdapter.Contract.BondCurrency(&_UMAAdapter.CallOpts)
}

// CanSettle is a free data retrieval call binding the contract method 0xad379089.
//
// Solidity: function canSettle(bytes32 marketId) view returns(bool)
func (_UMAAdapter *UMAAdapterCaller) CanSettle(opts *bind.CallOpts, marketId [32]byte) (bool, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "canSettle", marketId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// CanSettle is a free data retrieval call binding the contract method 0xad379089.
//
// Solidity: function canSettle(bytes32 marketId) view returns(bool)
func (_UMAAdapter *UMAAdapterSession) CanSettle(marketId [32]byte) (bool, error) {
	return _UMAAdapter.Contract.CanSettle(&_UMAAdapter.CallOpts, marketId)
}

// CanSettle is a free data retrieval call binding the contract method 0xad379089.
//
// Solidity: function canSettle(bytes32 marketId) view returns(bool)
func (_UMAAdapter *UMAAdapterCallerSession) CanSettle(marketId [32]byte) (bool, error) {
	return _UMAAdapter.Contract.CanSettle(&_UMAAdapter.CallOpts, marketId)
}

// GetAssertionDetails is a free data retrieval call binding the contract method 0x55da5539.
//
// Solidity: function getAssertionDetails(bytes32 marketId) view returns((bool,bool,bool,address,address,address,address,uint64,uint256,bytes32,bytes32))
func (_UMAAdapter *UMAAdapterCaller) GetAssertionDetails(opts *bind.CallOpts, marketId [32]byte) (IOptimisticOracleV3Assertion, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "getAssertionDetails", marketId)

	if err != nil {
		return *new(IOptimisticOracleV3Assertion), err
	}

	out0 := *abi.ConvertType(out[0], new(IOptimisticOracleV3Assertion)).(*IOptimisticOracleV3Assertion)

	return out0, err

}

// GetAssertionDetails is a free data retrieval call binding the contract method 0x55da5539.
//
// Solidity: function getAssertionDetails(bytes32 marketId) view returns((bool,bool,bool,address,address,address,address,uint64,uint256,bytes32,bytes32))
func (_UMAAdapter *UMAAdapterSession) GetAssertionDetails(marketId [32]byte) (IOptimisticOracleV3Assertion, error) {
	return _UMAAdapter.Contract.GetAssertionDetails(&_UMAAdapter.CallOpts, marketId)
}

// GetAssertionDetails is a free data retrieval call binding the contract method 0x55da5539.
//
// Solidity: function getAssertionDetails(bytes32 marketId) view returns((bool,bool,bool,address,address,address,address,uint64,uint256,bytes32,bytes32))
func (_UMAAdapter *UMAAdapterCallerSession) GetAssertionDetails(marketId [32]byte) (IOptimisticOracleV3Assertion, error) {
	return _UMAAdapter.Contract.GetAssertionDetails(&_UMAAdapter.CallOpts, marketId)
}

// GetResult is a free data retrieval call binding the contract method 0xadd4c784.
//
// Solidity: function getResult(bytes32 marketId) view returns((bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, bool finalized)
func (_UMAAdapter *UMAAdapterCaller) GetResult(opts *bind.CallOpts, marketId [32]byte) (struct {
	Facts     IResultOracleMatchFacts
	Finalized bool
}, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "getResult", marketId)

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
func (_UMAAdapter *UMAAdapterSession) GetResult(marketId [32]byte) (struct {
	Facts     IResultOracleMatchFacts
	Finalized bool
}, error) {
	return _UMAAdapter.Contract.GetResult(&_UMAAdapter.CallOpts, marketId)
}

// GetResult is a free data retrieval call binding the contract method 0xadd4c784.
//
// Solidity: function getResult(bytes32 marketId) view returns((bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, bool finalized)
func (_UMAAdapter *UMAAdapterCallerSession) GetResult(marketId [32]byte) (struct {
	Facts     IResultOracleMatchFacts
	Finalized bool
}, error) {
	return _UMAAdapter.Contract.GetResult(&_UMAAdapter.CallOpts, marketId)
}

// GetResultHash is a free data retrieval call binding the contract method 0x2ebcdb6e.
//
// Solidity: function getResultHash(bytes32 marketId) view returns(bytes32)
func (_UMAAdapter *UMAAdapterCaller) GetResultHash(opts *bind.CallOpts, marketId [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "getResultHash", marketId)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetResultHash is a free data retrieval call binding the contract method 0x2ebcdb6e.
//
// Solidity: function getResultHash(bytes32 marketId) view returns(bytes32)
func (_UMAAdapter *UMAAdapterSession) GetResultHash(marketId [32]byte) ([32]byte, error) {
	return _UMAAdapter.Contract.GetResultHash(&_UMAAdapter.CallOpts, marketId)
}

// GetResultHash is a free data retrieval call binding the contract method 0x2ebcdb6e.
//
// Solidity: function getResultHash(bytes32 marketId) view returns(bytes32)
func (_UMAAdapter *UMAAdapterCallerSession) GetResultHash(marketId [32]byte) ([32]byte, error) {
	return _UMAAdapter.Contract.GetResultHash(&_UMAAdapter.CallOpts, marketId)
}

// Identifier is a free data retrieval call binding the contract method 0x7998a1c4.
//
// Solidity: function identifier() view returns(bytes32)
func (_UMAAdapter *UMAAdapterCaller) Identifier(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "identifier")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// Identifier is a free data retrieval call binding the contract method 0x7998a1c4.
//
// Solidity: function identifier() view returns(bytes32)
func (_UMAAdapter *UMAAdapterSession) Identifier() ([32]byte, error) {
	return _UMAAdapter.Contract.Identifier(&_UMAAdapter.CallOpts)
}

// Identifier is a free data retrieval call binding the contract method 0x7998a1c4.
//
// Solidity: function identifier() view returns(bytes32)
func (_UMAAdapter *UMAAdapterCallerSession) Identifier() ([32]byte, error) {
	return _UMAAdapter.Contract.Identifier(&_UMAAdapter.CallOpts)
}

// IsFinalized is a free data retrieval call binding the contract method 0x7f8d429e.
//
// Solidity: function isFinalized(bytes32 marketId) view returns(bool)
func (_UMAAdapter *UMAAdapterCaller) IsFinalized(opts *bind.CallOpts, marketId [32]byte) (bool, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "isFinalized", marketId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsFinalized is a free data retrieval call binding the contract method 0x7f8d429e.
//
// Solidity: function isFinalized(bytes32 marketId) view returns(bool)
func (_UMAAdapter *UMAAdapterSession) IsFinalized(marketId [32]byte) (bool, error) {
	return _UMAAdapter.Contract.IsFinalized(&_UMAAdapter.CallOpts, marketId)
}

// IsFinalized is a free data retrieval call binding the contract method 0x7f8d429e.
//
// Solidity: function isFinalized(bytes32 marketId) view returns(bool)
func (_UMAAdapter *UMAAdapterCallerSession) IsFinalized(marketId [32]byte) (bool, error) {
	return _UMAAdapter.Contract.IsFinalized(&_UMAAdapter.CallOpts, marketId)
}

// Liveness is a free data retrieval call binding the contract method 0x6ad0690a.
//
// Solidity: function liveness() view returns(uint64)
func (_UMAAdapter *UMAAdapterCaller) Liveness(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "liveness")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// Liveness is a free data retrieval call binding the contract method 0x6ad0690a.
//
// Solidity: function liveness() view returns(uint64)
func (_UMAAdapter *UMAAdapterSession) Liveness() (uint64, error) {
	return _UMAAdapter.Contract.Liveness(&_UMAAdapter.CallOpts)
}

// Liveness is a free data retrieval call binding the contract method 0x6ad0690a.
//
// Solidity: function liveness() view returns(uint64)
func (_UMAAdapter *UMAAdapterCallerSession) Liveness() (uint64, error) {
	return _UMAAdapter.Contract.Liveness(&_UMAAdapter.CallOpts)
}

// MarketAssertions is a free data retrieval call binding the contract method 0xc65ac2b5.
//
// Solidity: function marketAssertions(bytes32 marketId) view returns(bytes32 assertionId)
func (_UMAAdapter *UMAAdapterCaller) MarketAssertions(opts *bind.CallOpts, marketId [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "marketAssertions", marketId)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// MarketAssertions is a free data retrieval call binding the contract method 0xc65ac2b5.
//
// Solidity: function marketAssertions(bytes32 marketId) view returns(bytes32 assertionId)
func (_UMAAdapter *UMAAdapterSession) MarketAssertions(marketId [32]byte) ([32]byte, error) {
	return _UMAAdapter.Contract.MarketAssertions(&_UMAAdapter.CallOpts, marketId)
}

// MarketAssertions is a free data retrieval call binding the contract method 0xc65ac2b5.
//
// Solidity: function marketAssertions(bytes32 marketId) view returns(bytes32 assertionId)
func (_UMAAdapter *UMAAdapterCallerSession) MarketAssertions(marketId [32]byte) ([32]byte, error) {
	return _UMAAdapter.Contract.MarketAssertions(&_UMAAdapter.CallOpts, marketId)
}

// OptimisticOracle is a free data retrieval call binding the contract method 0x22302922.
//
// Solidity: function optimisticOracle() view returns(address)
func (_UMAAdapter *UMAAdapterCaller) OptimisticOracle(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "optimisticOracle")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// OptimisticOracle is a free data retrieval call binding the contract method 0x22302922.
//
// Solidity: function optimisticOracle() view returns(address)
func (_UMAAdapter *UMAAdapterSession) OptimisticOracle() (common.Address, error) {
	return _UMAAdapter.Contract.OptimisticOracle(&_UMAAdapter.CallOpts)
}

// OptimisticOracle is a free data retrieval call binding the contract method 0x22302922.
//
// Solidity: function optimisticOracle() view returns(address)
func (_UMAAdapter *UMAAdapterCallerSession) OptimisticOracle() (common.Address, error) {
	return _UMAAdapter.Contract.OptimisticOracle(&_UMAAdapter.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_UMAAdapter *UMAAdapterCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _UMAAdapter.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_UMAAdapter *UMAAdapterSession) Owner() (common.Address, error) {
	return _UMAAdapter.Contract.Owner(&_UMAAdapter.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_UMAAdapter *UMAAdapterCallerSession) Owner() (common.Address, error) {
	return _UMAAdapter.Contract.Owner(&_UMAAdapter.CallOpts)
}

// DisputeAssertion is a paid mutator transaction binding the contract method 0x5e309398.
//
// Solidity: function disputeAssertion(bytes32 marketId, string reason) returns()
func (_UMAAdapter *UMAAdapterTransactor) DisputeAssertion(opts *bind.TransactOpts, marketId [32]byte, reason string) (*types.Transaction, error) {
	return _UMAAdapter.contract.Transact(opts, "disputeAssertion", marketId, reason)
}

// DisputeAssertion is a paid mutator transaction binding the contract method 0x5e309398.
//
// Solidity: function disputeAssertion(bytes32 marketId, string reason) returns()
func (_UMAAdapter *UMAAdapterSession) DisputeAssertion(marketId [32]byte, reason string) (*types.Transaction, error) {
	return _UMAAdapter.Contract.DisputeAssertion(&_UMAAdapter.TransactOpts, marketId, reason)
}

// DisputeAssertion is a paid mutator transaction binding the contract method 0x5e309398.
//
// Solidity: function disputeAssertion(bytes32 marketId, string reason) returns()
func (_UMAAdapter *UMAAdapterTransactorSession) DisputeAssertion(marketId [32]byte, reason string) (*types.Transaction, error) {
	return _UMAAdapter.Contract.DisputeAssertion(&_UMAAdapter.TransactOpts, marketId, reason)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address recipient, uint256 amount) returns()
func (_UMAAdapter *UMAAdapterTransactor) EmergencyWithdraw(opts *bind.TransactOpts, recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _UMAAdapter.contract.Transact(opts, "emergencyWithdraw", recipient, amount)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address recipient, uint256 amount) returns()
func (_UMAAdapter *UMAAdapterSession) EmergencyWithdraw(recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _UMAAdapter.Contract.EmergencyWithdraw(&_UMAAdapter.TransactOpts, recipient, amount)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address recipient, uint256 amount) returns()
func (_UMAAdapter *UMAAdapterTransactorSession) EmergencyWithdraw(recipient common.Address, amount *big.Int) (*types.Transaction, error) {
	return _UMAAdapter.Contract.EmergencyWithdraw(&_UMAAdapter.TransactOpts, recipient, amount)
}

// ProposeResult is a paid mutator transaction binding the contract method 0xc861161d.
//
// Solidity: function proposeResult(bytes32 marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts) returns()
func (_UMAAdapter *UMAAdapterTransactor) ProposeResult(opts *bind.TransactOpts, marketId [32]byte, facts IResultOracleMatchFacts) (*types.Transaction, error) {
	return _UMAAdapter.contract.Transact(opts, "proposeResult", marketId, facts)
}

// ProposeResult is a paid mutator transaction binding the contract method 0xc861161d.
//
// Solidity: function proposeResult(bytes32 marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts) returns()
func (_UMAAdapter *UMAAdapterSession) ProposeResult(marketId [32]byte, facts IResultOracleMatchFacts) (*types.Transaction, error) {
	return _UMAAdapter.Contract.ProposeResult(&_UMAAdapter.TransactOpts, marketId, facts)
}

// ProposeResult is a paid mutator transaction binding the contract method 0xc861161d.
//
// Solidity: function proposeResult(bytes32 marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts) returns()
func (_UMAAdapter *UMAAdapterTransactorSession) ProposeResult(marketId [32]byte, facts IResultOracleMatchFacts) (*types.Transaction, error) {
	return _UMAAdapter.Contract.ProposeResult(&_UMAAdapter.TransactOpts, marketId, facts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_UMAAdapter *UMAAdapterTransactor) RenounceOwnership(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _UMAAdapter.contract.Transact(opts, "renounceOwnership")
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_UMAAdapter *UMAAdapterSession) RenounceOwnership() (*types.Transaction, error) {
	return _UMAAdapter.Contract.RenounceOwnership(&_UMAAdapter.TransactOpts)
}

// RenounceOwnership is a paid mutator transaction binding the contract method 0x715018a6.
//
// Solidity: function renounceOwnership() returns()
func (_UMAAdapter *UMAAdapterTransactorSession) RenounceOwnership() (*types.Transaction, error) {
	return _UMAAdapter.Contract.RenounceOwnership(&_UMAAdapter.TransactOpts)
}

// SettleAssertion is a paid mutator transaction binding the contract method 0x4124beef.
//
// Solidity: function settleAssertion(bytes32 marketId) returns()
func (_UMAAdapter *UMAAdapterTransactor) SettleAssertion(opts *bind.TransactOpts, marketId [32]byte) (*types.Transaction, error) {
	return _UMAAdapter.contract.Transact(opts, "settleAssertion", marketId)
}

// SettleAssertion is a paid mutator transaction binding the contract method 0x4124beef.
//
// Solidity: function settleAssertion(bytes32 marketId) returns()
func (_UMAAdapter *UMAAdapterSession) SettleAssertion(marketId [32]byte) (*types.Transaction, error) {
	return _UMAAdapter.Contract.SettleAssertion(&_UMAAdapter.TransactOpts, marketId)
}

// SettleAssertion is a paid mutator transaction binding the contract method 0x4124beef.
//
// Solidity: function settleAssertion(bytes32 marketId) returns()
func (_UMAAdapter *UMAAdapterTransactorSession) SettleAssertion(marketId [32]byte) (*types.Transaction, error) {
	return _UMAAdapter.Contract.SettleAssertion(&_UMAAdapter.TransactOpts, marketId)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_UMAAdapter *UMAAdapterTransactor) TransferOwnership(opts *bind.TransactOpts, newOwner common.Address) (*types.Transaction, error) {
	return _UMAAdapter.contract.Transact(opts, "transferOwnership", newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_UMAAdapter *UMAAdapterSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _UMAAdapter.Contract.TransferOwnership(&_UMAAdapter.TransactOpts, newOwner)
}

// TransferOwnership is a paid mutator transaction binding the contract method 0xf2fde38b.
//
// Solidity: function transferOwnership(address newOwner) returns()
func (_UMAAdapter *UMAAdapterTransactorSession) TransferOwnership(newOwner common.Address) (*types.Transaction, error) {
	return _UMAAdapter.Contract.TransferOwnership(&_UMAAdapter.TransactOpts, newOwner)
}

// UMAAdapterAssertionCreatedIterator is returned from FilterAssertionCreated and is used to iterate over the raw logs and unpacked data for AssertionCreated events raised by the UMAAdapter contract.
type UMAAdapterAssertionCreatedIterator struct {
	Event *UMAAdapterAssertionCreated // Event containing the contract specifics and raw log

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
func (it *UMAAdapterAssertionCreatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UMAAdapterAssertionCreated)
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
		it.Event = new(UMAAdapterAssertionCreated)
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
func (it *UMAAdapterAssertionCreatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UMAAdapterAssertionCreatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UMAAdapterAssertionCreated represents a AssertionCreated event raised by the UMAAdapter contract.
type UMAAdapterAssertionCreated struct {
	MarketId    [32]byte
	AssertionId [32]byte
	Proposer    common.Address
	Facts       IResultOracleMatchFacts
	BondAmount  *big.Int
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterAssertionCreated is a free log retrieval operation binding the contract event 0x309face407a5a9f5edcd1ce1ea6fd7167f8a7b48276487f15041106f237bc80a.
//
// Solidity: event AssertionCreated(bytes32 indexed marketId, bytes32 indexed assertionId, address indexed proposer, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, uint256 bondAmount)
func (_UMAAdapter *UMAAdapterFilterer) FilterAssertionCreated(opts *bind.FilterOpts, marketId [][32]byte, assertionId [][32]byte, proposer []common.Address) (*UMAAdapterAssertionCreatedIterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var assertionIdRule []interface{}
	for _, assertionIdItem := range assertionId {
		assertionIdRule = append(assertionIdRule, assertionIdItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _UMAAdapter.contract.FilterLogs(opts, "AssertionCreated", marketIdRule, assertionIdRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return &UMAAdapterAssertionCreatedIterator{contract: _UMAAdapter.contract, event: "AssertionCreated", logs: logs, sub: sub}, nil
}

// WatchAssertionCreated is a free log subscription operation binding the contract event 0x309face407a5a9f5edcd1ce1ea6fd7167f8a7b48276487f15041106f237bc80a.
//
// Solidity: event AssertionCreated(bytes32 indexed marketId, bytes32 indexed assertionId, address indexed proposer, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, uint256 bondAmount)
func (_UMAAdapter *UMAAdapterFilterer) WatchAssertionCreated(opts *bind.WatchOpts, sink chan<- *UMAAdapterAssertionCreated, marketId [][32]byte, assertionId [][32]byte, proposer []common.Address) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var assertionIdRule []interface{}
	for _, assertionIdItem := range assertionId {
		assertionIdRule = append(assertionIdRule, assertionIdItem)
	}
	var proposerRule []interface{}
	for _, proposerItem := range proposer {
		proposerRule = append(proposerRule, proposerItem)
	}

	logs, sub, err := _UMAAdapter.contract.WatchLogs(opts, "AssertionCreated", marketIdRule, assertionIdRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UMAAdapterAssertionCreated)
				if err := _UMAAdapter.contract.UnpackLog(event, "AssertionCreated", log); err != nil {
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

// ParseAssertionCreated is a log parse operation binding the contract event 0x309face407a5a9f5edcd1ce1ea6fd7167f8a7b48276487f15041106f237bc80a.
//
// Solidity: event AssertionCreated(bytes32 indexed marketId, bytes32 indexed assertionId, address indexed proposer, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, uint256 bondAmount)
func (_UMAAdapter *UMAAdapterFilterer) ParseAssertionCreated(log types.Log) (*UMAAdapterAssertionCreated, error) {
	event := new(UMAAdapterAssertionCreated)
	if err := _UMAAdapter.contract.UnpackLog(event, "AssertionCreated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UMAAdapterAssertionSettledSuccessfullyIterator is returned from FilterAssertionSettledSuccessfully and is used to iterate over the raw logs and unpacked data for AssertionSettledSuccessfully events raised by the UMAAdapter contract.
type UMAAdapterAssertionSettledSuccessfullyIterator struct {
	Event *UMAAdapterAssertionSettledSuccessfully // Event containing the contract specifics and raw log

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
func (it *UMAAdapterAssertionSettledSuccessfullyIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UMAAdapterAssertionSettledSuccessfully)
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
		it.Event = new(UMAAdapterAssertionSettledSuccessfully)
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
func (it *UMAAdapterAssertionSettledSuccessfullyIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UMAAdapterAssertionSettledSuccessfullyIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UMAAdapterAssertionSettledSuccessfully represents a AssertionSettledSuccessfully event raised by the UMAAdapter contract.
type UMAAdapterAssertionSettledSuccessfully struct {
	MarketId    [32]byte
	AssertionId [32]byte
	Accepted    bool
	Raw         types.Log // Blockchain specific contextual infos
}

// FilterAssertionSettledSuccessfully is a free log retrieval operation binding the contract event 0xcb510e6fc9c8f5747fd8a66fb2cbe64bdc8ae7da1dee4eb498f0cb97cecade82.
//
// Solidity: event AssertionSettledSuccessfully(bytes32 indexed marketId, bytes32 indexed assertionId, bool accepted)
func (_UMAAdapter *UMAAdapterFilterer) FilterAssertionSettledSuccessfully(opts *bind.FilterOpts, marketId [][32]byte, assertionId [][32]byte) (*UMAAdapterAssertionSettledSuccessfullyIterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var assertionIdRule []interface{}
	for _, assertionIdItem := range assertionId {
		assertionIdRule = append(assertionIdRule, assertionIdItem)
	}

	logs, sub, err := _UMAAdapter.contract.FilterLogs(opts, "AssertionSettledSuccessfully", marketIdRule, assertionIdRule)
	if err != nil {
		return nil, err
	}
	return &UMAAdapterAssertionSettledSuccessfullyIterator{contract: _UMAAdapter.contract, event: "AssertionSettledSuccessfully", logs: logs, sub: sub}, nil
}

// WatchAssertionSettledSuccessfully is a free log subscription operation binding the contract event 0xcb510e6fc9c8f5747fd8a66fb2cbe64bdc8ae7da1dee4eb498f0cb97cecade82.
//
// Solidity: event AssertionSettledSuccessfully(bytes32 indexed marketId, bytes32 indexed assertionId, bool accepted)
func (_UMAAdapter *UMAAdapterFilterer) WatchAssertionSettledSuccessfully(opts *bind.WatchOpts, sink chan<- *UMAAdapterAssertionSettledSuccessfully, marketId [][32]byte, assertionId [][32]byte) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var assertionIdRule []interface{}
	for _, assertionIdItem := range assertionId {
		assertionIdRule = append(assertionIdRule, assertionIdItem)
	}

	logs, sub, err := _UMAAdapter.contract.WatchLogs(opts, "AssertionSettledSuccessfully", marketIdRule, assertionIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UMAAdapterAssertionSettledSuccessfully)
				if err := _UMAAdapter.contract.UnpackLog(event, "AssertionSettledSuccessfully", log); err != nil {
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

// ParseAssertionSettledSuccessfully is a log parse operation binding the contract event 0xcb510e6fc9c8f5747fd8a66fb2cbe64bdc8ae7da1dee4eb498f0cb97cecade82.
//
// Solidity: event AssertionSettledSuccessfully(bytes32 indexed marketId, bytes32 indexed assertionId, bool accepted)
func (_UMAAdapter *UMAAdapterFilterer) ParseAssertionSettledSuccessfully(log types.Log) (*UMAAdapterAssertionSettledSuccessfully, error) {
	event := new(UMAAdapterAssertionSettledSuccessfully)
	if err := _UMAAdapter.contract.UnpackLog(event, "AssertionSettledSuccessfully", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UMAAdapterOwnershipTransferredIterator is returned from FilterOwnershipTransferred and is used to iterate over the raw logs and unpacked data for OwnershipTransferred events raised by the UMAAdapter contract.
type UMAAdapterOwnershipTransferredIterator struct {
	Event *UMAAdapterOwnershipTransferred // Event containing the contract specifics and raw log

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
func (it *UMAAdapterOwnershipTransferredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UMAAdapterOwnershipTransferred)
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
		it.Event = new(UMAAdapterOwnershipTransferred)
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
func (it *UMAAdapterOwnershipTransferredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UMAAdapterOwnershipTransferredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UMAAdapterOwnershipTransferred represents a OwnershipTransferred event raised by the UMAAdapter contract.
type UMAAdapterOwnershipTransferred struct {
	PreviousOwner common.Address
	NewOwner      common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterOwnershipTransferred is a free log retrieval operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_UMAAdapter *UMAAdapterFilterer) FilterOwnershipTransferred(opts *bind.FilterOpts, previousOwner []common.Address, newOwner []common.Address) (*UMAAdapterOwnershipTransferredIterator, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _UMAAdapter.contract.FilterLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return &UMAAdapterOwnershipTransferredIterator{contract: _UMAAdapter.contract, event: "OwnershipTransferred", logs: logs, sub: sub}, nil
}

// WatchOwnershipTransferred is a free log subscription operation binding the contract event 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0.
//
// Solidity: event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
func (_UMAAdapter *UMAAdapterFilterer) WatchOwnershipTransferred(opts *bind.WatchOpts, sink chan<- *UMAAdapterOwnershipTransferred, previousOwner []common.Address, newOwner []common.Address) (event.Subscription, error) {

	var previousOwnerRule []interface{}
	for _, previousOwnerItem := range previousOwner {
		previousOwnerRule = append(previousOwnerRule, previousOwnerItem)
	}
	var newOwnerRule []interface{}
	for _, newOwnerItem := range newOwner {
		newOwnerRule = append(newOwnerRule, newOwnerItem)
	}

	logs, sub, err := _UMAAdapter.contract.WatchLogs(opts, "OwnershipTransferred", previousOwnerRule, newOwnerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UMAAdapterOwnershipTransferred)
				if err := _UMAAdapter.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
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
func (_UMAAdapter *UMAAdapterFilterer) ParseOwnershipTransferred(log types.Log) (*UMAAdapterOwnershipTransferred, error) {
	event := new(UMAAdapterOwnershipTransferred)
	if err := _UMAAdapter.contract.UnpackLog(event, "OwnershipTransferred", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UMAAdapterResultDisputedIterator is returned from FilterResultDisputed and is used to iterate over the raw logs and unpacked data for ResultDisputed events raised by the UMAAdapter contract.
type UMAAdapterResultDisputedIterator struct {
	Event *UMAAdapterResultDisputed // Event containing the contract specifics and raw log

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
func (it *UMAAdapterResultDisputedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UMAAdapterResultDisputed)
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
		it.Event = new(UMAAdapterResultDisputed)
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
func (it *UMAAdapterResultDisputedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UMAAdapterResultDisputedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UMAAdapterResultDisputed represents a ResultDisputed event raised by the UMAAdapter contract.
type UMAAdapterResultDisputed struct {
	MarketId  [32]byte
	FactsHash [32]byte
	Disputer  common.Address
	Reason    string
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterResultDisputed is a free log retrieval operation binding the contract event 0xbbbeedae39b2d17885fef07ce783ed99615993552c345e864913d87403656502.
//
// Solidity: event ResultDisputed(bytes32 indexed marketId, bytes32 indexed factsHash, address indexed disputer, string reason)
func (_UMAAdapter *UMAAdapterFilterer) FilterResultDisputed(opts *bind.FilterOpts, marketId [][32]byte, factsHash [][32]byte, disputer []common.Address) (*UMAAdapterResultDisputedIterator, error) {

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

	logs, sub, err := _UMAAdapter.contract.FilterLogs(opts, "ResultDisputed", marketIdRule, factsHashRule, disputerRule)
	if err != nil {
		return nil, err
	}
	return &UMAAdapterResultDisputedIterator{contract: _UMAAdapter.contract, event: "ResultDisputed", logs: logs, sub: sub}, nil
}

// WatchResultDisputed is a free log subscription operation binding the contract event 0xbbbeedae39b2d17885fef07ce783ed99615993552c345e864913d87403656502.
//
// Solidity: event ResultDisputed(bytes32 indexed marketId, bytes32 indexed factsHash, address indexed disputer, string reason)
func (_UMAAdapter *UMAAdapterFilterer) WatchResultDisputed(opts *bind.WatchOpts, sink chan<- *UMAAdapterResultDisputed, marketId [][32]byte, factsHash [][32]byte, disputer []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _UMAAdapter.contract.WatchLogs(opts, "ResultDisputed", marketIdRule, factsHashRule, disputerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UMAAdapterResultDisputed)
				if err := _UMAAdapter.contract.UnpackLog(event, "ResultDisputed", log); err != nil {
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
func (_UMAAdapter *UMAAdapterFilterer) ParseResultDisputed(log types.Log) (*UMAAdapterResultDisputed, error) {
	event := new(UMAAdapterResultDisputed)
	if err := _UMAAdapter.contract.UnpackLog(event, "ResultDisputed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UMAAdapterResultFinalizedIterator is returned from FilterResultFinalized and is used to iterate over the raw logs and unpacked data for ResultFinalized events raised by the UMAAdapter contract.
type UMAAdapterResultFinalizedIterator struct {
	Event *UMAAdapterResultFinalized // Event containing the contract specifics and raw log

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
func (it *UMAAdapterResultFinalizedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UMAAdapterResultFinalized)
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
		it.Event = new(UMAAdapterResultFinalized)
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
func (it *UMAAdapterResultFinalizedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UMAAdapterResultFinalizedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UMAAdapterResultFinalized represents a ResultFinalized event raised by the UMAAdapter contract.
type UMAAdapterResultFinalized struct {
	MarketId  [32]byte
	FactsHash [32]byte
	Accepted  bool
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterResultFinalized is a free log retrieval operation binding the contract event 0x4cb34067cc782b93372b2df0b774e841095666c2ec113563e41bc894b1bd836f.
//
// Solidity: event ResultFinalized(bytes32 indexed marketId, bytes32 indexed factsHash, bool accepted)
func (_UMAAdapter *UMAAdapterFilterer) FilterResultFinalized(opts *bind.FilterOpts, marketId [][32]byte, factsHash [][32]byte) (*UMAAdapterResultFinalizedIterator, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var factsHashRule []interface{}
	for _, factsHashItem := range factsHash {
		factsHashRule = append(factsHashRule, factsHashItem)
	}

	logs, sub, err := _UMAAdapter.contract.FilterLogs(opts, "ResultFinalized", marketIdRule, factsHashRule)
	if err != nil {
		return nil, err
	}
	return &UMAAdapterResultFinalizedIterator{contract: _UMAAdapter.contract, event: "ResultFinalized", logs: logs, sub: sub}, nil
}

// WatchResultFinalized is a free log subscription operation binding the contract event 0x4cb34067cc782b93372b2df0b774e841095666c2ec113563e41bc894b1bd836f.
//
// Solidity: event ResultFinalized(bytes32 indexed marketId, bytes32 indexed factsHash, bool accepted)
func (_UMAAdapter *UMAAdapterFilterer) WatchResultFinalized(opts *bind.WatchOpts, sink chan<- *UMAAdapterResultFinalized, marketId [][32]byte, factsHash [][32]byte) (event.Subscription, error) {

	var marketIdRule []interface{}
	for _, marketIdItem := range marketId {
		marketIdRule = append(marketIdRule, marketIdItem)
	}
	var factsHashRule []interface{}
	for _, factsHashItem := range factsHash {
		factsHashRule = append(factsHashRule, factsHashItem)
	}

	logs, sub, err := _UMAAdapter.contract.WatchLogs(opts, "ResultFinalized", marketIdRule, factsHashRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UMAAdapterResultFinalized)
				if err := _UMAAdapter.contract.UnpackLog(event, "ResultFinalized", log); err != nil {
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
func (_UMAAdapter *UMAAdapterFilterer) ParseResultFinalized(log types.Log) (*UMAAdapterResultFinalized, error) {
	event := new(UMAAdapterResultFinalized)
	if err := _UMAAdapter.contract.UnpackLog(event, "ResultFinalized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// UMAAdapterResultProposedIterator is returned from FilterResultProposed and is used to iterate over the raw logs and unpacked data for ResultProposed events raised by the UMAAdapter contract.
type UMAAdapterResultProposedIterator struct {
	Event *UMAAdapterResultProposed // Event containing the contract specifics and raw log

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
func (it *UMAAdapterResultProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(UMAAdapterResultProposed)
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
		it.Event = new(UMAAdapterResultProposed)
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
func (it *UMAAdapterResultProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *UMAAdapterResultProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// UMAAdapterResultProposed represents a ResultProposed event raised by the UMAAdapter contract.
type UMAAdapterResultProposed struct {
	MarketId  [32]byte
	Facts     IResultOracleMatchFacts
	FactsHash [32]byte
	Proposer  common.Address
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterResultProposed is a free log retrieval operation binding the contract event 0xf6cf8272543abecfdb5f9b23c9b35840bbfe239e36ff0294be5c9a989fb2e089.
//
// Solidity: event ResultProposed(bytes32 indexed marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, bytes32 indexed factsHash, address indexed proposer)
func (_UMAAdapter *UMAAdapterFilterer) FilterResultProposed(opts *bind.FilterOpts, marketId [][32]byte, factsHash [][32]byte, proposer []common.Address) (*UMAAdapterResultProposedIterator, error) {

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

	logs, sub, err := _UMAAdapter.contract.FilterLogs(opts, "ResultProposed", marketIdRule, factsHashRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return &UMAAdapterResultProposedIterator{contract: _UMAAdapter.contract, event: "ResultProposed", logs: logs, sub: sub}, nil
}

// WatchResultProposed is a free log subscription operation binding the contract event 0xf6cf8272543abecfdb5f9b23c9b35840bbfe239e36ff0294be5c9a989fb2e089.
//
// Solidity: event ResultProposed(bytes32 indexed marketId, (bytes32,uint8,uint8,bool,uint8,uint8,uint256) facts, bytes32 indexed factsHash, address indexed proposer)
func (_UMAAdapter *UMAAdapterFilterer) WatchResultProposed(opts *bind.WatchOpts, sink chan<- *UMAAdapterResultProposed, marketId [][32]byte, factsHash [][32]byte, proposer []common.Address) (event.Subscription, error) {

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

	logs, sub, err := _UMAAdapter.contract.WatchLogs(opts, "ResultProposed", marketIdRule, factsHashRule, proposerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(UMAAdapterResultProposed)
				if err := _UMAAdapter.contract.UnpackLog(event, "ResultProposed", log); err != nil {
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
func (_UMAAdapter *UMAAdapterFilterer) ParseResultProposed(log types.Log) (*UMAAdapterResultProposed, error) {
	event := new(UMAAdapterResultProposed)
	if err := _UMAAdapter.contract.UnpackLog(event, "ResultProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
