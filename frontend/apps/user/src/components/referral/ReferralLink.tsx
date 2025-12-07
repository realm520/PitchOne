'use client';

import { useState, useEffect } from 'react';
import { useAccount } from '@pitchone/web3';
import { Card, Button } from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';

/**
 * ReferralLink 组件
 *
 * 功能：
 * 1. 生成并显示用户的推荐链接
 * 2. 提供一键复制功能
 * 3. 显示复制状态反馈
 *
 * @example
 * ```tsx
 * import { ReferralLink } from '@/components/referral/ReferralLink';
 *
 * export default function ReferralPage() {
 *   return (
 *     <div>
 *       <h1>我的推荐链接</h1>
 *       <ReferralLink />
 *     </div>
 *   );
 * }
 * ```
 */
export function ReferralLink() {
  const { t } = useTranslation();
  const { address, isConnected } = useAccount();
  const [copied, setCopied] = useState(false);
  const [mounted, setMounted] = useState(false);

  // 避免 hydration 错误：等待客户端挂载后再渲染
  useEffect(() => {
    setMounted(true);
  }, []);

  // 生成推荐链接
  const getReferralLink = (): string => {
    if (!address) return '';

    const baseUrl = typeof window !== 'undefined' ? window.location.origin : '';
    return `${baseUrl}/?ref=${address}`;
  };

  // 复制到剪贴板（含 fallback 支持非安全上下文）
  const handleCopy = async () => {
    const link = getReferralLink();

    try {
      // 优先使用现代 Clipboard API
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(link);
      } else {
        // Fallback: 使用传统方法（支持 HTTP 环境）
        const textArea = document.createElement('textarea');
        textArea.value = link;
        textArea.style.position = 'fixed';
        textArea.style.left = '-9999px';
        textArea.style.top = '-9999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();

        const successful = document.execCommand('copy');
        document.body.removeChild(textArea);

        if (!successful) {
          throw new Error('execCommand copy failed');
        }
      }

      setCopied(true);

      // 2秒后重置复制状态
      setTimeout(() => {
        setCopied(false);
      }, 2000);
    } catch (err) {
      console.error('Copy failed:', err);
      // 可选：给用户提示
      alert(t('referral.link.copyFailed'));
    }
  };

  // 分享到社交媒体（示例）
  const handleShare = (platform: 'twitter' | 'telegram') => {
    const link = getReferralLink();
    const text = encodeURIComponent(t('referral.link.shareText'));

    let shareUrl = '';
    switch (platform) {
      case 'twitter':
        shareUrl = `https://twitter.com/intent/tweet?text=${text}&url=${encodeURIComponent(link)}`;
        break;
      case 'telegram':
        shareUrl = `https://t.me/share/url?url=${encodeURIComponent(link)}&text=${text}`;
        break;
    }

    if (shareUrl) {
      window.open(shareUrl, '_blank', 'noopener,noreferrer');
    }
  };

  // 在客户端挂载前，显示加载状态（避免 hydration 错误）
  if (!mounted) {
    return (
      <Card padding="lg">
        <div className="text-center py-8">
          <div className="w-12 h-12 mx-auto mb-4 animate-pulse bg-gray-700 rounded-full" />
          <p className="text-gray-400 text-sm">{t('referral.loading')}</p>
        </div>
      </Card>
    );
  }

  if (!isConnected) {
    return (
      <Card padding="lg">
        <div className="text-center py-8">
          <svg
            className="w-12 h-12 mx-auto mb-4 text-gray-500"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"
            />
          </svg>
          <p className="text-gray-400 text-sm">{t('referral.connectWalletForLink')}</p>
        </div>
      </Card>
    );
  }

  const referralLink = getReferralLink();

  return (
    <Card padding="lg">
      {/* 标题 */}
      <div className="mb-6">
        <h3 className="text-lg font-bold text-white mb-2">{t('referral.link.title')}</h3>
        <p className="text-sm text-gray-400">
          {t('referral.link.desc')}
        </p>
      </div>

      {/* 推荐链接输入框 */}
      <div className="mb-4">
        <div className="flex items-center gap-2">
          <div className="flex-1 relative">
            <input
              type="text"
              value={referralLink}
              readOnly
              className="w-full px-4 py-3 bg-dark-card border border-dark-border rounded-lg text-white text-sm focus:outline-none focus:border-neon-blue transition-colors"
            />
          </div>

          <Button
            onClick={handleCopy}
            variant={copied ? 'neon' : 'primary'}
            size="md"
            className="px-6"
          >
            {copied ? (
              <>
                <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
                {t('referral.copied')}
              </>
            ) : (
              <>
                <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
                  />
                </svg>
                {t('referral.copy')}
              </>
            )}
          </Button>
        </div>
      </div>

      {/* 分享到社交媒体 */}
      <div className="pt-4 border-t border-dark-border">
        <p className="text-sm text-gray-400 mb-3">{t('referral.link.shareTo')}</p>
        <div className="flex gap-3">
          <button
            onClick={() => handleShare('twitter')}
            className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-[#1DA1F2] hover:bg-[#1a8cd8] text-white rounded-lg transition-colors"
          >
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z" />
            </svg>
            Twitter
          </button>

          <button
            onClick={() => handleShare('telegram')}
            className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-[#0088cc] hover:bg-[#0077b5] text-white rounded-lg transition-colors"
          >
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z" />
            </svg>
            Telegram
          </button>
        </div>
      </div>

      {/* 提示信息 */}
      <div className="mt-4 p-3 bg-neon-blue/10 border border-neon-blue/30 rounded-lg">
        <div className="flex gap-2">
          <svg className="w-5 h-5 text-neon-blue flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div className="text-sm text-gray-300">
            <p className="font-medium mb-1">{t('referral.link.rulesTitle')}</p>
            <ul className="space-y-1 text-xs text-gray-400">
              <li>• {t('referral.link.rulesDesc1')}</li>
              <li>• {t('referral.link.rulesDesc2')}</li>
              <li>• {t('referral.link.rulesDesc3')}</li>
            </ul>
          </div>
        </div>
      </div>
    </Card>
  );
}
