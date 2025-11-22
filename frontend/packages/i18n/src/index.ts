// 配置导出
export {
  locales,
  defaultLocale,
  localeNames,
  localeHtmlLang,
  LOCALE_STORAGE_KEY,
  type Locale,
} from './config';

// Provider 和 hooks 导出
export { I18nProvider, useI18n, useTranslation } from './provider';

// 组件导出
export { LanguageSwitcher } from './components/LanguageSwitcher';

// 翻译文件类型导出（用于类型推断）
export type { default as TranslationsType } from './locales/zh.json';
