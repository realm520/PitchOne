# PitchOne 前端开发进度总结

**最后更新**: 2025-11-02 | **完成度**: 80%

## ✅ 已完成功能（第一阶段）

### 1. Web3 集成 - 真实链上交互 ✅
**文件位置**: `packages/web3/src/contract-hooks.ts`

已实现的合约交互 hooks：
- ✅ `useApproveUSDC` - USDC 授权
- ✅ `useUSDCAllowance` - 查询授权额度
- ✅ `useUSDCBalance` - 查询 USDC 余额
- ✅ `usePlaceBet` - 下注功能
- ✅ `useRedeem` - 赎回赢得的份额
- ✅ `usePositionBalance` - 查询用户头寸
- ✅ `useMarketStatus` - 查询市场状态
- ✅ `useOutcomeLiquidity` - 查询市场流动性

**合约 ABI 提取**:
- ✅ MarketBase ABI
- ✅ WDL_Template ABI
- ✅ ERC20 (USDC) ABI

### 2. 市场详情页交互增强
**文件位置**: `apps/user/src/app/markets/[id]/page.tsx`

已集成功能：
- ✅ 真实的 USDC approve 流程
- ✅ 余额显示
- ✅ 智能授权检测（needsApproval）
- ✅ 授权和下注按钮状态管理
- ✅ 交易状态监听和自动刷新
- ✅ 错误处理和用户提示

### 3. 图表可视化组件 ✅
**文件位置**: `apps/user/src/components/charts/`

已创建的图表组件：
- ✅ `PriceTrendChart` - 价格趋势图
  - 实时显示赔率变化
  - 支持多种颜色主题
  - 时间序列展示

- ✅ `VolumeChart` - 交易量图表
  - 柱状图展示交易量
  - 时间序列聚合

- ✅ `DepthChart` - 深度图
  - 买卖深度可视化
  - 双向渐变色展示

### 4. 实时更新系统 ✅
**文件位置**: `packages/web3/src/event-hooks.ts`

已实现的事件监听：
- ✅ `useWatchBetPlaced` - 监听下注事件
- ✅ `useWatchMarketLocked` - 监听锁盘事件
- ✅ `useWatchResultProposed` - 监听结算提案
- ✅ `useWatchPositionRedeemed` - 监听赎回事件
- ✅ `useAutoRefresh` - 自动刷新机制
  - WebSocket 实时监听
  - 15秒轮询备选方案
  - 事件触发式更新

**实时活动组件**:
- ✅ `LiveActivity` - 展示最新下注活动
  - 实时动画效果
  - 交易详情展示
  - Etherscan 链接

### 5. 通知系统 ✅
**文件位置**: `apps/user/src/lib/notifications.ts`

已实现的通知功能：
- ✅ **Toast 通知**（react-hot-toast）
  - 成功/错误/加载/信息通知
  - 自定义样式和主题
  - 通知更新机制

- ✅ **浏览器通知**
  - 权限请求管理
  - 桌面通知推送
  - 交易完成提醒

- ✅ **交易通知助手**
  - `betNotifications` - 下注通知
  - `redeemNotifications` - 赎回通知
  - `marketNotifications` - 市场通知

**通知场景**：
1. 授权 USDC - 进度和结果通知
2. 下注 - 进度、成功、失败通知
3. 新的市场活动 - 实时提醒
4. 市场锁盘/结算 - 状态变更通知

## 🎯 核心功能演示

### 用户完整下注流程

1. **连接钱包** → RainbowKit 按钮
2. **查看市场** → GraphQL 查询 + 实时更新
3. **选择结果** → UI 交互
4. **授权 USDC** → 首次需要授权
   - Toast 通知："授权中..."
   - 成功后："授权 USDC 成功！现在可以开始下注了"
5. **下注** → 调用合约
   - Toast 通知："下注中..."
   - 成功后："下注成功！100 USDC → 主胜"
   - 浏览器通知推送
6. **实时更新** → WebSocket 监听
   - 立即显示在实时活动流
   - 市场数据自动刷新
