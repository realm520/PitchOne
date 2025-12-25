#!/usr/bin/env node

/**
 * 从合约部署文件同步地址到前端
 *
 * 用法:
 *   npx ts-node scripts/sync-addresses.ts
 *   或
 *   pnpm sync-addresses
 */

import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

// ES Module 兼容的 __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const CONTRACTS_DEPLOYMENT_PATH = path.resolve(__dirname, '../../../../contracts/deployments/localhost_v3.json');
const ADDRESSES_OUTPUT_PATH = path.resolve(__dirname, '../src/addresses/index.ts');

interface DeploymentJson {
  chainId: number;
  contracts: {
    bettingRouter: string;
    factory: string;
    feeRouter: string;
    liquidityVault: string;
    marketImplementation: string;
    paramController: string;
    referralRegistry: string;
    usdc: string;
  };
  deployer: string;
  mappers: {
    ah: string;
    identity: string;
    oddEven: string;
    ou: string;
    score: string;
    wdl: string;
  };
  strategies: {
    cpmm: string;
    lmsr: string;
    parimutuel: string;
  };
  templateIds: {
    ah: string;
    firstGoalscorer: string;
    oddEven: string;
    ou: string;
    score: string;
    scorePari: string;
    wdl: string;
    wdlPari: string;
  };
}

function main() {
  // 检查部署文件是否存在
  if (!fs.existsSync(CONTRACTS_DEPLOYMENT_PATH)) {
    console.error(`❌ 部署文件不存在: ${CONTRACTS_DEPLOYMENT_PATH}`);
    console.error('请先运行合约部署脚本');
    process.exit(1);
  }

  // 读取部署文件
  const deploymentJson: DeploymentJson = JSON.parse(
    fs.readFileSync(CONTRACTS_DEPLOYMENT_PATH, 'utf-8')
  );

  console.log('📦 读取部署文件:', CONTRACTS_DEPLOYMENT_PATH);
  console.log('   Chain ID:', deploymentJson.chainId);
  console.log('   Deployer:', deploymentJson.deployer);

  // 生成 TypeScript 代码
  const timestamp = new Date().toISOString().split('T')[0];
  const content = `import type { Address, ContractAddresses } from '../index';

// Anvil 本地测试链地址 (V3 架构)
// 自动生成时间: ${timestamp} (来源: contracts/deployments/localhost_v3.json)
// 注意：每次 Anvil 重启后需要重新部署合约，地址会保持一致（确定性部署）
export const ANVIL_ADDRESSES: ContractAddresses = {
  // V3 核心合约
  factory: '${deploymentJson.contracts.factory}' as Address,
  vault: '${deploymentJson.contracts.liquidityVault}' as Address,
  bettingRouter: '${deploymentJson.contracts.bettingRouter}' as Address,
  feeRouter: '${deploymentJson.contracts.feeRouter}' as Address,
  referralRegistry: '${deploymentJson.contracts.referralRegistry}' as Address,
  paramController: '${deploymentJson.contracts.paramController}' as Address,
  usdc: '${deploymentJson.contracts.usdc}' as Address,

  // Market Implementation (用于 Clone)
  marketImplementation: '${deploymentJson.contracts.marketImplementation}' as Address,

  // V3 定价策略
  strategies: {
    cpmm: '${deploymentJson.strategies.cpmm}' as Address,
    lmsr: '${deploymentJson.strategies.lmsr}' as Address,
    parimutuel: '${deploymentJson.strategies.parimutuel}' as Address,
  },

  // V3 结果映射器
  mappers: {
    wdl: '${deploymentJson.mappers.wdl}' as Address,
    ou: '${deploymentJson.mappers.ou}' as Address,
    ah: '${deploymentJson.mappers.ah}' as Address,
    oddEven: '${deploymentJson.mappers.oddEven}' as Address,
    score: '${deploymentJson.mappers.score}' as Address,
    identity: '${deploymentJson.mappers.identity}' as Address,
  },

  // 模板 ID
  templateIds: {
    wdl: '${deploymentJson.templateIds.wdl}' as Address,
    wdlPari: '${deploymentJson.templateIds.wdlPari}' as Address,
    ou: '${deploymentJson.templateIds.ou}' as Address,
    ah: '${deploymentJson.templateIds.ah}' as Address,
    oddEven: '${deploymentJson.templateIds.oddEven}' as Address,
    score: '${deploymentJson.templateIds.score}' as Address,
    scorePari: '${deploymentJson.templateIds.scorePari}' as Address,
    firstGoalscorer: '${deploymentJson.templateIds.firstGoalscorer}' as Address,
  },

  // 运营合约（待部署）
  basket: '0x0000000000000000000000000000000000000000' as Address,
  correlationGuard: '0x0000000000000000000000000000000000000000' as Address,
  rewardsDistributor: '0x0000000000000000000000000000000000000000' as Address,

  // 兼容旧代码
  marketTemplateRegistry: '${deploymentJson.contracts.factory}' as Address,
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

  // 写入文件
  fs.writeFileSync(ADDRESSES_OUTPUT_PATH, content);
  console.log('✅ 地址已同步到:', ADDRESSES_OUTPUT_PATH);

  // 打印关键地址
  console.log('\n📋 关键合约地址:');
  console.log('   Factory:', deploymentJson.contracts.factory);
  console.log('   Vault:', deploymentJson.contracts.liquidityVault);
  console.log('   Router:', deploymentJson.contracts.bettingRouter);
  console.log('   USDC:', deploymentJson.contracts.usdc);
}

main();
