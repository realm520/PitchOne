import { HTMLAttributes, forwardRef } from 'react';
import { cn } from '@pitchone/utils';

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: 'default' | 'success' | 'warning' | 'error' | 'info' | 'neon';
  size?: 'sm' | 'md' | 'lg';
  dot?: boolean;
}

const Badge = forwardRef<HTMLSpanElement, BadgeProps>(
  (
    {
      className,
      variant = 'default',
      size = 'md',
      dot = false,
      children,
      ...props
    },
    ref
  ) => {
    const baseStyles =
      'inline-flex items-center gap-1.5 font-medium rounded-full';

    const variants = {
      default: 'bg-gray-800 text-gray-300',
      success: 'bg-neon-green/20 text-neon-green border border-neon-green/30',
      warning: 'bg-yellow-500/20 text-yellow-500 border border-yellow-500/30',
      error: 'bg-red-500/20 text-red-500 border border-red-500/30',
      info: 'bg-neon-blue/20 text-neon-blue border border-neon-blue/30',
      neon: 'bg-gradient-to-r from-neon-blue/20 to-neon-purple/20 text-neon-blue border border-neon-blue/30',
    };

    const sizes = {
      sm: 'px-2 py-0.5 text-xs',
      md: 'px-3 py-1 text-sm',
      lg: 'px-4 py-1.5 text-base',
    };

    return (
      <span
        ref={ref}
        className={cn(baseStyles, variants[variant], sizes[size], className)}
        {...props}
      >
        {dot && (
          <span
            className={cn(
              'w-1.5 h-1.5 rounded-full',
              variant === 'success' && 'bg-neon-green',
              variant === 'warning' && 'bg-yellow-500',
              variant === 'error' && 'bg-red-500',
              variant === 'info' && 'bg-neon-blue',
              variant === 'neon' && 'bg-neon-purple',
              variant === 'default' && 'bg-gray-400'
            )}
          />
        )}
        {children}
      </span>
    );
  }
);

Badge.displayName = 'Badge';

export { Badge };
