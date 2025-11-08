// 合约 ABI 导出
export { default as MarketBaseABI } from './abis/MarketBase';
export { default as WDL_TemplateABI } from './abis/WDL_Template';
export { default as ERC20ABI } from './abis/ERC20';
export { default as MarketTemplateRegistryABI } from './abis/MarketTemplateRegistry';
export { default as ParamControllerABI } from './abis/ParamController';
export { default as CampaignABI } from './abis/Campaign';
export { default as QuestABI } from './abis/Quest';
export { default as RewardsDistributorABI } from './abis/RewardsDistributor';
export { default as FeeRouterABI } from './abis/FeeRouter';
export { default as ReferralRegistryABI } from './abis/ReferralRegistry';
export { default as OU_TemplateABI } from './abis/OU_Template';
export { default as OU_MultiLineABI } from './abis/OU_MultiLine';
export { default as LiquidityVaultABI } from './abis/LiquidityVault';
export { default as BasketABI } from './abis/Basket';

// 合约地址导出
export * from './addresses';

// 类型定义
export type Address = `0x${string}`;

export interface ContractAddresses {
  marketTemplateRegistry: Address;
  vault?: Address;              // LiquidityVault (WDL 市场需要)
  basket: Address;
  correlationGuard: Address;
  feeRouter: Address;
  rewardsDistributor: Address;
  referralRegistry: Address;
  usdc: Address;
  simpleCPMM: Address;
  // 管理功能合约（可选）
  paramController?: Address;
  campaign?: Address;
  quest?: Address;
}
