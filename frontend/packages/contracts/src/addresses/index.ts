import type { Address, ContractAddresses } from '../index';

// Anvil 本地测试链地址
// 部署时间: 2025-11-06 (V2 System - Fresh Deploy)
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '0x6A59CC73e334b018C9922793d96Df84B538E6fD5', // MarketFactory_v2
  basket: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',        // 待部署
  correlationGuard: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',   // 待部署
  feeRouter: '0x871ACbEabBaf8Bed65c22ba7132beCFaBf8c27B5',
  rewardsDistributor: '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9', // 待部署
  referralRegistry: '0x8e264821AFa98DD104eEcfcfa7FD9f8D8B320adA',
  usdc: '0x967AB65ef14c58bD4DcfFeaAA1ADb40a022140E5',
  simpleCPMM: '0x0aec7c174554AF8aEc3680BB58431F6618311510',
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
