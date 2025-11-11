#!/usr/bin/env ts-node
/**
 * PitchOne 市场创建脚本
 *
 * 功能：
 * - 创建指定类型和数量的市场（支持全部 7 种市场类型）
 * - 支持随机生成测试数据
 * - 灵活的命令行参数
 * - 特别支持 OU_MultiLine 和 ScoreTemplate（Solidity 脚本无法实现）
 *
 * 使用示例：
 *   # 创建所有类型的市场各3个（7 种类型，共 21 个市场）
 *   pnpm tsx createMarkets.ts --all --count 3
 *
 *   # 只创建 WDL 市场 5 个
 *   pnpm tsx createMarkets.ts --type wdl --count 5
 *
 *   # 创建 OU_MultiLine 市场（Solidity 脚本无法创建）
 *   pnpm tsx createMarkets.ts --type ou_multiline --count 3
 *
 *   # 创建精确比分市场
 *   pnpm tsx createMarkets.ts --type score --count 2
 */

import { ethers } from 'ethers';
import * as fs from 'fs';
import * as path from 'path';

// ============ 类型定义 ============

type MarketType = 'wdl' | 'ou' | 'ou_multiline' | 'ah' | 'oddeven' | 'score' | 'playerprops';

interface DeploymentConfig {
  contracts: {
    factory: string;
    vault: string;
    usdc: string;
    feeRouter: string;
    cpmm: string;
  };
  templates: {
    wdl: string;
    ou: string;
    ouMultiLine: string;
    ah: string;
    oddEven: string;
    score: string;
    playerProps: string;
  };
}

interface CreateMarketOptions {
  type?: MarketType;
  count?: number;
  all?: boolean;
  preset?: boolean; // 使用预定义数据还是随机数据
}

// ============ 常量配置 ============

const TEAMS = {
  epl: [
    'Manchester United', 'Liverpool', 'Arsenal', 'Chelsea', 'Manchester City',
    'Tottenham', 'Leicester', 'West Ham', 'Aston Villa', 'Newcastle',
    'Brighton', 'Wolves', 'Everton', 'Fulham', 'Brentford', 'Crystal Palace',
    'Bournemouth', 'Southampton', 'Burnley'
  ],
  lal: [
    'Real Madrid', 'Barcelona', 'Atletico Madrid', 'Sevilla', 'Valencia',
    'Villarreal', 'Real Sociedad', 'Athletic Bilbao', 'Betis', 'Getafe'
  ],
  ser: [
    'Juventus', 'Inter Milan', 'AC Milan', 'Napoli', 'Roma',
    'Lazio', 'Atalanta', 'Fiorentina'
  ],
  bun: [
    'Bayern Munich', 'Dortmund', 'RB Leipzig', 'Leverkusen', 'Frankfurt',
    'Wolfsburg', 'Monchengladbach', 'Hoffenheim'
  ],
  lig: [
    'PSG', 'Marseille', 'Lyon', 'Monaco', 'Lille',
    'Nice', 'Rennes', 'Lens'
  ]
};

const PLAYERS = [
  'Erling Haaland', 'Mohamed Salah', 'Harry Kane', 'Kevin De Bruyne',
  'Bruno Fernandes', 'Son Heung-min', 'Bukayo Saka', 'Phil Foden',
  'Karim Benzema', 'Robert Lewandowski', 'Kylian Mbappe', 'Vinicius Jr',
  'Lautaro Martinez', 'Victor Osimhen', 'Dusan Vlahovic', 'Jamal Musiala',
  'Casemiro', 'Sergio Ramos'
];

const PROP_TYPES = [
  { id: 0, name: 'GOALS_OU', hasLine: true },
  { id: 1, name: 'ASSISTS_OU', hasLine: true },
  { id: 2, name: 'SHOTS_OU', hasLine: true },
  { id: 3, name: 'YELLOW_CARD', hasLine: false },
  { id: 4, name: 'RED_CARD', hasLine: false },
  { id: 5, name: 'ANYTIME_SCORER', hasLine: false }
];

// ============ 预定义市场数据 ============

