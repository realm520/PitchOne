import type { Address, ContractAddresses } from '../index';

// Anvil 本地测试链地址
// 部署时间: 2025-11-17 (自动同步)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// Anvil 本地测试链地址
// 部署时间: 2025-11-18 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// Anvil 本地测试链地址
// 部署时间: 2025-11-18 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// Anvil 本地测试链地址
// 部署时间: 2025-11-18 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// Anvil 本地测试链地址
// 部署时间: 2025-11-18 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '0xA7c59f010700930003b33aB25a7a0679C860f29c', // MarketFactory_v2
  vault: '0xc96304e3c037f81dA488ed9dEa1D8F2a48278a75',               // LiquidityVault (deprecated)
  usdc: '0x18E317A7D70d8fBf8e6E893616b52390EbBdb629',               // MockUSDC
  feeRouter: '0x22753E4264FDDc6181dc7cce468904A80a363E44',           // FeeRouter
  simpleCPMM: '0x34B40BA116d5Dec75548a9e9A8f15411461E8c70',          // SimpleCPMM
  parimutuel: '0xD0141E899a65C95a556fE2B27e5982A6DE7fDD7A',         // Parimutuel
  referralRegistry: '0x07882Ae1ecB7429a84f1D53048d35c4bB2056877',   // ReferralRegistry
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
      throw new Error(`Unsupported chain ID: ${chainId}`);
  }
}
