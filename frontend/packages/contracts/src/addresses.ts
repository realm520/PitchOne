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
  factory: '0xde2Bd2ffEA002b8E84ADeA96e5976aF664115E2c',
  vault: '0xFD6F7A6a5c21A3f503EBaE7a473639974379c351',
  bettingRouter: '0xaca81583840B1bf2dDF6CDe824ada250C1936B4D',
  feeRouter: '0xb7278A61aa25c888815aFC32Ad3cC52fF24fE575',
  referralRegistry: '0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154',
  paramController: '0x82e01223d51Eb87e16A03E24687EDF0F294da6f1',
  usdc: '0x6C2d83262fF84cBaDb3e416D527403135D757892',
  marketImplementation: '0xFD471836031dc5108809D173A067e8486B9047A3',
  strategies: {
    cpmm: '0x1429859428C0aBc9C2C47C8Ee9FBaf82cFA0F20f',
    lmsr: '0xB0D4afd8879eD9F52b28595d31B441D079B2Ca07',
    parimutuel: '0x162A433068F51e18b7d13932F27e66a3f99E6890',
  },
  mappers: {
    wdl: '0x922D6956C99E12DFeB3224DEA977D0939758A1Fe',
    ou: '0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f',
    ah: '0x1fA02b2d6A771842690194Cf62D91bdd92BfE28d',
    oddEven: '0xdbC43Ba45381e02825b14322cDdd15eC4B3164E6',
    score: '0x04C89607413713Ec9775E14b954286519d836FEf',
    identity: '0x4C4a2f8c81640e47606d3fd77B353E87Ba015584',
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