const PRESET_MARKETS = {
  wdl: [
    { matchId: 'EPL_2025_MUN_vs_LIV', home: 'Manchester United', away: 'Liverpool', days: 3 },
    { matchId: 'EPL_2025_ARS_vs_CHE', home: 'Arsenal', away: 'Chelsea', days: 4 },
    { matchId: 'EPL_2025_MCI_vs_TOT', home: 'Manchester City', away: 'Tottenham', days: 5 },
    { matchId: 'LAL_2025_RMA_vs_BAR', home: 'Real Madrid', away: 'Barcelona', days: 6 },
    { matchId: 'BUN_2025_BAY_vs_DOR', home: 'Bayern Munich', away: 'Dortmund', days: 7 }
  ],
  ou: [
    { matchId: 'EPL_OU_CHE_vs_NEW', home: 'Chelsea', away: 'Newcastle', days: 3, line: 2500 },
    { matchId: 'EPL_OU_AVL_vs_BRI', home: 'Aston Villa', away: 'Brighton', days: 4, line: 2500 },
    { matchId: 'EPL_OU_WHU_vs_WOL', home: 'West Ham', away: 'Wolves', days: 5, line: 1500 },
    { matchId: 'SER_OU_INT_vs_MIL', home: 'Inter Milan', away: 'AC Milan', days: 6, line: 3500 },
    { matchId: 'LIG_OU_PSG_vs_MAR', home: 'PSG', away: 'Marseille', days: 3, line: 500 },
    { matchId: 'BUN_OU_RBL_vs_LEV', home: 'RB Leipzig', away: 'Leverkusen', days: 4, line: 4500 }
  ],
  ou_multiline: [
    { matchId: 'EPL_ML_ARS_vs_MUN', home: 'Arsenal', away: 'Manchester United', days: 3, lines: [1500, 2500, 3500] },
    { matchId: 'LAL_ML_BAR_vs_ATM', home: 'Barcelona', away: 'Atletico Madrid', days: 4, lines: [500, 1500, 2500, 3500] },
    { matchId: 'BUN_ML_DOR_vs_RBL', home: 'Dortmund', away: 'RB Leipzig', days: 5, lines: [2500, 3500, 4500] }
  ],
  ah: [
    { matchId: 'EPL_AH_LIV_vs_BUR', home: 'Liverpool', away: 'Burnley', days: 3, handicap: -1500 },
    { matchId: 'EPL_AH_MCI_vs_SOU', home: 'Manchester City', away: 'Southampton', days: 4, handicap: -1000 },
    { matchId: 'LAL_AH_BAR_vs_GET', home: 'Barcelona', away: 'Getafe', days: 5, handicap: -500 },
    { matchId: 'SER_AH_JUV_vs_NAP', home: 'Juventus', away: 'Napoli', days: 6, handicap: -2000 },
    { matchId: 'LIG_AH_LYO_vs_MON', home: 'Lyon', away: 'Monaco', days: 7, handicap: -2500 }
  ],
  oddeven: [
    { matchId: 'EPL_OE_LEI_vs_FUL', home: 'Leicester', away: 'Fulham', days: 3 },
    { matchId: 'EPL_OE_BOU_vs_EVE', home: 'Bournemouth', away: 'Everton', days: 4 },
    { matchId: 'EPL_OE_CRY_vs_BRE', home: 'Crystal Palace', away: 'Brentford', days: 5 },
    { matchId: 'BUN_OE_BAY_vs_WOL', home: 'Bayern Munich', away: 'Wolfsburg', days: 6 },
    { matchId: 'LIG_OE_PSG_vs_LYO', home: 'PSG', away: 'Lyon', days: 7 }
  ],
  score: [
    { matchId: 'EPL_SC_CHE_vs_LIV', home: 'Chelsea', away: 'Liverpool', days: 3, scoreRange: 5 },
    { matchId: 'LAL_SC_RMA_vs_SEV', home: 'Real Madrid', away: 'Sevilla', days: 4, scoreRange: 4 },
    { matchId: 'SER_SC_JUV_vs_INT', home: 'Juventus', away: 'Inter Milan', days: 5, scoreRange: 6 }
  ],
  playerprops: [
    { matchId: 'EPL_PP_HAALAND_GOALS_1_5', player: 'Erling Haaland', match: 'Man City vs Liverpool', days: 3, propType: 0, line: 1500 },
    { matchId: 'EPL_PP_SALAH_GOALS_1_0', player: 'Mohamed Salah', match: 'Liverpool vs Arsenal', days: 4, propType: 0, line: 1000 },
    { matchId: 'EPL_PP_DEBRUYNE_ASSISTS', player: 'Kevin De Bruyne', match: 'Man City vs Chelsea', days: 5, propType: 1, line: 500 },
    { matchId: 'EPL_PP_CASEMIRO_YELLOW', player: 'Casemiro', match: 'Man Utd vs Tottenham', days: 6, propType: 3, line: 0 },
    { matchId: 'LAL_PP_RAMOS_RED', player: 'Sergio Ramos', match: 'Real Madrid vs Barcelona', days: 3, propType: 4, line: 0 },
    { matchId: 'EPL_PP_KANE_SCORER', player: 'Harry Kane', match: 'Tottenham vs Arsenal', days: 4, propType: 5, line: 0 },
    { matchId: 'SER_PP_VLAHOVIC_SHOTS', player: 'Dusan Vlahovic', match: 'Juventus vs AC Milan', days: 5, propType: 2, line: 2500 },
    { matchId: 'LAL_PP_BENZEMA_GOALS', player: 'Karim Benzema', match: 'Real Madrid vs Atletico', days: 6, propType: 0, line: 500 },
    { matchId: 'BUN_PP_MUSIALA_GOALS', player: 'Jamal Musiala', match: 'Bayern vs Dortmund', days: 7, propType: 0, line: 500 }
  ]
};

