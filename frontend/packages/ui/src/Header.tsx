'use client';

import { ReactNode } from 'react';
import { motion } from 'framer-motion';
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
    <motion.header
      className={cn(
        'w-full border-b border-dark-border bg-dark-bg/80 backdrop-blur-lg z-40',
        sticky && 'sticky top-0',
        className
      )}
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          {logo && (
            <div className="flex-shrink-0">
              {logo}
            </div>
          )}

          {/* Navigation */}
          {navigation && (
            <nav className="hidden md:flex items-center space-x-8">
              {navigation}
            </nav>
          )}

          {/* Actions (Wallet Connect, etc) */}
          {actions && (
            <div className="flex items-center gap-4">
              {actions}
            </div>
          )}
        </div>
      </div>
    </motion.header>
  );
}
