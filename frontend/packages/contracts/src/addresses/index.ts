import type { Address, ContractAddresses } from '../index';

// Anvil 本地测试链地址
// 部署时间: 2025-11-12 (自动生成)
// 来源: contracts/script/Deploy.s.sol 最新部署输出
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707', // MarketFactory_v2
  vault: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',               // LiquidityVault
  usdc: '0x5FbDB2315678afecb367f032d93F642f64180aa3',               // MockUSDC
  feeRouter: '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9',           // FeeRouter
  simpleCPMM: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',          // SimpleCPMM
  referralRegistry: '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9',   // ReferralRegistry
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
