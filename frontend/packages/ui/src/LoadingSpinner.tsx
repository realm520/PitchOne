import { HTMLAttributes } from 'react';
import { motion } from 'framer-motion';
import { cn } from '@pitchone/utils';

export interface LoadingSpinnerProps extends HTMLAttributes<HTMLDivElement> {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  variant?: 'primary' | 'neon';
  text?: string;
}

export function LoadingSpinner({
  size = 'md',
  variant = 'neon',
  text,
  className,
  ...props
}: LoadingSpinnerProps) {
  const sizes = {
    sm: 'w-4 h-4',
    md: 'w-8 h-8',
    lg: 'w-12 h-12',
    xl: 'w-16 h-16',
  };

  const variants = {
    primary: 'border-gray-600 border-t-gray-300',
    neon: 'border-zinc-700 border-t-white',
  };

  return (
    <div
      className={cn('flex flex-col items-center justify-center gap-3', className)}
      {...props}
    >
      <motion.div
        className={cn(
          'rounded-full border-2',
          sizes[size],
          variants[variant]
        )}
        animate={{ rotate: 360 }}
        transition={{
          duration: 1,
          repeat: Infinity,
          ease: 'linear',
        }}
      />
      {text && (
        <p className="text-sm text-gray-400 animate-pulse">{text}</p>
      )}
    </div>
  );
}
