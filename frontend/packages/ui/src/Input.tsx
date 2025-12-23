import { InputHTMLAttributes, forwardRef, ReactNode } from 'react';
import { cn } from '@pitchone/utils';

// 排除原生 input 的 prefix 属性，以便自定义为 ReactNode
export interface InputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'prefix'> {
  label?: string;
  error?: string;
  prefix?: ReactNode;
  suffix?: ReactNode;
  fullWidth?: boolean;
}

const Input = forwardRef<HTMLInputElement, InputProps>(
  (
    {
      className,
      label,
      error,
      prefix,
      suffix,
      fullWidth = false,
      disabled,
      ...props
    },
    ref
  ) => {
    const baseStyles =
      'bg-dark-card border border-dark-border rounded-lg px-4 py-3 text-gray-200 placeholder:text-gray-500 transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-white/20 focus:border-white/40 disabled:opacity-50 disabled:cursor-not-allowed';

    const errorStyles = error
      ? 'border-dashed border-zinc-500 focus:ring-zinc-500/30 focus:border-zinc-400'
      : '';

    const widthClass = fullWidth ? 'w-full' : '';

    return (
      <div className={cn('flex flex-col gap-1.5', widthClass)}>
        {label && (
          <label className="text-sm font-medium text-gray-300">{label}</label>
        )}

        <div className="relative">
          {prefix && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">
              {prefix}
            </div>
          )}

          <input
            ref={ref}
            className={cn(
              baseStyles,
              errorStyles,
              prefix && 'pl-10',
              suffix && 'pr-10',
              className
            )}
            disabled={disabled}
            {...props}
          />

          {suffix && (
            <div className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500">
              {suffix}
            </div>
          )}
        </div>

        {error && <p className="text-sm text-zinc-400">{error}</p>}
      </div>
    );
  }
);

Input.displayName = 'Input';

export { Input };
