'use client';

import { useState } from 'react';
import { Container } from '@pitchone/ui';
import { ParlayBuilder, ParlayList } from '../../components/parlay';
import { useAccount } from '@pitchone/web3';
import { useParlayStore } from '../../lib/parlay-store';
import { useTranslation } from '@pitchone/i18n';

/**
 * 串关页面客户端组件
 */
export function ParlayPageClient() {
  const { t } = useTranslation();
  const { address, isConnected } = useAccount();
  const { selectedOutcomes, removeOutcome, clearAll } = useParlayStore();
  const [activeTab, setActiveTab] = useState<'create' | 'my-parlays'>('create');

  // 创建成功后的回调
  const handleSuccess = () => {
    clearAll();
    setActiveTab('my-parlays');
  };

  if (!isConnected) {
    return (
      <Container className="min-h-screen py-12">
        <div className="max-w-2xl mx-auto text-center space-y-6">
          <h1 className="text-4xl font-bold text-white">{t('parlay.title')}</h1>
          <p className="text-xl text-gray-400">
            {t('parlay.connectWallet')}
          </p>
          <div className="pt-8">
            <div className="text-gray-500 text-sm">
              {t('parlay.connectDesc')}
            </div>
          </div>
        </div>
      </Container>
    );
  }

  return (
    <Container className="min-h-screen py-12">
      <div className="space-y-8">
        {/* Header */}
        <div className="text-center space-y-4">
          <h1 className="text-4xl md:text-5xl font-bold text-white">
            {t('parlay.pageTitle')}
          </h1>
          <p className="text-lg text-gray-400 max-w-2xl mx-auto">
            {t('parlay.pageSubtitle')}
          </p>
        </div>

        {/* Tab Navigation */}
        <div className="flex items-center justify-center gap-4">
          <button
            onClick={() => setActiveTab('create')}
            className={`px-6 py-3 rounded-lg font-semibold transition-all ${
              activeTab === 'create'
                ? 'bg-accent text-white shadow-sm'
                : 'bg-dark-card text-gray-400 hover:text-white border border-dark-border'
            }`}
          >
            {t('parlay.tabs.create')}
          </button>
          <button
            onClick={() => setActiveTab('my-parlays')}
            className={`px-6 py-3 rounded-lg font-semibold transition-all ${
              activeTab === 'my-parlays'
                ? 'bg-accent text-white shadow-sm'
                : 'bg-dark-card text-gray-400 hover:text-white border border-dark-border'
            }`}
          >
            {t('parlay.tabs.myParlays')}
          </button>
        </div>

        {/* Content */}
        <div className="max-w-6xl mx-auto">
          {activeTab === 'create' ? (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              {/* 左侧：市场选择提示 */}
              <div className="lg:col-span-2 space-y-6">
                <div className="bg-dark-card border border-dark-border rounded-xl p-6">
                  <h2 className="text-xl font-bold text-white mb-4">
                    {t('parlay.howTo.title')}
                  </h2>
                  <ol className="space-y-3 text-gray-400">
                    <li className="flex items-start gap-3">
                      <span className="text-accent font-bold">1.</span>
                      <span>{t('parlay.howTo.step1')}</span>
                    </li>
                    <li className="flex items-start gap-3">
                      <span className="text-accent font-bold">2.</span>
                      <span>{t('parlay.howTo.step2')}</span>
                    </li>
                    <li className="flex items-start gap-3">
                      <span className="text-accent font-bold">3.</span>
                      <span>{t('parlay.howTo.step3')}</span>
                    </li>
                    <li className="flex items-start gap-3">
                      <span className="text-accent font-bold">4.</span>
                      <span>{t('parlay.howTo.step4')}</span>
                    </li>
                  </ol>

                  <div className="mt-6 pt-6 border-t border-dark-border">
                    <a
                      href="/markets"
                      className="inline-flex items-center gap-2 px-6 py-3 bg-accent text-white rounded-lg font-semibold hover:bg-accent-hover transition-colors"
                    >
                      {t('parlay.goToMarkets')}
                      <svg
                        className="w-4 h-4"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M13 7l5 5m0 0l-5 5m5-5H6"
                        />
                      </svg>
                    </a>
                  </div>
                </div>

                {/* 串关规则说明 */}
                <div className="bg-yellow-500/10 border border-yellow-500/30 rounded-xl p-6">
                  <h3 className="text-lg font-bold text-yellow-400 mb-3">
                    {t('parlay.rules.title')}
                  </h3>
                  <ul className="space-y-2 text-sm text-yellow-200">
                    <li>• {t('parlay.rules.rule1')}</li>
                    <li>• {t('parlay.rules.rule2')}</li>
                    <li>• {t('parlay.rules.rule3')}</li>
                    <li>• {t('parlay.rules.rule4')}</li>
                    <li>• {t('parlay.rules.rule5')}</li>
                  </ul>
                </div>
              </div>

              {/* 右侧：串关构建器 */}
              <div className="lg:col-span-1">
                <ParlayBuilder
                  selectedOutcomes={selectedOutcomes}
                  onRemoveOutcome={removeOutcome}
                  onClearAll={clearAll}
                  onSuccess={handleSuccess}
                />
              </div>
            </div>
          ) : (
            <ParlayList userAddress={address} />
          )}
        </div>
      </div>
    </Container>
  );
}
