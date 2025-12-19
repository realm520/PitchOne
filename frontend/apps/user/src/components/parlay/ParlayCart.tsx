'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useParlayStore } from '../../lib/parlay-store';
import { Button } from '@pitchone/ui';
import { motion, AnimatePresence } from 'framer-motion';

/**
 * 浮动串关购物车组件
 * 显示在页面右下角，展示已选择的市场数量
 */
export function ParlayCart() {
  const router = useRouter();
  const { selectedOutcomes, removeOutcome, clearAll } = useParlayStore();
  const [isExpanded, setIsExpanded] = useState(false);

  // 如果没有选择，不显示
  if (selectedOutcomes.length === 0) {
    return null;
  }

  const handleGoToParlay = () => {
    router.push('/parlay');
    setIsExpanded(false);
  };

  return (
    <>
      {/* 浮动按钮 */}
      <motion.div
        initial={{ scale: 0, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0, opacity: 0 }}
        className="fixed bottom-6 right-6 z-50"
      >
        <Button
          onClick={() => setIsExpanded(!isExpanded)}
          className="relative bg-white hover:bg-zinc-200 text-zinc-900 shadow-lg rounded-full w-16 h-16 flex items-center justify-center"
        >
          {/* 串关图标 */}
          <svg
            className="w-8 h-8"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
            />
          </svg>

          {/* 数量徽章 */}
          <span className="absolute -top-2 -right-2 bg-zinc-700 text-white text-xs font-bold rounded-full w-6 h-6 flex items-center justify-center border border-zinc-500">
            {selectedOutcomes.length}
          </span>
        </Button>
      </motion.div>

      {/* 展开的购物车 */}
      <AnimatePresence>
        {isExpanded && (
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.95 }}
            className="fixed bottom-28 right-6 w-96 bg-dark-card border border-white/20 rounded-xl shadow-lg z-50 overflow-hidden"
          >
            {/* Header */}
            <div className="bg-zinc-800 border-b border-zinc-700 px-4 py-3 flex items-center justify-between">
              <h3 className="text-white font-bold">
                串关购物车 ({selectedOutcomes.length})
              </h3>
              <div className="flex items-center gap-2">
                <button
                  onClick={clearAll}
                  className="text-zinc-500 hover:text-white text-sm"
                >
                  清空
                </button>
                <button
                  onClick={() => setIsExpanded(false)}
                  className="text-gray-400 hover:text-white"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                </button>
              </div>
            </div>

            {/* 选中的市场列表 */}
            <div className="max-h-96 overflow-y-auto">
              {selectedOutcomes.map((outcome, index) => (
                <div
                  key={outcome.marketAddress}
                  className="px-4 py-3 border-b border-dark-border hover:bg-dark-bg/50 transition-colors"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="text-white font-mono text-sm">#{index + 1}</span>
                        <span className="text-white text-sm font-semibold line-clamp-1">
                          {outcome.marketName}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-gray-400 text-xs">{outcome.outcomeName}</span>
                        <span className="text-zinc-300 text-xs font-mono">@ {outcome.odds}</span>
                      </div>
                    </div>
                    <button
                      onClick={() => removeOutcome(outcome.marketAddress)}
                      className="text-zinc-500 hover:text-white transition-colors"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                        />
                      </svg>
                    </button>
                  </div>
                </div>
              ))}
            </div>

            {/* Footer - 创建串关按钮 */}
            <div className="px-4 py-3 bg-dark-bg border-t border-zinc-700">
              <Button
                onClick={handleGoToParlay}
                className="w-full bg-white hover:bg-zinc-200 text-zinc-900 font-semibold"
                disabled={selectedOutcomes.length < 2}
              >
                {selectedOutcomes.length < 2
                  ? '至少选择 2 场比赛'
                  : `创建 ${selectedOutcomes.length} 场串关`}
              </Button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
