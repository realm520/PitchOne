import { HTMLAttributes, forwardRef } from 'react';
import { motion } from 'framer-motion';
import { cn } from '@pitchone/utils';

// 排除与 framer-motion 冲突的属性
type ExcludedProps = 'onDrag' | 'onDragStart' | 'onDragEnd' | 'onAnimationStart' | 'onAnimationEnd';

export interface CardProps extends Omit<HTMLAttributes<HTMLDivElement>, ExcludedProps> {
  variant?: 'default' | 'neon' | 'glass';
  hoverable?: boolean;
  padding?: 'none' | 'sm' | 'md' | 'lg';
}

const Card = forwardRef<HTMLDivElement, CardProps>(
  (
    {
      className,
      variant = 'default',
      hoverable = false,
      padding = 'md',
      children,
      ...props
    },
    ref
  ) => {
    const baseStyles = 'rounded-xl transition-all duration-300';

    const variants = {
      default:
        'bg-dark-card border border-dark-border',
      neon: 'bg-dark-card border border-dark-border hover:border-white/30',
      glass:
        'bg-glass backdrop-blur-lg border border-dark-border/50',
    };

    const paddings = {
      none: '',
      sm: 'p-4',
      md: 'p-6',
      lg: 'p-8',
    };

    const hoverStyles = hoverable
      ? 'cursor-pointer hover:scale-[1.02] hover:shadow-card'
      : '';

    return (
      <motion.div
        ref={ref}
        className={cn(
          baseStyles,
          variants[variant],
          paddings[padding],
          hoverStyles,
          className
        )}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        {...props}
      >
        {children}
      </motion.div>
    );
  }
);

Card.displayName = 'Card';

export { Card };
