/**
 * PitchOne Subgraph - Registry 事件处理器 (V4 架构)
 * 处理 MarketFactory_V3 的事件，实现动态市场索引
 */

import { Address, Bytes, log } from '@graphprotocol/graph-ts';
import {
  MarketCreated as MarketCreatedV4Event,
  TemplateRegistered as TemplateRegisteredV4Event,
  TemplateUpdated as TemplateUpdatedV4Event,
} from '../generated/MarketFactory/MarketFactory_V3';
import { Market_V3 as Market_V3Template } from '../generated/templates';
import { Market_V3 } from '../generated/templates/Market_V3/Market_V3';
import { Template, GlobalStats, Market } from '../generated/schema';
import { loadOrCreateGlobalStats, ZERO_BD } from './helpers';

/**
 * 处理 V4 Factory 的 MarketCreated 事件
 * 创建动态数据源并初始化 Market 实体
 */
export function handleMarketCreatedV4(event: MarketCreatedV4Event): void {
  const marketAddress = event.params.market;
  const templateId = event.params.templateId;
  const matchId = event.params.matchId;
  const kickoffTime = event.params.kickoffTime;

  log.info('V4 Factory: Market created at {} with template {} for match {}', [
    marketAddress.toHexString(),
    templateId.toHexString(),
    matchId,
  ]);

  // 创建动态数据源
  Market_V3Template.create(marketAddress);

  // 创建 Market 实体
  let market = new Market(marketAddress.toHexString());
  market.templateId = templateId.toHexString();
  market.matchId = matchId;
  market.kickoffTime = kickoffTime;
  market.homeTeam = "";  // 将在 MarketInitialized 事件中更新
  market.awayTeam = "";
  market.ruleVer = Bytes.empty();
  market.state = "Open";
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
 * 处理 V4 模板注册事件
 */
export function handleTemplateRegisteredV4(event: TemplateRegisteredV4Event): void {
  const templateId = event.params.templateId;
  const name = event.params.name;
  const strategyType = event.params.strategyType;

  log.info('V4 Factory: Template registered - id: {}, name: {}, strategy: {}', [
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
 * 处理 V4 模板更新事件
 */
export function handleTemplateUpdatedV4(event: TemplateUpdatedV4Event): void {
  const templateId = event.params.templateId;
  const active = event.params.active;

  log.info('V4 Factory: Template {} active status updated to {}', [
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

// ============================================================================
// 旧版处理器（已废弃，保留用于兼容性）
// ============================================================================

/**
 * @deprecated 使用 handleMarketCreatedV4
 */
export function handleMarketCreatedFromRegistry(): void {
  log.warning('handleMarketCreatedFromRegistry is deprecated, use handleMarketCreatedV4', []);
}

/**
 * @deprecated 使用 handleTemplateRegisteredV4
 */
export function handleTemplateRegistered(): void {
  log.warning('handleTemplateRegistered is deprecated, use handleTemplateRegisteredV4', []);
}

/**
 * @deprecated 使用 handleTemplateUpdatedV4
 */
export function handleTemplateActiveStatusUpdated(): void {
  log.warning('handleTemplateActiveStatusUpdated is deprecated, use handleTemplateUpdatedV4', []);
}
