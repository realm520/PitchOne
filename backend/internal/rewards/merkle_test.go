package rewards

import (
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNewMerkleTree(t *testing.T) {
	entries := []RewardEntry{
		{User: common.HexToAddress("0x1111111111111111111111111111111111111111"), Week: 0, Amount: "1000"},
		{User: common.HexToAddress("0x2222222222222222222222222222222222222222"), Week: 0, Amount: "2000"},
		{User: common.HexToAddress("0x3333333333333333333333333333333333333333"), Week: 0, Amount: "3000"},
	}

	tree, err := NewMerkleTree(entries)
	require.NoError(t, err)
	require.NotNil(t, tree)

	// 验证基本属性
	assert.Len(t, tree.Leaves, 3)
	assert.NotEqual(t, common.Hash{}, tree.Root)

	// 验证每个用户都有证明
	for _, entry := range entries {
		proof, exists := tree.GetProof(entry.User)
		assert.True(t, exists)
		assert.NotEmpty(t, proof)
	}
}

func TestNewMerkleTree_EmptyEntries(t *testing.T) {
	_, err := NewMerkleTree([]RewardEntry{})
	assert.Error(t, err)
}

func TestNewMerkleTree_SingleEntry(t *testing.T) {
	entries := []RewardEntry{
		{User: common.HexToAddress("0x1111111111111111111111111111111111111111"), Week: 0, Amount: "1000"},
	}

	tree, err := NewMerkleTree(entries)
	require.NoError(t, err)

	assert.Len(t, tree.Leaves, 1)
	assert.NotEqual(t, common.Hash{}, tree.Root)
}

func TestVerifyProof(t *testing.T) {
	entries := []RewardEntry{
		{User: common.HexToAddress("0x1111111111111111111111111111111111111111"), Week: 0, Amount: "1000"},
		{User: common.HexToAddress("0x2222222222222222222222222222222222222222"), Week: 0, Amount: "2000"},
		{User: common.HexToAddress("0x3333333333333333333333333333333333333333"), Week: 0, Amount: "3000"},
	}

	tree, err := NewMerkleTree(entries)
	require.NoError(t, err)

	// 验证每个用户的证明
	// 注意：NewMerkleTree 会对 entries 排序，所以需要重新生成叶子节点而不是使用索引
	for _, entry := range entries {
		proof, exists := tree.GetProof(entry.User)
		require.True(t, exists, "Proof not found for user %s", entry.User.Hex())

		// 重新生成叶子节点以确保与树中的叶子节点匹配
		leaf := GenerateLeaf(entry.User, entry.Week, entry.Amount)
		assert.True(t, VerifyProof(proof, tree.Root, leaf), "Proof verification failed for user %s", entry.User.Hex())
	}
}

func TestVerifyProof_InvalidProof(t *testing.T) {
	entries := []RewardEntry{
		{User: common.HexToAddress("0x1111111111111111111111111111111111111111"), Week: 0, Amount: "1000"},
		{User: common.HexToAddress("0x2222222222222222222222222222222222222222"), Week: 0, Amount: "2000"},
	}

	tree, err := NewMerkleTree(entries)
	require.NoError(t, err)

	// 使用错误的叶子节点
	wrongLeaf := common.HexToHash("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
	proof, _ := tree.GetProof(entries[0].User)

	assert.False(t, VerifyProof(proof, tree.Root, wrongLeaf))
}

func TestHashPair(t *testing.T) {
	a := common.HexToHash("0x1111111111111111111111111111111111111111111111111111111111111111")
	b := common.HexToHash("0x2222222222222222222222222222222222222222222222222222222222222222")

	// 验证排序一致性
	hash1 := HashPair(a, b)
	hash2 := HashPair(b, a)

	assert.Equal(t, hash1, hash2, "HashPair should be order-independent")
}

func TestBuildDistribution(t *testing.T) {
	entries := []RewardEntry{
		{User: common.HexToAddress("0x1111111111111111111111111111111111111111"), Week: 0, Amount: "1000"},
		{User: common.HexToAddress("0x2222222222222222222222222222222222222222"), Week: 0, Amount: "2000"},
	}

	dist, err := BuildDistribution(0, entries, 10000)
	require.NoError(t, err)

	assert.Equal(t, uint64(0), dist.Week)
	assert.Equal(t, uint64(10000), dist.ScaleBps)
	assert.Equal(t, 2, dist.Recipients)
	assert.NotEmpty(t, dist.Root)
	assert.Len(t, dist.Proofs, 2)
}

func TestBuildDistribution_InvalidScaleBps(t *testing.T) {
	entries := []RewardEntry{
		{User: common.HexToAddress("0x1111111111111111111111111111111111111111"), Week: 0, Amount: "1000"},
	}

	// scaleBps = 0
	_, err := BuildDistribution(0, entries, 0)
	assert.Error(t, err)

	// scaleBps > 10000
	_, err = BuildDistribution(0, entries, 10001)
	assert.Error(t, err)
}

func TestSerializeProof(t *testing.T) {
	proof := []common.Hash{
		common.HexToHash("0x1111111111111111111111111111111111111111111111111111111111111111"),
		common.HexToHash("0x2222222222222222222222222222222222222222222222222222222222222222"),
	}

	serialized := SerializeProof(proof)
	assert.Contains(t, serialized, "0x1111111111111111111111111111111111111111111111111111111111111111")
	assert.Contains(t, serialized, "0x2222222222222222222222222222222222222222222222222222222222222222")
}

func TestChecksum(t *testing.T) {
	dist1 := &MerkleDistribution{
		Week:        0,
		Root:        "0x1234567890abcdef",
		Recipients:  10,
		ScaleBps:    10000,
	}

	dist2 := &MerkleDistribution{
		Week:        0,
		Root:        "0x1234567890abcdef",
		Recipients:  10,
		ScaleBps:    10000,
	}

	dist3 := &MerkleDistribution{
		Week:        1, // 不同
		Root:        "0x1234567890abcdef",
		Recipients:  10,
		ScaleBps:    10000,
	}

	// 相同的数据应该有相同的校验和
	assert.Equal(t, dist1.Checksum(), dist2.Checksum())

	// 不同的数据应该有不同的校验和
	assert.NotEqual(t, dist1.Checksum(), dist3.Checksum())
}

// Benchmark tests
func BenchmarkNewMerkleTree(b *testing.B) {
	entries := make([]RewardEntry, 1000)
	for i := 0; i < 1000; i++ {
		entries[i] = RewardEntry{
			User:   common.BigToAddress(big.NewInt(int64(i + 1))),
			Week:   0,
			Amount: "1000",
		}
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = NewMerkleTree(entries)
	}
}

func BenchmarkVerifyProof(b *testing.B) {
	entries := make([]RewardEntry, 1000)
	for i := 0; i < 1000; i++ {
		entries[i] = RewardEntry{
			User:   common.BigToAddress(big.NewInt(int64(i + 1))),
			Week:   0,
			Amount: "1000",
		}
	}

	tree, _ := NewMerkleTree(entries)
	proof, _ := tree.GetProof(entries[0].User)
	leaf := tree.Leaves[0]

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		VerifyProof(proof, tree.Root, leaf)
	}
}
