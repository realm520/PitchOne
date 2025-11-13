#!/usr/bin/env node
/**
 * 前端合约地址自动同步脚本
 * 从 deployments/localhost.json 读取合约地址并更新 frontend 配置
 *
 * 使用方法:
 *   node scripts/update-addresses.js ../../contracts/deployments/localhost.json
 */

const fs = require('fs');
const path = require('path');

// 读取命令行参数
const deploymentFile = process.argv[2];
if (!deploymentFile) {
  console.error('❌ Usage: node update-addresses.js <deployment-file>');
  console.error('   Example: node update-addresses.js ../../contracts/deployments/localhost.json');
  process.exit(1);
}

// 检查文件是否存在
const deploymentPath = path.resolve(__dirname, deploymentFile);
if (!fs.existsSync(deploymentPath)) {
  console.error(`❌ Deployment file not found: ${deploymentPath}`);
  process.exit(1);
}

// 读取部署数据
const deployment = JSON.parse(fs.readFileSync(deploymentPath, 'utf-8'));

console.log('\n📝 Updating Frontend contract addresses...');
console.log(`  Network: ${deployment.network}`);
console.log(`  ChainId: ${deployment.chainId}`);
console.log(`  Timestamp: ${deployment.timestamp}`);

// 生成新的地址配置文件内容
const timestamp = new Date().toISOString().split('T')[0];
const addressesContent = `import type { Address, ContractAddresses } from '../index';

// Anvil 本地测试链地址
// 部署时间: ${timestamp} (自动生成)
// 来源: contracts/script/Deploy.s.sol 最新部署输出
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '${deployment.contracts.factory}', // MarketFactory_v2
  vault: '${deployment.contracts.vault}',               // LiquidityVault
  usdc: '${deployment.contracts.usdc}',               // MockUSDC
  feeRouter: '${deployment.contracts.feeRouter}',           // FeeRouter
  simpleCPMM: '${deployment.contracts.cpmm}',          // SimpleCPMM
  referralRegistry: '${deployment.contracts.referralRegistry}',   // ReferralRegistry
  basket: '0x0000000000000000000000000000000000000000',            // 待部署
  correlationGuard: '0x0000000000000000000000000000000000000000',   // 待部署
  rewardsDistributor: '0x0000000000000000000000000000000000000000', // 待部署
};

// Sepolia 测试网地址 (待部署)
export const SEPOLIA_ADDRESSES: Partial<ContractAddresses> = {
  // TODO: 部署后填写
};

// 根据 chainId 获取地址
export function getContractAddresses(chainId: number): ContractAddresses {
  switch (chainId) {
    case 31337: // Anvil
      return ANVIL_ADDRESSES;
    case 11155111: // Sepolia
      return SEPOLIA_ADDRESSES as ContractAddresses;
    default:
      throw new Error(\`Unsupported chain ID: \${chainId}\`);
  }
}
`;

// 写入配置文件
const outputPath = path.join(__dirname, '../src/addresses/index.ts');
fs.writeFileSync(outputPath, addressesContent);

console.log('\n✅ Frontend addresses updated successfully!');
console.log(`  USDC: ${deployment.contracts.usdc}`);
console.log(`  Factory: ${deployment.contracts.factory}`);
console.log(`  Vault: ${deployment.contracts.vault}`);
console.log(`  SimpleCPMM: ${deployment.contracts.cpmm}`);
console.log(`  FeeRouter: ${deployment.contracts.feeRouter}`);
console.log(`  ReferralRegistry: ${deployment.contracts.referralRegistry}`);
console.log(`  Output: ${outputPath}\n`);
