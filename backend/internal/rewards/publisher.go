package rewards

import (
	"context"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Publisher 负责将 Merkle Root 发布到链上
type Publisher struct {
	client           *ethclient.Client
	distributorAddr  common.Address
	privateKey       string
	chainID          *big.Int
}

// NewPublisher 创建发布器
func NewPublisher(rpcURL string, distributorAddr common.Address, privateKey string) (*Publisher, error) {
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to RPC: %w", err)
	}

	chainID, err := client.ChainID(context.Background())
	if err != nil {
		return nil, fmt.Errorf("failed to get chain ID: %w", err)
	}

	return &Publisher{
		client:          client,
		distributorAddr: distributorAddr,
		privateKey:      privateKey,
		chainID:         chainID,
	}, nil
}

// PublishRoot 发布 Merkle Root 到 RewardsDistributor 合约
func (p *Publisher) PublishRoot(ctx context.Context, dist *MerkleDistribution) (*types.Transaction, error) {
	// 解析私钥
	privateKey, err := crypto.HexToECDSA(p.privateKey)
	if err != nil {
		return nil, fmt.Errorf("invalid private key: %w", err)
	}

	// 创建交易选项
	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, p.chainID)
	if err != nil {
		return nil, fmt.Errorf("failed to create transactor: %w", err)
	}

	// 设置 Gas 参数（可选，根据网络情况调整）
	auth.GasLimit = 200000
	auth.Context = ctx

	// 调用合约的 publishRoot 函数
	// function publishRoot(uint256 week, bytes32 merkleRoot, uint256 totalAmount, uint256 scaleBps)
	rootHash := common.HexToHash(dist.Root)
	totalAmount, ok := new(big.Int).SetString(dist.TotalAmount, 10)
	if !ok {
		return nil, fmt.Errorf("invalid total amount: %s", dist.TotalAmount)
	}

	// 构造调用数据
	// 这里简化处理，实际应该使用生成的 ABI 绑定
	// 示例：使用手动构造的调用数据
	callData := packPublishRootData(dist.Week, rootHash, totalAmount, big.NewInt(int64(dist.ScaleBps)))

	// 发送交易
	nonce, err := p.client.PendingNonceAt(ctx, auth.From)
	if err != nil {
		return nil, fmt.Errorf("failed to get nonce: %w", err)
	}

	gasPrice, err := p.client.SuggestGasPrice(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get gas price: %w", err)
	}

	tx := types.NewTransaction(
		nonce,
		p.distributorAddr,
		big.NewInt(0), // 不发送 ETH
		auth.GasLimit,
		gasPrice,
		callData,
	)

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(p.chainID), privateKey)
	if err != nil {
		return nil, fmt.Errorf("failed to sign transaction: %w", err)
	}

	if err := p.client.SendTransaction(ctx, signedTx); err != nil {
		return nil, fmt.Errorf("failed to send transaction: %w", err)
	}

	return signedTx, nil
}

// packPublishRootData 打包 publishRoot 调用数据
// function publishRoot(uint256 week, bytes32 merkleRoot, uint256 totalAmount, uint256 scaleBps)
func packPublishRootData(week uint64, root common.Hash, totalAmount, scaleBps *big.Int) []byte {
	// 函数选择器: keccak256("publishRoot(uint256,bytes32,uint256,uint256)")[:4]
	// 简化处理，这里硬编码（实际应该从 ABI 生成）
	selector := crypto.Keccak256([]byte("publishRoot(uint256,bytes32,uint256,uint256)"))[:4]

	// 编码参数
	data := make([]byte, 4+32*4) // 4 bytes selector + 4 * 32 bytes params
	copy(data[0:4], selector)

	// week (uint256)
	weekBig := new(big.Int).SetUint64(week)
	copy(data[4:36], common.LeftPadBytes(weekBig.Bytes(), 32))

	// merkleRoot (bytes32)
	copy(data[36:68], root.Bytes())

	// totalAmount (uint256)
	copy(data[68:100], common.LeftPadBytes(totalAmount.Bytes(), 32))

	// scaleBps (uint256)
	copy(data[100:132], common.LeftPadBytes(scaleBps.Bytes(), 32))

	return data
}

// WaitForConfirmation 等待交易确认
func (p *Publisher) WaitForConfirmation(ctx context.Context, tx *types.Transaction, confirmations uint64) (*types.Receipt, error) {
	receipt, err := bind.WaitMined(ctx, p.client, tx)
	if err != nil {
		return nil, fmt.Errorf("failed to wait for transaction: %w", err)
	}

	if receipt.Status != types.ReceiptStatusSuccessful {
		return nil, fmt.Errorf("transaction failed: %s", tx.Hash().Hex())
	}

	// 等待额外确认
	if confirmations > 1 {
		currentBlock := receipt.BlockNumber.Uint64()
		targetBlock := currentBlock + confirmations - 1

		for {
			select {
			case <-ctx.Done():
				return nil, ctx.Err()
			default:
				latestBlock, err := p.client.BlockNumber(ctx)
				if err != nil {
					return nil, fmt.Errorf("failed to get latest block: %w", err)
				}

				if latestBlock >= targetBlock {
					return receipt, nil
				}

				// 等待一段时间后重试
				select {
				case <-ctx.Done():
					return nil, ctx.Err()
				case <-time.After(5 * time.Second):
					// 继续等待
				}
			}
		}
	}

	return receipt, nil
}

// GetPublishedRoot 从合约查询已发布的 Root
func (p *Publisher) GetPublishedRoot(ctx context.Context, week uint64) (common.Hash, error) {
	// 调用合约的 weeklyRewards(week) 函数
	// function weeklyRewards(uint256) returns (bytes32 merkleRoot, ...)

	// 构造调用数据
	selector := crypto.Keccak256([]byte("weeklyRewards(uint256)"))[:4]
	data := make([]byte, 4+32)
	copy(data[0:4], selector)
	weekBig := new(big.Int).SetUint64(week)
	copy(data[4:36], common.LeftPadBytes(weekBig.Bytes(), 32))

	// 调用合约
	msg := ethereum.CallMsg{
		To:   &p.distributorAddr,
		Data: data,
	}

	result, err := p.client.CallContract(ctx, msg, nil)
	if err != nil {
		return common.Hash{}, fmt.Errorf("failed to call contract: %w", err)
	}

	if len(result) < 32 {
		return common.Hash{}, fmt.Errorf("invalid response length: %d", len(result))
	}

	// 解析 merkleRoot (第一个返回值)
	return common.BytesToHash(result[0:32]), nil
}

// Close 关闭连接
func (p *Publisher) Close() {
	if p.client != nil {
		p.client.Close()
	}
}
