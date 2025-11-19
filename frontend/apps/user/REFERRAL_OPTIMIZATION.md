# 推荐系统性能优化和改进建议

## 性能优化

### 1. GraphQL 查询优化

#### 1.1 批量查询合并
**问题**: 多个组件独立查询 Subgraph,导致重复请求

**当前实现**:
```tsx
// ReferralStats 查询
const { stats } = useReferrerStats(address);

// ReferralList 查询
const { referrals } = useReferrals(address, 20, 0);

// ReferralRewardsHistory 查询
const { rewards } = useReferralRewards(address, 50);
```

**优化方案**: 使用单一查询获取所有数据
```tsx
// 新建 hooks/useReferralFullData.ts
export function useReferralFullData(address?: Address) {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!address) return;

    const query = `
      query ReferralFullData($referrerId: ID!, $first: Int, $rewardsFirst: Int) {
        referrerStats(id: $referrerId) {
          id
          referralCount
          totalRewards
          validReferralCount
          lastUpdatedAt
          referrals(first: $first, orderBy: boundAt, orderDirection: desc) {
            id
            referee { id totalBetAmount totalBets }
            boundAt
          }
          rewardRecords(first: $rewardsFirst, orderBy: timestamp, orderDirection: desc) {
            id
            referee { id }
            amount
            timestamp
            transactionHash
          }
        }
      }
    `;

    fetchData(query, { referrerId, first: 20, rewardsFirst: 50 });
  }, [address]);

  return { data, loading };
}
```

**预期收益**: 减少 70% 的 API 请求数

---

#### 1.2 分页优化
**问题**: 每次翻页都重新查询所有数据

