'use client';

import { ReactNode } from 'react';
import { cn } from '@pitchone/utils';

export interface HeaderProps {
  logo?: ReactNode;
  navigation?: ReactNode;
  actions?: ReactNode;
  className?: string;
  sticky?: boolean;
}

export function Header({
  logo,
  navigation,
  actions,
  className,
  sticky = true,
}: HeaderProps) {
  return (
    <header
      className={cn(
        'w-full border-b border-dark-border bg-dark-bg/80 backdrop-blur-lg z-50',
        sticky && 'sticky top-0',
        className
      )}
    >
      <div className="w-full px-4">
        <div className="flex items-center justify-between h-16">
          {/* Left: Logo + Navigation */}
          <div className="flex items-center gap-10">
            {logo && (
              <div className="flex-shrink-0">
                {logo}
              </div>
            )}
            {navigation && (
              <nav className="hidden md:flex items-center">
                {navigation}
              </nav>
            )}
          </div>

          {/* Right: Actions */}
          {actions && (
            <div className="flex items-center gap-3">
              {actions}
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
