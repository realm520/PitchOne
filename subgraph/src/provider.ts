/**
 * PitchOne Subgraph - Liquidity Provider 事件处理器
 * 处理 ERC4626LiquidityProvider、ParimutuelLiquidityProvider 和 LiquidityProviderFactory 的事件
 */

import { Address, BigInt, Bytes, log } from "@graphprotocol/graph-ts";
import {
  LiquidityBorrowed as LiquidityBorrowedEvent,
  LiquidityRepaid as LiquidityRepaidEvent,
  MarketAuthorizationChanged as MarketAuthorizationChangedEvent,
  Paused as PausedEvent,
  Unpaused as UnpausedEvent,
} from "../generated/ERC4626LiquidityProvider/ERC4626LiquidityProvider";
import {
  Deposit as VaultDepositEvent,
  Withdraw as VaultWithdrawEvent,
} from "../generated/LiquidityVault_V3/LiquidityVault_V3";
import {
  PoolContribution as PoolContributionEvent,
  RevenueDistributed as RevenueDistributedEvent,
} from "../generated/ParimutuelLiquidityProvider/ParimutuelLiquidityProvider";
import {
  ProviderDeployed as ProviderDeployedEvent,
  ProviderTypeRegistered as ProviderTypeRegisteredEvent,
  DeployerAuthorized as DeployerAuthorizedEvent,
} from "../generated/LiquidityProviderFactory/LiquidityProviderFactory";
import {
  LiquidityProvider,
  LiquidityProviderFactory,
  LiquidityBorrowEvent,
  PoolContribution,
  MarketAuthorization,
  ProviderDeployment,
  ProviderTypeRegistration,
} from "../generated/schema";
import { toDecimal, generateEventId } from "./helpers";
import { ERC4626LiquidityProvider } from "../generated/ERC4626LiquidityProvider/ERC4626LiquidityProvider";

// ============================================================================
// LiquidityVault_V3 - Vault 存取款事件
// ============================================================================

/**
 * 处理 V3 Vault 存款事件
 */
