'use client';

import React, { createContext, useContext, useState, useEffect, useCallback, useMemo } from 'react';
import { Locale, defaultLocale, locales, LOCALE_STORAGE_KEY, localeHtmlLang } from './config';

// 导入翻译文件
import zh from './locales/zh.json';
import en from './locales/en.json';
import ja from './locales/ja.json';
import ko from './locales/ko.json';

// 翻译资源映射
const translations: Record<Locale, typeof zh> = {
  zh,
  en,
  ja,
  ko,
};

// 翻译值类型（支持嵌套）
type TranslationValue = string | { [key: string]: TranslationValue };
type Translations = typeof zh;

// Context 类型
interface I18nContextType {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (key: string, params?: Record<string, string | number>) => string;
  translations: Translations;
}

const I18nContext = createContext<I18nContextType | null>(null);

// 根据路径获取嵌套对象的值
function getNestedValue(obj: TranslationValue, path: string): string | undefined {
  const keys = path.split('.');
  let current: TranslationValue = obj;

  for (const key of keys) {
    if (typeof current !== 'object' || current === null) {
      return undefined;
    }
    current = (current as Record<string, TranslationValue>)[key];
  }

  return typeof current === 'string' ? current : undefined;
}

// 替换参数占位符 {{param}}
function interpolate(text: string, params?: Record<string, string | number>): string {
  if (!params) return text;

  return text.replace(/\{\{(\w+)\}\}/g, (_, key) => {
    return params[key]?.toString() ?? `{{${key}}}`;
  });
}

// 检测浏览器语言
function detectBrowserLocale(): Locale {
  if (typeof window === 'undefined') return defaultLocale;

  const browserLang = navigator.language.split('-')[0];
  if (locales.includes(browserLang as Locale)) {
    return browserLang as Locale;
  }
  return defaultLocale;
}

// 从 localStorage 获取语言
function getStoredLocale(): Locale | null {
  if (typeof window === 'undefined') return null;

  const stored = localStorage.getItem(LOCALE_STORAGE_KEY);
  if (stored && locales.includes(stored as Locale)) {
    return stored as Locale;
  }
  return null;
}

// Provider 组件
export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(defaultLocale);
  const [isHydrated, setIsHydrated] = useState(false);

  // 客户端 hydration 后初始化语言
  useEffect(() => {
    const stored = getStoredLocale();
    const detected = stored ?? detectBrowserLocale();
    setLocaleState(detected);
    setIsHydrated(true);
  }, []);

  // 更新 HTML lang 属性
  useEffect(() => {
    if (isHydrated) {
      document.documentElement.lang = localeHtmlLang[locale];
    }
  }, [locale, isHydrated]);

  // 设置语言并持久化
  const setLocale = useCallback((newLocale: Locale) => {
    setLocaleState(newLocale);
    localStorage.setItem(LOCALE_STORAGE_KEY, newLocale);
  }, []);

  // 翻译函数
  const t = useCallback((key: string, params?: Record<string, string | number>): string => {
    const value = getNestedValue(translations[locale], key);
    if (value === undefined) {
      console.warn(`[i18n] Missing translation: ${key} (${locale})`);
      return key;
    }
    return interpolate(value, params);
  }, [locale]);

  const value = useMemo(
    () => ({
      locale,
      setLocale,
      t,
      translations: translations[locale],
    }),
    [locale, setLocale, t]
  );

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

// Hook
export function useI18n() {
  const context = useContext(I18nContext);
  if (!context) {
    throw new Error('useI18n must be used within an I18nProvider');
  }
  return context;
}

// 简化的翻译 hook
export function useTranslation() {
  const { t, locale } = useI18n();

  // 翻译球队名称，如果没有翻译则返回原始名称
  const translateTeam = useCallback((teamName: string): string => {
    const key = `teams.${teamName}`;
    const translated = getNestedValue(translations[locale], key);
    return translated ?? teamName;
  }, [locale]);

  // 翻译联赛名称，如果没有翻译则返回原始名称
  const translateLeague = useCallback((leagueName: string): string => {
    const key = `leagues.${leagueName}`;
    const translated = getNestedValue(translations[locale], key);
    return translated ?? leagueName;
  }, [locale]);

  return { t, locale, translateTeam, translateLeague };
}
