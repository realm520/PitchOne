import { ReactNode } from 'react';
import { motion } from 'framer-motion';
import { cn } from '@pitchone/utils';
import { Button } from './Button';

export interface ErrorStateProps {
  title?: string;
  message: string;
  onRetry?: () => void;
  retryText?: string;
  icon?: ReactNode;
  className?: string;
}

export function ErrorState({
  title,
  message,
  onRetry,
  retryText,
  icon,
  className,
}: ErrorStateProps) {
  const defaultIcon = (
    <svg
      className="w-16 h-16"
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
      />
    </svg>
  );

  return (
    <motion.div
      className={cn(
        'flex flex-col items-center justify-center py-12 px-4 text-center',
        className
      )}
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.3 }}
    >
      <motion.div
        className="mb-4 text-red-500"
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.1, type: 'spring', stiffness: 200 }}
      >
        {icon || defaultIcon}
      </motion.div>

      <h3 className="text-xl font-semibold text-gray-200 mb-2">{title}</h3>

      <p className="text-sm text-gray-400 mb-6 max-w-md">{message}</p>

      {onRetry && (
        <Button variant="primary" onClick={onRetry}>
          {retryText}
        </Button>
      )}
    </motion.div>
  );
}
