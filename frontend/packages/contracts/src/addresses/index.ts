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
// Anvil 本地测试链地址
// 部署时间: 2025-11-20 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// Anvil 本地测试链地址
// 部署时间: 2025-11-20 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
// Anvil 本地测试链地址
// 部署时间: 2025-11-20 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh 自动同步
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '0x9fD16eA9E31233279975D99D5e8Fc91dd214c7Da', // MarketFactory_v2
  vault: '0xeAd789bd8Ce8b9E94F5D0FCa99F8787c7e758817',               // LiquidityVault (deprecated)
  usdc: '0x547382C0D1b23f707918D3c83A77317B71Aa8470',               // MockUSDC
  feeRouter: '0x512F7469BcC83089497506b5df64c6E246B39925',           // FeeRouter
  simpleCPMM: '0x95775fD3Afb1F4072794CA4ddA27F2444BCf8Ac3',          // SimpleCPMM
  parimutuel: '0xd9fEc8238711935D6c8d79Bef2B9546ef23FC046',         // Parimutuel
  referralRegistry: '0xd3FFD73C53F139cEBB80b6A524bE280955b3f4db',   // ReferralRegistry
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
