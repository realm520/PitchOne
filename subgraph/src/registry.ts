/**
 * PitchOne Subgraph - Registry 事件处理器
 * 处理 MarketTemplateRegistry 的事件，实现动态市场索引
 */

import { Address, Bytes, log } from '@graphprotocol/graph-ts';
import {
  MarketCreated as MarketCreatedFromRegistryEvent,
  TemplateRegistered as TemplateRegisteredEvent,
  TemplateUnregistered as TemplateUnregisteredEvent,
  TemplateActiveStatusUpdated as TemplateActiveStatusUpdatedEvent,
} from '../generated/MarketTemplateRegistry/MarketTemplateRegistry';
import { WDLMarket, OUMarket, OUMultiMarket, OddEvenMarket } from '../generated/templates';
import { WDL_Template } from '../generated/templates/WDLMarket/WDL_Template';
import { OU_Template } from '../generated/templates/OUMarket/OU_Template';
import { OddEven_Template } from '../generated/templates/OddEvenMarket/OddEven_Template';
import { Template, GlobalStats, Market } from '../generated/schema';
import { loadOrCreateGlobalStats, ZERO_BD } from './helpers';

// 模板 ID 常量（对应合约中的 keccak256(abi.encode(name, version))）
// 这些值需要与链上注册的模板 ID 匹配
const WDL_TEMPLATE_ID = '0x'; // 需要从链上获取实际值
const OU_TEMPLATE_ID = '0x';
const OU_MULTI_TEMPLATE_ID = '0x';

/**
 * 处理 Registry 的 MarketCreated 事件
 * 根据 templateId 动态创建对应的 data source，并从链上读取市场信息创建 Market 实体
 */
export function handleMarketCreatedFromRegistry(event: MarketCreatedFromRegistryEvent): void {
  const marketAddress = event.params.market;
  const templateId = event.params.templateId;
  const creator = event.params.creator;

  log.info('Registry: Market created at {} with template {}', [
    marketAddress.toHexString(),
    templateId.toHexString(),
  ]);

  // 加载模板信息
  let template = Template.load(templateId.toHexString());
  if (template === null) {
    log.warning('Registry: Template {} not found, skipping market {}', [
      templateId.toHexString(),
      marketAddress.toHexString(),
    ]);
    return;
  }

  // 根据模板名称创建对应的 data source 和 Market 实体
  const templateName = template.name;

  log.info('Registry: Template name is: "{}", type: {}', [
    templateName !== null ? templateName! : 'null',
    templateName !== null ? 'string' : 'null'
  ]);

  if (templateName != null && templateName == 'WDL') {
    log.info('Registry: Creating WDL market data source for {}', [marketAddress.toHexString()]);
    WDLMarket.create(marketAddress);
    createWDLMarketEntity(marketAddress, event);
  } else if (templateName != null && templateName == 'OU') {
    log.info('Registry: Creating OU market data source for {}', [marketAddress.toHexString()]);
    OUMarket.create(marketAddress);
    createOUMarketEntity(marketAddress, event);
  } else if (templateName != null && templateName == 'OU_MultiLine') {
    log.info('Registry: Creating OU MultiLine market data source for {}', [marketAddress.toHexString()]);
    OUMultiMarket.create(marketAddress);
    createOUMarketEntity(marketAddress, event); // 暂时使用相同的处理
  } else if (templateName != null && templateName == 'OddEven') {
    log.info('Registry: Creating OddEven market data source for {}', [marketAddress.toHexString()]);
    OddEvenMarket.create(marketAddress);
    createOddEvenMarketEntity(marketAddress, event);
  } else {
    log.warning('Registry: Unknown template name {} for market {}', [
      templateName !== null ? templateName! : 'null',
      marketAddress.toHexString(),
    ]);
  }
}

/**
 * 从链上读取并创建 WDL Market 实体
 */
