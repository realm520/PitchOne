package testutil

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// DeployedContracts holds addresses of deployed test contracts
type DeployedContracts struct {
	MarketAddr  common.Address
	OracleAddr  common.Address
	USDCAddr    common.Address
	FeeRouter   common.Address
	CPMMAddr    common.Address
}

// DeployMarketViaScript deploys a new WDL market using the Foundry script
// kickoffTime is the Unix timestamp when the market should be locked
func DeployMarketViaScript(kickoffTime int64) (marketAddr, oracleAddr common.Address, err error) {
	// Find the contracts directory
	contractsDir, err := findContractsDir()
	if err != nil {
		return common.Address{}, common.Address{}, fmt.Errorf("failed to find contracts directory: %w", err)
	}

	// Prepare the forge script command
	cmd := exec.Command(
		"forge", "script",
		"script/DeployNewMarket.s.sol",
		"--rpc-url", "http://localhost:8545",
		"--broadcast",
		"--silent",
	)
	cmd.Dir = contractsDir
	cmd.Env = append(os.Environ(), fmt.Sprintf("KICKOFF_TIME=%d", kickoffTime))

	// Capture output
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// Run the command
	if err := cmd.Run(); err != nil {
		return common.Address{}, common.Address{}, fmt.Errorf("forge script failed: %w\nStderr: %s", err, stderr.String())
	}

	output := stdout.String()

	// Parse market address from output
	marketAddr, err = parseAddressFromOutput(output, "Market Address:")
	if err != nil {
		// Try alternative pattern
		marketAddr, err = parseAddressFromOutput(output, "Market:")
		if err != nil {
			return common.Address{}, common.Address{}, fmt.Errorf("failed to parse market address from output: %w\nOutput: %s", err, output)
		}
	}

	// For now, use a placeholder oracle address (we'll use MockOracle from the deployment)
	// In a real test, we'd parse this from the output too
	oracleAddr = common.HexToAddress("0x2222222222222222222222222222222222222222")

	return marketAddr, oracleAddr, nil
}

// GetMarketStatusOnChain returns the status of a market from the blockchain
// Status: 0=Open, 1=Locked, 2=Resolved, 3=Finalized
func GetMarketStatusOnChain(client *ethclient.Client, marketAddr common.Address) (uint8, error) {
	// Call the status() function (selector: 0x200d2ed2)
	callData := common.Hex2Bytes("200d2ed2")

	msg := ethereum.CallMsg{
		To:   &marketAddr,
		Data: callData,
	}

	result, err := client.CallContract(context.Background(), msg, nil)

	if err != nil {
		return 0, fmt.Errorf("failed to call status(): %w", err)
	}

	if len(result) == 0 {
		return 0, fmt.Errorf("empty result from status() call")
	}

	// Status is returned as uint8, but padded to 32 bytes
	return uint8(result[31]), nil
}

// GetOracleResult retrieves the result from the oracle for a specific market
func GetOracleResult(client *ethclient.Client, oracleAddr, marketAddr common.Address) (bool, error) {
	// Call the hasResult(bytes32) function
	// For now, we'll implement this when needed for settle tests
	return false, fmt.Errorf("not implemented yet")
}

// SubmitOracleResult submits a match result to the oracle (simulates external oracle)
func SubmitOracleResult(client *ethclient.Client, oracleAddr common.Address, marketAddr common.Address, homeGoals, awayGoals int) error {
	// This would call the oracle's proposeResult() function
	// For now, we'll implement this when needed for settle tests
	return fmt.Errorf("not implemented yet")
}

// findContractsDir finds the contracts directory by walking up from the current directory
func findContractsDir() (string, error) {
	// Start from current working directory
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}

	// Walk up until we find a directory with "contracts" subdirectory
	for {
		contractsPath := filepath.Join(dir, "contracts")
		if _, err := os.Stat(contractsPath); err == nil {
			return contractsPath, nil
		}

		// Move up one directory
		parent := filepath.Dir(dir)
		if parent == dir {
			// Reached the root
			break
		}
		dir = parent
	}

	// Try relative path from backend directory
	contractsPath := filepath.Join("..", "..", "contracts")
	if _, err := os.Stat(contractsPath); err == nil {
		absPath, _ := filepath.Abs(contractsPath)
		return absPath, nil
	}

	return "", fmt.Errorf("contracts directory not found")
}

// parseAddressFromOutput extracts an Ethereum address from script output
// It looks for a line containing the prefix and extracts the address after it
func parseAddressFromOutput(output, prefix string) (common.Address, error) {
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if strings.Contains(line, prefix) {
			// Extract the address using regex
			re := regexp.MustCompile(`0x[a-fA-F0-9]{40}`)
			match := re.FindString(line)
			if match != "" {
				return common.HexToAddress(match), nil
			}
		}
	}
	return common.Address{}, fmt.Errorf("address not found with prefix: %s", prefix)
}

// GetDefaultContracts returns the default contract addresses (from阶段 3.7)
func GetDefaultContracts() *DeployedContracts {
	return &DeployedContracts{
		USDCAddr:  common.HexToAddress("0x36C02dA8a0983159322a80FFE9F24b1acfF8B570"),
		FeeRouter: common.HexToAddress("0x4c5859f0F772848b2D91F1D83E2Fe57935348029"),
		CPMMAddr:  common.HexToAddress("0x1291Be112d480055DaFd8a610b7d1e203891C274"),
	}
}

// WaitForTransaction waits for a transaction to be mined and returns the receipt status
func WaitForTransaction(client *ethclient.Client, txHash common.Hash) (bool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return false, fmt.Errorf("timeout waiting for transaction %s", txHash.Hex())
		case <-ticker.C:
			receipt, err := client.TransactionReceipt(ctx, txHash)
			if err != nil {
				// Transaction not mined yet, continue waiting
				continue
			}
			return receipt.Status == 1, nil
		}
	}
}