// ============ 辅助函数 ============

function loadDeploymentConfig(): DeploymentConfig {
  // 支持从 script/ts 或 contracts 根目录运行
  let configPath = path.join(process.cwd(), 'deployments', 'localhost.json');
  if (!fs.existsSync(configPath)) {
    // 如果当前目录找不到，尝试从上两级目录查找（script/ts -> contracts）
    configPath = path.join(process.cwd(), '..', '..', 'deployments', 'localhost.json');
  }
  if (!fs.existsSync(configPath)) {
    throw new Error(`Deployment config not found: ${configPath}`);
  }
  return JSON.parse(fs.readFileSync(configPath, 'utf-8'));
}

function randomItem<T>(array: T[]): T {
  return array[Math.floor(Math.random() * array.length)];
}

function randomTeamPair(league: keyof typeof TEAMS): [string, string] {
  const teams = [...TEAMS[league]];
  const home = randomItem(teams);
  const awayTeams = teams.filter(t => t !== home);
  const away = randomItem(awayTeams);
  return [home, away];
}

function generateMatchId(type: string, home: string, away: string): string {
  const timestamp = Date.now().toString(36);
  const homeCode = home.substring(0, 3).toUpperCase();
  const awayCode = away.substring(0, 3).toUpperCase();
  return `${type}_${homeCode}_vs_${awayCode}_${timestamp}`;
}

function getFutureTimestamp(daysFromNow: number): number {
  return Math.floor(Date.now() / 1000) + daysFromNow * 24 * 60 * 60;
}

// ============ 市场创建类 ============

class MarketCreator {
  private provider: ethers.Provider;
  private signer: ethers.Signer;
  private config: DeploymentConfig;
  private factory: ethers.Contract;
  private vault: ethers.Contract;
  private currentNonce: number = 0;
  private usePreset: boolean = false; // 是否使用预定义数据
  private presetCounters: Record<MarketType, number> = {
    wdl: 0,
    ou: 0,
    ou_multiline: 0,
    ah: 0,
    oddeven: 0,
    score: 0,
    playerprops: 0
  };

  constructor(provider: ethers.Provider, signer: ethers.Signer, config: DeploymentConfig, usePreset: boolean = false) {
    this.provider = provider;
    this.signer = signer;
    this.config = config;
    this.usePreset = usePreset;

    // 加载合约 ABI
    const factoryAbi = this.loadAbi('MarketFactory_v2');
    const vaultAbi = this.loadAbi('LiquidityVault');

    this.factory = new ethers.Contract(config.contracts.factory, factoryAbi, signer);
    this.vault = new ethers.Contract(config.contracts.vault, vaultAbi, signer);
  }

  private getNextNonce(): number {
    return this.currentNonce++;
  }

  async initNonce(): Promise<void> {
    this.currentNonce = await this.signer.getNonce();
  }
  
  private loadAbi(contractName: string): any[] {
    // 支持从 script/ts 或 contracts 根目录运行
    let abiPath = path.join(process.cwd(), 'out', `${contractName}.sol`, `${contractName}.json`);
    if (!fs.existsSync(abiPath)) {
      // 如果当前目录找不到，尝试从上两级目录查找（script/ts -> contracts）
      abiPath = path.join(process.cwd(), '..', '..', 'out', `${contractName}.sol`, `${contractName}.json`);
    }
    if (!fs.existsSync(abiPath)) {
      throw new Error(`ABI not found for ${contractName}: ${abiPath}`);
    }
    const artifact = JSON.parse(fs.readFileSync(abiPath, 'utf-8'));
    return artifact.abi;
  }

  private getBytecode(contractName: string): string {
    // 支持从 script/ts 或 contracts 根目录运行
    let abiPath = path.join(process.cwd(), 'out', `${contractName}.sol`, `${contractName}.json`);
    if (!fs.existsSync(abiPath)) {
      // 如果当前目录找不到，尝试从上两级目录查找（script/ts -> contracts）
      abiPath = path.join(process.cwd(), '..', '..', 'out', `${contractName}.sol`, `${contractName}.json`);
    }
    if (!fs.existsSync(abiPath)) {
      throw new Error(`Bytecode not found for ${contractName}: ${abiPath}`);
    }
    const artifact = JSON.parse(fs.readFileSync(abiPath, 'utf-8'));
    return artifact.bytecode.object;
  }
  
