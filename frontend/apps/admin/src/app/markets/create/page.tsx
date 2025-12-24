'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAccount, useCreateMarket, type CreateMarketParams } from '@pitchone/web3';
import { getContractAddresses } from '@pitchone/contracts';
import { Card, Button, LoadingSpinner } from '@pitchone/ui';
import { encodeFunctionData, parseAbiParameters } from 'viem';
import Link from 'next/link';

// 市场模板类型
// Template ID 来源: contracts/script/Deploy.s.sol 输出
// 注意: 这些 ID 必须与 MarketFactory 注册的模板一致
const MARKET_TEMPLATES = [
  {
    id: 'WDL',
    name: '胜平负 (Win-Draw-Lose)',
    description: '经典三向盘口：主胜/平局/客胜',
    version: 'V2', // 注意: 脚本中注册为 "V2" 而非 "1.0.0"
    templateId: '0xd3848d8e7c5941e95e6e0b351749b347dbeb1b308f305f28b95b1328a3e669dc' as `0x${string}`,
  },
  {
    id: 'OU',
    name: '大小球 (Over/Under)',
    description: '单线大小球盘口',
    version: '1.0.0',
    templateId: '0x6441bdfa8f4495d4dd881afce0e761e3a05085b4330b9db35c684a348ef2697f' as `0x${string}`,
  },
  {
    id: 'OddEven',
    name: '单双号 (Odd/Even)',
    description: '总进球数单双号',
    version: '1.0.0',
    templateId: '0xf1d71fd4a1d5c765ed93ae053cb712e5c2d053fc61d39d01a15c3aadf1da027b' as `0x${string}`,
  },
];

interface MarketFormData {
  // 步骤 1：模板选择
  templateType: string;

  // 步骤 2：赛事信息
  matchId: string;
  homeTeam: string;
  awayTeam: string;
  kickoffTime: string; // ISO 格式时间

  // 步骤 3：市场参数
  feeRate: string; // basis points (200 = 2%)
  disputePeriod: string; // 秒
  initialLiquidity: string; // USDC
  pricingMode: 'cpmm' | 'parimutuel'; // 定价模式

  // OU 特定参数
  line?: string; // 如 "2.5"
}

