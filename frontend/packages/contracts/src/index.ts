// V3 合约 ABI 导出
export { default as Market_V3_ABI } from './abis/Market_V3';
export { default as MarketFactory_V3_ABI } from './abis/MarketFactory_V3';
export { default as BettingRouter_V3_ABI } from './abis/BettingRouter_V3';
export { default as LiquidityVault_V3_ABI } from './abis/LiquidityVault_V3';

// 通用合约 ABI 导出
export { default as ERC20ABI } from './abis/ERC20';
export { default as ParamControllerABI } from './abis/ParamController';
export { default as FeeRouterABI } from './abis/FeeRouter';
export { default as ReferralRegistryABI } from './abis/ReferralRegistry';

// 运营合约 ABI 导出
export { default as CampaignABI } from './abis/Campaign';
export { default as QuestABI } from './abis/Quest';
export { default as RewardsDistributorABI } from './abis/RewardsDistributor';
export { default as BasketABI } from './abis/Basket';

// 合约地址导出
export * from './addresses';

// 类型定义
export type Address = `0x${string}`;

export interface ContractAddresses {
  // V3 核心合约
  factory: Address;              // MarketFactory_V3
  vault: Address;                // LiquidityVault_V3
  bettingRouter: Address;        // BettingRouter_V3
  feeRouter: Address;            // FeeRouter
  referralRegistry: Address;     // ReferralRegistry
  paramController: Address;      // ParamController
  usdc: Address;                 // USDC Token

  // V3 定价策略
  strategies: {
    cpmm: Address;               // CPMMStrategy
    lmsr: Address;               // LMSRStrategy
    parimutuel: Address;         // ParimutuelStrategy
  };

  // V3 结果映射器
  mappers: {
    wdl: Address;                // WDL_Mapper
    ou: Address;                 // OU_Mapper
    ah: Address;                 // AH_Mapper
    oddEven: Address;            // OddEven_Mapper
    score: Address;              // Score_Mapper
    identity: Address;           // Identity_Mapper
  };

  // Market Implementation (用于 Clone)
  marketImplementation: Address;

  // 模板 ID
  templateIds: {
    wdl: Address;
    wdlPari: Address;
    ou: Address;
    ah: Address;
    oddEven: Address;
    score: Address;
    scorePari: Address;
    firstGoalscorer: Address;
  };

  // 运营合约（可选，待部署）
  basket?: Address;
  correlationGuard?: Address;
  rewardsDistributor?: Address;
  campaign?: Address;
  quest?: Address;

  // 兼容旧代码（已废弃，指向 factory）
  /** @deprecated 使用 factory 代替 */
  marketTemplateRegistry?: Address;
}
