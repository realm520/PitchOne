/**
 * PitchOne Subgraph - CreditToken 免佣券事件处理器
 * 处理券种创建、使用、转移等事件
 */

import { BigInt, Bytes, BigDecimal, Address } from "@graphprotocol/graph-ts";
import {
  CreditTypeCreated as CreditTypeCreatedEvent,
  CreditTypeStatusUpdated as CreditTypeStatusUpdatedEvent,
  CreditUsed as CreditUsedEvent,
  CreditBatchMinted as CreditBatchMintedEvent,
  TransferSingle as TransferSingleEvent,
  TransferBatch as TransferBatchEvent,
} from "../generated/CreditToken/CreditToken";
import {
  CreditType,
  CreditUsage,
  CreditBalance,
  User,
} from "../generated/schema";
import {
  loadOrCreateUser,
  toDecimal,
  ZERO_BD,
  ZERO_BI,
  ONE_BI,
} from "./helpers";

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * 加载或创建用户券余额
 */
function loadOrCreateCreditBalance(
  creditTypeId: string,
  userAddress: Address
): CreditBalance {
  const balanceId = creditTypeId + "-" + userAddress.toHexString();
  let balance = CreditBalance.load(balanceId);

  if (balance === null) {
    balance = new CreditBalance(balanceId);
    balance.creditType = creditTypeId;
    balance.user = userAddress;
    balance.balance = ZERO_BI;
    balance.usedCount = 0;
    balance.lastUpdatedAt = ZERO_BI;
  }

  return balance;
}

// ============================================================================
// Event Handlers
// ============================================================================

/**
 * 处理券种创建事件
 */
export function handleCreditTypeCreated(
  event: CreditTypeCreatedEvent
): void {
  const creditTypeId = event.params.creditTypeId.toString();

  let creditType = new CreditType(creditTypeId);
  creditType.value = toDecimal(event.params.value, 6); // USDC 6 decimals
  creditType.discountBps = event.params.discountBps.toI32();
  creditType.expiresAt = event.params.expiresAt;
  creditType.maxUses = event.params.maxUses.toI32();
  creditType.isActive = true;
  creditType.metadata = "";
  creditType.totalSupply = ZERO_BI;
  creditType.totalUsed = ZERO_BI;
  creditType.createdAt = event.block.timestamp;
  creditType.blockNumber = event.block.number;
  creditType.transactionHash = event.transaction.hash;
  creditType.save();
}

/**
 * 处理券种状态更新事件
 */
export function handleCreditTypeStatusUpdated(
  event: CreditTypeStatusUpdatedEvent
): void {
  const creditTypeId = event.params.creditTypeId.toString();

  let creditType = CreditType.load(creditTypeId);
  if (creditType !== null) {
    creditType.isActive = event.params.isActive;
    creditType.save();
  }
}

/**
 * 处理券使用事件
 */
export function handleCreditUsed(event: CreditUsedEvent): void {
  const creditTypeId = event.params.creditTypeId.toString();
  const userAddress = event.params.user;
  const usageId =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  const amount = event.params.amount;

  // 创建使用记录
  let usage = new CreditUsage(usageId);
  usage.creditType = creditTypeId;
  usage.user = userAddress.toHexString();
  usage.amount = amount.toI32();
  usage.discountValue = toDecimal(event.params.discountValue, 6);
  usage.timestamp = event.block.timestamp;
  usage.blockNumber = event.block.number;
  usage.transactionHash = event.transaction.hash;
  usage.save();

  // 更新券种统计
  let creditType = CreditType.load(creditTypeId);
  if (creditType !== null) {
    creditType.totalUsed = creditType.totalUsed.plus(amount);
    creditType.save();
  }

  // 更新用户余额（usedCount）
  let balance = loadOrCreateCreditBalance(creditTypeId, userAddress);
  balance.usedCount += amount.toI32();
  balance.lastUpdatedAt = event.block.timestamp;
  balance.save();

  // 确保用户实体存在
  loadOrCreateUser(userAddress);
}