export default function CreateMarketPage() {
  const router = useRouter();
  const { address, chainId, isConnected } = useAccount();
  const { createMarket, isPending, isConfirming, isSuccess, error, hash } = useCreateMarket();

  const [step, setStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false); // 本地提交状态
  const [formData, setFormData] = useState<MarketFormData>({
    templateType: '',
    matchId: '',
    homeTeam: '',
    awayTeam: '',
    kickoffTime: '',
    feeRate: '200', // 2%
    disputePeriod: '7200', // 2 小时
    initialLiquidity: '1000', // 1000 USDC
    pricingMode: 'parimutuel', // 默认奖池模式
  });

  // 获取合约地址
  const addresses = chainId ? getContractAddresses(chainId) : null;

  // 计算最小开赛时间（当前时间 + 1 小时）
  const minKickoffTime = new Date(Date.now() + 60 * 60 * 1000)
    .toISOString()
    .slice(0, 16); // datetime-local 格式: YYYY-MM-DDTHH:mm

  // 更新表单数据
  const updateFormData = (field: keyof MarketFormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  // 验证当前步骤
  const validateStep = (currentStep: number): boolean => {
    switch (currentStep) {
      case 1:
        return !!formData.templateType;
      case 2:
        return !!(formData.matchId && formData.homeTeam && formData.awayTeam && formData.kickoffTime);
      case 3:
        if (formData.templateType === 'OU' || formData.templateType === 'OU_MULTI') {
          return !!(formData.feeRate && formData.disputePeriod && formData.line);
        }
        return !!(formData.feeRate && formData.disputePeriod);
      default:
        return false;
    }
  };

  // WDL_Template_V2 的 initialize ABI
  const WDL_INITIALIZE_ABI = [
    {
      type: 'function',
      name: 'initialize',
      inputs: [
        { name: '_matchId', type: 'string' },
        { name: '_homeTeam', type: 'string' },
        { name: '_awayTeam', type: 'string' },
        { name: '_kickoffTime', type: 'uint256' },
        { name: '_settlementToken', type: 'address' },
        { name: '_feeRecipient', type: 'address' },
        { name: '_feeRate', type: 'uint256' },
        { name: '_disputePeriod', type: 'uint256' },
        { name: '_pricingEngine', type: 'address' },
        { name: '_vault', type: 'address' },
        { name: '_uri', type: 'string' },
        { name: '_virtualReservePerSide', type: 'uint256' },
      ],
    },
  ] as const;

  // OU_Template 的 initialize ABI (12 个参数)
  const OU_INITIALIZE_ABI = [
    {
      type: 'function',
      name: 'initialize',
      inputs: [
        { name: '_matchId', type: 'string' },
        { name: '_homeTeam', type: 'string' },
        { name: '_awayTeam', type: 'string' },
        { name: '_kickoffTime', type: 'uint256' },
        { name: '_line', type: 'uint256' },
        { name: '_settlementToken', type: 'address' },
        { name: '_feeRecipient', type: 'address' },
        { name: '_feeRate', type: 'uint256' },
        { name: '_disputePeriod', type: 'uint256' },
        { name: '_pricingEngine', type: 'address' },
        { name: '_uri', type: 'string' },
        { name: '_owner', type: 'address' },
      ],
    },
  ] as const;

  // OddEven_Template 的 initialize ABI (11 个参数)
  const ODDEVEN_INITIALIZE_ABI = [
    {
      type: 'function',
      name: 'initialize',
      inputs: [
        { name: '_matchId', type: 'string' },
        { name: '_homeTeam', type: 'string' },
        { name: '_awayTeam', type: 'string' },
        { name: '_kickoffTime', type: 'uint256' },
        { name: '_settlementToken', type: 'address' },
        { name: '_feeRecipient', type: 'address' },
        { name: '_feeRate', type: 'uint256' },
        { name: '_disputePeriod', type: 'uint256' },
        { name: '_pricingEngine', type: 'address' },
        { name: '_uri', type: 'string' },
        { name: '_owner', type: 'address' },
      ],
    },
  ] as const;

  // 生成 initData (使用 encodeFunctionData 包含函数选择器)
  const generateInitData = () => {
    const kickoffTimestamp = BigInt(Math.floor(new Date(formData.kickoffTime).getTime() / 1000));

    if (formData.templateType === 'WDL') {
      // WDL_Template_V2.initialize() - 12 个参数
      // 根据定价模式选择不同的参数
      const isParimutuel = formData.pricingMode === 'parimutuel';
      const pricingEngine = isParimutuel ? addresses!.parimutuel : addresses!.simpleCPMM;
      const virtualReserve = isParimutuel ? 0n : BigInt(7200) * BigInt(10) ** BigInt(6); // Parimutuel = 0, CPMM = 7200 USDC

      return encodeFunctionData({
        abi: WDL_INITIALIZE_ABI,
        functionName: 'initialize',
        args: [
          formData.matchId,           // _matchId
          formData.homeTeam,          // _homeTeam
          formData.awayTeam,          // _awayTeam
          kickoffTimestamp,           // _kickoffTime
          addresses!.usdc,            // _settlementToken
          addresses!.feeRouter,       // _feeRecipient
          BigInt(formData.feeRate),   // _feeRate
          BigInt(formData.disputePeriod), // _disputePeriod
          pricingEngine,              // _pricingEngine (根据模式选择)
          addresses!.vault!,          // _vault
          `https://api.pitchone.io/metadata/wdl/${formData.matchId}`, // _uri
          virtualReserve,             // _virtualReservePerSide (0 = Parimutuel)
        ],
      });
    } else if (formData.templateType === 'OU') {
      // OU_Template.initialize() - 12 个参数
      // _line: 必须是半球盘（如 2500 = 2.5 球），单位是 1/1000
      const lineInBps = BigInt(Math.floor(parseFloat(formData.line!) * 1000));
      return encodeFunctionData({
        abi: OU_INITIALIZE_ABI,
        functionName: 'initialize',
        args: [
          formData.matchId,           // _matchId
          formData.homeTeam,          // _homeTeam
          formData.awayTeam,          // _awayTeam
          kickoffTimestamp,           // _kickoffTime
          lineInBps,                  // _line (2500 = 2.5 球)
          addresses!.usdc,            // _settlementToken
          addresses!.feeRouter,       // _feeRecipient
          BigInt(formData.feeRate),   // _feeRate
          BigInt(formData.disputePeriod), // _disputePeriod
          addresses!.simpleCPMM,      // _pricingEngine
          `https://api.pitchone.io/metadata/ou/${formData.matchId}`, // _uri
          address!,                   // _owner
        ],
      });
    } else if (formData.templateType === 'OddEven') {
      // OddEven_Template.initialize() - 11 个参数
      return encodeFunctionData({
        abi: ODDEVEN_INITIALIZE_ABI,
        functionName: 'initialize',
        args: [
          formData.matchId,           // _matchId
          formData.homeTeam,          // _homeTeam
          formData.awayTeam,          // _awayTeam
          kickoffTimestamp,           // _kickoffTime
          addresses!.usdc,            // _settlementToken
          addresses!.feeRouter,       // _feeRecipient
          BigInt(formData.feeRate),   // _feeRate
          BigInt(formData.disputePeriod), // _disputePeriod
          addresses!.simpleCPMM,      // _pricingEngine
          `https://api.pitchone.io/metadata/oddeven/${formData.matchId}`, // _uri
          address!,                   // _owner
        ],
      });
    }

    throw new Error('Unsupported template type');
  };

  // 获取 templateId (使用预定义的硬编码值)
  const getTemplateId = (): `0x${string}` => {
    const template = MARKET_TEMPLATES.find(t => t.id === formData.templateType);
    if (!template) throw new Error('Template not found');
    return template.templateId;
  };

  // 提交创建市场
  const handleSubmit = async () => {
    // 防止重复提交
    if (isSubmitting || isPending || isConfirming) {
      console.warn('[CreateMarket] 阻止重复提交');
      return;
    }

    if (!isConnected || !addresses) {
      alert('请先连接钱包');
      return;
    }

    // 验证开赛时间必须在未来（至少 1 小时后）
    const kickoffTime = new Date(formData.kickoffTime).getTime();
    const minTime = Date.now() + 60 * 60 * 1000; // 1 小时后
    if (kickoffTime < minTime) {
      alert('开赛时间必须至少在 1 小时后');
      return;
    }

    try {
      // 立即设置提交状态，防止快速双击
      setIsSubmitting(true);

      const templateId = getTemplateId();
      const kickoffTimestamp = BigInt(Math.floor(new Date(formData.kickoffTime).getTime() / 1000));

      // 构建 CreateMarketParams
      const params: CreateMarketParams = {
        templateId,
        matchId: formData.matchId,
        kickoffTime: kickoffTimestamp,
        mapperInitData: '0x' as `0x${string}`, // 默认空数据
        initialLiquidity: 0n, // 使用模板默认值
        outcomeRules: [], // 使用模板默认规则
      };

      console.log('创建市场:', {
        params,
        formData
      });

      await createMarket(params);
    } catch (err) {
      console.error('创建市场失败:', err);
      alert(`创建失败: ${err instanceof Error ? err.message : '未知错误'}\n\n如果遇到 nonce 错误，请刷新页面重试。`);
      setIsSubmitting(false); // 失败时重置状态
    }
  };

  // 监听交易状态，重置提交状态
  useEffect(() => {
    if (isSuccess || error) {
      setIsSubmitting(false);
    }
  }, [isSuccess, error]);

  // 交易成功后跳转
  useEffect(() => {
    if (isSuccess && hash) {
      const timer = setTimeout(() => {
        router.push('/markets');
      }, 2000);
      return () => clearTimeout(timer);
    }
  }, [isSuccess, hash, router]);

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                创建市场
              </h1>
              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                通过工厂合约创建新的博彩市场
              </p>
            </div>
            <Link href="/markets">
              <Button variant="outline">
                ← 返回列表
              </Button>
            </Link>
          </div>

          {/* 步骤指示器 */}
          <div className="mt-8 flex items-center justify-center">
            {[1, 2, 3, 4].map((s) => (
              <div key={s} className="flex items-center">
                <div
                  className={`flex items-center justify-center w-10 h-10 rounded-full border-2 ${
                    step >= s
                      ? 'border-blue-500 bg-blue-500 text-white'
                      : 'border-gray-300 bg-white text-gray-500'
                  }`}
                >
                  {s}
                </div>
                {s < 4 && (
                  <div
                    className={`w-16 h-0.5 ${
                      step > s ? 'bg-blue-500' : 'bg-gray-300'
                    }`}
                  />
                )}
              </div>
            ))}
          </div>
          <div className="mt-4 flex items-center justify-center gap-16 text-xs text-gray-500">
            <span className={step === 1 ? 'font-semibold text-blue-500' : ''}>选择模板</span>
            <span className={step === 2 ? 'font-semibold text-blue-500' : ''}>赛事信息</span>
            <span className={step === 3 ? 'font-semibold text-blue-500' : ''}>市场参数</span>
            <span className={step === 4 ? 'font-semibold text-blue-500' : ''}>确认创建</span>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <Card className="p-8">
          {/* 步骤 1: 选择模板 */}
          {step === 1 && (
            <div className="space-y-6">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                选择市场模板
              </h2>
              <div className="grid grid-cols-1 gap-4">
                {MARKET_TEMPLATES.map((template) => (
                  <button
                    key={template.id}
                    onClick={() => updateFormData('templateType', template.id)}
                    className={`p-6 border-2 rounded-lg text-left transition-all ${
                      formData.templateType === template.id
                        ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                        : 'border-gray-200 dark:border-gray-700 hover:border-gray-300'
                    }`}
                  >
                    <h3 className="font-semibold text-gray-900 dark:text-white">
                      {template.name}
                    </h3>
                    <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                      {template.description}
                    </p>
                    <p className="mt-2 text-xs text-gray-400">
                      版本: {template.version}
                    </p>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* 步骤 2: 赛事信息 */}
          {step === 2 && (
            <div className="space-y-6">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                填写赛事信息
              </h2>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    比赛 ID *
                  </label>
                  <input
                    type="text"
                    value={formData.matchId}
                    onChange={(e) => updateFormData('matchId', e.target.value)}
                    placeholder="例如: EPL_2024_MUN_vs_MCI"
                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      主队 *
                    </label>
                    <input
                      type="text"
                      value={formData.homeTeam}
                      onChange={(e) => updateFormData('homeTeam', e.target.value)}
                      placeholder="曼联"
                      className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      客队 *
                    </label>
                    <input
                      type="text"
                      value={formData.awayTeam}
                      onChange={(e) => updateFormData('awayTeam', e.target.value)}
                      placeholder="曼城"
                      className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    开赛时间 *
                  </label>
                  <input
                    type="datetime-local"
                    value={formData.kickoffTime}
                    onChange={(e) => updateFormData('kickoffTime', e.target.value)}
                    min={minKickoffTime}
                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
                  />
                  <p className="mt-1 text-xs text-gray-500">
                    必须选择至少 1 小时后的时间
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* 步骤 3: 市场参数 */}
          {step === 3 && (
            <div className="space-y-6">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                配置市场参数
              </h2>
              <div className="space-y-4">
                {/* 定价模式选择 - 仅 WDL 支持 */}
                {formData.templateType === 'WDL' && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      定价模式 *
                    </label>
                    <div className="grid grid-cols-2 gap-4">
                      <button
                        type="button"
                        onClick={() => updateFormData('pricingMode', 'parimutuel')}
                        className={`p-4 border-2 rounded-lg text-left transition-all ${
                          formData.pricingMode === 'parimutuel'
                            ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                            : 'border-gray-200 dark:border-gray-700 hover:border-gray-300'
                        }`}
                      >
                        <h3 className="font-semibold text-gray-900 dark:text-white">
                          奖池模式 (Parimutuel)
                        </h3>
                        <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                          所有投注进入共享奖池，赢家按份额分配
                        </p>
                      </button>
                      <button
                        type="button"
                        onClick={() => updateFormData('pricingMode', 'cpmm')}
                        className={`p-4 border-2 rounded-lg text-left transition-all ${
                          formData.pricingMode === 'cpmm'
                            ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                            : 'border-gray-200 dark:border-gray-700 hover:border-gray-300'
                        }`}
                      >
                        <h3 className="font-semibold text-gray-900 dark:text-white">
                          做市商模式 (CPMM)
                        </h3>
                        <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                          AMM 自动做市，赔率随投注量动态调整
                        </p>
                      </button>
                    </div>
                  </div>
                )}
                {(formData.templateType === 'OU' || formData.templateType === 'OU_MULTI') && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      大小球盘口线 *
                    </label>
                    <input
                      type="number"
                      step="0.5"
                      value={formData.line || ''}
                      onChange={(e) => updateFormData('line', e.target.value)}
                      placeholder="2.5"
                      className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
                    />
                    <p className="mt-1 text-xs text-gray-500">
                      例如: 2.5 表示大于 2.5 球 vs 小于 2.5 球
                    </p>
                  </div>
                )}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    手续费率 (basis points) *
                  </label>
                  <input
                    type="number"
                    value={formData.feeRate}
                    onChange={(e) => updateFormData('feeRate', e.target.value)}
                    placeholder="200"
                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
                  />
                  <p className="mt-1 text-xs text-gray-500">
                    200 = 2%, 100 = 1%
                  </p>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    争议期（秒）*
                  </label>
                  <input
                    type="number"
                    value={formData.disputePeriod}
                    onChange={(e) => updateFormData('disputePeriod', e.target.value)}
                    placeholder="7200"
                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
                  />
                  <p className="mt-1 text-xs text-gray-500">
                    7200 = 2 小时
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* 步骤 4: 确认创建 */}
          {step === 4 && (
            <div className="space-y-6">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                确认市场信息
              </h2>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-6 space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">模板类型</p>
                    <p className="font-medium text-gray-900 dark:text-white">
                      {MARKET_TEMPLATES.find(t => t.id === formData.templateType)?.name}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">比赛 ID</p>
                    <p className="font-medium text-gray-900 dark:text-white">{formData.matchId}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">对阵双方</p>
                    <p className="font-medium text-gray-900 dark:text-white">
                      {formData.homeTeam} vs {formData.awayTeam}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">开赛时间</p>
                    <p className="font-medium text-gray-900 dark:text-white">
                      {new Date(formData.kickoffTime).toLocaleString('zh-CN')}
                    </p>
                  </div>
                  {formData.line && (
                    <div>
                      <p className="text-sm text-gray-500 dark:text-gray-400">盘口线</p>
                      <p className="font-medium text-gray-900 dark:text-white">{formData.line} 球</p>
                    </div>
                  )}
                  {formData.templateType === 'WDL' && (
                    <div>
                      <p className="text-sm text-gray-500 dark:text-gray-400">定价模式</p>
                      <p className="font-medium text-gray-900 dark:text-white">
                        {formData.pricingMode === 'parimutuel' ? '奖池模式 (Parimutuel)' : '做市商模式 (CPMM)'}
                      </p>
                    </div>
                  )}
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">手续费率</p>
                    <p className="font-medium text-gray-900 dark:text-white">
                      {(parseInt(formData.feeRate) / 100).toFixed(2)}%
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500 dark:text-gray-400">争议期</p>
                    <p className="font-medium text-gray-900 dark:text-white">
                      {parseInt(formData.disputePeriod) / 3600} 小时
                    </p>
                  </div>
                </div>
              </div>

              {/* 交易状态 */}
              {isPending && (
                <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
                  <p className="text-sm text-yellow-800 dark:text-yellow-200">
                    ⏳ 等待钱包确认...
                  </p>
                </div>
              )}
              {isConfirming && (
                <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
                  <div className="flex items-center gap-3">
                    <LoadingSpinner size="sm" />
                    <div>
                      <p className="text-sm font-medium text-blue-800 dark:text-blue-200">
                        ⛓️ 交易确认中...
                      </p>
                      {hash && (
                        <a
                          href={`http://localhost:8545/tx/${hash}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-xs text-blue-600 dark:text-blue-400 hover:underline"
                        >
                          查看交易: {hash.slice(0, 10)}...
                        </a>
                      )}
                    </div>
                  </div>
                </div>
              )}
              {isSuccess && (
                <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4">
                  <p className="text-sm font-medium text-green-800 dark:text-green-200">
                    ✅ 市场创建成功！即将跳转...
                  </p>
                </div>
              )}
              {error && (
                <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
                  <p className="text-sm font-medium text-red-800 dark:text-red-200">
                    ❌ 创建失败
                  </p>
                  <p className="text-xs text-red-600 dark:text-red-400 mt-1">
                    {error.message}
                  </p>
                </div>
              )}
            </div>
          )}

          {/* 操作按钮 */}
          <div className="mt-8 flex items-center justify-between">
            <Button
              variant="outline"
              onClick={() => setStep(Math.max(1, step - 1))}
              disabled={step === 1 || isPending || isConfirming}
            >
              ← 上一步
            </Button>
            {step < 4 ? (
              <Button
                variant="outline"
                onClick={() => setStep(step + 1)}
                disabled={!validateStep(step)}
              >
                下一步 →
              </Button>
            ) : (
              <Button
                variant="outline"
                onClick={handleSubmit}
                disabled={!isConnected || isSubmitting || isPending || isConfirming || isSuccess}
              >
                {isSubmitting || isPending || isConfirming ? '创建中...' : '创建市场'}
              </Button>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
}
