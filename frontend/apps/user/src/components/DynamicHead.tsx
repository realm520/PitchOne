'use client';

import { useEffect } from 'react';
import { useTranslation } from '@pitchone/i18n';

// Default title fallback (matches static metadata in layout.tsx)
const DEFAULT_TITLE = 'PitchOne - Decentralized Football Prediction Platform';

/**
 * Dynamic head component for client-side title/lang updates
 * Updates document title and html lang attribute based on current locale
 */
export function DynamicHead() {
  const { t, locale } = useTranslation();

  useEffect(() => {
    // Update document title (with fallback if translation returns key)
    const translatedTitle = t('meta.title');
    // Only update if translation succeeded (not returning the key itself)
    if (translatedTitle && translatedTitle !== 'meta.title') {
      document.title = translatedTitle;
    } else {
      document.title = DEFAULT_TITLE;
    }

    // Update html lang attribute
    const htmlLang = locale === 'zh' ? 'zh-CN' : locale;
    document.documentElement.lang = htmlLang;
  }, [t, locale]);

  return null;
}
