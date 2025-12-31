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

// Localhost (Anvil) - Chain ID 31337
// 自动生成时间: 2025-12-31 (来源: contracts/deployments/localhost_v3.json)
const localhost: ContractAddresses = {
  factory: '0xE3011A37A904aB90C8881a99BD1F6E21401f1522',
  vault: '0xfaAddC93baf78e89DCf37bA67943E1bE8F37Bb8c',
  bettingRouter: '0xd6e1afe5cA8D00A2EFC01B89997abE2De47fdfAf',
  feeRouter: '0x3347B4d90ebe72BeFb30444C9966B2B990aE9FcB',
  referralRegistry: '0x276C216D241856199A83bf27b2286659e5b877D3',
  paramController: '0x5bf5b11053e734690269C6B9D438F8C9d48F528A',
  usdc: '0xA7c59f010700930003b33aB25a7a0679C860f29c',
  marketImplementation: '0x1f10F3Ba7ACB61b2F50B9d6DdCf91a6f787C0E82',
  strategies: {
    cpmm: '0x525C7063E7C20997BaaE9bDa922159152D0e8417',
    lmsr: '0x38a024C0b412B9d1db8BC398140D00F5Af3093D4',
    parimutuel: '0x5fc748f1FEb28d7b76fa1c6B07D8ba2d5535177c',
  },
  mappers: {
    wdl: '0xB82008565FdC7e44609fA118A4a681E92581e680',
    ou: '0x2a810409872AfC346F9B5b26571Fd6eC42EA4849',
    ah: '0xb9bEECD1A582768711dE1EE7B0A1d582D9d72a6C',
    oddEven: '0x8A93d247134d91e0de6f96547cB0204e5BE8e5D8',
    score: '0x40918Ba7f132E0aCba2CE4de4c4baF9BD2D7D849',
    identity: '0xF32D39ff9f6Aa7a7A64d7a4F00a54826Ef791a55',
  },
  templateIds: {
    wdl: '0x850ca3b5a2939c6d60042c83f2b881cb9112b18403eff8ca6bdf8643f6929255',
    wdlPari: '0xef6f1330cf58b013258b8e3d5fd49f219361a51fb17cfc622a124addb42faba9',
    ou: '0xa495d730efcaf403352bdd628d1de38d992ff3375848cdb98afa28b5b59cff7b',
    ah: '0xc1c2f947cb05772ac139e3b4a8985ea02d5427a87efb0d84b8c5713211cf6d77',
    oddEven: '0x9e6a6038ade81f51943384cf6c154288dd6bd60d302d9b47259fe682aed4ca3b',
    score: '0xbdbbbdbba6720937df16c0157e4817cd43f0c24162746ecde369b852ad34983e',
    scorePari: '0x213a5ab57fbce6773e92530fea5eb10bd610aa9e6dbad2d98cf07f414d074123',
    firstGoalscorer: '0xf44ca50923fd3146c0ae29ba2693c48afd11abbeebce7c5c9a714f7a46e85b73',
  },
  // 兼容旧代码
  marketTemplateRegistry: '0xE3011A37A904aB90C8881a99BD1F6E21401f1522',
};

// 地址映射表
const addresses: Record<number, ContractAddresses> = {
  31337: localhost,
};

/**
 * 根据链 ID 获取合约地址
 */
export function getContractAddresses(chainId: number | undefined): ContractAddresses {
  if (!chainId) {
    return localhost; // 默认返回 localhost
  }
  return addresses[chainId] || localhost;
}

/**
 * 获取所有支持的链 ID
 */
export function getSupportedChainIds(): number[] {
  return Object.keys(addresses).map(Number);
}

/**
 * 检查链 ID 是否支持
 */
export function isChainSupported(chainId: number): boolean {
  return chainId in addresses;
}

// 导出默认地址（localhost）
export const defaultAddresses = localhost;
