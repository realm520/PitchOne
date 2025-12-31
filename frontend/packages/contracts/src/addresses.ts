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
// 自动生成时间: 2025-12-31 (来源: 远端服务器 /home/harry/code/PitchOne/contracts/deployments/localhost_v3.json)
const localhost: ContractAddresses = {
  factory: '0x1bEfE2d8417e22Da2E0432560ef9B2aB68Ab75Ad',
  vault: '0x8aAC5570d54306Bb395bf2385ad327b7b706016b',
  bettingRouter: '0x88D1aF96098a928eE278f162c1a84f339652f95b',
  feeRouter: '0x1757a98c1333B9dc8D408b194B2279b5AFDF70Cc',
  referralRegistry: '0x64f5219563e28EeBAAd91Ca8D31fa3b36621FD4f',
  paramController: '0xf201fFeA8447AB3d43c98Da3349e0749813C9009',
  usdc: '0xa85EffB2658CFd81e0B1AaD4f2364CdBCd89F3a1',
  marketImplementation: '0x04f1A5b9BD82a5020C49975ceAd160E98d8B77Af',
  strategies: {
    cpmm: '0xbFD3c8A956AFB7a9754C951D03C9aDdA7EC5d638',
    lmsr: '0x38F6F2caE52217101D7CA2a5eC040014b4164E6C',
    parimutuel: '0xc075BC0f734EFE6ceD866324fc2A9DBe1065CBB1',
  },
  mappers: {
    wdl: '0x837a41023CF81234f89F956C94D676918b4791c1',
    ou: '0x04d7478fDF318C3C22cECE62Da9D78ff94807D77',
    ah: '0xd9abC93F81394Bd161a1b24B03518e0a570bDEAd',
    oddEven: '0xcB0f2a13098f8e841e6Adfa5B17Ec00508b27665',
    score: '0x37D31345F164Ab170B19bc35225Abc98Ce30b46A',
    identity: '0x6345e50859b0Ce82D8A495ba9894C6C81de385F3',
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
  marketTemplateRegistry: '0x1bEfE2d8417e22Da2E0432560ef9B2aB68Ab75Ad',
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
