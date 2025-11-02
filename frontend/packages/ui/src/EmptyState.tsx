import { ReactNode } from 'react';
import { motion } from 'framer-motion';
import { cn } from '@pitchone/utils';

export interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
  className?: string;
}

export function EmptyState({
  icon,
  title,
  description,
  action,
  className,
}: EmptyStateProps) {
  return (
    <motion.div
      className={cn(
        'flex flex-col items-center justify-center py-12 px-4 text-center',
        className
      )}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
    >
      {icon && (
        <motion.div
          className="mb-4 text-gray-600"
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ delay: 0.2, type: 'spring' }}
        >
          {icon}
        </motion.div>
      )}

      <h3 className="text-xl font-semibold text-gray-300 mb-2">{title}</h3>

      {description && (
        <p className="text-sm text-gray-500 mb-6 max-w-md">{description}</p>
      )}

      {action && <div>{action}</div>}
    </motion.div>
  );
}
