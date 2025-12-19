'use client';

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
  onClick: () => void;
  variant?: 'card' | 'detail';
  showBorder?: boolean;
}

export function OutcomeButton({
  outcome,
  isSelected,
  isDisabled,
  isLoading = false,
  onClick,
  variant = 'detail',
  showBorder = true,
}: OutcomeButtonProps) {
  if (variant === 'card') {
    // Compact version for market cards in the list
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
          flex flex-col items-center justify-center py-2 px-3 rounded-md transition-all min-w-[60px]
          ${isSelected
            ? 'bg-blue-500 text-white ring-2 ring-blue-300'
            : 'bg-gray-100 hover:bg-gray-200 text-gray-900'
          }
          ${isDisabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
        `}
      >
        {isLoading ? (
          <LoadingSpinner size="sm" />
        ) : (
          <>
            <span className="text-xs text-opacity-80 mb-0.5">
              {isSelected ? outcome.name : outcome.name.slice(0, 4)}
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
