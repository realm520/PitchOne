package testutil

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/ethclient"
)

// IncreaseTime increases the EVM time by the specified number of seconds
// Note: This only affects the timestamp of the next block, you need to mine a block for it to take effect
func IncreaseTime(client *ethclient.Client, seconds int64) error {
	var result interface{}
	err := client.Client().Call(&result, "evm_increaseTime", fmt.Sprintf("0x%x", seconds))
	if err != nil {
		return fmt.Errorf("failed to increase time: %w", err)
	}
	return nil
}

// MineBlock mines a single block, advancing the blockchain by one block
func MineBlock(client *ethclient.Client) error {
	var result interface{}
	err := client.Client().Call(&result, "evm_mine")
	if err != nil {
		return fmt.Errorf("failed to mine block: %w", err)
	}
	return nil
}

// MineBlocks mines multiple blocks
func MineBlocks(client *ethclient.Client, count int) error {
	for i := 0; i < count; i++ {
		if err := MineBlock(client); err != nil {
			return fmt.Errorf("failed to mine block %d: %w", i+1, err)
		}
	}
	return nil
}

// GetBlockTime returns the timestamp of the latest block
func GetBlockTime(client *ethclient.Client) (uint64, error) {
	header, err := client.HeaderByNumber(context.Background(), nil)
	if err != nil {
		return 0, fmt.Errorf("failed to get block header: %w", err)
	}
	return header.Time, nil
}

// GetBlockNumber returns the current block number
func GetBlockNumber(client *ethclient.Client) (uint64, error) {
	blockNumber, err := client.BlockNumber(context.Background())
	if err != nil {
		return 0, fmt.Errorf("failed to get block number: %w", err)
	}
	return blockNumber, nil
}

// AdvanceToTime advances the EVM time to the target time
// If the current time is already past the target, this function does nothing
func AdvanceToTime(client *ethclient.Client, targetTime uint64) error {
	currentTime, err := GetBlockTime(client)
	if err != nil {
		return err
	}

	if currentTime >= targetTime {
		// Already at or past the target time, just mine a block to ensure consistency
		return MineBlock(client)
	}

	delta := targetTime - currentTime

	// Increase time
	if err := IncreaseTime(client, int64(delta)); err != nil {
		return err
	}

	// Mine a block to apply the time change
	if err := MineBlock(client); err != nil {
		return err
	}

	return nil
}

// AdvanceTimeAndMine is a convenience function that increases time and mines a block in one call
func AdvanceTimeAndMine(client *ethclient.Client, seconds int64) error {
	if err := IncreaseTime(client, seconds); err != nil {
		return err
	}
	return MineBlock(client)
}

// SetNextBlockTimestamp sets the timestamp of the next block (Anvil-specific)
func SetNextBlockTimestamp(client *ethclient.Client, timestamp uint64) error {
	var result interface{}
	err := client.Client().Call(&result, "evm_setNextBlockTimestamp", fmt.Sprintf("0x%x", timestamp))
	if err != nil {
		return fmt.Errorf("failed to set next block timestamp: %w", err)
	}
	return nil
}

// Snapshot creates a snapshot of the current blockchain state and returns the snapshot ID
func Snapshot(client *ethclient.Client) (*big.Int, error) {
	var result string
	err := client.Client().Call(&result, "evm_snapshot")
	if err != nil {
		return nil, fmt.Errorf("failed to create snapshot: %w", err)
	}

	snapshotID := new(big.Int)
	snapshotID.SetString(result[2:], 16) // Remove "0x" prefix
	return snapshotID, nil
}

// Revert reverts the blockchain to a previous snapshot
func Revert(client *ethclient.Client, snapshotID *big.Int) error {
	var result bool
	err := client.Client().Call(&result, "evm_revert", fmt.Sprintf("0x%x", snapshotID))
	if err != nil {
		return fmt.Errorf("failed to revert to snapshot: %w", err)
	}
	if !result {
		return fmt.Errorf("revert failed: snapshot not found")
	}
	return nil
}
