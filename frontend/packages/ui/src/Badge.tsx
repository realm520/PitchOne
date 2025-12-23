import { HTMLAttributes, forwardRef } from 'react';
import { cn } from '@pitchone/utils';

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: 'default' | 'success' | 'warning' | 'error' | 'info' | 'neon' | 'primary';
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
      default: 'bg-zinc-800 text-zinc-300',
      success: 'bg-zinc-800 text-white border border-zinc-600',
      warning: 'bg-zinc-700 text-zinc-300 border border-zinc-500',
      error: 'bg-zinc-800 text-zinc-400 border border-dashed border-zinc-600',
      info: 'bg-zinc-700 text-zinc-300 border border-zinc-600',
      neon: 'bg-zinc-800 text-white border border-zinc-500',
      primary: 'bg-white/10 text-white border border-white/20',
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
              variant === 'success' && 'bg-white',
              variant === 'warning' && 'bg-zinc-400',
              variant === 'error' && 'bg-zinc-500',
              variant === 'info' && 'bg-zinc-400',
              variant === 'neon' && 'bg-white',
              variant === 'primary' && 'bg-white',
              variant === 'default' && 'bg-zinc-400'
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
