package keeper

import (
	"context"
	"crypto/ecdsa"
	"errors"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Web3Client handles Ethereum blockchain interactions
type Web3Client struct {
	client     *ethclient.Client
	privateKey *ecdsa.PrivateKey
	account    common.Address
	chainID    *big.Int
}

// NewWeb3Client creates a new Web3 client
func NewWeb3Client(rpcURL string, privateKeyHex string, chainID *big.Int) (*Web3Client, error) {
	// Validate inputs
	if rpcURL == "" {
		return nil, errors.New("RPC URL is required")
	}

	if privateKeyHex == "" {
		return nil, errors.New("private key is required")
	}

	// Connect to Ethereum node
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Ethereum node: %w", err)
	}

	// Parse private key
	privateKey, err := crypto.HexToECDSA(stripHexPrefix(privateKeyHex))
	if err != nil {
		return nil, fmt.Errorf("invalid private key: %w", err)
	}

	// Derive public key and address
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return nil, errors.New("failed to cast public key to ECDSA")
	}

	account := crypto.PubkeyToAddress(*publicKeyECDSA)

	return &Web3Client{
		client:     client,
		privateKey: privateKey,
		account:    account,
		chainID:    chainID,
	}, nil
}

// GetAccount returns the keeper's Ethereum address
func (w *Web3Client) GetAccount() common.Address {
	return w.account
}

// GetBalance returns the balance of an address
func (w *Web3Client) GetBalance(ctx context.Context, address common.Address) (*big.Int, error) {
	balance, err := w.client.BalanceAt(ctx, address, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get balance: %w", err)
	}
	return balance, nil
}

// GetBlockNumber returns the current block number
func (w *Web3Client) GetBlockNumber(ctx context.Context) (*big.Int, error) {
	blockNumber, err := w.client.BlockNumber(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get block number: %w", err)
	}
	return big.NewInt(int64(blockNumber)), nil
}

// GetGasPrice returns the current gas price
func (w *Web3Client) GetGasPrice(ctx context.Context) (*big.Int, error) {
	gasPrice, err := w.client.SuggestGasPrice(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get gas price: %w", err)
	}
	return gasPrice, nil
}

// CalculateGasPrice returns the gas price, capped at maxGasPrice
func (w *Web3Client) CalculateGasPrice(ctx context.Context, maxGasPrice *big.Int) (*big.Int, error) {
	currentGasPrice, err := w.GetGasPrice(ctx)
	if err != nil {
		return nil, err
	}

	// Cap gas price
	if currentGasPrice.Cmp(maxGasPrice) > 0 {
		return maxGasPrice, nil
	}

	return currentGasPrice, nil
}

// EstimateGas estimates the gas required for a transaction
func (w *Web3Client) EstimateGas(ctx context.Context, to common.Address, value *big.Int, data []byte) (uint64, error) {
	msg := ethereum.CallMsg{
		From:  w.account,
		To:    &to,
		Value: value,
		Data:  data,
	}

	gasLimit, err := w.client.EstimateGas(ctx, msg)
	if err != nil {
		return 0, fmt.Errorf("failed to estimate gas: %w", err)
	}

	return gasLimit, nil
}

// GetNonce returns the next nonce for the account
func (w *Web3Client) GetNonce(ctx context.Context, address common.Address) (uint64, error) {
	nonce, err := w.client.PendingNonceAt(ctx, address)
	if err != nil {
		return 0, fmt.Errorf("failed to get nonce: %w", err)
	}
	return nonce, nil
}

// SendTransaction sends a signed transaction to the network
func (w *Web3Client) SendTransaction(ctx context.Context, tx *types.Transaction) error {
	err := w.client.SendTransaction(ctx, tx)
	if err != nil {
		return fmt.Errorf("failed to send transaction: %w", err)
	}
	return nil
}

// WaitForTransaction waits for a transaction to be mined
func (w *Web3Client) WaitForTransaction(ctx context.Context, txHash common.Hash) (*types.Receipt, error) {
	receipt, err := w.client.TransactionReceipt(ctx, txHash)
	if err != nil {
		return nil, fmt.Errorf("failed to get transaction receipt: %w", err)
	}
	return receipt, nil
}

// SignTransaction signs a transaction with the keeper's private key
func (w *Web3Client) SignTransaction(tx *types.Transaction) (*types.Transaction, error) {
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(w.chainID), w.privateKey)
	if err != nil {
		return nil, fmt.Errorf("failed to sign transaction: %w", err)
	}
	return signedTx, nil
}

// Close closes the Ethereum client connection
func (w *Web3Client) Close() {
	if w.client != nil {
		w.client.Close()
	}
}

// stripHexPrefix removes "0x" prefix from hex string
func stripHexPrefix(hexStr string) string {
	if len(hexStr) >= 2 && hexStr[0:2] == "0x" {
		return hexStr[2:]
	}
	return hexStr
}
