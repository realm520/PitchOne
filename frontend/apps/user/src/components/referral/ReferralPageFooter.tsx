'use client';

import { useReferralParams } from '@pitchone/web3';
import { useTranslation } from '@pitchone/i18n';

/**
 * ReferralPageFooter 组件
 *
 * 功能：
 * 1. 显示推荐系统使用说明
 * 2. 动态显示从合约读取的返佣比例
 *
 * @example
 * ```tsx
 * import { ReferralPageFooter } from '@/components/referral/ReferralPageFooter';
 *
 * export default function ReferralPage() {
 *   return <ReferralPageFooter />;
 * }
 * ```
 */
export function ReferralPageFooter() {
  const { t } = useTranslation();
  const { feeBps } = useReferralParams();

  const feePercentage = feeBps
    ? (Number(feeBps) / 100).toFixed(2)
    : '8.00'; // 默认值

  return (
    <div className="mt-8 p-6 bg-dark-card border border-dark-border rounded-lg">
      <div className="flex items-start gap-4">
        <svg
          className="w-6 h-6 text-accent flex-shrink-0 mt-1"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
        <div>
          <h3 className="text-lg font-bold text-white mb-2">{t('referral.footer.title')}</h3>
          <ol className="space-y-2 text-sm text-gray-400">
            <li className="flex gap-2">
              <span className="text-accent">1.</span>
              <span>{t('referral.footer.step1')}</span>
            </li>
            <li className="flex gap-2">
              <span className="text-accent">2.</span>
              <span>{t('referral.footer.step2')}</span>
            </li>
            <li className="flex gap-2">
              <span className="text-accent">3.</span>
              <span>
                {t('referral.footer.step3')}{' '}
                <span className="text-accent font-semibold">{feePercentage}%</span> {t('referral.footer.step3Suffix')}
              </span>
            </li>
            <li className="flex gap-2">
              <span className="text-accent">4.</span>
              <span>{t('referral.footer.step4')}</span>
            </li>
          </ol>
        </div>
      </div>
    </div>
  );
}
