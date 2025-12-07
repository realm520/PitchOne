/**
 * 体育类型和联赛定义
 */

export interface SportType {
  id: string;
  name: string;      // i18n key
  icon: string;
  enabled: boolean;
  order: number;
}

export interface League {
  id: string;
  sportId: string;
  name: string;        // i18n key
  country?: string;
  logo?: string;
  marketCount: number;
  order: number;
}

// 预定义体育类型（可扩展）
export const SPORT_TYPES: SportType[] = [
  { id: 'football', name: 'sidebar.sports.football', icon: 'football', enabled: true, order: 1 },
  { id: 'basketball', name: 'sidebar.sports.basketball', icon: 'basketball', enabled: false, order: 2 },
  { id: 'tennis', name: 'sidebar.sports.tennis', icon: 'tennis', enabled: false, order: 3 },
  { id: 'esports', name: 'sidebar.sports.esports', icon: 'esports', enabled: false, order: 4 },
];

// 预定义足球联赛配置
export const FOOTBALL_LEAGUES: Omit<League, 'marketCount'>[] = [
  { id: 'EPL', sportId: 'football', name: 'leagues.EPL', country: 'England', order: 1 },
  { id: 'LALIGA', sportId: 'football', name: 'leagues.LALIGA', country: 'Spain', order: 2 },
  { id: 'SERIE_A', sportId: 'football', name: 'leagues.SERIE_A', country: 'Italy', order: 3 },
  { id: 'BUNDESLIGA', sportId: 'football', name: 'leagues.BUNDESLIGA', country: 'Germany', order: 4 },
  { id: 'LIGUE1', sportId: 'football', name: 'leagues.LIGUE1', country: 'France', order: 5 },
  { id: 'UCL', sportId: 'football', name: 'leagues.UCL', order: 6 },
  { id: 'UEL', sportId: 'football', name: 'leagues.UEL', order: 7 },
];

// 从 matchId 解析联赛 ID（如 "EPL_2024_MUN_vs_MCI" -> "EPL"）
export function parseLeagueFromMatchId(matchId: string): string {
  const parts = matchId.split('_');
  return parts[0] || 'UNKNOWN';
}
