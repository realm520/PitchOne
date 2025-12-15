import type { Address, ContractAddresses } from '../index';

// ============================================================================
// Anvil 本地测试链地址
// 部署时间: 2025-11-27 (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh
// ============================================================================
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '0xddE78e6202518FF4936b5302cC2891ec180E8bFf', // MarketFactory_v2
  vault: '0x74Cf9087AD26D541930BaC724B7ab21bA8F00a27',               // LiquidityVault (deprecated)
  usdc: '0xe1Fd27F4390DcBE165f4D60DBF821e4B9Bb02dEd',               // MockUSDC
  feeRouter: '0x26B862f640357268Bd2d9E95bc81553a2Aa81D7E',           // FeeRouter
  simpleCPMM: '0xefAB0Beb0A557E452b398035eA964948c750b2Fd',          // SimpleCPMM
  parimutuel: '0xaca81583840B1bf2dDF6CDe824ada250C1936B4D',         // Parimutuel
  referralRegistry: '0x70bDA08DBe07363968e9EE53d899dFE48560605B',   // ReferralRegistry
  basket: '0x0000000000000000000000000000000000000000',            // 待部署
  correlationGuard: '0x0000000000000000000000000000000000000000',   // 待部署
  rewardsDistributor: '0x0000000000000000000000000000000000000000', // 待部署
  paramController: '0x5D42EBdBBa61412295D7b0302d6F50aC449Ddb4F',          // ParamController
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
