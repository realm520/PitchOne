#!/usr/bin/env node
/**
 * 前端合约地址自动同步脚本 (V3)
 * 从 deployments/localhost_v3.json 读取合约地址并更新 frontend 配置
 *
 * 使用方法:
 *   node scripts/update-addresses.js ../../contracts/deployments/localhost_v3.json
 */

const fs = require('fs');
const path = require('path');

// 读取命令行参数
const deploymentFile = process.argv[2];
if (!deploymentFile) {
  console.error('❌ Usage: node update-addresses.js <deployment-file>');
  console.error('   Example: node update-addresses.js ../../../contracts/deployments/localhost_v3.json');
  process.exit(1);
}

// 解析文件路径（支持绝对路径和相对路径）
const deploymentPath = path.isAbsolute(deploymentFile)
  ? deploymentFile
  : path.resolve(process.cwd(), deploymentFile);

if (!fs.existsSync(deploymentPath)) {
  console.error(`❌ Deployment file not found: ${deploymentPath}`);
  process.exit(1);
}

// 读取部署数据
const deployment = JSON.parse(fs.readFileSync(deploymentPath, 'utf-8'));

console.log('\n📝 Updating Frontend contract addresses (V3)...');
console.log(`  Network: ${deployment.network}`);
console.log(`  ChainId: ${deployment.chainId}`);
console.log(`  Deployer: ${deployment.deployer}`);

// 生成新的地址配置文件内容
const timestamp = new Date().toISOString().split('T')[0];
const addressesContent = `import type { Address, ContractAddresses } from '../index';

// Anvil 本地测试链地址 (V3 架构)
// 部署时间: ${timestamp} (自动生成)
// 来源: contracts/deployments/localhost_v3.json
export const ANVIL_ADDRESSES: ContractAddresses = {
  // V3 核心合约
  factory: '${deployment.contracts.factory}' as Address,
  vault: '${deployment.contracts.liquidityVault}' as Address,
  bettingRouter: '${deployment.contracts.bettingRouter}' as Address,
  feeRouter: '${deployment.contracts.feeRouter}' as Address,
  referralRegistry: '${deployment.contracts.referralRegistry}' as Address,
  paramController: '${deployment.contracts.paramController}' as Address,
  usdc: '${deployment.contracts.usdc}' as Address,

  // Market Implementation (用于 Clone)
  marketImplementation: '${deployment.contracts.marketImplementation}' as Address,

  // V3 定价策略
  strategies: {
    cpmm: '${deployment.strategies.cpmm}' as Address,
    lmsr: '${deployment.strategies.lmsr}' as Address,
    parimutuel: '${deployment.strategies.parimutuel}' as Address,
  },

  // V3 结果映射器
  mappers: {
    wdl: '${deployment.mappers.wdl}' as Address,
    ou: '${deployment.mappers.ou}' as Address,
    ah: '${deployment.mappers.ah}' as Address,
    oddEven: '${deployment.mappers.oddEven}' as Address,
    score: '${deployment.mappers.score}' as Address,
    identity: '${deployment.mappers.identity}' as Address,
  },

  // 模板 ID
  templateIds: {
    wdl: '${deployment.templateIds.wdl}' as Address,
    wdlPari: '${deployment.templateIds.wdlPari}' as Address,
    ou: '${deployment.templateIds.ou}' as Address,
    ah: '${deployment.templateIds.ah}' as Address,
    oddEven: '${deployment.templateIds.oddEven}' as Address,
    score: '${deployment.templateIds.score}' as Address,
    scorePari: '${deployment.templateIds.scorePari}' as Address,
    firstGoalscorer: '${deployment.templateIds.firstGoalscorer}' as Address,
  },

  // 运营合约（待部署）
  basket: '0x0000000000000000000000000000000000000000' as Address,
  correlationGuard: '0x0000000000000000000000000000000000000000' as Address,
  rewardsDistributor: '0x0000000000000000000000000000000000000000' as Address,

  // 兼容旧代码
  marketTemplateRegistry: '${deployment.contracts.factory}' as Address,
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
console.log('\n📋 Core Contracts:');
console.log(`  Factory:         ${deployment.contracts.factory}`);
console.log(`  Vault:           ${deployment.contracts.liquidityVault}`);
console.log(`  BettingRouter:   ${deployment.contracts.bettingRouter}`);
console.log(`  FeeRouter:       ${deployment.contracts.feeRouter}`);
console.log(`  ParamController: ${deployment.contracts.paramController}`);
console.log(`  USDC:            ${deployment.contracts.usdc}`);
console.log('\n📋 Strategies:');
console.log(`  CPMM:            ${deployment.strategies.cpmm}`);
console.log(`  LMSR:            ${deployment.strategies.lmsr}`);
console.log(`  Parimutuel:      ${deployment.strategies.parimutuel}`);
console.log('\n📋 Mappers:');
console.log(`  WDL:             ${deployment.mappers.wdl}`);
console.log(`  OU:              ${deployment.mappers.ou}`);
console.log(`  AH:              ${deployment.mappers.ah}`);
console.log(`  OddEven:         ${deployment.mappers.oddEven}`);
console.log(`  Score:           ${deployment.mappers.score}`);
console.log(`  Identity:        ${deployment.mappers.identity}`);
console.log(`\n📁 Output: ${outputPath}\n`);
