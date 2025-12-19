'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTranslation, LanguageSwitcher } from '@pitchone/i18n';
import { CustomConnectButton } from '@pitchone/web3';

const navItems = [
  { href: '/markets', labelKey: 'nav.markets' },
  { href: '/portfolio', labelKey: 'nav.portfolio' },
  { href: '/referral', labelKey: 'nav.referral' },
];

export function Navigation() {
  const { t } = useTranslation();
  const pathname = usePathname();

  return (
    <div className="flex items-center gap-10">
      {navItems.map((item) => {
        const isActive = pathname === item.href || pathname?.startsWith(item.href + '/');
        return (
          <Link
            key={item.href}
            href={item.href}
            className={`relative py-1 text-lg font-semibold transition-colors duration-200 ${
              isActive
                ? 'text-white'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            {t(item.labelKey)}
            {isActive && (
              <span className="absolute left-0 right-0 bottom-0 h-0.5 bg-white rounded-full" />
            )}
          </Link>
        );
      })}
    </div>
  );
}

export function HeaderActions() {
  return (
    <div className="flex items-center gap-3">
      <CustomConnectButton />
      <LanguageSwitcher />
    </div>
  );
}
