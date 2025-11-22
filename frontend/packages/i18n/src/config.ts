// 支持的语言列表
export const locales = ['zh', 'en', 'ja', 'ko'] as const;
export type Locale = (typeof locales)[number];

// 默认语言
export const defaultLocale: Locale = 'zh';

// 语言显示名称
export const localeNames: Record<Locale, string> = {
  zh: '中文',
  en: 'English',
  ja: '日本語',
  ko: '한국어',
};

// 语言对应的 HTML lang 属性值
export const localeHtmlLang: Record<Locale, string> = {
  zh: 'zh-CN',
  en: 'en',
  ja: 'ja',
  ko: 'ko',
};

// localStorage 存储的 key
export const LOCALE_STORAGE_KEY = 'pitchone-locale';
