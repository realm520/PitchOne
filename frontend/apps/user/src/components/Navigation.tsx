'use client';

import Link from 'next/link';
import { useTranslation, LanguageSwitcher } from '@pitchone/i18n';
import { ConnectButton } from '@pitchone/web3';

export function Navigation() {
  const { t } = useTranslation();

  return (
    <div className="flex items-center gap-6">
      <Link href="/markets" className="text-gray-300 hover:text-neon-blue transition-colors">
        {t('nav.markets')}
      </Link>
      <Link href="/portfolio" className="text-gray-300 hover:text-neon-purple transition-colors">
        {t('nav.portfolio')}
      </Link>
      {/* 暂时隐藏串关功能
      <Link href="/parlay" className="text-gray-300 hover:text-neon-green transition-colors">
        {t('nav.parlay')}
      </Link>
      */}
      <Link href="/referral" className="text-gray-300 hover:text-orange-400 transition-colors">
        {t('nav.referral')}
      </Link>
    </div>
  );
}

export function HeaderActions() {
  return (
    <div className="flex items-center gap-3">
      <LanguageSwitcher />
      <ConnectButton />
    </div>
  );
}
