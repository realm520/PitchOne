import type { Address, ContractAddresses } from '../index';

// ============================================================================
// Anvil 本地测试链地址
// 部署时间: 2025-11-20 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// ============================================================================
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '0x7A5EC257391817ef241ef8451642cC6b222d4f8C', // MarketFactory_v2
  vault: '0x4c04377f90Eb1E42D845AB21De874803B8773669',               // LiquidityVault (deprecated)
  usdc: '0xE401FBb0d6828e9f25481efDc9dd18Da9E500983',               // MockUSDC
  feeRouter: '0xCA87833e830652C2ab07E1e03eBa4F2c246D3b58',           // FeeRouter
  simpleCPMM: '0xf93b0549cD50c849D792f0eAE94A598fA77C7718',          // SimpleCPMM
  parimutuel: '0x8CeA85eC7f3D314c4d144e34F2206C8Ac0bbadA1',         // Parimutuel
  referralRegistry: '0x29023DE63D7075B4cC2CE30B55f050f9c67548d4',   // ReferralRegistry
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
