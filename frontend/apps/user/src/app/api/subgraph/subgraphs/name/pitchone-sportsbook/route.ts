import { NextRequest, NextResponse } from 'next/server';

/**
 * API 路由：代理 GraphQL 请求到本地 Graph Node
 *
 * 用途：避免浏览器 CORS 限制，将前端的 GraphQL 请求转发到 Graph Node
 *
 * 端点：POST /api/subgraph/subgraphs/name/pitchone-sportsbook
 */
export async function POST(request: NextRequest) {
  // 支持多个备选地址，解决不同环境的连接问题
  const graphNodeUrls = [
    process.env.GRAPH_NODE_URL,
    'http://127.0.0.1:8010/subgraphs/name/pitchone-sportsbook',
    'http://localhost:8010/subgraphs/name/pitchone-sportsbook',
    'http://[::1]:8010/subgraphs/name/pitchone-sportsbook',
  ].filter(Boolean) as string[];

  try {
    // 读取请求体（GraphQL 查询）
    const body = await request.json();

    let lastError: Error | null = null;

    // 尝试所有备选地址
    for (const graphNodeUrl of graphNodeUrls) {
      try {
        const response = await fetch(graphNodeUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(body),
          // 添加超时
          signal: AbortSignal.timeout(5000),
        });

        // 检查响应状态
        if (!response.ok) {
          console.error(`[API Proxy] Graph Node ${graphNodeUrl} 返回错误:`, response.status);
          continue;
        }

        // 解析并返回 GraphQL 响应
        const data = await response.json();
        return NextResponse.json(data);
      } catch (err) {
        lastError = err instanceof Error ? err : new Error(String(err));
        console.warn(`[API Proxy] 尝试 ${graphNodeUrl} 失败:`, lastError.message);
      }
    }

    // 所有地址都失败了
    console.error('[API Proxy] 所有 Graph Node 地址都无法连接');
    return NextResponse.json(
      {
        error: '无法连接到 Graph Node',
        details: lastError?.message || 'Unknown error',
        triedUrls: graphNodeUrls
      },
      { status: 503 }
    );

  } catch (error) {
    console.error('[API Proxy] 代理请求失败:', error);
    return NextResponse.json(
      { error: '代理请求失败', details: error instanceof Error ? error.message : String(error) },
      { status: 500 }
    );
  }
}

/**
 * GET 请求处理（可选，用于测试）
 */
export async function GET() {
  return NextResponse.json({
    message: 'GraphQL Proxy API',
    endpoint: 'POST /api/subgraph/subgraphs/name/pitchone-sportsbook',
    graphNodeUrl: 'http://localhost:8010/subgraphs/name/pitchone-sportsbook',
    status: 'OK',
  });
}
