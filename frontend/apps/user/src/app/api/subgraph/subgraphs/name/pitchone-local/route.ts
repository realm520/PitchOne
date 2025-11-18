import { NextRequest, NextResponse } from 'next/server';

/**
 * API 路由：代理 GraphQL 请求到本地 Graph Node
 *
 * 用途：避免浏览器 CORS 限制，将前端的 GraphQL 请求转发到 Graph Node
 *
 * 端点：POST /api/subgraph/subgraphs/name/pitchone-local
 */
export async function POST(request: NextRequest) {
  try {
    // 读取请求体（GraphQL 查询）
    const body = await request.json();

    // 转发到本地 Graph Node（使用 127.0.0.1 而不是 localhost，避免 DNS 解析问题）
    const graphNodeUrl = process.env.GRAPH_NODE_URL || 'http://127.0.0.1:8010/subgraphs/name/pitchone-local';

    const response = await fetch(graphNodeUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    // 检查响应状态
    if (!response.ok) {
      console.error('[API Proxy] Graph Node 返回错误:', response.status, response.statusText);
      return NextResponse.json(
        { error: 'Graph Node 请求失败', status: response.status },
        { status: response.status }
      );
    }

    // 解析并返回 GraphQL 响应
    const data = await response.json();
    return NextResponse.json(data);

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
    endpoint: 'POST /api/subgraph/subgraphs/name/pitchone-local',
    graphNodeUrl: 'http://localhost:8010/subgraphs/name/pitchone-local',
    status: 'OK',
  });
}
