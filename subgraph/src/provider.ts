/**
 * PitchOne Subgraph - Liquidity Provider 事件处理器
 * 处理 LiquidityVault_V3 的事件
 */

import { Address, BigInt, Bytes, log } from "@graphprotocol/graph-ts";
import {
  Deposit as VaultDepositEvent,
  Withdraw as VaultWithdrawEvent,
  MarketAuthorized as MarketAuthorizedEvent,
  MarketRevoked as MarketRevokedEvent,
  LiquidityVault_V3,
} from "../generated/LiquidityVault/LiquidityVault_V3";
import {
  LiquidityProvider,
  MarketAuthorization,
} from "../generated/schema";
import { toDecimal, generateEventId } from "./helpers";

// ============================================================================
// LiquidityVault_V3 - Vault 存取款事件
// ============================================================================

/**
 * 处理 V3 Vault 存款事件
 */
export function handleDeposit(event: VaultDepositEvent): void {
  const vaultAddress = event.address;
  const sender = event.params.sender;
  const owner = event.params.owner;
  const assets = event.params.assets;
  const shares = event.params.shares;

  log.info("Vault V3: Deposit - vault: {}, sender: {}, owner: {}, assets: {}, shares: {}", [
    vaultAddress.toHexString(),
    sender.toHexString(),
    owner.toHexString(),
    assets.toString(),
    shares.toString(),
  ]);

  // 加载或创建 Provider 实体
  let provider = loadOrCreateProvider(vaultAddress);

  // 更新 Provider 状态
  updateProviderStateFromChain(provider, vaultAddress);
  provider.lastUpdatedAt = event.block.timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();
}

/**
 * 处理 V3 Vault 取款事件
 */
export function handleWithdraw(event: VaultWithdrawEvent): void {
  const vaultAddress = event.address;
  const sender = event.params.sender;
  const receiver = event.params.receiver;
  const owner = event.params.owner;
  const assets = event.params.assets;
  const shares = event.params.shares;

  log.info("Vault V3: Withdraw - vault: {}, sender: {}, receiver: {}, owner: {}, assets: {}, shares: {}", [
    vaultAddress.toHexString(),
    sender.toHexString(),
    receiver.toHexString(),
    owner.toHexString(),
    assets.toString(),
    shares.toString(),
  ]);

  // 加载或创建 Provider 实体
  let provider = loadOrCreateProvider(vaultAddress);

  // 更新 Provider 状态
  updateProviderStateFromChain(provider, vaultAddress);
  provider.lastUpdatedAt = event.block.timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();
}

/**
 * 处理 V3 Vault 市场授权事件
 */
export function handleMarketAuthorized(event: MarketAuthorizedEvent): void {
  const vaultAddress = event.address;
  const market = event.params.market;

  log.info("Vault V3: Market authorized - vault: {}, market: {}", [
    vaultAddress.toHexString(),
    market.toHexString(),
  ]);

  // 加载或创建 Provider 实体
  let provider = loadOrCreateProvider(vaultAddress);

  // 添加到授权市场列表
  let authorizedMarkets = provider.authorizedMarkets;
  let found = false;
  for (let i = 0; i < authorizedMarkets.length; i++) {
    if (authorizedMarkets[i].equals(market)) {
      found = true;
      break;
    }
  }
  if (!found) {
    authorizedMarkets.push(market);
    provider.authorizedMarkets = authorizedMarkets;
  }

  provider.lastUpdatedAt = event.block.timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();

  // 创建授权事件记录
  const eventId = generateEventId(event.transaction.hash, event.logIndex);
  let authEvent = new MarketAuthorization(eventId);
  authEvent.provider = provider.id;
  authEvent.market = market;
  authEvent.authorized = true;
  authEvent.timestamp = event.block.timestamp;
  authEvent.blockNumber = event.block.number;
  authEvent.transactionHash = event.transaction.hash;
  authEvent.save();
}

/**
 * 处理 V3 Vault 市场撤销授权事件
 */
export function handleMarketRevoked(event: MarketRevokedEvent): void {
  const vaultAddress = event.address;
  const market = event.params.market;

  log.info("Vault V3: Market revoked - vault: {}, market: {}", [
    vaultAddress.toHexString(),
    market.toHexString(),
  ]);

  // 加载或创建 Provider 实体
  let provider = loadOrCreateProvider(vaultAddress);

  // 从授权市场列表移除
  let authorizedMarkets = provider.authorizedMarkets;
  let newAuthorizedMarkets: Bytes[] = [];
  for (let i = 0; i < authorizedMarkets.length; i++) {
    if (!authorizedMarkets[i].equals(market)) {
      newAuthorizedMarkets.push(authorizedMarkets[i]);
    }
  }
  provider.authorizedMarkets = newAuthorizedMarkets;

  provider.lastUpdatedAt = event.block.timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();

  // 创建撤销授权事件记录
  const eventId = generateEventId(event.transaction.hash, event.logIndex);
  let authEvent = new MarketAuthorization(eventId);
  authEvent.provider = provider.id;
  authEvent.market = market;
  authEvent.authorized = false;
  authEvent.timestamp = event.block.timestamp;
  authEvent.blockNumber = event.block.number;
  authEvent.transactionHash = event.transaction.hash;
  authEvent.save();
}

// ============================================================================
// 辅助函数
// ============================================================================

/**
 * 加载或创建 LiquidityProvider 实体
 */
function loadOrCreateProvider(address: Bytes): LiquidityProvider {
  let provider = LiquidityProvider.load(address.toHexString());
  if (provider === null) {
    provider = new LiquidityProvider(address.toHexString());
    provider.providerType = "LiquidityVault_V3";
    provider.asset = Bytes.empty();
    provider.totalLiquidity = toDecimal(BigInt.zero());
    provider.availableLiquidity = toDecimal(BigInt.zero());
    provider.totalBorrowed = toDecimal(BigInt.zero());
    provider.utilizationRate = 0;
    provider.authorizedMarkets = [];
    provider.deployer = Bytes.empty();
    provider.createdAt = BigInt.zero();
    provider.createdAtBlock = BigInt.zero();
    provider.createdAtTransaction = Bytes.empty();
    provider.isPaused = false;
    provider.lastUpdatedAt = BigInt.zero();
    provider.lastUpdatedAtBlock = BigInt.zero();
  }
  return provider as LiquidityProvider;
}

/**
 * 从链上读取并更新 Provider 状态
 */
function updateProviderStateFromChain(provider: LiquidityProvider, address: Bytes): void {
  let contract = LiquidityVault_V3.bind(Address.fromBytes(address));

  // 尝试读取 totalAssets (映射到 totalLiquidity)
  let totalAssetsResult = contract.try_totalAssets();
  if (!totalAssetsResult.reverted) {
    provider.totalLiquidity = toDecimal(totalAssetsResult.value);
  }

  // 尝试读取 availableLiquidity
  let availableLiquidityResult = contract.try_availableLiquidity();
  if (!availableLiquidityResult.reverted) {
    provider.availableLiquidity = toDecimal(availableLiquidityResult.value);
  }

  // 尝试读取 utilizationRate
  let utilizationRateResult = contract.try_utilizationRate();
  if (!utilizationRateResult.reverted) {
    provider.utilizationRate = utilizationRateResult.value.toI32();
  }

  // 尝试读取 asset
  let assetResult = contract.try_asset();
  if (!assetResult.reverted) {
    provider.asset = assetResult.value;
  }
}
