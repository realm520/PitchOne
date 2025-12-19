'use client';

import { LoadingSpinner } from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';

type LoadingType = 'chart' | 'activity' | 'market' | 'marketDetail' | 'position';

interface LoadingFallbackProps {
  type: LoadingType;
  height?: string;
  size?: 'sm' | 'md' | 'lg';
}

/**
 * Internationalized loading fallback component
 * Used for Suspense boundaries and lazy-loaded components
 */
export function LoadingFallback({ type, height = '300px', size = 'lg' }: LoadingFallbackProps) {
  const { t } = useTranslation();

  return (
    <div
      className="flex items-center justify-center"
      style={{ height }}
    >
      <LoadingSpinner size={size} text={t(`loading.${type}`)} />
    </div>
  );
}
