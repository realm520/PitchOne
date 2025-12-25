import type { Address, ContractAddresses } from '../index';

// Anvil 本地测试链地址 (V3 架构)
// 部署时间: 2025-12-25 (自动生成)
// 来源: 远程服务器 contracts/deployments/localhost_v3.json
export const ANVIL_ADDRESSES: ContractAddresses = {
  // V3 核心合约
  factory: '0x88D1aF96098a928eE278f162c1a84f339652f95b' as Address,
  vault: '0x38F6F2caE52217101D7CA2a5eC040014b4164E6C' as Address,
  bettingRouter: '0xfc073209b7936A771F77F63D42019a3a93311869' as Address,
  feeRouter: '0x837a41023CF81234f89F956C94D676918b4791c1' as Address,
  referralRegistry: '0xc075BC0f734EFE6ceD866324fc2A9DBe1065CBB1' as Address,
  paramController: '0xd9abC93F81394Bd161a1b24B03518e0a570bDEAd' as Address,
  usdc: '0xbFD3c8A956AFB7a9754C951D03C9aDdA7EC5d638' as Address,

  // Market Implementation (用于 Clone)
  marketImplementation: '0x7Ce73F8f636C6bD3357A0A8a59e0ab6462C955B0' as Address,

  // V3 定价策略
  strategies: {
    cpmm: '0x746a48E39dC57Ff14B872B8979E20efE5E5100B1' as Address,
    lmsr: '0x96E303b6D807c0824E83f954784e2d6f3614f167' as Address,
    parimutuel: '0x9CC8B5379C40E24F374cd55973c138fff83ed214' as Address,
  },

  // V3 结果映射器
  mappers: {
    wdl: '0xd3b893cd083f07Fe371c1a87393576e7B01C52C6' as Address,
    ou: '0x3BFbbf82657577668144921b96aAb72BC170646C' as Address,
    ah: '0x930b218f3e63eE452c13561057a8d5E61367d5b7' as Address,
    oddEven: '0x721d8077771Ebf9B931733986d619aceea412a1C' as Address,
    score: '0x38c76A767d45Fc390160449948aF80569E2C4217' as Address,
    identity: '0xDC57724Ea354ec925BaFfCA0cCf8A1248a8E5CF1' as Address,
  },

  // 模板 ID
  templateIds: {
    wdl: '0x850ca3b5a2939c6d60042c83f2b881cb9112b18403eff8ca6bdf8643f6929255' as Address,
    wdlPari: '0xef6f1330cf58b013258b8e3d5fd49f219361a51fb17cfc622a124addb42faba9' as Address,
    ou: '0xa495d730efcaf403352bdd628d1de38d992ff3375848cdb98afa28b5b59cff7b' as Address,
    ah: '0xc1c2f947cb05772ac139e3b4a8985ea02d5427a87efb0d84b8c5713211cf6d77' as Address,
    oddEven: '0x9e6a6038ade81f51943384cf6c154288dd6bd60d302d9b47259fe682aed4ca3b' as Address,
    score: '0xbdbbbdbba6720937df16c0157e4817cd43f0c24162746ecde369b852ad34983e' as Address,
    scorePari: '0x213a5ab57fbce6773e92530fea5eb10bd610aa9e6dbad2d98cf07f414d074123' as Address,
    firstGoalscorer: '0xf44ca50923fd3146c0ae29ba2693c48afd11abbeebce7c5c9a714f7a46e85b73' as Address,
  },

  // 运营合约（待部署）
  basket: '0x0000000000000000000000000000000000000000' as Address,
  correlationGuard: '0x0000000000000000000000000000000000000000' as Address,
  rewardsDistributor: '0x0000000000000000000000000000000000000000' as Address,

  // 兼容旧代码
  marketTemplateRegistry: '0x88D1aF96098a928eE278f162c1a84f339652f95b' as Address,
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
      throw new Error(`Unsupported chain ID: ${chainId}`);
  }
}