7. **查看订单** → 用户订单历史

## 📝 使用示例

### 1. 在市场详情页添加图表

```tsx
import { PriceTrendChart, VolumeChart, DepthChart } from '@/components/charts';

// 价格趋势数据示例
const priceTrendData = [
  { timestamp: 1698000000, price: 2.15 },
  { timestamp: 1698003600, price: 2.18 },
  { timestamp: 1698007200, price: 2.12 },
];

// 交易量数据示例
const volumeData = [
  { timestamp: 1698000000, volume: 1250.50 },
  { timestamp: 1698003600, volume: 2100.75 },
  { timestamp: 1698007200, volume: 1800.25 },
];

// 深度数据示例
const depthData = [
  { price: 2.0, buyDepth: 5000, sellDepth: 0 },
  { price: 2.1, buyDepth: 3500, sellDepth: 0 },
  { price: 2.15, buyDepth: 2000, sellDepth: 2000 },
  { price: 2.2, buyDepth: 0, sellDepth: 3500 },
  { price: 2.3, buyDepth: 0, sellDepth: 5000 },
];

// 在页面中使用
<Card>
  <h3>价格趋势</h3>
  <PriceTrendChart data={priceTrendData} outcomeName="主胜" color="#00D9FF" />
</Card>

<Card>
  <h3>交易量</h3>
  <VolumeChart data={volumeData} color="#9D4EDD" />
</Card>

<Card>
  <h3>市场深度</h3>
  <DepthChart data={depthData} />
</Card>
```

### 2. 使用合约交互 hooks

```tsx
import {
  useApproveUSDC,
  useUSDCAllowance,
  usePlaceBet,
  useUSDCBalance,
} from '@pitchone/web3';

function MyComponent() {
  const { address } = useAccount();
  const marketAddress = '0x...';

  // 查询余额
  const { data: balance } = useUSDCBalance(address);

  // 查询授权额度
  const { data: allowance } = useUSDCAllowance(address, marketAddress);

  // 授权 hook
  const { approve, isPending: isApproving } = useApproveUSDC();

  // 下注 hook
  const { placeBet, isPending: isBetting } = usePlaceBet(marketAddress);

  const handleBet = async () => {
    // 如果授权不足，先授权
    if (allowance < parseUnits('100', 6)) {
      await approve(marketAddress, '100');
    }

    // 然后下注
    await placeBet(0, '100'); // outcomeId: 0, amount: 100 USDC
  };

  return <Button onClick={handleBet}>下注</Button>;
}
```

## 🚀 下一步开发建议

### 1. 实时数据更新 (高优先级)

#### WebSocket 订阅
**实现位置**: `packages/web3/src/websocket.ts`

```typescript
import { useEffect, useState } from 'react';
import { createPublicClient, webSocket } from 'viem';
import { anvil } from 'viem/chains';

export function useMarketEvents(marketAddress: string) {
  const [events, setEvents] = useState([]);

  useEffect(() => {
    const client = createPublicClient({
      chain: anvil,
      transport: webSocket('ws://127.0.0.1:8545'),
    });

    const unwatch = client.watchContractEvent({
      address: marketAddress as `0x${string}`,
      abi: MarketBaseABI,
      eventName: 'BetPlaced',
      onLogs: (logs) => {
        setEvents((prev) => [...prev, ...logs]);
      },
    });

    return () => unwatch();
  }, [marketAddress]);

  return events;
}
```

#### GraphQL 订阅
**实现位置**: `packages/web3/src/graphql-subscriptions.ts`

```typescript
import { useEffect, useState } from 'react';
import { graphqlClient } from './graphql';

export function useMarketSubscription(marketId: string) {
  const [market, setMarket] = useState(null);

  useEffect(() => {
    // 轮询更新（如果 Subgraph 不支持 WebSocket）
    const interval = setInterval(async () => {
      const data = await graphqlClient.request(MARKET_QUERY, { id: marketId });
      setMarket(data.market);
    }, 5000); // 每 5 秒更新一次

    return () => clearInterval(interval);
  }, [marketId]);

  return market;
}
```