function createWDLMarketEntity(marketAddress: Address, event: MarketCreatedFromRegistryEvent): void {
  let market = Market.load(marketAddress.toHexString());
  if (market !== null) {
    log.info('Registry: Market {} already exists, skipping', [marketAddress.toHexString()]);
    return;
  }

  // 从链上读取市场信息
  let marketContract = WDL_Template.bind(marketAddress);

  market = new Market(marketAddress.toHexString());
  market.templateId = "WDL";
  market.matchId = marketContract.matchId();
  market.homeTeam = marketContract.homeTeam();
  market.awayTeam = marketContract.awayTeam();
  market.kickoffTime = marketContract.kickoffTime();
  market.ruleVer = Bytes.empty();
  market.state = "Open";
  market.createdAt = event.block.timestamp;
  market.totalVolume = ZERO_BD;
  market.feeAccrued = ZERO_BD;
  market.lpLiquidity = ZERO_BD;
  market.uniqueBettors = 0;
  market.oracle = null;
  market.pricingEngine = marketContract.pricingEngine();
  market.save();

  log.info('Registry: Created WDL market entity: {} vs {}', [
    market.homeTeam,
    market.awayTeam,
  ]);

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalMarkets = stats.totalMarkets + 1;
  stats.activeMarkets = stats.activeMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 从链上读取并创建 OU Market 实体
 */
function createOUMarketEntity(marketAddress: Address, event: MarketCreatedFromRegistryEvent): void {
  let market = Market.load(marketAddress.toHexString());
  if (market !== null) {
    log.info('Registry: Market {} already exists, skipping', [marketAddress.toHexString()]);
    return;
  }

  // 从链上读取市场信息
  let marketContract = OU_Template.bind(marketAddress);

  market = new Market(marketAddress.toHexString());
  market.templateId = "OU";
  market.matchId = marketContract.matchId();
  market.homeTeam = marketContract.homeTeam();
  market.awayTeam = marketContract.awayTeam();
  market.kickoffTime = marketContract.kickoffTime();
  market.ruleVer = Bytes.empty();
  market.state = "Open";
  market.createdAt = event.block.timestamp;
  market.totalVolume = ZERO_BD;
  market.feeAccrued = ZERO_BD;
  market.lpLiquidity = ZERO_BD;
  market.uniqueBettors = 0;
  market.oracle = null;
  market.pricingEngine = marketContract.pricingEngine();
  market.save();

  log.info('Registry: Created OU market entity: {} vs {}', [
    market.homeTeam,
    market.awayTeam,
  ]);

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalMarkets = stats.totalMarkets + 1;
  stats.activeMarkets = stats.activeMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 从链上读取并创建 OddEven Market 实体
 */
function createOddEvenMarketEntity(marketAddress: Address, event: MarketCreatedFromRegistryEvent): void {
  let market = Market.load(marketAddress.toHexString());
  if (market !== null) {
    log.info('Registry: Market {} already exists, skipping', [marketAddress.toHexString()]);
    return;
  }

  // 从链上读取市场信息
  let marketContract = OddEven_Template.bind(marketAddress);

  market = new Market(marketAddress.toHexString());
  market.templateId = "OddEven";
  market.matchId = marketContract.matchId();
  market.homeTeam = marketContract.homeTeam();
  market.awayTeam = marketContract.awayTeam();
  market.kickoffTime = marketContract.kickoffTime();
  market.ruleVer = Bytes.empty();
  market.state = "Open";
  market.createdAt = event.block.timestamp;
  market.totalVolume = ZERO_BD;
  market.feeAccrued = ZERO_BD;
  market.lpLiquidity = ZERO_BD;
  market.uniqueBettors = 0;
  market.oracle = null;
  market.pricingEngine = marketContract.pricingEngine();
  market.save();

  log.info('Registry: Created OddEven market entity: {} vs {}', [
    market.homeTeam,
    market.awayTeam,
  ]);

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalMarkets = stats.totalMarkets + 1;
  stats.activeMarkets = stats.activeMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理模板注册事件
 */
export function handleTemplateRegistered(event: TemplateRegisteredEvent): void {
  const templateId = event.params.templateId;
  const implementation = event.params.implementation;
  const name = event.params.name;
  const version = event.params.version;

  log.info('Registry: Template registered - id: {}, name: {}, version: {}, impl: {}', [
    templateId.toHexString(),
    name,
    version,
    implementation.toHexString(),
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
 * 处理模板注销事件
 */
export function handleTemplateUnregistered(event: TemplateUnregisteredEvent): void {
  const templateId = event.params.templateId;
  const implementation = event.params.implementation;

  log.info('Registry: Template unregistered - id: {}, impl: {}', [
    templateId.toHexString(),
    implementation.toHexString(),
  ]);

  // 删除模板实体
  let template = Template.load(templateId.toHexString());
  if (template !== null) {
    template.active = false;
    template.save();
  }

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理模板激活状态更新事件
 */
export function handleTemplateActiveStatusUpdated(event: TemplateActiveStatusUpdatedEvent): void {
  const templateId = event.params.templateId;
  const active = event.params.active;

  log.info('Registry: Template {} active status updated to {}', [
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
 * 注册已部署的市场（用于迁移现有市场）
 * 这些市场是在 Subgraph 部署之前创建的，需要手动注册
 */
export function registerExistingMarkets(): void {
  // WDL Market: Barcelona vs Real Madrid
  WDLMarket.create(Address.fromString('0x4A679253410272dd5232B3Ff7cF5dbB88f295319'));

  // OU Single-Line Market: Bayern vs Dortmund
  OUMarket.create(Address.fromString('0x7a2088a1bFc9d81c55368AE168C2C02570cB814F'));

  // OU Multi-Line Market: PSG vs Lyon
  OUMultiMarket.create(Address.fromString('0x09635F643e140090A9A8Dcd712eD6285858ceBef'));
}
