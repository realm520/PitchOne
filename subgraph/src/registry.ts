/**
 * PitchOne Subgraph - Registry 事件处理器 (V3 架构)
 * 处理 MarketFactory_V3 的事件，实现动态市场索引
 */

import { Address, Bytes, log } from '@graphprotocol/graph-ts';
import {
  MarketCreated as MarketCreatedEvent,
  TemplateRegistered as TemplateRegisteredEvent,
  TemplateUpdated as TemplateUpdatedEvent,
} from '../generated/MarketFactory/MarketFactory_V3';
import { Market_V3 as Market_V3Template } from '../generated/templates';
import { Market_V3 } from '../generated/templates/Market_V3/Market_V3';
import { Template, GlobalStats, Market } from '../generated/schema';
import { loadOrCreateGlobalStats, ZERO_BD, parseTeamsFromMatchId } from './helpers';

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
  market.templateId = templateId.toHexString();
  market.matchId = matchId;
  market.kickoffTime = kickoffTime;

  // 从 matchId 解析球队信息
  let teams = parseTeamsFromMatchId(matchId);
  market.homeTeam = teams[0];
  market.awayTeam = teams[1];
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
