import { HTMLAttributes, forwardRef } from 'react';
import { cn } from '@pitchone/utils';

export interface ContainerProps extends HTMLAttributes<HTMLDivElement> {
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full';
  centerContent?: boolean;
}

const Container = forwardRef<HTMLDivElement, ContainerProps>(
  (
    {
      className,
      size = 'lg',
      centerContent = false,
      children,
      ...props
    },
    ref
  ) => {
    const sizes = {
      sm: 'max-w-3xl',
      md: 'max-w-5xl',
      lg: 'max-w-7xl',
      xl: 'max-w-[1536px]',
      full: 'max-w-full',
    };

    return (
      <div
        ref={ref}
        className={cn(
          'w-full mx-auto px-4 sm:px-6 lg:px-8',
          sizes[size],
          centerContent && 'flex flex-col items-center',
          className
        )}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Container.displayName = 'Container';

export { Container };
