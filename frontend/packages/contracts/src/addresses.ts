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
const localhost: ContractAddresses = {
  factory: '0xc351628EB244ec633d5f21fBD6621e1a683B1181',
  vault: '0x1291Be112d480055DaFd8a610b7d1e203891C274',
  bettingRouter: '0x21dF544947ba3E8b3c32561399E88B52Dc8b2823',
  feeRouter: '0x6212cb549De37c25071cF506aB7E115D140D9e42',
  referralRegistry: '0xa195ACcEB1945163160CD5703Ed43E4f78176a54',
  paramController: '0xf4AE7E15B1012edceD8103510eeB560a9343AFd3',
  usdc: '0x4c5859f0F772848b2D91F1D83E2Fe57935348029',
  marketImplementation: '0xC0BF43A4Ca27e0976195E6661b099742f10507e5',
  strategies: {
    cpmm: '0x9D3DA37d36BB0B825CD319ed129c2872b893f538',
    lmsr: '0x59C4e2c6a6dC27c259D6d067a039c831e1ff4947',
    parimutuel: '0x9d136eEa063eDE5418A6BC7bEafF009bBb6CFa70',
  },
  mappers: {
    wdl: '0x687bB6c57915aa2529EfC7D2a26668855e022fAE',
    ou: '0x49149a233de6E4cD6835971506F47EE5862289c1',
    ah: '0xAe2563b4315469bF6bdD41A6ea26157dE57Ed94e',
    oddEven: '0x30426D33a78afdb8788597D5BFaBdADc3Be95698',
    score: '0x85495222Fd7069B987Ca38C2142732EbBFb7175D',
    identity: '0x3abBB0D6ad848d64c8956edC9Bf6f18aC22E1485',
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
  marketTemplateRegistry: '0xc351628EB244ec633d5f21fBD6621e1a683B1181',
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
