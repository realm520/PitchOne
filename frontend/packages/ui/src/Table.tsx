'use client';

import { HTMLAttributes, TdHTMLAttributes, ThHTMLAttributes, forwardRef } from 'react';
import { cn } from '@pitchone/utils';

// ============================================================================
// Table Container - 支持小屏幕左右滑动
// ============================================================================

export interface TableProps extends HTMLAttributes<HTMLDivElement> {
  /** 是否显示边框 */
  bordered?: boolean;
  /** 是否显示斑马纹 */
  striped?: boolean;
  /** 是否支持 hover 高亮 */
  hoverable?: boolean;
}

const Table = forwardRef<HTMLDivElement, TableProps>(
  ({ className, bordered = false, striped = false, hoverable = true, children, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('w-full overflow-x-auto', className)}
        {...props}
      >
        <table
          className={cn(
            'w-full min-w-[600px] text-sm text-left',
            bordered && 'border border-dark-border',
            '[&_tbody_tr]:border-b [&_tbody_tr]:border-dark-border',
            striped && '[&_tbody_tr:nth-child(even)]:bg-dark-card/50',
            hoverable && '[&_tbody_tr:hover_td]:bg-white/10 [&_tbody_tr:hover_td:first-child]:rounded-l-lg [&_tbody_tr:hover_td:last-child]:rounded-r-lg'
          )}
        >
          {children}
        </table>
      </div>
    );
  }
);

Table.displayName = 'Table';

// ============================================================================
// Table Head
// ============================================================================

export interface HeadProps extends HTMLAttributes<HTMLTableSectionElement> {}

const Head = forwardRef<HTMLTableSectionElement, HeadProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <thead
        ref={ref}
        className={cn('bg-dark-card/60 text-gray-400 uppercase text-xs', className)}
        {...props}
      >
        {children}
      </thead>
    );
  }
);

Head.displayName = 'Head';

// ============================================================================
// Table Body
// ============================================================================

export interface BodyProps extends HTMLAttributes<HTMLTableSectionElement> {}

const Body = forwardRef<HTMLTableSectionElement, BodyProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <tbody ref={ref} className={cn('', className)} {...props}>
        {children}
      </tbody>
    );
  }
);

Body.displayName = 'Body';

// ============================================================================
// Table Row
// ============================================================================

export interface RowProps extends HTMLAttributes<HTMLTableRowElement> {}

const Row = forwardRef<HTMLTableRowElement, RowProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <tr
        ref={ref}
        className={cn('transition-colors', className)}
        {...props}
      >
        {children}
      </tr>
    );
  }
);

Row.displayName = 'Row';

// ============================================================================
// Table Header Cell
// ============================================================================

export interface ThProps extends ThHTMLAttributes<HTMLTableCellElement> {
  /** 列宽度，如 "100px"、"20%"、"auto" */
  width?: string | number;
}

const Th = forwardRef<HTMLTableCellElement, ThProps>(
  ({ className, children, width, style, ...props }, ref) => {
    return (
      <th
        ref={ref}
        className={cn('px-4 py-3 font-medium whitespace-nowrap', className)}
        style={{ width, ...style }}
        {...props}
      >
        {children}
      </th>
    );
  }
);

Th.displayName = 'Th';

// ============================================================================
// Table Data Cell
// ============================================================================

export interface TdProps extends TdHTMLAttributes<HTMLTableCellElement> {
  /** 列宽度，如 "100px"、"20%"、"auto" */
  width?: string | number;
}

const Td = forwardRef<HTMLTableCellElement, TdProps>(
  ({ className, children, width, style, ...props }, ref) => {
    return (
      <td
        ref={ref}
        className={cn('px-4 py-3 text-white whitespace-nowrap', className)}
        style={{ width, ...style }}
        {...props}
      >
        {children}
      </td>
    );
  }
);

Td.displayName = 'Td';

// ============================================================================
// Exports
// ============================================================================

export { Table, Head, Body, Row, Th, Td };
