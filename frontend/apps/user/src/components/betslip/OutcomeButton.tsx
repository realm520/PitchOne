'use client';

import { Trophy } from 'lucide-react';
import { LoadingSpinner } from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';

export interface OutcomeData {
  id: number;
  name: string;
  odds: string;
}

interface OutcomeButtonProps {
  outcome: OutcomeData;
  isSelected: boolean;
  isDisabled: boolean;
  isLoading?: boolean;
  isWinner?: boolean;
  onClick: () => void;
  variant?: 'card' | 'detail';
  showBorder?: boolean;
}

export function OutcomeButton({
  outcome,
  isSelected,
  isDisabled,
  isLoading = false,
  isWinner = false,
  onClick,
  variant = 'detail',
  showBorder = true,
}: OutcomeButtonProps) {
  const { t } = useTranslation();

  // Translate outcome name if it's an i18n key
  const displayName = outcome.name.startsWith('outcomes.')
    ? t(outcome.name, { id: outcome.id })
    : outcome.name;
  if (variant === 'card') {
    // Compact version for market cards in the list
    const cardStyles = isWinner
      ? 'bg-yellow-500/20 border border-yellow-500/50 text-yellow-400'
      : isSelected
        ? 'bg-white text-gray-900'
        : 'bg-white/10 text-gray-200 border border-white/10 hover:bg-white/15 hover:border-white/20';

    return (
      <button
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          if (!isDisabled && !isLoading) {
            onClick();
          }
        }}
        disabled={isDisabled}
        className={`
          flex items-center justify-between py-2 px-3 rounded-md transition-all
          ${cardStyles}
          ${isDisabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
        `}
      >
        {isLoading ? (
          <LoadingSpinner size="sm" />
        ) : (
          <>
            <span className="flex items-center gap-1 text-xs">
              {isWinner && <Trophy className="w-3 h-3" />}
              {displayName}
            </span>
            <span className="text-sm font-bold">{outcome.odds}</span>
          </>
        )}
      </button>
    );
  }

  // Full version for detail page (dark theme) - horizontal layout like card
  const detailStyles = isWinner
    ? 'bg-yellow-500/20 border border-yellow-500/50 text-yellow-400'
    : isSelected
      ? 'bg-white text-gray-900'
      : 'bg-white/10 text-gray-200 border border-white/10 hover:bg-white/15 hover:border-white/20';

  return (
    <button
      onClick={(e) => {
        e.preventDefault();
        e.stopPropagation();
        if (!isDisabled && !isLoading) {
          onClick();
        }
      }}
      disabled={isDisabled}
      className={`
        flex items-center justify-between py-3 px-4 rounded-lg transition-all
        ${detailStyles}
        ${isDisabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
      `}
    >
      {isLoading ? (
        <LoadingSpinner size="sm" />
      ) : (
        <>
          <span className={`flex items-center gap-1.5 text-sm font-medium ${isSelected ? 'text-gray-600' : isWinner ? 'text-yellow-400' : 'text-gray-300'}`}>
            {isWinner && <Trophy className="w-4 h-4" />}
            {displayName}
          </span>
          <span className={`text-lg font-bold ${isSelected ? 'text-gray-900' : isWinner ? 'text-yellow-400' : 'text-white'}`}>{outcome.odds}</span>
        </>
      )}
    </button>
  );
}
