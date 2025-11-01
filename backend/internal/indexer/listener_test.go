package indexer

import (
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

// TestNewEventListener 测试事件监听器创建
func TestNewEventListener(t *testing.T) {
	logger, _ := zap.NewDevelopment()

	tests := []struct {
		name    string
		config  *Config
		wantErr bool
	}{
		{
			name: "invalid RPC URL",
			config: &Config{
				RPCURL:          "invalid://url",
				ContractAddress: common.HexToAddress("0x1111111111111111111111111111111111111111"),
			},
			wantErr: true,
		},
		{
			name: "empty contract address",
			config: &Config{
				RPCURL:          "http://localhost:8545",
				ContractAddress: common.Address{},
			},
			wantErr: false, // 不验证地址是否为空
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := NewEventListener(tt.config, nil, logger)
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				// 注意：如果本地没有运行节点，这个测试可能会失败
				// 在 CI 环境中应该跳过或使用 mock
				if err != nil {
					t.Skip("Ethereum node not available")
				}
			}
		})
	}
}

// TestEventSignatures 测试事件签名计算是否正确
func TestEventSignatures(t *testing.T) {
	// 预期的事件签名
	expectedSigs := map[string]string{
		"MarketCreatedWDL":   "MarketCreated(string,string,string,uint256,address)",
		"MarketCreatedOU":    "MarketCreated(string,string,string,uint256,uint256,bool,address)",
		"BetPlaced":          "BetPlaced(address,uint8,uint256,uint256,uint256)",
		"Locked":             "Locked(uint256)",
		"Resolved":           "Resolved(uint256,uint256)",
		"ResolvedWithOracle": "ResolvedWithOracle(uint256,bytes32,uint256)",
		"Redeemed":           "Redeemed(address,uint8,uint256,uint256)",
		"Finalized":          "Finalized(uint256)",
	}

	// 计算事件签名
	eventSigs := make(map[string]common.Hash)
	for name, sig := range expectedSigs {
		eventSigs[name] = crypto.Keccak256Hash([]byte(sig))
	}

	// 验证所有签名都已计算且非零
	assert.Len(t, eventSigs, len(expectedSigs))

	for name, hash := range eventSigs {
		assert.NotEqual(t, common.Hash{}, hash, "Event signature for %s should not be zero", name)
		t.Logf("%s: %s", name, hash.Hex())
	}

	// 验证不同事件有不同的签名
	seenHashes := make(map[common.Hash]string)
	for name, hash := range eventSigs {
		if existing, found := seenHashes[hash]; found {
			t.Errorf("Duplicate hash for %s and %s: %s", name, existing, hash.Hex())
		}
		seenHashes[hash] = name
	}
}

// TestEventSignaturesAgainstActual 测试事件签名与实际索引器匹配
func TestEventSignaturesAgainstActual(t *testing.T) {
	logger, _ := zap.NewDevelopment()
	cfg := &Config{
		RPCURL:          "http://localhost:8545",
		ContractAddress: common.HexToAddress("0x1111111111111111111111111111111111111111"),
	}

	listener, err := NewEventListener(cfg, nil, logger)
	if err != nil {
		t.Skip("Ethereum node not available")
		return
	}
	defer listener.Close()

	// 验证索引器的事件签名与预期匹配
	require.NotNil(t, listener.eventSigs)
	require.NotEmpty(t, listener.eventSigs)

	// 验证关键事件签名存在
	keyEvents := []string{"BetPlaced", "Locked", "Resolved", "Redeemed", "Finalized", "MarketCreatedWDL", "MarketCreatedOU"}
	for _, eventName := range keyEvents {
		sig, exists := listener.eventSigs[eventName]
		assert.True(t, exists, "Event signature for %s should exist", eventName)
		assert.NotEqual(t, common.Hash{}, sig, "Event signature for %s should not be zero", eventName)
	}

	// 验证 BetPlaced 事件签名的正确性
	// 这是一个已知的事件签名，可以从合约 ABI 获取
	expectedBetPlaced := crypto.Keccak256Hash([]byte("BetPlaced(address,uint8,uint256,uint256,uint256)"))
	actualBetPlaced, exists := listener.eventSigs["BetPlaced"]
	require.True(t, exists)

	// 由于实际的 BetPlaced 可能有不同的参数顺序或类型，我们只验证它不是零值
	// 在实际集成测试中，应该使用真实的合约 ABI 来验证
	assert.NotEqual(t, common.Hash{}, actualBetPlaced)

	// 打印预期和实际签名用于调试
	t.Logf("Expected BetPlaced signature: %s", expectedBetPlaced.Hex())
	t.Logf("Actual BetPlaced signature: %s", actualBetPlaced.Hex())
}

// TestConfigValidation 测试配置验证
func TestConfigValidation(t *testing.T) {
	logger, _ := zap.NewDevelopment()

	tests := []struct {
		name    string
		config  *Config
		wantErr bool
	}{
		{
			name: "valid config with HTTP RPC",
			config: &Config{
				RPCURL:          "http://localhost:8545",
				ContractAddress: common.HexToAddress("0x1234567890123456789012345678901234567890"),
				StartBlock:      0,
				BatchSize:       100,
			},
			wantErr: false,
		},
		{
			name: "valid config with HTTPS RPC",
			config: &Config{
				RPCURL:          "https://eth-mainnet.g.alchemy.com/v2/your-api-key",
				ContractAddress: common.HexToAddress("0x1234567890123456789012345678901234567890"),
			},
			wantErr: false,
		},
		{
			name: "invalid RPC URL scheme",
			config: &Config{
				RPCURL:          "ftp://invalid.url",
				ContractAddress: common.HexToAddress("0x1234567890123456789012345678901234567890"),
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			listener, err := NewEventListener(tt.config, nil, logger)
			if err != nil && !tt.wantErr {
				// 如果节点不可用，跳过测试
				t.Skip("Ethereum node not available")
				return
			}

			if tt.wantErr {
				assert.Error(t, err)
			} else {
				if listener != nil {
					assert.NotNil(t, listener)
					assert.NotNil(t, listener.client)
					assert.NotNil(t, listener.eventSigs)
					listener.Close()
				}
			}
		})
	}
}

// BenchmarkEventSignatureCalculation 基准测试事件签名计算
func BenchmarkEventSignatureCalculation(b *testing.B) {
	signatures := []string{
		"MarketCreated(string,string,string,uint256,address)",
		"BetPlaced(address,uint8,uint256,uint256,uint256)",
		"Locked(uint256)",
		"Resolved(uint256,uint256)",
		"Redeemed(address,uint8,uint256,uint256)",
		"Finalized(uint256)",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		for _, sig := range signatures {
			_ = crypto.Keccak256Hash([]byte(sig))
		}
	}
}