  // ========== WDL 市场 ==========
  async createWdlMarket(): Promise<string> {
    let matchId: string, home: string, away: string, kickoffTime: number;

    if (this.usePreset && this.presetCounters.wdl < PRESET_MARKETS.wdl.length) {
      // 使用预定义数据
      const preset = PRESET_MARKETS.wdl[this.presetCounters.wdl];
      this.presetCounters.wdl++;
      matchId = preset.matchId;
      home = preset.home;
      away = preset.away;
      kickoffTime = getFutureTimestamp(preset.days);
    } else {
      // 使用随机数据
      const league = randomItem(['epl', 'lal', 'ser', 'bun', 'lig'] as const);
      [home, away] = randomTeamPair(league);
      matchId = generateMatchId('WDL', home, away);
      kickoffTime = getFutureTimestamp(Math.floor(Math.random() * 7) + 1);
    }
    
    const wdlAbi = this.loadAbi('WDL_Template_V2');
    const iface = new ethers.Interface(wdlAbi);

    const signerAddress = await this.signer.getAddress();
    const initData = iface.encodeFunctionData('initialize', [
      matchId,
      home,
      away,
      kickoffTime,
      this.config.contracts.usdc,
      signerAddress, // feeRecipient
      200, // 2% fee
      2 * 60 * 60, // 2 hours dispute period
      this.config.contracts.cpmm, // pricingEngine
      this.config.contracts.vault, // vault
      `https://api.pitchone.io/metadata/wdl/${matchId}` // uri
    ]);
    
    const tx = await this.factory.createMarket(this.config.templates.wdl, initData, { nonce: this.getNextNonce() });
    const receipt = await tx.wait();

    // 从事件中提取市场地址
    const marketCreatedEvent = receipt.logs.find((log: any) => {
      try {
        const parsed = this.factory.interface.parseLog(log);
        return parsed?.name === 'MarketCreated';
      } catch {
        return false;
      }
    });

    const marketAddress = marketCreatedEvent ?
      this.factory.interface.parseLog(marketCreatedEvent).args.market :
      null;

    if (marketAddress) {
      // 授权 Vault
      await this.vault.authorizeMarket(marketAddress, { nonce: this.getNextNonce() });
      console.log(`✅ WDL Market created: ${home} vs ${away} -> ${marketAddress}`);
    }

    return marketAddress;
  }
  
  // ========== OU 单线市场 ==========
  async createOuMarket(): Promise<string> {
    let matchId: string, home: string, away: string, kickoffTime: number, line: number;

    if (this.usePreset && this.presetCounters.ou < PRESET_MARKETS.ou.length) {
      // 使用预定义数据
      const preset = PRESET_MARKETS.ou[this.presetCounters.ou];
      this.presetCounters.ou++;
      matchId = preset.matchId;
      home = preset.home;
      away = preset.away;
      kickoffTime = getFutureTimestamp(preset.days);
      line = preset.line;
    } else {
      // 使用随机数据
      const league = randomItem(['epl', 'lal', 'ser', 'bun', 'lig'] as const);
      [home, away] = randomTeamPair(league);
      matchId = generateMatchId('OU', home, away);
      kickoffTime = getFutureTimestamp(Math.floor(Math.random() * 7) + 1);
      const lines = [500, 1500, 2500, 3500, 4500];
      line = randomItem(lines);
    }
    
    const ouAbi = this.loadAbi('OU_Template');
    const iface = new ethers.Interface(ouAbi);

    const signerAddress = await this.signer.getAddress();
    const initData = iface.encodeFunctionData('initialize', [
      matchId,
      home,
      away,
      kickoffTime,
      line,
      this.config.contracts.usdc,
      signerAddress, // feeRecipient
      200,
      2 * 60 * 60,
      this.config.contracts.cpmm,
      `https://api.pitchone.io/metadata/ou/${matchId}`,
      signerAddress // owner
    ]);
    
    const tx = await this.factory.createMarket(this.config.templates.ou, initData, { nonce: this.getNextNonce() });
    const receipt = await tx.wait();
    
    const marketCreatedEvent = receipt.logs.find((log: any) => {
      try {
        const parsed = this.factory.interface.parseLog(log);
        return parsed?.name === 'MarketCreated';
      } catch {
        return false;
      }
    });
    
    const marketAddress = marketCreatedEvent ? 
      this.factory.interface.parseLog(marketCreatedEvent).args.market : 
      null;
    
    if (marketAddress) {
      console.log(`✅ OU Market created: ${home} vs ${away} (${line/1000} goals) -> ${marketAddress}`);
    }
    
    return marketAddress;
  }
  
