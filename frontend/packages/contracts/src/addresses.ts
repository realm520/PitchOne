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
  factory: '0xcC4c41415fc68B2fBf70102742A83cDe435e0Ca7',
  vault: '0x162700d1613DfEC978032A909DE02643bC55df1A',
  bettingRouter: '0x0fe4223AD99dF788A6Dcad148eB4086E6389cEB6',
  feeRouter: '0x114e375B6FCC6d6fCb68c7A1d407E652C54F25FB',
  referralRegistry: '0x67aD6EA566BA6B0fC52e97Bc25CE46120fdAc04c',
  paramController: '0x976C214741b4657bd99DFD38a5c0E3ac5C99D903',
  usdc: '0x9385556B571ab92bf6dC9a0DbD75429Dd4d56F91',
  marketImplementation: '0xa722bdA6968F50778B973Ae2701e90200C564B49',
  strategies: {
    cpmm: '0x967AB65ef14c58bD4DcfFeaAA1ADb40a022140E5',
    lmsr: '0xe1708FA6bb2844D5384613ef0846F9Bc1e8eC55E',
    parimutuel: '0x0aec7c174554AF8aEc3680BB58431F6618311510',
  },
  mappers: {
    wdl: '0x8e264821AFa98DD104eEcfcfa7FD9f8D8B320adA',
    ou: '0x871ACbEabBaf8Bed65c22ba7132beCFaBf8c27B5',
    ah: '0x6A59CC73e334b018C9922793d96Df84B538E6fD5',
    oddEven: '0xC1e0A9DB9eA830c52603798481045688c8AE99C2',
    score: '0x683d9CDD3239E0e01E8dC6315fA50AD92aB71D2d',
    identity: '0x1c9fD50dF7a4f066884b58A05D91e4b55005876A',
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
  marketTemplateRegistry: '0xcC4c41415fc68B2fBf70102742A83cDe435e0Ca7',
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
