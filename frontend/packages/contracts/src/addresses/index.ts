import type { Address, ContractAddresses } from '../index';

// Anvil 本地测试链地址
// 部署时间: 2025-11-07 Block 591 (全新部署，确保无历史数据干扰)
// 来源: contracts/script/Deploy.s.sol 最新部署输出
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '0x47c05BCCA7d57c87083EB4e586007530eE4539e9', // MarketFactory_v2 (NEW)
  vault: '0xF85895D097B2C25946BB95C4d11E2F3c035F8f0C',               // LiquidityVault (NEW)
  usdc: '0x2b639Cc84e1Ad3aA92D4Ee7d2755A6ABEf300D72',               // MockUSDC (NEW)
  feeRouter: '0xB468647B04bF657C9ee2de65252037d781eABafD',           // FeeRouter (NEW)
  simpleCPMM: '0x0b27a79cb9C0B38eE06Ca3d94DAA68e0Ed17F953',          // SimpleCPMM (NEW)
  referralRegistry: '0x7bdd3b028C4796eF0EAf07d11394d0d9d8c24139',   // ReferralRegistry (NEW)
  basket: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',            // 待部署
  correlationGuard: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',   // 待部署
  rewardsDistributor: '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9', // 待部署
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