  // ========== AH 让球市场 ==========
  async createAhMarket(): Promise<string> {
    let matchId: string, home: string, away: string, kickoffTime: number, handicap: number, handicapType: number;

    if (this.usePreset && this.presetCounters.ah < PRESET_MARKETS.ah.length) {
      // 使用预定义数据
      const preset = PRESET_MARKETS.ah[this.presetCounters.ah];
      this.presetCounters.ah++;
      matchId = preset.matchId;
      home = preset.home;
      away = preset.away;
      kickoffTime = getFutureTimestamp(preset.days);
      handicap = preset.handicap;
      handicapType = handicap % 1000 === 0 ? 1 : 0; // 0=HALF, 1=WHOLE
    } else {
      // 使用随机数据
      const league = randomItem(['epl', 'lal', 'ser', 'bun', 'lig'] as const);
      [home, away] = randomTeamPair(league);
      matchId = generateMatchId('AH', home, away);
      kickoffTime = getFutureTimestamp(Math.floor(Math.random() * 7) + 1);
      const handicaps = [-2500, -2000, -1500, -1000, -500, 500, 1000, 1500];
      handicap = randomItem(handicaps);
      handicapType = handicap % 1000 === 0 ? 1 : 0; // 0=HALF, 1=WHOLE
    }
    
    const ahAbi = this.loadAbi('AH_Template');
    const iface = new ethers.Interface(ahAbi);

    const signerAddress = await this.signer.getAddress();
    const initData = iface.encodeFunctionData('initialize', [
      matchId,
      home,
      away,
      kickoffTime,
      handicap,
      handicapType,
      this.config.contracts.usdc,
      signerAddress, // feeRecipient
      200,
      2 * 60 * 60,
      this.config.contracts.cpmm,
      `https://api.pitchone.io/metadata/ah/${matchId}`,
      signerAddress // owner
    ]);
    
    const tx = await this.factory.createMarket(this.config.templates.ah, initData, { nonce: this.getNextNonce() });
    const receipt = await tx.wait();
    
    const marketCreatedEvent = receipt.logs.find((log: any) => {
      try {
        const parsed = this.factory.interface.parseLog(log);
        return parsed?.name === 'MarketCreated';
      } catch {
        return false;
      }
    });
    
    const marketAddress = marketCreatedEvent ? 
      this.factory.interface.parseLog(marketCreatedEvent).args.market : 
      null;
    
    if (marketAddress) {
      console.log(`✅ AH Market created: ${home} vs ${away} (${handicap/1000}) -> ${marketAddress}`);
    }
    
    return marketAddress;
  }
  
  // ========== OddEven 市场 ==========
  async createOddEvenMarket(): Promise<string> {
    let matchId: string, home: string, away: string, kickoffTime: number;

    if (this.usePreset && this.presetCounters.oddeven < PRESET_MARKETS.oddeven.length) {
      // 使用预定义数据
      const preset = PRESET_MARKETS.oddeven[this.presetCounters.oddeven];
      this.presetCounters.oddeven++;
      matchId = preset.matchId;
      home = preset.home;
      away = preset.away;
      kickoffTime = getFutureTimestamp(preset.days);
    } else {
      // 使用随机数据
      const league = randomItem(['epl', 'lal', 'ser', 'bun', 'lig'] as const);
      [home, away] = randomTeamPair(league);
      matchId = generateMatchId('OE', home, away);
      kickoffTime = getFutureTimestamp(Math.floor(Math.random() * 7) + 1);
    }
    
    const oddEvenAbi = this.loadAbi('OddEven_Template');
    const iface = new ethers.Interface(oddEvenAbi);

    const signerAddress = await this.signer.getAddress();
    const initData = iface.encodeFunctionData('initialize', [
      matchId,
      home,
      away,
      kickoffTime,
      this.config.contracts.usdc,
      signerAddress, // feeRecipient
      200,
      2 * 60 * 60,
      this.config.contracts.cpmm,
      `https://api.pitchone.io/metadata/oddeven/${matchId}`,
      signerAddress // owner
    ]);
    
    const tx = await this.factory.createMarket(this.config.templates.oddEven, initData, { nonce: this.getNextNonce() });
    const receipt = await tx.wait();
    
    const marketCreatedEvent = receipt.logs.find((log: any) => {
      try {
        const parsed = this.factory.interface.parseLog(log);
        return parsed?.name === 'MarketCreated';
      } catch {
        return false;
      }
    });
    
    const marketAddress = marketCreatedEvent ? 
      this.factory.interface.parseLog(marketCreatedEvent).args.market : 
      null;
    
    if (marketAddress) {
      console.log(`✅ OddEven Market created: ${home} vs ${away} -> ${marketAddress}`);
    }
    
    return marketAddress;
  }
  
