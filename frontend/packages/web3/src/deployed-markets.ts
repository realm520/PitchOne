/**
 * Deployed market addresses for local development
 * Auto-generated from deployment script
 */

export const DEPLOYED_MARKETS = [
  {
    id: '0x4A679253410272dd5232B3Ff7cF5dbB88f295319',
    matchId: 'LALIGA_2024_BAR_vs_RMA',
    homeTeam: 'FC Barcelona',
    awayTeam: 'Real Madrid',
    marketType: 'WDL' as const,
  },
  {
    id: '0x7a2088a1bFc9d81c55368AE168C2C02570cB814F',
    matchId: 'BUNDESLIGA_2024_BAY_vs_DOR',
    homeTeam: 'Bayern Munich',
    awayTeam: 'Borussia Dortmund',
    marketType: 'OU_SINGLE' as const,
    line: 2.5,
  },
  {
    id: '0x09635F643e140090A9A8Dcd712eD6285858ceBef',
    matchId: 'LIGUE1_2024_PSG_vs_LYO',
    homeTeam: 'Paris Saint-Germain',
    awayTeam: 'Olympique Lyon',
    marketType: 'OU_MULTI' as const,
    lines: [2.0, 2.5, 3.0],
  },
] as const;

export const USDC_ADDRESS = '0x68B1D87F95878fE05B998F19b66F4baba5De1aed' as const;
