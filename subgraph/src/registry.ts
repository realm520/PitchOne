/**
 * PitchOne Subgraph - 注册表事件处理器
 * 处理市场模板注册和市场创建事件
 */

import { BigInt } from "@graphprotocol/graph-ts";
import {
  MarketCreated as MarketCreatedEvent,
  TemplateRegistered as TemplateRegisteredEvent,
  TemplateActiveStatusUpdated as TemplateActiveStatusUpdatedEvent,
} from "../generated/MarketTemplateRegistry/MarketTemplateRegistry";
import { Market, Template, GlobalStats } from "../generated/schema";
import {
  loadOrCreateGlobalStats,
  ZERO_BI,
  ZERO_BD,
} from "./helpers";

// ============================================================================
// MarketCreated - 市场创建事件
// ============================================================================

export function handleMarketCreated(event: MarketCreatedEvent): void {
  const marketAddress = event.params.market;
  const templateId = event.params.templateId;
  const matchId = event.params.matchId;
  const ruleVer = event.params.ruleVer;

  // 创建市场实体
  let market = new Market(marketAddress.toHexString());
  market.templateId = templateId;
  market.matchId = matchId;
  market.ruleVer = ruleVer;
  market.state = "Open";
  market.createdAt = event.block.timestamp;
  market.lockedAt = null;
  market.resolvedAt = null;
  market.finalizedAt = null;
  market.winnerOutcome = null;
  market.params = null;
  market.totalVolume = ZERO_BD;
  market.feeAccrued = ZERO_BD;
  market.lpLiquidity = ZERO_BD;
  market.uniqueBettors = 0;
  market.oracle = null;
  market.pricingEngine = null;
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalMarkets = stats.totalMarkets + 1;
  stats.activeMarkets = stats.activeMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// TemplateRegistered - 模板注册事件
// ============================================================================

export function handleTemplateRegistered(event: TemplateRegisteredEvent): void {
  const templateId = event.params.templateId;
  const templateAddress = event.params.templateAddress;

  // 创建模板实体
  let template = new Template(templateAddress.toHexString());
  template.templateId = templateId;
  template.name = null; // 可以从链下数据源获取
  template.active = true;
  template.registeredAt = event.block.timestamp;
  template.save();
}

// ============================================================================
// TemplateActiveStatusUpdated - 模板激活状态更新事件
// ============================================================================

export function handleTemplateActiveStatusUpdated(
  event: TemplateActiveStatusUpdatedEvent
): void {
  const templateId = event.params.templateId;
  const active = event.params.active;

  // 注意：这里需要通过 templateId 查找 Template
  // 但 Template 的 ID 是地址，需要额外的映射关系
  // 简化处理：遍历所有 Template 实体（不推荐生产环境使用）
  // 生产环境应该维护一个 templateId -> address 的映射

  // TODO: 实现更高效的查找逻辑
  // 暂时跳过此功能
}
