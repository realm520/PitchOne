'use client';

import { HTMLAttributes, forwardRef } from 'react';
import { cn } from '@pitchone/utils';
import { ChevronLeft, ChevronRight } from 'lucide-react';

export interface PaginationProps extends HTMLAttributes<HTMLDivElement> {
  /** 当前页码（从1开始） */
  currentPage: number;
  /** 总页数 */
  totalPages: number;
  /** 页码变化回调 */
  onPageChange: (page: number) => void;
  /** 显示的页码按钮数量（默认5） */
  visiblePages?: number;
  /** 是否显示首页/末页按钮 */
  showFirstLast?: boolean;
  /** 是否禁用 */
  disabled?: boolean;
}

const Pagination = forwardRef<HTMLDivElement, PaginationProps>(
  (
    {
      className,
      currentPage,
      totalPages,
      onPageChange,
      visiblePages = 5,
      showFirstLast = true,
      disabled = false,
      ...props
    },
    ref
  ) => {
    // 计算要显示的页码范围
    const getPageNumbers = (): (number | 'ellipsis')[] => {
      if (totalPages <= visiblePages) {
        return Array.from({ length: totalPages }, (_, i) => i + 1);
      }

      const pages: (number | 'ellipsis')[] = [];
      const half = Math.floor(visiblePages / 2);

      let start = Math.max(1, currentPage - half);
      let end = Math.min(totalPages, currentPage + half);

      // 调整范围确保显示足够的页码
      if (currentPage - half < 1) {
        end = Math.min(totalPages, visiblePages);
      }
      if (currentPage + half > totalPages) {
        start = Math.max(1, totalPages - visiblePages + 1);
      }

      // 添加首页和省略号
      if (start > 1) {
        pages.push(1);
        if (start > 2) {
          pages.push('ellipsis');
        }
      }

      // 添加中间页码
      for (let i = start; i <= end; i++) {
        if (i !== 1 && i !== totalPages) {
          pages.push(i);
        } else if (start === 1 || end === totalPages) {
          pages.push(i);
        }
      }

      // 添加省略号和末页
      if (end < totalPages) {
        if (end < totalPages - 1) {
          pages.push('ellipsis');
        }
        pages.push(totalPages);
      }

      return pages;
    };

    const handlePageChange = (page: number) => {
      if (disabled || page < 1 || page > totalPages || page === currentPage) {
        return;
      }
      onPageChange(page);
    };

    const buttonBaseClass =
      'inline-flex items-center justify-center min-w-[36px] h-9 px-3 text-sm font-medium rounded-lg transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed';

    const pageButtonClass = (isActive: boolean) =>
      cn(
        buttonBaseClass,
        isActive
          ? 'bg-white text-zinc-900'
          : 'bg-dark-card text-gray-300 border border-dark-border hover:border-zinc-500 hover:bg-dark-hover hover:text-white'
      );

    const navButtonClass = cn(
      buttonBaseClass,
      'bg-dark-card text-gray-300 border border-dark-border hover:border-zinc-500 hover:bg-dark-hover hover:text-white'
    );

    if (totalPages <= 1) {
      return null;
    }

    const pageNumbers = getPageNumbers();

    return (
      <div
        ref={ref}
        className={cn('flex items-center justify-center gap-1', className)}
        {...props}
      >
        {/* 上一页 */}
        <button
          className={navButtonClass}
          onClick={() => handlePageChange(currentPage - 1)}
          disabled={disabled || currentPage === 1}
          aria-label="Previous page"
        >
          <ChevronLeft className="w-4 h-4" />
        </button>

        {/* 页码按钮 */}
        {pageNumbers.map((page, index) =>
          page === 'ellipsis' ? (
            <span
              key={`ellipsis-${index}`}
              className="inline-flex items-center justify-center min-w-[36px] h-9 text-gray-500"
            >
              ...
            </span>
          ) : (
            <button
              key={page}
              className={pageButtonClass(page === currentPage)}
              onClick={() => handlePageChange(page)}
              disabled={disabled}
              aria-label={`Page ${page}`}
              aria-current={page === currentPage ? 'page' : undefined}
            >
              {page}
            </button>
          )
        )}

        {/* 下一页 */}
        <button
          className={navButtonClass}
          onClick={() => handlePageChange(currentPage + 1)}
          disabled={disabled || currentPage === totalPages}
          aria-label="Next page"
        >
          <ChevronRight className="w-4 h-4" />
        </button>
      </div>
    );
  }
);

Pagination.displayName = 'Pagination';

export { Pagination };
