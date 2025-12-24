import type { Address, ContractAddresses } from '../index';

// Anvil 本地测试链地址 (V3 架构)
// 部署时间: 2025-12-23 (自动生成)
// 来源: contracts/deployments/localhost_v3.json
export const ANVIL_ADDRESSES: ContractAddresses = {
  // V3 核心合约
  factory: '0x8A791620dd6260079BF849Dc5567aDC3F2FdC318' as Address,
  vault: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512' as Address,
  bettingRouter: '0x59b670e9fA9D0A427751Af201D676719a970857b' as Address,
  feeRouter: '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9' as Address,
  referralRegistry: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0' as Address,
  paramController: '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707' as Address,
  usdc: '0x5FbDB2315678afecb367f032d93F642f64180aa3' as Address,

  // Market Implementation (用于 Clone)
  marketImplementation: '0x610178dA211FEF7D417bC0e6FeD39F05609AD788' as Address,

  // V3 定价策略
  strategies: {
    cpmm: '0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0' as Address,
    lmsr: '0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82' as Address,
    parimutuel: '0x9A676e781A523b5d0C0e43731313A708CB607508' as Address,
  },

  // V3 结果映射器
  mappers: {
    wdl: '0x0B306BF915C4d645ff596e518fAf3F9669b97016' as Address,
    ou: '0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1' as Address,
    ah: '0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE' as Address,
    oddEven: '0x68B1D87F95878fE05B998F19b66F4baba5De1aed' as Address,
    score: '0x3Aa5ebB10DC797CAC828524e59A333d0A371443c' as Address,
    identity: '0xc6e7DF5E7b4f2A278906862b61205850344D4e7d' as Address,
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
  marketTemplateRegistry: '0x8A791620dd6260079BF849Dc5567aDC3F2FdC318' as Address,
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
