'use client';

import { Ticket } from 'lucide-react';
import { useTranslation } from '@pitchone/i18n';

export function BetSlipEmpty() {
  const { t } = useTranslation();

  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      {/* 双票券图标 */}
      <div className="relative w-20 h-20 mb-6">
        {/* 后面的票券 */}
        <Ticket
          className="absolute top-0 left-1/2 -translate-x-1/2 w-16 h-16 text-zinc-600 -rotate-12"
          strokeWidth={1.5}
        />
        {/* 前面的票券 */}
        <Ticket
          className="absolute top-2 left-1/2 -translate-x-1/2 w-16 h-16 text-zinc-500 rotate-6"
          strokeWidth={1.5}
        />
      </div>

      {/* 文字 */}
      <p className="text-white font-semibold text-lg mb-2">
        {t('betslip.empty.title')}
      </p>
      <p className="text-zinc-500 text-sm max-w-[200px]">
        {t('betslip.empty.desc')}
      </p>
    </div>
  );
}