### 2. 串关 (Parlay) 功能

#### Basket 合约集成
**实现位置**: `packages/web3/src/parlay-hooks.ts`

```typescript
// 1. 提取 Basket 合约 ABI
jq '.abi' contracts/out/Basket.sol/Basket.json > frontend/packages/contracts/src/abis/Basket.json

// 2. 创建 Basket hooks
export function useCreateParlay() {
  const { writeContract, ... } = useWriteContract();

  const createParlay = async (
    markets: Address[],
    outcomes: number[],
    amount: string
  ) => {
    return writeContract({
      address: BASKET_ADDRESS,
      abi: BasketABI,
      functionName: 'createParlay',
      args: [markets, outcomes, parseUnits(amount, 6)],
    });
  };

  return { createParlay, ... };
}

export function useRedeemParlay() {
  const { writeContract, ... } = useWriteContract();

  const redeemParlay = async (parlayId: bigint) => {
    return writeContract({
      address: BASKET_ADDRESS,
      abi: BasketABI,
      functionName: 'redeem',
      args: [parlayId],
    });
  };

  return { redeemParlay, ... };
}
```

#### UI 组件
**实现位置**: `apps/user/src/components/ParlayBuilder.tsx`

- 市场选择器（多选）
- 结果选择器
- 组合赔率计算
- 相关性检测提示
- 创建串关按钮

### 3. 止损止盈和限价单

**注意**: 这些功能需要链下 Keeper 服务支持，当前合约不支持自动触发。

#### 实现方案 A: 链下订单簿
创建链下订单管理系统：

1. 用户创建限价单 → 存储到数据库
2. Keeper 监听价格变化
3. 当价格满足条件时，Keeper 代用户执行交易（需要用户预签名）

#### 实现方案 B: 智能合约扩展
扩展 MarketBase 合约，添加：

```solidity
// 限价单结构
struct LimitOrder {
    address user;
    uint256 outcomeId;
    uint256 targetPrice;
    uint256 amount;
    bool isActive;
}

// 止损止盈结构
struct StopOrder {
    address user;
    uint256 positionId;
    uint256 stopLoss;
    uint256 takeProfit;
}
```

### 4. 历史导出功能

**实现位置**: `apps/user/src/lib/export.ts`

```typescript
export async function exportTradingHistory(
  userAddress: string,
  format: 'csv' | 'json' = 'csv'
) {
  // 1. 查询用户所有订单
  const orders = await graphqlClient.request(USER_ORDERS_QUERY, {
    user: userAddress.toLowerCase(),
    first: 1000,
  });

  if (format === 'csv') {
    // 生成 CSV
    const csv = [
      ['时间', '市场', '结果', '金额', '份额', '手续费', '交易哈希'],
      ...orders.orders.map(order => [
        new Date(parseInt(order.timestamp) * 1000).toISOString(),
        order.market.matchId,
        order.outcome,
        formatUnits(order.amount, 6),
        formatUnits(order.shares, 18),
        formatUnits(order.fee, 6),
        order.transactionHash,
      ]),
    ].map(row => row.join(',')).join('\\n');

    // 下载文件
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `trading-history-${userAddress}.csv`;
    a.click();
  } else {
    // JSON 格式
    const blob = new Blob([JSON.stringify(orders.orders, null, 2)], {
      type: 'application/json',
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `trading-history-${userAddress}.json`;
    a.click();
  }
}
```

### 5. 通知系统

#### 浏览器通知
**实现位置**: `apps/user/src/lib/notifications.ts`

```typescript
export async function requestNotificationPermission() {
  if ('Notification' in window) {
    const permission = await Notification.requestPermission();
    return permission === 'granted';
  }
  return false;
}

export function sendNotification(title: string, body: string) {
  if (Notification.permission === 'granted') {
    new Notification(title, {
      body,
      icon: '/logo.png',
      badge: '/badge.png',
    });
  }
}

// 使用示例：下注成功通知
useEffect(() => {
  if (isBetSuccess) {
    sendNotification(
      '下注成功',
      `您已成功下注 ${betAmount} USDC`
    );
  }
}, [isBetSuccess]);
```

