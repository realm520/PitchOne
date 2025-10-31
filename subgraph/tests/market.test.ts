/**
 * PitchOne Subgraph - 市场事件测试
 * 使用 matchstick-as 测试框架
 */

import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll,
  createMockedFunction,
} from "matchstick-as/assembly/index";
import { Address, BigInt, Bytes, ethereum } from "@graphprotocol/graph-ts";
import { handleBetPlaced, handleLocked, handleResolved } from "../src/market";
import { Market, Order, User, GlobalStats } from "../generated/schema";
import { BetPlaced } from "../generated/WDL_Template/MarketBase";
import { newMockEvent } from "matchstick-as/assembly/index";

// ============================================================================
// 测试辅助函数
// ============================================================================

function createBetPlacedEvent(
  user: Address,
  outcome: i32,
  amount: BigInt,
  shares: BigInt
): BetPlaced {
  let event = changetype<BetPlaced>(newMockEvent());
  event.parameters = new Array();

  event.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  );
  event.parameters.push(
    new ethereum.EventParam(
      "outcome",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(outcome))
    )
  );
  event.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  );
  event.parameters.push(
    new ethereum.EventParam("shares", ethereum.Value.fromUnsignedBigInt(shares))
  );

  return event;
}

// ============================================================================
// 测试套件
// ============================================================================

describe("Market Event Handlers", () => {
  beforeAll(() => {
    // 设置测试环境
  });

  afterAll(() => {
    clearStore();
  });

  describe("handleBetPlaced", () => {
    test("should create Order and update User stats", () => {
      const userAddress = Address.fromString(
        "0x0000000000000000000000000000000000000001"
      );
      const outcome = 0;
      const amount = BigInt.fromI64(1000000); // 1 USDC (6 decimals)
      const shares = BigInt.fromI64(980000); // 0.98 shares

      const event = createBetPlacedEvent(userAddress, outcome, amount, shares);
      handleBetPlaced(event);

      // 验证 Order 创建
      const orderId = event.transaction.hash
        .toHexString()
        .concat("-")
        .concat(event.logIndex.toString());
      assert.fieldEquals("Order", orderId, "outcome", outcome.toString());
      assert.fieldEquals("Order", orderId, "shares", shares.toString());

      // 验证 User 统计更新
      assert.fieldEquals("User", userAddress.toHexString(), "totalBets", "1");

      clearStore();
    });

    test("should update GlobalStats volume", () => {
      const userAddress = Address.fromString(
        "0x0000000000000000000000000000000000000002"
      );
      const amount = BigInt.fromI64(2000000); // 2 USDC

      const event = createBetPlaced Event(userAddress, 1, amount, amount);
      handleBetPlaced(event);

      // 验证全局统计
      assert.fieldEquals("GlobalStats", "global", "totalMarkets", "1");

      clearStore();
    });

    test("should create Position with correct balance", () => {
      const userAddress = Address.fromString(
        "0x0000000000000000000000000000000000000003"
      );
      const marketAddress = Address.fromString(
        "0x1000000000000000000000000000000000000001"
      );
      const outcome = 2;
      const shares = BigInt.fromI64(5000000);

      const event = createBetPlacedEvent(userAddress, outcome, shares, shares);
      event.address = marketAddress;
      handleBetPlaced(event);

      // 验证 Position
      const positionId = marketAddress
        .toHexString()
        .concat("-")
        .concat(userAddress.toHexString())
        .concat("-")
        .concat(outcome.toString());
      assert.fieldEquals("Position", positionId, "balance", shares.toString());
      assert.fieldEquals("Position", positionId, "outcome", outcome.toString());

      clearStore();
    });
  });

  describe("handleLocked", () => {
    test("should update Market state to Locked", () => {
      // TODO: 实现 Locked 事件测试
      assert.assertTrue(true);
    });
  });

  describe("handleResolved", () => {
    test("should set winnerOutcome correctly", () => {
      // TODO: 实现 Resolved 事件测试
      assert.assertTrue(true);
    });
  });
});
