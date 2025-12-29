/**
 * PitchOne Subgraph - Registry 事件处理器 (V3 架构)
 * 处理 MarketFactory_V3 的事件，实现动态市场索引
 */

import { Address, BigInt, Bytes, log, crypto, ethereum } from '@graphprotocol/graph-ts';
import {
  MarketCreated as MarketCreatedEvent,
  TemplateRegistered as TemplateRegisteredEvent,
  TemplateUpdated as TemplateUpdatedEvent,
  RoleGranted as RoleGrantedEvent,
  RoleRevoked as RoleRevokedEvent,
} from '../generated/MarketFactory/MarketFactory_V3';
import { Market_V3 as Market_V3Template } from '../generated/templates';
import { Market_V3 } from '../generated/templates/Market_V3/Market_V3';
import { Template, GlobalStats, Market, Admin, RoleChange } from '../generated/schema';
import { loadOrCreateGlobalStats, ZERO_BD, parseTeamsFromMatchId, toDecimal } from './helpers';
import { IPricingStrategy } from '../generated/MarketFactory/IPricingStrategy';

// 角色哈希常量
const DEFAULT_ADMIN_ROLE = Bytes.fromHexString('0x0000000000000000000000000000000000000000000000000000000000000000');
const OPERATOR_ROLE = crypto.keccak256(Bytes.fromUTF8('OPERATOR_ROLE'));
const ROUTER_ROLE = crypto.keccak256(Bytes.fromUTF8('ROUTER_ROLE'));
const KEEPER_ROLE = crypto.keccak256(Bytes.fromUTF8('KEEPER_ROLE'));
const ORACLE_ROLE = crypto.keccak256(Bytes.fromUTF8('ORACLE_ROLE'));

/**
 * 根据角色哈希返回角色名称
 */
function getRoleName(roleHash: Bytes): string {
  if (roleHash.equals(DEFAULT_ADMIN_ROLE)) return 'DEFAULT_ADMIN_ROLE';
  if (roleHash.equals(OPERATOR_ROLE)) return 'OPERATOR_ROLE';
  if (roleHash.equals(ROUTER_ROLE)) return 'ROUTER_ROLE';
  if (roleHash.equals(KEEPER_ROLE)) return 'KEEPER_ROLE';
  if (roleHash.equals(ORACLE_ROLE)) return 'ORACLE_ROLE';
  return 'UNKNOWN_ROLE';
}

/**
 * 加载或创建 Admin 实体
 */
function loadOrCreateAdmin(address: Address, timestamp: BigInt): Admin {
  let admin = Admin.load(address.toHexString());
  if (admin === null) {
    admin = new Admin(address.toHexString());
    admin.hasAdminRole = false;
    admin.hasOperatorRole = false;
    admin.hasRouterRole = false;
    admin.hasKeeperRole = false;
    admin.hasOracleRole = false;
    admin.firstGrantedAt = timestamp;
    admin.lastUpdatedAt = timestamp;
  }
  return admin;
}

/**
 * 处理 MarketFactory_V3 的 MarketCreated 事件
 * 创建动态数据源并初始化 Market 实体
 */
