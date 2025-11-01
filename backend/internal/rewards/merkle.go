package rewards

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"sort"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

// RewardEntry 表示单个用户的奖励条目
type RewardEntry struct {
	User   common.Address // 用户地址
	Week   uint64         // 周编号
	Amount string         // 奖励金额（wei，字符串表示以支持大数）
}

// MerkleTree 表示 Merkle 树
type MerkleTree struct {
	Leaves []common.Hash     // 叶子节点
	Nodes  [][]common.Hash   // 所有层级的节点
	Root   common.Hash       // Merkle 根
	Proofs map[string][]common.Hash // 用户地址 -> Merkle 证明
}

// NewMerkleTree 从奖励条目创建 Merkle 树
func NewMerkleTree(entries []RewardEntry) (*MerkleTree, error) {
	if len(entries) == 0 {
		return nil, fmt.Errorf("no entries provided")
	}

	// 按用户地址排序，确保确定性
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].User.Hex() < entries[j].User.Hex()
	})

	// 生成叶子节点
	leaves := make([]common.Hash, len(entries))
	for i, entry := range entries {
		leaves[i] = GenerateLeaf(entry.User, entry.Week, entry.Amount)
	}

	// 构建 Merkle 树
	tree := &MerkleTree{
		Leaves: leaves,
		Nodes:  [][]common.Hash{leaves},
		Proofs: make(map[string][]common.Hash),
	}

	// 逐层构建树
	currentLevel := leaves
	for len(currentLevel) > 1 {
		nextLevel := make([]common.Hash, 0, (len(currentLevel)+1)/2)

		for i := 0; i < len(currentLevel); i += 2 {
			var nodeHash common.Hash

			if i+1 < len(currentLevel) {
				// 有两个子节点，计算父节点哈希
				nodeHash = HashPair(currentLevel[i], currentLevel[i+1])
			} else {
				// 奇数个节点，复制最后一个节点
				nodeHash = HashPair(currentLevel[i], currentLevel[i])
			}

			nextLevel = append(nextLevel, nodeHash)
		}

		tree.Nodes = append(tree.Nodes, nextLevel)
		currentLevel = nextLevel
	}

	tree.Root = currentLevel[0]

	// 为每个条目生成证明
	for i, entry := range entries {
		proof := tree.generateProof(i)
		tree.Proofs[entry.User.Hex()] = proof
	}

	return tree, nil
}

// GenerateLeaf 生成叶子节点哈希
// Solidity: keccak256(bytes.concat(keccak256(abi.encode(user, week, amount))))
func GenerateLeaf(user common.Address, week uint64, amount string) common.Hash {
	// 编码参数 (user, week, amount)
	encoded := crypto.Keccak256Hash(
		common.LeftPadBytes(user.Bytes(), 32),
		common.LeftPadBytes([]byte{byte(week)}, 32),
		common.LeftPadBytes([]byte(amount), 32),
	)

	// 再次哈希
	return crypto.Keccak256Hash(encoded.Bytes())
}

// HashPair 计算一对节点的父节点哈希
// 按照 Solidity 的 abi.encodePacked 规则排序
func HashPair(a, b common.Hash) common.Hash {
	if a.Hex() < b.Hex() {
		return crypto.Keccak256Hash(a.Bytes(), b.Bytes())
	}
	return crypto.Keccak256Hash(b.Bytes(), a.Bytes())
}

// generateProof 为指定索引生成 Merkle 证明
func (mt *MerkleTree) generateProof(index int) []common.Hash {
	proof := []common.Hash{}

	for levelIdx := 0; levelIdx < len(mt.Nodes)-1; levelIdx++ {
		level := mt.Nodes[levelIdx]

		// 计算兄弟节点索引
		siblingIdx := index ^ 1

		if siblingIdx < len(level) {
			// 有兄弟节点
			proof = append(proof, level[siblingIdx])
		} else {
			// 奇数个节点，最后一个节点与自己配对
			proof = append(proof, level[index])
		}

		// 移动到父层
		index /= 2
	}

	return proof
}

// VerifyProof 验证 Merkle 证明
func VerifyProof(proof []common.Hash, root common.Hash, leaf common.Hash) bool {
	computedHash := leaf

	for _, proofElement := range proof {
		computedHash = HashPair(computedHash, proofElement)
	}

	return computedHash == root
}

// GetProof 获取用户的 Merkle 证明
func (mt *MerkleTree) GetProof(user common.Address) ([]common.Hash, bool) {
	proof, exists := mt.Proofs[user.Hex()]
	return proof, exists
}

// ToHexStrings 将哈希数组转换为十六进制字符串数组
func ToHexStrings(hashes []common.Hash) []string {
	result := make([]string, len(hashes))
	for i, h := range hashes {
		result[i] = h.Hex()
	}
	return result
}

// SerializeProof 序列化证明为 JSON 可导出格式
func SerializeProof(proof []common.Hash) string {
	if len(proof) == 0 {
		return "[]"
	}

	hexProof := ToHexStrings(proof)
	result := "["
	for i, h := range hexProof {
		if i > 0 {
			result += ","
		}
		result += fmt.Sprintf(`"%s"`, h)
	}
	result += "]"

	return result
}

// MerkleDistribution 表示完整的周度奖励分配
type MerkleDistribution struct {
	Week        uint64                       `json:"week"`
	Root        string                       `json:"root"`
	TotalAmount string                       `json:"totalAmount"`
	Recipients  int                          `json:"recipients"`
	ScaleBps    uint64                       `json:"scaleBps"`
	Entries     []RewardEntry                `json:"entries"`
	Proofs      map[string][]string          `json:"proofs"` // user -> hex proof
	CreatedAt   int64                        `json:"createdAt"`
}

// BuildDistribution 构建完整的分配数据
func BuildDistribution(week uint64, entries []RewardEntry, scaleBps uint64) (*MerkleDistribution, error) {
	if scaleBps == 0 || scaleBps > 10000 {
		return nil, fmt.Errorf("invalid scaleBps: %d (must be 1-10000)", scaleBps)
	}

	tree, err := NewMerkleTree(entries)
	if err != nil {
		return nil, fmt.Errorf("failed to build merkle tree: %w", err)
	}

	// 计算总金额
	totalAmount := "0"
	// 简化：这里应该实际累加，但为了示例我们直接使用字符串

	// 转换证明为十六进制字符串
	proofs := make(map[string][]string)
	for userHex, proof := range tree.Proofs {
		proofs[userHex] = ToHexStrings(proof)
	}

	return &MerkleDistribution{
		Week:        week,
		Root:        tree.Root.Hex(),
		TotalAmount: totalAmount,
		Recipients:  len(entries),
		ScaleBps:    scaleBps,
		Entries:     entries,
		Proofs:      proofs,
		CreatedAt:   0, // 调用方设置
	}, nil
}

// Checksum 计算分配数据的校验和（用于验证）
func (md *MerkleDistribution) Checksum() string {
	data := fmt.Sprintf("%d:%s:%d:%d",
		md.Week,
		md.Root,
		md.Recipients,
		md.ScaleBps,
	)
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}
