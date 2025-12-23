import { Position, MarketStatus } from "@pitchone/web3";

// 模拟 Position 数据
export const MOCK_POSITIONS: Position[] = [
    {
        id: '0x1234-0-0x5678',
        market: {
            id: '0x1234567890abcdef1234567890abcdef12345678',
            matchId: 'EPL_2024_MUN_vs_MCI',
            templateId: '1', // WDL
            homeTeam: 'Manchester United',
            awayTeam: 'Manchester City',
            kickoffTime: String(Math.floor(Date.now() / 1000) + 86400), // 明天
            state: MarketStatus.Open,
            line: undefined,
        },
        outcome: 0, // 主队胜
        balance: '150000000', // 150 USDC (6 decimals)
        owner: '0xabcdef1234567890abcdef1234567890abcdef12',
        averageCost: '0.667',
        totalInvested: '100',
        createdAt: String(Math.floor(Date.now() / 1000) - 3600),
        lastUpdatedAt: String(Math.floor(Date.now() / 1000) - 1800),
    },
    {
        id: '0x2345-1-0x5678',
        market: {
            id: '0x234567890abcdef1234567890abcdef123456789',
            matchId: 'EPL_2024_LIV_vs_ARS',
            templateId: '2', // OU
            homeTeam: 'Liverpool',
            awayTeam: 'Arsenal',
            kickoffTime: String(Math.floor(Date.now() / 1000) + 172800), // 后天
            state: MarketStatus.Open,
            line: '2500000', // 2.5 球
        },
        outcome: 0, // Over
        balance: '80000000', // 80 USDC
        owner: '0xabcdef1234567890abcdef1234567890abcdef12',
        averageCost: '0.625',
        totalInvested: '50',
        createdAt: String(Math.floor(Date.now() / 1000) - 7200),
        lastUpdatedAt: String(Math.floor(Date.now() / 1000) - 3600),
    },
    {
        id: '0x3456-2-0x5678',
        market: {
            id: '0x34567890abcdef1234567890abcdef1234567890',
            matchId: 'LALIGA_2024_RMA_vs_BAR',
            templateId: '1', // WDL
            homeTeam: 'Real Madrid',
            awayTeam: 'Barcelona',
            kickoffTime: String(Math.floor(Date.now() / 1000) - 86400), // 昨天（已结束）
            state: MarketStatus.Resolved,
            winnerOutcome: 0, // 主队胜
        },
        outcome: 0, // 押主队胜（赢了）
        balance: '200000000', // 200 USDC
        owner: '0xabcdef1234567890abcdef1234567890abcdef12',
        averageCost: '0.5',
        totalInvested: '100',
        createdAt: String(Math.floor(Date.now() / 1000) - 172800),
        lastUpdatedAt: String(Math.floor(Date.now() / 1000) - 86400),
    },
    {
        id: '0x4567-1-0x5678',
        market: {
            id: '0x4567890abcdef1234567890abcdef12345678901',
            matchId: 'SERIA_2024_JUV_vs_MIL',
            templateId: '3', // AH 让球
            homeTeam: 'Juventus',
            awayTeam: 'AC Milan',
            kickoffTime: String(Math.floor(Date.now() / 1000) - 43200), // 12小时前（已结束）
            state: MarketStatus.Finalized,
            winnerOutcome: 1, // 客队赢盘
            line: '-500000', // -0.5 让球
        },
        outcome: 0, // 押主队赢盘（输了）
        balance: '0',
        owner: '0xabcdef1234567890abcdef1234567890abcdef12',
        averageCost: '0.6',
        totalInvested: '75',
        createdAt: String(Math.floor(Date.now() / 1000) - 259200),
        lastUpdatedAt: String(Math.floor(Date.now() / 1000) - 43200),
    },
    {
        id: '0x5678-0-0x5678',
        market: {
            id: '0x567890abcdef1234567890abcdef123456789012',
            matchId: 'BUNDESLIGA_2024_BAY_vs_DOR',
            templateId: '2', // OU
            homeTeam: 'Bayern Munich',
            awayTeam: 'Borussia Dortmund',
            kickoffTime: String(Math.floor(Date.now() / 1000) + 259200), // 3天后
            state: MarketStatus.Open,
            line: '3000000', // 3.0 球
        },
        outcome: 1, // Under
        balance: '120000000', // 120 USDC
        owner: '0xabcdef1234567890abcdef1234567890abcdef12',
        averageCost: '0.75',
        totalInvested: '90',
        createdAt: String(Math.floor(Date.now() / 1000) - 1800),
    },
];
