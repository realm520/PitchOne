'use client';

import React, { useState } from 'react';
import { Globe } from 'lucide-react';
import { useI18n } from '../provider';
import { locales, localeNames, type Locale } from '../config';

// 语言图标（使用国旗 emoji）
const localeFlags: Record<Locale, string> = {
  zh: '🇨🇳',
  en: '🇺🇸',
  ja: '🇯🇵',
  ko: '🇰🇷',
};

interface LanguageSwitcherProps {
  className?: string;
  variant?: 'dropdown' | 'inline';
}

export function LanguageSwitcher({ className = '', variant = 'dropdown' }: LanguageSwitcherProps) {
  const { locale, setLocale } = useI18n();
  const [isOpen, setIsOpen] = useState(false);

  // 内联模式：直接显示所有语言选项
  if (variant === 'inline') {
    return (
      <div className={`flex items-center gap-2 ${className}`}>
        {locales.map((loc) => (
          <button
            key={loc}
            onClick={() => setLocale(loc)}
            className={`px-2 py-1 rounded text-sm transition-colors ${
              locale === loc
                ? 'bg-accent/20 text-accent'
                : 'text-gray-400 hover:text-white hover:bg-white/10'
            }`}
          >
            <span className="mr-1">{localeFlags[loc]}</span>
            {localeNames[loc]}
          </button>
        ))}
      </div>
    );
  }

  // 下拉菜单模式（hover 触发）
  return (
    <div
      className={`relative ${className}`}
      onMouseEnter={() => setIsOpen(true)}
      onMouseLeave={() => setIsOpen(false)}
    >
      <button
        className={`flex items-center justify-center p-2 transition-colors duration-200 ${
          isOpen ? 'text-white' : 'text-gray-400 hover:text-white'
        }`}
        aria-label="Select language"
      >
        <Globe className="w-6 h-6" />
      </button>

      {isOpen && (
        <div className="absolute right-0 top-full pt-2">
          <div className="py-1 min-w-[130px] bg-dark-card border border-dark-border rounded-lg shadow-card overflow-hidden">
            {locales.map((loc) => (
              <button
                key={loc}
                onClick={() => {
                  setLocale(loc);
                  setIsOpen(false);
                }}
                className={`w-full flex items-center gap-2.5 px-3 py-2 text-sm transition-colors ${
                  locale === loc
                    ? 'bg-accent/15 text-accent'
                    : 'text-gray-300 hover:bg-dark-hover hover:text-white'
                }`}
              >
                <span>{localeFlags[loc]}</span>
                <span>{localeNames[loc]}</span>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
