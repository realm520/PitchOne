import type { Address, ContractAddresses } from '../index';

// ============================================================================
// Anvil 本地测试链地址
// 部署时间: 2025-11-20 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// ============================================================================
// Anvil 本地测试链地址
// 部署时间: 2025-11-21 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// Anvil 本地测试链地址
// 部署时间: 2025-11-21 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// Anvil 本地测试链地址
// 部署时间: 2025-11-22 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// Anvil 本地测试链地址
// 部署时间: 2025-11-22 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '0x08677Af0A7F54fE2a190bb1F75DE682fe596317e', // MarketFactory_v2
  vault: '0x02121128f1Ed0AdA5Df3a87f42752fcE4Ad63e59',               // LiquidityVault (deprecated)
  usdc: '0x6858dF5365ffCbe31b5FE68D9E6ebB81321F7F86',               // MockUSDC
  feeRouter: '0x1E53bea57Dd5dDa7bFf1a1180a2f64a5c9e222f5',           // FeeRouter
  simpleCPMM: '0x95D7fF1684a8F2e202097F28Dc2e56F773A55D02',          // SimpleCPMM
  parimutuel: '0x897945A56464616a525C9e5F11a8D400a72a8f3A',         // Parimutuel
  referralRegistry: '0x633a7eB9b8912b22f3616013F3153de687F96074',   // ReferralRegistry
  basket: '0x0000000000000000000000000000000000000000',            // 待部署
  correlationGuard: '0x0000000000000000000000000000000000000000',   // 待部署
  rewardsDistributor: '0x0000000000000000000000000000000000000000', // 待部署
  paramController: '0x17f4B55A352Be71CC03856765Ad04147119Aa09B',          // ParamController
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
      // 开发环境下，未知链默认使用 Anvil 地址
      console.warn(`Unknown chain ID: ${chainId}, falling back to Anvil addresses`);
      return ANVIL_ADDRESSES;
  }
}