export function handleMarketCreatedFromFactory(event: MarketCreatedEvent): void {
  const marketAddress = event.params.market;
  const templateId = event.params.templateId;
  const matchId = event.params.matchId;
  const kickoffTime = event.params.kickoffTime;

  log.info('MarketFactory_V3: Market created at {} with template {} for match {}', [
    marketAddress.toHexString(),
    templateId.toHexString(),
    matchId,
  ]);

  // 创建动态数据源
  Market_V3Template.create(marketAddress);

  // 创建 Market 实体
  let market = new Market(marketAddress.toHexString());

  // 尝试从 Template 实体获取名称，如果不存在则使用 hex 字符串
  let template = Template.load(templateId.toHexString());
  if (template !== null && template.name !== null) {
    market.templateId = template.name as string;
  } else {
    market.templateId = templateId.toHexString();
  }

  market.matchId = matchId;
  market.kickoffTime = kickoffTime;

  // 从 matchId 解析球队信息
  let teams = parseTeamsFromMatchId(matchId);
  market.homeTeam = teams[0];
  market.awayTeam = teams[1];
  market.ruleVer = Bytes.empty();
  market.state = "Open";
  market.paused = false;
  market.createdAt = event.block.timestamp;
  market.totalVolume = ZERO_BD;
  market.feeAccrued = ZERO_BD;
  market.lpLiquidity = ZERO_BD;
  market.uniqueBettors = 0;
  market.oracle = null;
  market.pricingEngine = null;

  // 尝试从链上读取更多信息
  let marketContract = Market_V3.bind(marketAddress);
  let pricingResult = marketContract.try_pricingStrategy();
  if (!pricingResult.reverted) {
    market.pricingEngine = pricingResult.value;

    // 读取定价策略类型
    let strategyContract = IPricingStrategy.bind(pricingResult.value);
    let typeResult = strategyContract.try_strategyType();
    if (!typeResult.reverted) {
      market.pricingType = typeResult.value;
    }
  }

  // 读取初始流动性
  let liquidityResult = marketContract.try_initialLiquidity();
  if (!liquidityResult.reverted) {
    market.initialLiquidity = toDecimal(liquidityResult.value);
  }

  // 如果是 LMSR 策略，解码 pricingState 获取 b 参数
  if (market.pricingType !== null && market.pricingType == 'LMSR') {
    let stateResult = marketContract.try_pricingState();
    if (!stateResult.reverted && stateResult.value.length > 0) {
      // LMSR state 结构: abi.encode(uint256[] quantities, uint256 b)
      // 解码最后 32 字节获取 b 值
      let stateBytes = stateResult.value;
      if (stateBytes.length >= 32) {
        // b 是编码数据的最后 32 字节
        // 先解码 quantities 数组长度，然后跳过数组数据读取 b
        let decoded = ethereum.decode('(uint256[],uint256)', stateBytes);
        if (decoded !== null) {
          let tuple = decoded.toTuple();
          let bValue = tuple[1].toBigInt();
          market.lmsrB = toDecimal(bValue);
        }
      }
    }
  }

  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalMarkets = stats.totalMarkets + 1;
  stats.activeMarkets = stats.activeMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理 TemplateRegistered 事件
 */
export function handleTemplateRegistered(event: TemplateRegisteredEvent): void {
  const templateId = event.params.templateId;
  const name = event.params.name;
  const strategyType = event.params.strategyType;

  log.info('MarketFactory_V3: Template registered - id: {}, name: {}, strategy: {}', [
    templateId.toHexString(),
    name,
    strategyType,
  ]);

  // 创建或更新模板实体
  let template = new Template(templateId.toHexString());
  template.templateId = templateId;
  template.name = name;
  template.active = true;
  template.registeredAt = event.block.timestamp;
  template.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理 TemplateUpdated 事件
 */
export function handleTemplateUpdated(event: TemplateUpdatedEvent): void {
  const templateId = event.params.templateId;
  const active = event.params.active;

  log.info('MarketFactory_V3: Template {} active status updated to {}', [
    templateId.toHexString(),
    active ? 'true' : 'false',
  ]);

  // 更新模板实体
  let template = Template.load(templateId.toHexString());
  if (template !== null) {
    template.active = active;
    template.save();
  }

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理 RoleGranted 事件
 * OpenZeppelin AccessControl 在授予角色时触发
 */
export function handleRoleGranted(event: RoleGrantedEvent): void {
  const role = event.params.role;
  const account = event.params.account;
  const sender = event.params.sender;

  const roleName = getRoleName(role);

  log.info('MarketFactory_V3: Role {} granted to {} by {}', [
    roleName,
    account.toHexString(),
    sender.toHexString(),
  ]);

  // 加载或创建 Admin 实体
  let admin = loadOrCreateAdmin(account, event.block.timestamp);

  // 更新角色状态
  if (role.equals(DEFAULT_ADMIN_ROLE)) {
    admin.hasAdminRole = true;
  } else if (role.equals(OPERATOR_ROLE)) {
    admin.hasOperatorRole = true;
  } else if (role.equals(ROUTER_ROLE)) {
    admin.hasRouterRole = true;
  } else if (role.equals(KEEPER_ROLE)) {
    admin.hasKeeperRole = true;
  } else if (role.equals(ORACLE_ROLE)) {
    admin.hasOracleRole = true;
  }

  admin.lastUpdatedAt = event.block.timestamp;
  admin.save();

  // 创建 RoleChange 记录
  const changeId = event.transaction.hash.toHexString() + '-' + event.logIndex.toString();
  let roleChange = new RoleChange(changeId);
  roleChange.admin = admin.id;
  roleChange.role = role;
  roleChange.roleName = roleName;
  roleChange.action = 'Grant';
  roleChange.sender = sender;
  roleChange.timestamp = event.block.timestamp;
  roleChange.blockNumber = event.block.number;
  roleChange.transactionHash = event.transaction.hash;
  roleChange.save();
}

/**
 * 处理 RoleRevoked 事件
 * OpenZeppelin AccessControl 在撤销角色时触发
 */
export function handleRoleRevoked(event: RoleRevokedEvent): void {
  const role = event.params.role;
  const account = event.params.account;
  const sender = event.params.sender;

  const roleName = getRoleName(role);

  log.info('MarketFactory_V3: Role {} revoked from {} by {}', [
    roleName,
    account.toHexString(),
    sender.toHexString(),
  ]);

  // 加载 Admin 实体
  let admin = Admin.load(account.toHexString());
  if (admin === null) {
    // 理论上不应该发生，但为了安全起见
    admin = loadOrCreateAdmin(account, event.block.timestamp);
  }

  // 更新角色状态
  if (role.equals(DEFAULT_ADMIN_ROLE)) {
    admin.hasAdminRole = false;
  } else if (role.equals(OPERATOR_ROLE)) {
    admin.hasOperatorRole = false;
  } else if (role.equals(ROUTER_ROLE)) {
    admin.hasRouterRole = false;
  } else if (role.equals(KEEPER_ROLE)) {
    admin.hasKeeperRole = false;
  } else if (role.equals(ORACLE_ROLE)) {
    admin.hasOracleRole = false;
  }

  admin.lastUpdatedAt = event.block.timestamp;
  admin.save();

  // 创建 RoleChange 记录
  const changeId = event.transaction.hash.toHexString() + '-' + event.logIndex.toString();
  let roleChange = new RoleChange(changeId);
  roleChange.admin = admin.id;
  roleChange.role = role;
  roleChange.roleName = roleName;
  roleChange.action = 'Revoke';
  roleChange.sender = sender;
  roleChange.timestamp = event.block.timestamp;
  roleChange.blockNumber = event.block.number;
  roleChange.transactionHash = event.transaction.hash;
  roleChange.save();
}