/**
 * 处理批量发放事件
 */
export function handleCreditBatchMinted(
  event: CreditBatchMintedEvent
): void {
  const creditTypeId = event.params.creditTypeId.toString();
  const totalAmount = event.params.totalAmount;

  // 更新券种总发行量
  let creditType = CreditType.load(creditTypeId);
  if (creditType !== null) {
    creditType.totalSupply = creditType.totalSupply.plus(totalAmount);
    creditType.save();
  }

  // 注意：具体的用户余额更新将由 TransferSingle 事件处理
}

/**
 * 处理单个 ERC-1155 转移事件
 */
export function handleTransferSingle(event: TransferSingleEvent): void {
  const creditTypeId = event.params.id.toString();
  const from = event.params.from;
  const to = event.params.to;
  const value = event.params.value;

  const ZERO_ADDRESS = Address.fromString(
    "0x0000000000000000000000000000000000000000"
  );

  // 铸造（from = 0x0）
  if (from.equals(ZERO_ADDRESS)) {
    let balance = loadOrCreateCreditBalance(creditTypeId, to);
    balance.balance = balance.balance.plus(value);
    balance.lastUpdatedAt = event.block.timestamp;
    balance.save();

    // 确保用户实体存在
    loadOrCreateUser(to);
  }
  // 销毁（to = 0x0）
  else if (to.equals(ZERO_ADDRESS)) {
    let balance = loadOrCreateCreditBalance(creditTypeId, from);
    balance.balance = balance.balance.minus(value);
    balance.lastUpdatedAt = event.block.timestamp;
    balance.save();
  }
  // 正常转移
  else {
    // 减少发送方余额
    let fromBalance = loadOrCreateCreditBalance(creditTypeId, from);
    fromBalance.balance = fromBalance.balance.minus(value);
    fromBalance.lastUpdatedAt = event.block.timestamp;
    fromBalance.save();

    // 增加接收方余额
    let toBalance = loadOrCreateCreditBalance(creditTypeId, to);
    toBalance.balance = toBalance.balance.plus(value);
    toBalance.lastUpdatedAt = event.block.timestamp;
    toBalance.save();

    // 确保用户实体存在
    loadOrCreateUser(to);
  }
}

/**
 * 处理批量 ERC-1155 转移事件
 */
export function handleTransferBatch(event: TransferBatchEvent): void {
  const ids = event.params.ids;
  const values = event.params.values;
  const from = event.params.from;
  const to = event.params.to;

  const ZERO_ADDRESS = Address.fromString(
    "0x0000000000000000000000000000000000000000"
  );

  for (let i = 0; i < ids.length; i++) {
    const creditTypeId = ids[i].toString();
    const value = values[i];

    // 铸造
    if (from.equals(ZERO_ADDRESS)) {
      let balance = loadOrCreateCreditBalance(creditTypeId, to);
      balance.balance = balance.balance.plus(value);
      balance.lastUpdatedAt = event.block.timestamp;
      balance.save();
    }
    // 销毁
    else if (to.equals(ZERO_ADDRESS)) {
      let balance = loadOrCreateCreditBalance(creditTypeId, from);
      balance.balance = balance.balance.minus(value);
      balance.lastUpdatedAt = event.block.timestamp;
      balance.save();
    }
    // 正常转移
    else {
      let fromBalance = loadOrCreateCreditBalance(creditTypeId, from);
      fromBalance.balance = fromBalance.balance.minus(value);
      fromBalance.lastUpdatedAt = event.block.timestamp;
      fromBalance.save();

      let toBalance = loadOrCreateCreditBalance(creditTypeId, to);
      toBalance.balance = toBalance.balance.plus(value);
      toBalance.lastUpdatedAt = event.block.timestamp;
      toBalance.save();
    }
  }

  // 确保用户实体存在
  if (!to.equals(ZERO_ADDRESS)) {
    loadOrCreateUser(to);
  }
}