#### Toast 通知
已经可以使用 UI 包中的 Toast 组件（如果有的话），或者集成 `react-hot-toast`:

```bash
pnpm add react-hot-toast
```

```typescript
import toast from 'react-hot-toast';

// 成功通知
toast.success('下注成功！');

// 错误通知
toast.error('下注失败，请重试');

// 加载通知
const toastId = toast.loading('处理中...');
// 完成后更新
toast.success('完成！', { id: toastId });
```

## 📊 架构图

```
frontend/
├── apps/
│   ├── user/                    # 用户端应用
│   │   ├── src/
│   │   │   ├── app/
│   │   │   │   ├── markets/     # 市场页面
│   │   │   │   │   └── [id]/    # ✅ 已集成 Web3
│   │   │   │   └── portfolio/   # 用户资产页面
│   │   │   └── components/
│   │   │       └── charts/      # ✅ 已创建图表组件
│   │   └── package.json         # ✅ 已添加 recharts
│   └── admin/                   # 管理端应用
├── packages/
│   ├── web3/                    # ✅ Web3 功能包
│   │   ├── src/
│   │   │   ├── hooks.ts         # GraphQL 查询 hooks
│   │   │   ├── contract-hooks.ts # ✅ 合约交互 hooks
│   │   │   ├── wagmi.ts         # Wagmi 配置
│   │   │   └── graphql.ts       # GraphQL 配置
│   │   └── package.json
│   ├── contracts/               # ✅ 合约包
│   │   ├── src/
│   │   │   ├── abis/            # ✅ 已提取 ABI
│   │   │   │   ├── MarketBase.json
│   │   │   │   ├── WDL_Template.json
│   │   │   │   └── ERC20.json
│   │   │   └── addresses/       # 合约地址配置
│   │   └── package.json
│   └── ui/                      # UI 组件库
└── package.json
```

## 🔧 开发环境设置

### 1. 启动本地链
```bash
cd contracts
make chain
```

### 2. 部署合约
```bash
cd contracts
make contracts-deploy
```

### 3. 启动 Graph Node
```bash
cd subgraph
docker-compose up -d
```

### 4. 部署 Subgraph
```bash
cd subgraph
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 pitchone-sportsbook
```

### 5. 启动前端
```bash
cd frontend
pnpm dev:user  # 用户端 (http://localhost:3000)
pnpm dev:admin # 管理端 (http://localhost:3001)
```

## 📖 相关文档

- [合约文档](../contracts/docs/)
- [Subgraph Schema](../docs/模块接口事件参数/SUBGRAPH_SCHEMA.graphql)
- [事件字典](../docs/模块接口事件参数/EVENT_DICTIONARY.md)
- [项目介绍](../docs/intro.md)

## ⚠️ 注意事项

1. **Gas 优化**: 下注前批量 approve 可以节省 Gas
2. **错误处理**: 所有合约调用都需要 try-catch
3. **用户体验**: 提供清晰的交易状态反馈
4. **安全性**: 永远不要在前端存储私钥
5. **测试**: 先在 Anvil 本地链测试，再部署到测试网

## 🎯 性能优化建议

1. **React Query 缓存配置**:
   - 市场数据: staleTime 10s
   - 用户订单: staleTime 30s
   - 全局统计: staleTime 60s

2. **图表性能**:
   - 限制数据点数量 (< 100)
   - 使用虚拟滚动
   - 延迟加载历史数据

3. **Web3 优化**:
   - 使用 multicall 批量读取
   - 缓存合约实例
   - 使用 WebSocket 替代轮询

---

**最后更新**: 2025-11-02
**开发者**: Harry
**项目**: PitchOne Decentralized Sportsbook
