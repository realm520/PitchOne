'use client';

import { Card } from '@pitchone/ui';

export function BetSlipEmpty() {
  return (
    <Card className="bg-white shadow-lg border border-gray-200" padding="lg">
      <h3 className="text-lg font-bold text-gray-900 mb-4">Bet Slip</h3>

      <div className="flex flex-col items-center justify-center py-8 text-center">
        <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-4">
          <svg
            className="w-8 h-8 text-gray-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M12 6v6m0 0v6m0-6h6m-6 0H6"
            />
          </svg>
        </div>
        <p className="text-gray-500 text-sm mb-2">No selection yet</p>
        <p className="text-gray-400 text-xs max-w-[200px]">
          Click on an outcome to add it to your bet slip
        </p>
      </div>
    </Card>
  );
}