export function handleVaultDeposit(event: VaultDepositEvent): void {
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
export function handleVaultWithdraw(event: VaultWithdrawEvent): void {
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

// ============================================================================
// ERC4626LiquidityProvider - 借贷事件
// ============================================================================

/**
 * 处理流动性借出事件
 */
export function handleLiquidityBorrowed(event: LiquidityBorrowedEvent): void {
  const providerAddress = event.address;
  const market = event.params.market;
  const amount = event.params.amount;
  const timestamp = event.params.timestamp;

  log.info("Provider: Liquidity borrowed - provider: {}, market: {}, amount: {}", [
    providerAddress.toHexString(),
    market.toHexString(),
    amount.toString(),
  ]);

  // 加载或创建 Provider 实体
  let provider = loadOrCreateProvider(providerAddress);

  // 创建借贷事件记录
  const eventId = generateEventId(event.transaction.hash, event.logIndex);
  let borrowEvent = new LiquidityBorrowEvent(eventId);
  borrowEvent.provider = provider.id;
  borrowEvent.market = market;
  borrowEvent.eventType = "Borrow";
  borrowEvent.principal = toDecimal(amount);
  borrowEvent.revenue = toDecimal(BigInt.zero()); // Borrow 事件无 revenue
  borrowEvent.timestamp = timestamp;
  borrowEvent.blockNumber = event.block.number;
  borrowEvent.transactionHash = event.transaction.hash;

  // 从链上读取 Provider 最新状态
  updateProviderStateFromChain(provider, providerAddress);

  // 保存事件快照
  borrowEvent.snapshotTotalLiquidity = provider.totalLiquidity;
  borrowEvent.snapshotAvailableLiquidity = provider.availableLiquidity;
  borrowEvent.snapshotUtilizationRate = provider.utilizationRate;
  borrowEvent.save();

  // 更新 Provider 状态
  provider.totalBorrowed = provider.totalBorrowed.plus(toDecimal(amount));
  provider.lastUpdatedAt = timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();
}

/**
 * 处理流动性归还事件
 */
export function handleLiquidityRepaid(event: LiquidityRepaidEvent): void {
  const providerAddress = event.address;
  const market = event.params.market;
  const principal = event.params.principal;
  const revenue = event.params.revenue;
  const timestamp = event.params.timestamp;

  log.info("Provider: Liquidity repaid - provider: {}, market: {}, principal: {}, revenue: {}", [
    providerAddress.toHexString(),
    market.toHexString(),
    principal.toString(),
    revenue.toString(),
  ]);

  // 加载 Provider 实体
  let provider = loadOrCreateProvider(providerAddress);

  // 创建还款事件记录
  const eventId = generateEventId(event.transaction.hash, event.logIndex);
  let repayEvent = new LiquidityBorrowEvent(eventId);
  repayEvent.provider = provider.id;
  repayEvent.market = market;
  repayEvent.eventType = "Repay";
  repayEvent.principal = toDecimal(principal);
  repayEvent.revenue = toDecimal(revenue);
  repayEvent.timestamp = timestamp;
  repayEvent.blockNumber = event.block.number;
  repayEvent.transactionHash = event.transaction.hash;

  // 从链上读取 Provider 最新状态
  updateProviderStateFromChain(provider, providerAddress);

  // 保存事件快照
  repayEvent.snapshotTotalLiquidity = provider.totalLiquidity;
  repayEvent.snapshotAvailableLiquidity = provider.availableLiquidity;
  repayEvent.snapshotUtilizationRate = provider.utilizationRate;
  repayEvent.save();

  // 更新 Provider 状态
  provider.totalBorrowed = provider.totalBorrowed.minus(toDecimal(principal));
  provider.lastUpdatedAt = timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();
}

/**
 * 处理市场授权变更事件（授权或撤销）
 */
export function handleMarketAuthorizationChanged(event: MarketAuthorizationChangedEvent): void {
  const providerAddress = event.address;
  const market = event.params.market;
  const authorized = event.params.authorized;

  log.info("Provider: Market authorization changed - provider: {}, market: {}, authorized: {}", [
    providerAddress.toHexString(),
    market.toHexString(),
    authorized.toString(),
  ]);

  // 加载 Provider 实体
  let provider = loadOrCreateProvider(providerAddress);

  // 根据 authorized 参数更新授权市场列表
  let authorizedMarkets = provider.authorizedMarkets;
  if (authorized) {
    // 授权：添加到列表（如果不存在）
    let found = false;
    for (let i = 0; i < authorizedMarkets.length; i++) {
      if (authorizedMarkets[i].equals(market)) {
        found = true;
        break;
      }
    }
    if (!found) {
      authorizedMarkets.push(market);
    }
  } else {
    // 撤销：从列表中移除
    let newAuthorizedMarkets: Bytes[] = [];
    for (let i = 0; i < authorizedMarkets.length; i++) {
      if (!authorizedMarkets[i].equals(market)) {
        newAuthorizedMarkets.push(authorizedMarkets[i]);
      }
    }
    authorizedMarkets = newAuthorizedMarkets;
  }

  provider.authorizedMarkets = authorizedMarkets;
  provider.lastUpdatedAt = event.block.timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();

  // 创建授权事件记录
  const eventId = generateEventId(event.transaction.hash, event.logIndex);
  let authEvent = new MarketAuthorization(eventId);
  authEvent.provider = provider.id;
  authEvent.market = market;
  authEvent.authorized = authorized;
  authEvent.timestamp = event.block.timestamp;
  authEvent.blockNumber = event.block.number;
  authEvent.transactionHash = event.transaction.hash;
  authEvent.save();
}

/**
 * 处理 Provider 暂停事件
 */
export function handlePaused(event: PausedEvent): void {
  const providerAddress = event.address;

  log.info("Provider: Paused - provider: {}", [providerAddress.toHexString()]);

  let provider = loadOrCreateProvider(providerAddress);
  provider.isPaused = true;
  provider.lastUpdatedAt = event.block.timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();
}

/**
 * 处理 Provider 恢复事件
 */
export function handleUnpaused(event: UnpausedEvent): void {
  const providerAddress = event.address;

  log.info("Provider: Unpaused - provider: {}", [providerAddress.toHexString()]);

  let provider = loadOrCreateProvider(providerAddress);
  provider.isPaused = false;
  provider.lastUpdatedAt = event.block.timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();
}

// ============================================================================
// ParimutuelLiquidityProvider - 彩池事件
// ============================================================================

/**
 * 处理彩池贡献事件
 */
export function handlePoolContribution(event: PoolContributionEvent): void {
  const providerAddress = event.address;
  const contributor = event.params.contributor;
  const amount = event.params.amount;
  const timestamp = event.params.timestamp;

  log.info("Provider: Pool contribution - provider: {}, contributor: {}, amount: {}", [
    providerAddress.toHexString(),
    contributor.toHexString(),
    amount.toString(),
  ]);

  // 加载 Provider 实体
  let provider = loadOrCreateProvider(providerAddress);

  // 创建贡献记录
  const eventId = generateEventId(event.transaction.hash, event.logIndex);
  let contribution = new PoolContribution(eventId);
  contribution.provider = provider.id;
  contribution.contributor = contributor;
  contribution.amount = toDecimal(amount);
  contribution.contributionShareBps = 0; // 需要从链上读取
  contribution.timestamp = timestamp;
  contribution.blockNumber = event.block.number;
  contribution.transactionHash = event.transaction.hash;
  contribution.save();

  // 更新 Provider 状态
  updateProviderStateFromChain(provider, providerAddress);
  provider.lastUpdatedAt = timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();
}

/**
 * 处理收益分配事件
 */
export function handleRevenueDistributed(event: RevenueDistributedEvent): void {
  const providerAddress = event.address;
  const amount = event.params.amount;
  const timestamp = event.params.timestamp;

  log.info("Provider: Revenue distributed - provider: {}, amount: {}", [
    providerAddress.toHexString(),
    amount.toString(),
  ]);

  // 加载 Provider 实体
  let provider = loadOrCreateProvider(providerAddress);

  // 更新 Provider 状态
  updateProviderStateFromChain(provider, providerAddress);
  provider.lastUpdatedAt = timestamp;
  provider.lastUpdatedAtBlock = event.block.number;
  provider.save();
}

// ============================================================================
// LiquidityProviderFactory - 工厂事件
// ============================================================================

/**
 * 处理 Provider 类型注册事件
 */
export function handleProviderTypeRegistered(event: ProviderTypeRegisteredEvent): void {
  const factoryAddress = event.address;
  const providerType = event.params.providerType.toString();
  const implementation = event.params.implementation;

  log.info("Factory: Provider type registered - factory: {}, type: {}, implementation: {}", [
    factoryAddress.toHexString(),
    providerType,
    implementation.toHexString(),
  ]);

  // 加载或创建 Factory 实体
  let factory = loadOrCreateFactory(factoryAddress);

  // 创建类型注册记录
  const registrationId = factoryAddress.toHexString() + "-" + providerType;
  let registration = new ProviderTypeRegistration(registrationId);
  registration.factory = factory.id;
  registration.providerType = providerType;
  registration.implementation = implementation;
  registration.registeredAt = event.block.timestamp;
  registration.registeredAtBlock = event.block.number;
  registration.registeredAtTransaction = event.transaction.hash;
  registration.save();

  // 更新 Factory 状态
  factory.save();
}

/**
 * 处理 Provider 部署事件
 */
export function handleProviderDeployed(event: ProviderDeployedEvent): void {
  const factoryAddress = event.address;
  const provider = event.params.provider;
  const providerType = event.params.providerType.toString();
  const deployer = event.params.deployer;
  const index = event.params.index;

  log.info("Factory: Provider deployed - factory: {}, provider: {}, type: {}, deployer: {}, index: {}", [
    factoryAddress.toHexString(),
    provider.toHexString(),
    providerType,
    deployer.toHexString(),
    index.toString(),
  ]);

  // 加载 Factory 实体
  let factory = loadOrCreateFactory(factoryAddress);

  // 创建部署记录
  const eventId = generateEventId(event.transaction.hash, event.logIndex);
  let deployment = new ProviderDeployment(eventId);
  deployment.factory = factory.id;
  deployment.provider = provider;
  deployment.providerType = providerType;
  deployment.deployer = deployer;
  deployment.deploymentIndex = index;
  deployment.deployedAt = event.block.timestamp;
  deployment.deployedAtBlock = event.block.number;
  deployment.deployedAtTransaction = event.transaction.hash;
  deployment.save();

  // 创建 Provider 实体
  let providerEntity = new LiquidityProvider(provider.toHexString());
  providerEntity.providerType = providerType;
  providerEntity.asset = Bytes.empty(); // 需要从链上读取
  providerEntity.totalLiquidity = toDecimal(BigInt.zero());
  providerEntity.availableLiquidity = toDecimal(BigInt.zero());
  providerEntity.totalBorrowed = toDecimal(BigInt.zero());
  providerEntity.utilizationRate = 0;
  providerEntity.authorizedMarkets = [];
  providerEntity.deployer = deployer;
  providerEntity.createdAt = event.block.timestamp;
  providerEntity.createdAtBlock = event.block.number;
  providerEntity.createdAtTransaction = event.transaction.hash;
  providerEntity.isPaused = false;
  providerEntity.lastUpdatedAt = event.block.timestamp;
  providerEntity.lastUpdatedAtBlock = event.block.number;

  // 从链上读取初始状态
  updateProviderStateFromChain(providerEntity, provider);
  providerEntity.save();

  // 更新 Factory 统计
  factory.totalDeployments = factory.totalDeployments.plus(BigInt.fromI32(1));
  factory.save();
}

/**
 * 处理 Deployer 授权事件
 */
export function handleDeployerAuthorized(event: DeployerAuthorizedEvent): void {
  const factoryAddress = event.address;
  const deployer = event.params.deployer;
  const authorized = event.params.authorized;

  log.info("Factory: Deployer authorized - factory: {}, deployer: {}, authorized: {}", [
    factoryAddress.toHexString(),
    deployer.toHexString(),
    authorized.toString(),
  ]);

  // 加载 Factory 实体
  let factory = loadOrCreateFactory(factoryAddress);

  // 更新授权的 Deployer 列表
  let authorizedDeployers = factory.authorizedDeployers;
  if (authorized) {
    // 添加
    let found = false;
    for (let i = 0; i < authorizedDeployers.length; i++) {
      if (authorizedDeployers[i].equals(deployer)) {
        found = true;
        break;
      }
    }
    if (!found) {
      authorizedDeployers.push(deployer);
    }
  } else {
    // 移除
    let newDeployers: Bytes[] = [];
    for (let i = 0; i < authorizedDeployers.length; i++) {
      if (!authorizedDeployers[i].equals(deployer)) {
        newDeployers.push(authorizedDeployers[i]);
      }
    }
    authorizedDeployers = newDeployers;
  }

  factory.authorizedDeployers = authorizedDeployers;
  factory.save();
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
    provider.providerType = "Unknown"; // 需要从链上读取或事件推断
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
 * 加载或创建 LiquidityProviderFactory 实体
 */
function loadOrCreateFactory(address: Bytes): LiquidityProviderFactory {
  let factory = LiquidityProviderFactory.load(address.toHexString());
  if (factory === null) {
    factory = new LiquidityProviderFactory(address.toHexString());
    factory.owner = Bytes.empty(); // 需要从链上读取
    factory.authorizedDeployers = [];
    factory.totalDeployments = BigInt.zero();
    factory.createdAt = BigInt.zero();
    factory.createdAtBlock = BigInt.zero();
  }
  return factory as LiquidityProviderFactory;
}

/**
 * 从链上读取并更新 Provider 状态
 */
function updateProviderStateFromChain(provider: LiquidityProvider, address: Bytes): void {
  let contract = ERC4626LiquidityProvider.bind(address as Address);

  // 尝试读取 totalLiquidity
  let totalLiquidityResult = contract.try_totalLiquidity();
  if (!totalLiquidityResult.reverted) {
    provider.totalLiquidity = toDecimal(totalLiquidityResult.value);
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

  // 尝试读取 providerType
  let providerTypeResult = contract.try_providerType();
  if (!providerTypeResult.reverted) {
    provider.providerType = providerTypeResult.value;
  }
}
