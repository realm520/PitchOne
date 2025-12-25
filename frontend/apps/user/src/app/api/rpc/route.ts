import { NextRequest, NextResponse } from 'next/server';

const RPC_URL = process.env.ANVIL_RPC_URL || 'http://localhost:8545';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const response = await fetch(RPC_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('[RPC Proxy] Error:', error);
    return NextResponse.json(
      { error: 'RPC proxy error' },
      { status: 500 }
    );
  }
}
