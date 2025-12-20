import type { Address, ContractAddresses } from '../index';

// ============================================================================
// Anvil 本地测试链地址 (V3 架构)
// 部署时间: 2025-12-20 (自动更新)
// 来源: contracts/deployments/localhost_v3.json
// ============================================================================
export const ANVIL_ADDRESSES: ContractAddresses = {
  // V3 核心合约
  factory: '0x3235570150Ce492bC2b41a899D602f944EFa178d',
  vault: '0x00a66377e109B1348Ac65B31d8729a55EfEa75f4',
  bettingRouter: '0x187867371cB1da84469A82398A4192b0e94B6A4d',
  feeRouter: '0x3907e0Ebb70c4e556a9DFAC210ACE0B7b6c9c3c4',
  referralRegistry: '0x23b9efEC6328249538614171626feAf27031791b',
  paramController: '0x8D6d6a6FEa4c03CD138A0738Dc9c6f27ef5E673b',
  usdc: '0x631Cc89BAb95812b5FBdfD65A039a103210105b5',

  // V3 定价策略
  strategies: {
    cpmm: '0xBb1b80a6b42c78402b4d6621d8f04cd3c646a0c9',
    lmsr: '0x8891c6951AF060959c4f848A28FcF45AC96391eb',
    parimutuel: '0x29C5eAfE3Ed1F169b3CD594CE0506A3c0FFBfb85',
  },

  // V3 结果映射器
  mappers: {
    wdl: '0xA2008D7cfAC9B6078fa3Be7dA38A92306cb14BD8',
    ou: '0x05F3E9fFeEEeb7d5D3E691c2f0E5709Bc6D50b80',
    ah: '0x3aB35Bd6Ff2Ab3adbb4BF1cd5D575c37BC89557A',
    oddEven: '0x076D96825C7A6c9CE98864Cd0D84ab86d9B5bee9',
    score: '0x4081abAe8976dAC95551f3292fCd00cd15cD9E64',
    identity: '0x9DBCA797101Fb4B2186919778E0175a5576D0895',
  },

  // Market Implementation
  marketImplementation: '0x46F40df41128A641C143382Cc861ef60CacEADab',

  // 模板 ID
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

  // 运营合约（待部署）
  basket: undefined,
  correlationGuard: undefined,
  rewardsDistributor: undefined,

  // 兼容旧代码
  marketTemplateRegistry: '0x3235570150Ce492bC2b41a899D602f944EFa178d',
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
      // 开发环境下，未知链默认使用 Anvil 地址
      console.warn(`Unknown chain ID: ${chainId}, falling back to Anvil addresses`);
      return ANVIL_ADDRESSES;
  }
}