  // ========== PlayerProps 市场 ==========
  async createPlayerPropsMarket(): Promise<string> {
    let player: string, propType: any, matchId: string, kickoffTime: number, propLine: number, matchInfo: string;

    if (this.usePreset && this.presetCounters.playerprops < PRESET_MARKETS.playerprops.length) {
      // 使用预定义数据
      const preset = PRESET_MARKETS.playerprops[this.presetCounters.playerprops];
      this.presetCounters.playerprops++;
      matchId = preset.matchId;
      player = preset.player;
      matchInfo = preset.match;
      propType = PROP_TYPES.find(p => p.id === preset.propType) || PROP_TYPES[0];
      propLine = preset.line;
      kickoffTime = getFutureTimestamp(preset.days);
    } else {
      // 使用随机数据（原逻辑）
      player = randomItem(PLAYERS);
      propType = randomItem(PROP_TYPES);
      matchId = generateMatchId('PP', player.split(' ')[0], propType.name);
      kickoffTime = getFutureTimestamp(Math.floor(Math.random() * 7) + 1);
      propLine = propType.hasLine ? randomItem([500, 1500, 2500]) : 0; // 只使用半球盘简化处理
      const league = randomItem(['epl', 'lal', 'ser', 'bun', 'lig'] as const);
      const [home, away] = randomTeamPair(league);
      matchInfo = `${home} vs ${away}`;
    }

    const ppAbi = this.loadAbi('PlayerProps_Template');
    const iface = new ethers.Interface(ppAbi);

    const signerAddress = await this.signer.getAddress();

    // 计算 outcomeCount 和初始储备
    // OU 类型半球盘：2 向（Over/Under）
    // OU 类型整球盘：3 向（Over/Push/Under）
    // Yes/No 类型：2 向
    // FIRST_SCORER：N+1 向（N 个球员 + 无进球）
    let outcomeCount = 2; // 默认 2 向
    if (propType.id <= 2) { // GOALS_OU, ASSISTS_OU, SHOTS_OU
      outcomeCount = (propLine % 1000 === 0) ? 3 : 2; // 整球盘 3 向，半球盘 2 向
    }

    // SimpleCPMM 需要初始化虚拟储备（每个 outcome 1000 * 1e18）
    const initialReserves = Array(outcomeCount).fill(ethers.parseEther('1000'));

    // 构造 PlayerPropsInitData 结构体
    const initDataStruct = {
      matchId: matchId,
      playerId: player,
      playerName: player,
      propType: propType.id,  // PropType 枚举值 (0-6)
      line: propLine,
      kickoffTime: kickoffTime,
      settlementToken: this.config.contracts.usdc,
      feeRecipient: signerAddress,
      feeRate: 200,
      disputePeriod: 2 * 60 * 60,
      uri: `https://api.pitchone.io/metadata/pp/${matchId}`,
      owner: signerAddress,
      pricingEngineAddr: this.config.contracts.cpmm,
      initialReserves: initialReserves, // SimpleCPMM 虚拟储备
      playerIds: [],       // 非 FIRST_SCORER 类型为空
      playerNames: []      // 非 FIRST_SCORER 类型为空
    };

    const initData = iface.encodeFunctionData('initialize', [initDataStruct]);
    
    const tx = await this.factory.createMarket(this.config.templates.playerProps, initData, { nonce: this.getNextNonce() });
    const receipt = await tx.wait();
    
    const marketCreatedEvent = receipt.logs.find((log: any) => {
      try {
        const parsed = this.factory.interface.parseLog(log);
        return parsed?.name === 'MarketCreated';
      } catch {
        return false;
      }
    });
    
    const marketAddress = marketCreatedEvent ? 
      this.factory.interface.parseLog(marketCreatedEvent).args.market : 
      null;
    
    if (marketAddress) {
      console.log(`✅ PlayerProps Market created: ${player} ${propType.name} -> ${marketAddress}`);
    }
    
    return marketAddress;
  }
  
