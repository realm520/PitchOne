'use client';

import { Trophy } from 'lucide-react';
import { LoadingSpinner } from '@pitchone/ui';

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
              {outcome.name}
            </span>
            <span className="text-sm font-bold">{outcome.odds}</span>
          </>
        )}
      </button>
    );
  }

  // Full version for detail page
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
        py-4 px-2 text-center transition-all
        ${showBorder ? 'border-r border-gray-200 last:border-r-0' : ''}
        ${isSelected
          ? 'bg-gray-100 ring-2 ring-inset ring-blue-500'
          : 'bg-gray-50 hover:bg-gray-100'
        }
        ${isDisabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
      `}
    >
      {isLoading ? (
        <div className="flex justify-center">
          <LoadingSpinner size="sm" />
        </div>
      ) : (
        <>
          <p className="text-gray-600 text-sm font-medium mb-1">{outcome.name}</p>
          <p className="text-gray-900 text-xl font-bold">{outcome.odds}</p>
        </>
      )}
    </button>
  );
}
