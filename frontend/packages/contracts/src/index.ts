// 合约 ABI 导出
export * as MarketBaseABI from './abis/MarketBase';
export * as BasketABI from './abis/Basket';
export * as WDL_TemplateABI from './abis/WDL_Template';

// 合约地址导出
export * from './addresses';

// 类型定义
export type Address = `0x${string}`;

export interface ContractAddresses {
  marketTemplateRegistry: Address;
  basket: Address;
  correlationGuard: Address;
  feeRouter: Address;
  rewardsDistributor: Address;
  referralRegistry: Address;
  usdc: Address;
}