  // ========== ScoreTemplate 市场 ==========
  async createScoreMarket(): Promise<string> {
    let matchId: string, home: string, away: string, kickoffTime: number, scoreRange: number;

    if (this.usePreset && this.presetCounters.score < PRESET_MARKETS.score.length) {
      // 使用预定义数据
      const preset = PRESET_MARKETS.score[this.presetCounters.score];
      this.presetCounters.score++;
      matchId = preset.matchId;
      home = preset.home;
      away = preset.away;
      kickoffTime = getFutureTimestamp(preset.days);
      scoreRange = preset.scoreRange;
    } else {
      // 使用随机数据
      const league = randomItem(['epl', 'lal', 'ser', 'bun', 'lig'] as const);
      [home, away] = randomTeamPair(league);
      matchId = generateMatchId('SC', home, away);
      kickoffTime = getFutureTimestamp(Math.floor(Math.random() * 7) + 1);
      const scoreRanges = [4, 5, 6];
      scoreRange = randomItem(scoreRanges);
    }

    const scoreAbi = this.loadAbi('ScoreTemplate');
    const iface = new ethers.Interface(scoreAbi);

    const signerAddress = await this.signer.getAddress();

    // 使用空数组让合约自动使用均匀分布
    const initialProbabilities: any[] = [];

    const initData = iface.encodeFunctionData('initialize', [
      matchId,
      home,
      away,
      kickoffTime,
      scoreRange,
      this.config.contracts.usdc,
      signerAddress, // feeRecipient
      200, // 2% fee
      2 * 60 * 60, // 2 hours dispute period
      ethers.parseUnits('10000', 6), // liquidityB for LMSR (10,000 USDC)
      initialProbabilities, // 空数组，使用均匀分布
      `https://api.pitchone.io/metadata/score/${matchId}`,
      signerAddress // owner
    ]);

    const tx = await this.factory.createMarket(this.config.templates.score, initData, { nonce: this.getNextNonce() });
    const receipt = await tx.wait();

    const marketCreatedEvent = receipt.logs.find((log: any) => {
      try {
        const parsed = this.factory.interface.parseLog(log);
        return parsed?.name === 'MarketCreated';
      } catch {
        return false;
      }
    });

    const marketAddress = marketCreatedEvent ?
      this.factory.interface.parseLog(marketCreatedEvent).args.market :
      null;

    if (marketAddress) {
      console.log(`✅ Score Market created: ${home} vs ${away} (0-${scoreRange}) -> ${marketAddress}`);
    }

    return marketAddress;
  }

  // ========== OU_MultiLine 市场 ==========
  async createOuMultiLineMarket(): Promise<string> {
    let matchId: string, home: string, away: string, kickoffTime: number, lines: number[];

    if (this.usePreset && this.presetCounters.ou_multiline < PRESET_MARKETS.ou_multiline.length) {
      // 使用预定义数据
      const preset = PRESET_MARKETS.ou_multiline[this.presetCounters.ou_multiline];
      this.presetCounters.ou_multiline++;
      matchId = preset.matchId;
      home = preset.home;
      away = preset.away;
      kickoffTime = getFutureTimestamp(preset.days);
      lines = preset.lines;
    } else {
      // 使用随机数据
      const league = randomItem(['epl', 'lal', 'ser', 'bun', 'lig'] as const);
      [home, away] = randomTeamPair(league);
      matchId = generateMatchId('OU_ML', home, away);
      kickoffTime = getFutureTimestamp(Math.floor(Math.random() * 7) + 1);
      const lineGroups = [
        [1500, 2500, 3500],           // 1.5, 2.5, 3.5
        [500, 1500, 2500, 3500],      // 0.5, 1.5, 2.5, 3.5
        [2500, 3500, 4500]            // 2.5, 3.5, 4.5
      ];
      lines = randomItem(lineGroups);
    }

    // 部署 LinkedLinesController
    const LinkedLinesController = new ethers.ContractFactory(
      this.loadAbi('LinkedLinesController'),
      this.getBytecode('LinkedLinesController'),
      this.signer
    );
    const signerAddress = await this.signer.getAddress();
    const controller = await LinkedLinesController.deploy(signerAddress, ethers.ZeroAddress, { nonce: this.getNextNonce() });
    await controller.waitForDeployment();
    const controllerAddress = await controller.getAddress();

    const ouMultiLineAbi = this.loadAbi('OU_MultiLine');
    const iface = new ethers.Interface(ouMultiLineAbi);

    // 构造 InitializeParams 结构体
    const initParams = {
      matchId: matchId,
      homeTeam: home,
      awayTeam: away,
      kickoffTime: kickoffTime,
      lines: lines,
      settlementToken: this.config.contracts.usdc,
      feeRecipient: signerAddress,
      feeRate: 200,
      disputePeriod: 2 * 60 * 60,
      pricingEngine: this.config.contracts.cpmm,
      linkedLinesController: controllerAddress,
      uri: `https://api.pitchone.io/metadata/ou-ml/${matchId}`,
      owner: signerAddress
    };

    const initData = iface.encodeFunctionData('initialize', [initParams]);

    const tx = await this.factory.createMarket(this.config.templates.ouMultiLine, initData, { nonce: this.getNextNonce() });
    const receipt = await tx.wait();

    const marketCreatedEvent = receipt.logs.find((log: any) => {
      try {
        const parsed = this.factory.interface.parseLog(log);
        return parsed?.name === 'MarketCreated';
      } catch {
        return false;
      }
    });

    const marketAddress = marketCreatedEvent ?
      this.factory.interface.parseLog(marketCreatedEvent).args.market :
      null;

    if (marketAddress) {
      console.log(`✅ OU_MultiLine Market created: ${home} vs ${away} (${lines.map(l => l/1000).join(', ')} goals) -> ${marketAddress}`);
      console.log(`   Controller: ${controllerAddress}`);
    }

    return marketAddress;
  }

