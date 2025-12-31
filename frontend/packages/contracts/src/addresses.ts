// 导入本地地址配置（由 sync-addresses 脚本生成）
// 此文件在 .gitignore 中，每个环境独立生成
// 运行 `pnpm sync-addresses` 生成
import { localAddresses } from './addresses.local';

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

/**
 * 获取 localhost 地址配置
 */
function getLocalhostAddresses(): ContractAddresses {
  return localAddresses;
}

/**
 * 根据链 ID 获取合约地址
 */
export function getContractAddresses(chainId: number | undefined): ContractAddresses {
  // 目前只支持 localhost (31337)
  // 未来可以添加其他网络
  return getLocalhostAddresses();
}

/**
 * 获取所有支持的链 ID
 */
export function getSupportedChainIds(): number[] {
  return [31337];
}

/**
 * 检查链 ID 是否支持
 */
export function isChainSupported(chainId: number): boolean {
  return chainId === 31337;
}

// 导出默认地址（动态获取）
export const defaultAddresses = new Proxy({} as ContractAddresses, {
  get(_, prop) {
    return getLocalhostAddresses()[prop as keyof ContractAddresses];
  }
});
