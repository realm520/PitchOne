'use client';

import Link from 'next/link';
import { useTranslation } from '@pitchone/i18n';
import { TwitterIcon, DiscordIcon } from '@pitchone/ui';

/**
 * AppFooter 组件
 *
 * 支持国际化的页脚组件
 */
export function AppFooter() {
  const { t } = useTranslation();
  const currentYear = new Date().getFullYear();

  return (
    <footer className="w-full border-t border-dark-border bg-dark-card mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* About */}
          <div className="space-y-4">
            <h3 className="text-lg font-bold text-accent">PitchOne</h3>
            <p className="text-sm text-gray-400">
              {t('footer.description')}
            </p>
          </div>

          {/* Quick Links */}
          <div className="space-y-4">
            <h4 className="text-sm font-semibold text-gray-300">{t('footer.quickLinks')}</h4>
            <ul className="space-y-2">
              <li>
                <Link href="/markets" className="text-sm text-gray-400 hover:text-accent transition-colors">
                  {t('footer.markets')}
                </Link>
              </li>
              <li>
                <Link href="/portfolio" className="text-sm text-gray-400 hover:text-accent transition-colors">
                  {t('footer.portfolio')}
                </Link>
              </li>
              <li>
                <Link href="/parlay" className="text-sm text-gray-400 hover:text-accent transition-colors">
                  {t('footer.parlay')}
                </Link>
              </li>
            </ul>
          </div>

          {/* Resources */}
          <div className="space-y-4">
            <h4 className="text-sm font-semibold text-gray-300">{t('footer.resources')}</h4>
            <ul className="space-y-2">
              <li>
                <Link href="/docs" className="text-sm text-gray-400 hover:text-accent transition-colors">
                  {t('footer.docs')}
                </Link>
              </li>
              <li>
                <Link href="/faq" className="text-sm text-gray-400 hover:text-accent transition-colors">
                  {t('footer.faq')}
                </Link>
              </li>
              <li>
                <a href="https://github.com/pitchone" target="_blank" rel="noopener noreferrer" className="text-sm text-gray-400 hover:text-accent transition-colors">
                  {t('footer.github')}
                </a>
              </li>
            </ul>
          </div>

          {/* Legal */}
          <div className="space-y-4">
            <h4 className="text-sm font-semibold text-gray-300">{t('footer.legal')}</h4>
            <ul className="space-y-2">
              <li>
                <Link href="/terms" className="text-sm text-gray-400 hover:text-accent transition-colors">
                  {t('footer.terms')}
                </Link>
              </li>
              <li>
                <Link href="/privacy" className="text-sm text-gray-400 hover:text-accent transition-colors">
                  {t('footer.privacy')}
                </Link>
              </li>
              <li>
                <Link href="/risks" className="text-sm text-gray-400 hover:text-accent transition-colors">
                  {t('footer.risks')}
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="mt-8 pt-8 border-t border-dark-border">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <p className="text-sm text-gray-500">
              {t('footer.copyright', { year: currentYear })}
            </p>
            <div className="flex items-center gap-6">
              <a
                href="https://twitter.com/pitchone"
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-400 hover:text-accent transition-colors"
              >
                <TwitterIcon />
              </a>
              <a
                href="https://discord.gg/pitchone"
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-400 hover:text-accent transition-colors"
              >
                <DiscordIcon />
              </a>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
