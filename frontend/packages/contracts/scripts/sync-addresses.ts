#!/usr/bin/env node

/**
 * 从合约部署文件同步地址到 .env.local
 *
 * 用法:
 *   npx ts-node scripts/sync-addresses.ts
 *   或
 *   pnpm sync-addresses
 *
 * 输出:
 *   - 更新 frontend/.env.local 中的合约地址
 *   - 打印环境变量配置（可手动复制）
 */

import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

// ES Module 兼容的 __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const CONTRACTS_DEPLOYMENT_PATH = path.resolve(__dirname, '../../../../contracts/deployments/localhost_v3.json');
const ENV_LOCAL_PATH = path.resolve(__dirname, '../../../.env.local');
const ADDRESSES_LOCAL_PATH = path.resolve(__dirname, '../src/addresses.local.ts');

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

  // 生成环境变量内容
  const envContent = `# 本地开发环境配置
# 使用: pnpm dev
# 自动生成时间: ${new Date().toISOString().split('T')[0]}

# 本地 Anvil RPC
ANVIL_RPC_URL=http://localhost:8545

# 本地 Graph Node
GRAPH_NODE_URL=http://localhost:8010/subgraphs/name/pitchone-sportsbook

# ============================================================================
# 合约地址配置（从 contracts/deployments/localhost_v3.json 同步）
# 每个环境（本地/服务器）需要配置各自的地址
# ============================================================================

# 核心合约
NEXT_PUBLIC_FACTORY_ADDRESS=${deploymentJson.contracts.factory}
NEXT_PUBLIC_VAULT_ADDRESS=${deploymentJson.contracts.liquidityVault}
NEXT_PUBLIC_BETTING_ROUTER_ADDRESS=${deploymentJson.contracts.bettingRouter}
NEXT_PUBLIC_FEE_ROUTER_ADDRESS=${deploymentJson.contracts.feeRouter}
NEXT_PUBLIC_REFERRAL_REGISTRY_ADDRESS=${deploymentJson.contracts.referralRegistry}
NEXT_PUBLIC_PARAM_CONTROLLER_ADDRESS=${deploymentJson.contracts.paramController}
NEXT_PUBLIC_USDC_ADDRESS=${deploymentJson.contracts.usdc}
NEXT_PUBLIC_MARKET_IMPLEMENTATION_ADDRESS=${deploymentJson.contracts.marketImplementation}

# 定价策略
NEXT_PUBLIC_STRATEGY_CPMM_ADDRESS=${deploymentJson.strategies.cpmm}
NEXT_PUBLIC_STRATEGY_LMSR_ADDRESS=${deploymentJson.strategies.lmsr}
NEXT_PUBLIC_STRATEGY_PARIMUTUEL_ADDRESS=${deploymentJson.strategies.parimutuel}

# 结果映射器
NEXT_PUBLIC_MAPPER_WDL_ADDRESS=${deploymentJson.mappers.wdl}
NEXT_PUBLIC_MAPPER_OU_ADDRESS=${deploymentJson.mappers.ou}
NEXT_PUBLIC_MAPPER_AH_ADDRESS=${deploymentJson.mappers.ah}
NEXT_PUBLIC_MAPPER_ODDEVEN_ADDRESS=${deploymentJson.mappers.oddEven}
NEXT_PUBLIC_MAPPER_SCORE_ADDRESS=${deploymentJson.mappers.score}
NEXT_PUBLIC_MAPPER_IDENTITY_ADDRESS=${deploymentJson.mappers.identity}

# 可选：客户端直连（如果不想走代理，取消注释以下配置）
# NEXT_PUBLIC_ANVIL_RPC_URL=http://localhost:8545
# NEXT_PUBLIC_SUBGRAPH_URL=http://localhost:8010/subgraphs/name/pitchone-sportsbook
`;

  // 写入 .env.local
  fs.writeFileSync(ENV_LOCAL_PATH, envContent);
  console.log('✅ 地址已同步到:', ENV_LOCAL_PATH);

  // 生成 addresses.local.ts 文件（供共享包直接使用）
  const addressesLocalContent = `// 本地合约地址配置
// 自动生成，请勿手动修改
// 生成时间: ${new Date().toISOString().split('T')[0]}
// 此文件已加入 .gitignore，不会被提交

import type { ContractAddresses, Address } from './addresses';

export const localAddresses: ContractAddresses = {
  // 核心合约
  factory: '${deploymentJson.contracts.factory}' as Address,
  vault: '${deploymentJson.contracts.liquidityVault}' as Address,
  bettingRouter: '${deploymentJson.contracts.bettingRouter}' as Address,
  feeRouter: '${deploymentJson.contracts.feeRouter}' as Address,
  referralRegistry: '${deploymentJson.contracts.referralRegistry}' as Address,
  paramController: '${deploymentJson.contracts.paramController}' as Address,
  usdc: '${deploymentJson.contracts.usdc}' as Address,
  marketImplementation: '${deploymentJson.contracts.marketImplementation}' as Address,

  // 定价策略
  strategies: {
    cpmm: '${deploymentJson.strategies.cpmm}' as Address,
    lmsr: '${deploymentJson.strategies.lmsr}' as Address,
    parimutuel: '${deploymentJson.strategies.parimutuel}' as Address,
  },

  // 结果映射器
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

  // 兼容旧代码
  get marketTemplateRegistry() {
    return this.factory;
  },
};
`;

  fs.writeFileSync(ADDRESSES_LOCAL_PATH, addressesLocalContent);
  console.log('✅ 地址已同步到:', ADDRESSES_LOCAL_PATH);

  // 打印关键地址
  console.log('\n📋 关键合约地址:');
  console.log('   Factory:', deploymentJson.contracts.factory);
  console.log('   Vault:', deploymentJson.contracts.liquidityVault);
  console.log('   Router:', deploymentJson.contracts.bettingRouter);
  console.log('   USDC:', deploymentJson.contracts.usdc);
}

main();
