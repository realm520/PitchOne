import type { Address, ContractAddresses } from '../index';

// ============================================================================
// Anvil 本地测试链地址
// 部署时间: 2025-12-19 (自动更新)
// 来源: contracts/deployments/localhost.json
// ============================================================================
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '0xC6c5Ab5039373b0CBa7d0116d9ba7fb9831C3f42', // MarketFactory_v2
  vault: '0x021DBfF4A864Aa25c51F0ad2Cd73266Fde66199d',               // LiquidityVault
  usdc: '0x687bB6c57915aa2529EfC7D2a26668855e022fAE',               // MockUSDC
  feeRouter: '0x6DcBc91229d812910b54dF91b5c2b592572CD6B0',           // FeeRouter
  simpleCPMM: '0x4CF4dd3f71B67a7622ac250f8b10d266Dc5aEbcE',          // SimpleCPMM
  parimutuel: '0x2498e8059929e18e2a2cED4e32ef145fa2F4a744',         // Parimutuel
  referralRegistry: '0x447786d977Ea11Ad0600E193b2d07A06EfB53e5F',   // ReferralRegistry
  basket: '0x0000000000000000000000000000000000000000',            // 待部署
  correlationGuard: '0x0000000000000000000000000000000000000000',   // 待部署
  rewardsDistributor: '0x0000000000000000000000000000000000000000', // 待部署
  paramController: '0xE2b5bDE7e80f89975f7229d78aD9259b2723d11F',    // ParamController
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