  // ========== 创建指定类型的市场 ==========
  async createMarket(type: MarketType): Promise<string> {
    switch (type) {
      case 'wdl':
        return await this.createWdlMarket();
      case 'ou':
        return await this.createOuMarket();
      case 'ou_multiline':
        return await this.createOuMultiLineMarket();
      case 'ah':
        return await this.createAhMarket();
      case 'oddeven':
        return await this.createOddEvenMarket();
      case 'score':
        return await this.createScoreMarket();
      case 'playerprops':
        return await this.createPlayerPropsMarket();
      default:
        throw new Error(`Unsupported market type: ${type}`);
    }
  }
}

// ============ 主函数 ============

async function main() {
  // 解析命令行参数
  const args = process.argv.slice(2);
  const options: CreateMarketOptions = {};
  
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--type':
        options.type = args[++i] as MarketType;
        break;
      case '--count':
        options.count = parseInt(args[++i]);
        break;
      case '--all':
        options.all = true;
        break;
      case '--preset':
        options.preset = true;
        break;
    }
  }
  
  console.log('\n========================================');
  console.log('  PitchOne Market Creator');
  console.log('========================================\n');
  
  // 加载配置
  const config = loadDeploymentConfig();
  console.log('📋 Deployment Config Loaded');
  console.log(`   Factory: ${config.contracts.factory}`);
  console.log(`   Vault: ${config.contracts.vault}\n`);
  
  // 连接到本地节点
  const provider = new ethers.JsonRpcProvider('http://localhost:8545');
  const privateKey = process.env.PRIVATE_KEY || '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
  const signer = new ethers.Wallet(privateKey, provider);
  
  console.log(`🔑 Signer: ${await signer.getAddress()}\n`);

  const usePreset = options.preset || false;
  if (usePreset) {
    console.log('📌 Using preset market data (same as Solidity script)\n');
  } else {
    console.log('🎲 Using random market data\n');
  }

  const creator = new MarketCreator(provider, signer, config, usePreset);
  await creator.initNonce(); // 初始化 nonce

  let marketsToCreate: MarketType[] = [];
  
  if (options.all) {
    // 创建所有类型的市场
    const count = options.count || 3;
    const types: MarketType[] = ['wdl', 'ou', 'ou_multiline', 'ah', 'oddeven', 'score', 'playerprops'];
    marketsToCreate = types.flatMap(type => Array(count).fill(type));
    console.log(`📊 Creating ${count} markets of each type (${types.length} types, ${marketsToCreate.length} total)\n`);
  } else if (options.type) {
    // 创建指定类型的市场
    const count = options.count || 1;
    marketsToCreate = Array(count).fill(options.type);
    console.log(`🎯 Creating ${count} ${options.type.toUpperCase()} market(s)\n`);
  } else {
    console.log('❌ No markets specified. Use --help for usage instructions.\n');
    console.log('Examples:');
    console.log('  pnpm tsx script/ts/createMarkets.ts --all --count 3');
    console.log('  pnpm tsx script/ts/createMarkets.ts --type wdl --count 5');
    console.log('  pnpm tsx script/ts/createMarkets.ts --type ou_multiline --count 2\n');
    return;
  }
  
  // 创建市场
  const created: string[] = [];
  for (let i = 0; i < marketsToCreate.length; i++) {
    const type = marketsToCreate[i];
    try {
      const address = await creator.createMarket(type);
      if (address) {
        created.push(address);
      }
    } catch (error: any) {
      console.log(`❌ Failed to create ${type} market: ${error.message}`);
    }
  }
  
  console.log('\n========================================');
  console.log('  Summary');
  console.log('========================================');
  console.log(`Total Markets Created: ${created.length}/${marketsToCreate.length}`);
  console.log('========================================\n');
}

main().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