**优化方案**: 使用游标分页和本地缓存
```tsx
export function useReferralsPaginated(address?: Address, pageSize = 20) {
  const [allReferrals, setAllReferrals] = useState<any[]>([]);
  const [hasMore, setHasMore] = useState(true);
  const [cursor, setCursor] = useState<string | null>(null);

  const loadMore = async () => {
    const query = `
      query ReferralsPaginated($referrerId: ID!, $first: Int, $after: String) {
        referrerStats(id: $referrerId) {
          referrals(first: $first, after: $after) {
            edges {
              node { id referee { id } boundAt }
              cursor
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      }
    `;

    const data = await graphqlClient.request(query, {
      referrerId: address.toLowerCase(),
      first: pageSize,
      after: cursor,
    });

    const newReferrals = data.referrerStats.referrals.edges.map(e => e.node);
    setAllReferrals([...allReferrals, ...newReferrals]);
    setCursor(data.referrerStats.referrals.pageInfo.endCursor);
    setHasMore(data.referrerStats.referrals.pageInfo.hasNextPage);
  };

  return { referrals: allReferrals, loadMore, hasMore };
}
```

---

### 2. 前端缓存策略

#### 2.1 React Query 集成
**目标**: 自动缓存和刷新数据

**实现** (`lib/queries/referral.ts`):
```tsx
import { useQuery } from '@tanstack/react-query';

export function useReferrerStatsQuery(address?: Address) {
  return useQuery({
    queryKey: ['referrerStats', address],
    queryFn: async () => {
      const data = await graphqlClient.request(REFERRER_STATS_QUERY, {
        referrerId: address.toLowerCase(),
      });
      return data.referrerStats;
    },
    enabled: !!address,
    staleTime: 1000 * 60, // 1 分钟内数据视为新鲜
    refetchInterval: 1000 * 60 * 5, // 每 5 分钟自动刷新
  });
}
```

#### 2.2 排行榜缓存
```tsx
export function useReferralLeaderboardQuery(limit = 10) {
  return useQuery({
    queryKey: ['referralLeaderboard', limit],
    queryFn: () => graphqlClient.request(REFERRAL_LEADERBOARD_QUERY, { first: limit }),
    staleTime: 1000 * 60 * 10, // 排行榜 10 分钟更新一次
  });
}
```

---

### 3. 组件懒加载

#### 3.1 代码分割
```tsx
// 推荐主页优化
import dynamic from 'next/dynamic';

const ReferralLeaderboard = dynamic(
  () => import('@/components/referral').then(mod => ({ default: mod.ReferralLeaderboard })),
  {
    loading: () => <LoadingSkeleton />,
    ssr: false, // 排行榜不需要 SSR
  }
);

const ReferralRewardsHistory = dynamic(
  () => import('@/components/referral').then(mod => ({ default: mod.ReferralRewardsHistory })),
  { loading: () => <LoadingSkeleton /> }
);
```

---

### 4. 数据格式化优化

#### 4.1 Memo 化计算
```tsx
// ReferralRewardsHistory.tsx
export function ReferralRewardsHistory() {
  const { rewards } = useReferralRewards(address, 50);

  // ❌ 每次渲染都重新计算
  const totalRewards = rewards.reduce((sum, r) => sum + Number(r.amount), 0);

  // ✅ 使用 useMemo
  const totalRewards = useMemo(
    () => rewards.reduce((sum, r) => sum + Number(r.amount), 0),
    [rewards]
  );

  return ...;
}
```

#### 4.2 虚拟滚动
**适用场景**: 推荐列表超过 100 条记录

```tsx
import { VirtualList } from '@pitchone/ui';

export function ReferralList() {
  const { referrals } = useReferrals(address, 1000); // 加载所有

  return (
    <VirtualList
      data={referrals}
      itemHeight={80}
      renderItem={(referral) => <ReferralItem data={referral} />}
    />
  );
}
```

---

## 错误处理改进

### 1. 统一错误处理

#### 1.1 创建错误边界组件
```tsx
// components/ErrorBoundary.tsx
import { Component, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

export class ReferralErrorBoundary extends Component<Props, { hasError: boolean }> {
  state = { hasError: false };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error) {
    console.error('[Referral] 组件错误:', error);
    // 可选: 发送到错误追踪服务 (Sentry)
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <Card padding="lg">
          <div className="text-center py-8">
            <p className="text-red-400">加载推荐数据时出错</p>
            <button onClick={() => window.location.reload()}>
              刷新页面
            </button>
          </div>
        </Card>
      );
    }

    return this.props.children;
  }
}
```

#### 1.2 使用错误边界
```tsx
// app/referral/page.tsx
export default function ReferralPage() {
  return (
    <ReferralErrorBoundary>
      <ReferralStats />
      <ReferralList />
      <ReferralRewardsHistory />
    </ReferralErrorBoundary>
  );
}
```

---

### 2. 网络错误处理

#### 2.1 自动重试机制
```tsx
// hooks/useReferrerStats.ts (优化版)
export function useReferrerStats(referrerAddress?: Address) {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [retryCount, setRetryCount] = useState(0);
  const MAX_RETRIES = 3;

  useEffect(() => {
    if (!referrerAddress) return;

    const fetchWithRetry = async (attempt = 0) => {
      try {
        setLoading(true);
        setError(null);

        const data = await graphqlClient.request(REFERRER_STATS_QUERY, {
          referrerId: referrerAddress.toLowerCase(),
        });

        setStats(data.referrerStats);
        setRetryCount(0); // 重置重试计数
      } catch (err) {
        console.error(`[useReferrerStats] 查询失败 (尝试 ${attempt + 1}/${MAX_RETRIES}):`, err);

        if (attempt < MAX_RETRIES - 1) {
          // 指数退避: 1s, 2s, 4s
          const delay = Math.pow(2, attempt) * 1000;
          setTimeout(() => fetchWithRetry(attempt + 1), delay);
          setRetryCount(attempt + 1);
        } else {
          setError(err instanceof Error ? err : new Error('查询推荐统计失败'));
        }
      } finally {
        setLoading(false);
      }
    };

    fetchWithRetry();
  }, [referrerAddress]);

  return { stats, loading, error, retryCount };
}
```

#### 2.2 降级策略
```tsx
// ReferralStats.tsx (优化版)
export function ReferralStats() {
  const { address } = useAccount();

  // 链上查询（实时，高可靠性）
  const { data: onChainStats, isLoading: onChainLoading } = useReferrerStatsOnChain(address);

  // Subgraph 查询（详细，可能失败）
  const { stats: subgraphStats, loading: subgraphLoading, error } = useReferrerStats(address);

  // 降级: Subgraph 失败时使用链上数据
  const displayStats = error ? {
    referralCount: Number(onChainStats?.count || 0),
    totalRewards: onChainStats?.rewards ? formatUSDCFromWei(onChainStats.rewards) : '0',
    validReferralCount: 0, // 链上无此数据
  } : subgraphStats;

  return (
    <div>
      {error && (
        <div className="mb-4 p-3 bg-yellow-500/10 border border-yellow-500/30 rounded-lg text-sm text-yellow-400">
          ⚠️ Subgraph 查询失败,显示链上实时数据
        </div>
      )}
      {/* ... 统计卡片 */}
    </div>
  );
}
```

---

### 3. 用户友好的错误提示

#### 3.1 特定错误提示
```tsx
function getErrorMessage(error: Error): string {
  if (error.message.includes('ECONNREFUSED')) {
    return 'Subgraph 服务暂时不可用,请稍后再试';
  }

  if (error.message.includes('User denied')) {
    return '您取消了交易';
  }

  if (error.message.includes('insufficient funds')) {
    return '余额不足,无法支付 Gas 费';
  }

  if (error.message.includes('already bound')) {
    return '您已绑定推荐人,无法重复绑定';
  }

  return '操作失败,请重试';
}
```

#### 3.2 Toast 通知优化
```tsx
// ReferralBinder.tsx (优化版)
useEffect(() => {
  if (error) {
    setBindingStatus('error');
    const friendlyMessage = getErrorMessage(error);
    setErrorMessage(friendlyMessage);
    setShowNotification(true);

    // 记录详细错误到控制台
    console.error('[ReferralBinder] 绑定失败:', {
      error: error.message,
      stack: error.stack,
      referrer: referrerAddress,
      user: address,
    });
  }
}, [error]);
```

---

## 用户体验改进

### 1. 加载状态优化

#### 1.1 骨架屏
```tsx
// components/LoadingSkeleton.tsx
export function ReferralStatsSkeleton() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {[1, 2, 3].map((i) => (
        <Card key={i} padding="lg">
          <div className="animate-pulse">
            <div className="h-4 bg-gray-700 rounded w-1/3 mb-2" />
            <div className="h-8 bg-gray-700 rounded w-1/2 mb-1" />
            <div className="h-3 bg-gray-700 rounded w-1/4" />
          </div>
        </Card>
      ))}
    </div>
  );
}
```

#### 1.2 渐进式加载
```tsx
export default function ReferralPage() {
  return (
    <div>
      {/* 立即加载: 推荐链接 */}
      <ReferralLink />

      {/* 懒加载: 统计数据 */}
      <Suspense fallback={<ReferralStatsSkeleton />}>
        <ReferralStats />
      </Suspense>

      {/* 懒加载: 列表和历史 */}
      <Suspense fallback={<LoadingSkeleton />}>
        <ReferralList />
        <ReferralRewardsHistory />
      </Suspense>
    </div>
  );
}
```

---

### 2. 数据刷新优化

#### 2.1 下拉刷新
```tsx
import { usePullToRefresh } from '@/hooks/usePullToRefresh';

export function ReferralPage() {
  const { refetch } = useReferrerStatsQuery(address);

  usePullToRefresh({
    onRefresh: async () => {
      await refetch();
    },
  });

  return ...;
}
```

#### 2.2 自动刷新
```tsx
export function ReferralRewardsHistory() {
  const { rewards, loading, refetch } = useReferralRewards(address, 50);

  // 每 30 秒自动刷新一次
  useEffect(() => {
    const interval = setInterval(refetch, 30000);
    return () => clearInterval(interval);
  }, [refetch]);

  return ...;
}
```

---

## 安全性改进

### 1. 地址验证

```tsx
import { isAddress as viemIsAddress } from 'viem';

function validateReferrerAddress(address: string): boolean {
  if (!viemIsAddress(address)) {
    console.warn('[Referral] 无效的地址格式:', address);
    return false;
  }

  // 防止零地址
  if (address === '0x0000000000000000000000000000000000000000') {
    console.warn('[Referral] 不能使用零地址');
    return false;
  }

  return true;
}
```

### 2. Rate Limiting

```tsx
// hooks/useRateLimit.ts
export function useRateLimit(key: string, maxCalls: number, windowMs: number) {
  const calls = useRef<number[]>([]);

  const checkRateLimit = (): boolean => {
    const now = Date.now();
    calls.current = calls.current.filter(time => now - time < windowMs);

    if (calls.current.length >= maxCalls) {
      console.warn(`[RateLimit] ${key} 超过限制: ${maxCalls}次/${windowMs}ms`);
      return false;
    }

    calls.current.push(now);
    return true;
  };

  return { checkRateLimit };
}

// 使用示例
export function useBindReferral() {
  const { checkRateLimit } = useRateLimit('bindReferral', 5, 60000); // 每分钟最多 5 次

  const bindReferral = async (referrer: Address) => {
    if (!checkRateLimit()) {
      throw new Error('操作过于频繁,请稍后再试');
    }

    // ... 执行绑定
  };

  return { bindReferral };
}
```

---

## 监控和分析

### 1. 性能监控

```tsx
// lib/analytics.ts
export function trackReferralEvent(event: string, data?: any) {
  if (typeof window === 'undefined') return;

  console.log('[Analytics]', event, data);

  // 集成第三方分析工具 (Google Analytics, Mixpanel)
  if (window.gtag) {
    window.gtag('event', event, data);
  }
}

// 使用示例
export function useBindReferral() {
  const bindReferral = async (referrer: Address) => {
    trackReferralEvent('referral_bind_start', { referrer });

    try {
      await writeContract(...);
      trackReferralEvent('referral_bind_success', { referrer });
    } catch (err) {
      trackReferralEvent('referral_bind_error', {
        referrer,
        error: err.message,
      });
    }
  };

  return { bindReferral };
}
```

---

## 实施优先级

### 高优先级 (立即实施)
1. ✅ 统一错误处理和友好提示
2. ✅ 自动重试机制
3. ✅ 加载骨架屏
4. ✅ 地址验证

### 中优先级 (下个迭代)
1. ⏳ React Query 集成
2. ⏳ 批量查询合并
3. ⏳ 组件懒加载
4. ⏳ 降级策略

### 低优先级 (性能优化)
1. ⏸️ 虚拟滚动
2. ⏸️ 游标分页
3. ⏸️ Rate Limiting
4. ⏸️ 性能监控

---

## 预期效果

实施所有优化后:
- **加载时间**: 减少 50%
- **API 请求数**: 减少 70%
- **错误恢复率**: 提高到 95%
- **用户满意度**: 显著提升
