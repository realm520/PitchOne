import { ReactNode } from 'react';

// 按钮变体样式
const BTN_VARIANTS = {
  primary: 'bg-blue-600 text-white hover:bg-blue-700',
  secondary: 'bg-amber-500 text-white hover:bg-amber-600',
  outline: 'border border-gray-300 text-gray-700 bg-white hover:bg-gray-50',
  danger: 'bg-red-600 text-white hover:bg-red-700',
  warning: 'bg-yellow-500 text-white hover:bg-yellow-600',
} as const;

export function AdminButton({
  children, variant = 'primary', disabled, onClick, className = '',
}: {
  children: ReactNode;
  variant?: keyof typeof BTN_VARIANTS;
  disabled?: boolean;
  onClick?: () => void;
  className?: string;
}) {
  return (
    <button
      className={`inline-flex items-center justify-center px-4 py-2 text-sm font-medium rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${BTN_VARIANTS[variant]} ${className}`}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  );
}

export function AdminCard({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`bg-white border border-gray-200 rounded-lg shadow-sm ${className}`}>
      {children}
    </div>
  );
}

export function InfoCard({ title, value, subtitle }: { title: string; value: string; subtitle?: string }) {
  return (
    <AdminCard className="p-6">
      <h3 className="text-sm font-medium text-gray-500 mb-2">{title}</h3>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
      {subtitle && <p className="text-xs text-gray-500 mt-1">{subtitle}</p>}
    </AdminCard>
  );
}

// 通用分页组件
export function Pagination({
  current, total, onChange,
}: {
  current: number;
  total: number;
  onChange: (page: number) => void;
}) {
  if (total <= 1) return null;

  const pageNums = Array.from({ length: Math.min(5, total) }, (_, i) => {
    if (total <= 5) return i + 1;
    if (current <= 3) return i + 1;
    if (current >= total - 2) return total - 4 + i;
    return current - 2 + i;
  });

  const btnClass = 'px-3 py-2 border border-gray-300 rounded-lg bg-white text-gray-900 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed';

  return (
    <div className="flex items-center gap-2">
      <button onClick={() => onChange(1)} disabled={current === 1} className={btnClass}>首页</button>
      <button onClick={() => onChange(current - 1)} disabled={current === 1} className={btnClass}>上一页</button>
      {pageNums.map(n => (
        <button
          key={n}
          onClick={() => onChange(n)}
          className={`w-10 h-10 flex items-center justify-center border rounded-lg text-sm font-medium ${
            current === n ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-gray-900 border-gray-300 hover:bg-gray-50'
          }`}
        >
          {n}
        </button>
      ))}
      <button onClick={() => onChange(current + 1)} disabled={current === total} className={btnClass}>下一页</button>
      <button onClick={() => onChange(total)} disabled={current === total} className={btnClass}>末页</button>
    </div>
  );
}

// 确认对话框
export function ConfirmDialog({
  open, title, message, warning, warningType = 'warning',
  confirmText, confirmVariant = 'primary', loading, onConfirm, onCancel,
}: {
  open: boolean;
  title: string;
  message: string;
  warning?: string;
  warningType?: 'warning' | 'danger' | 'info';
  confirmText: string;
  confirmVariant?: keyof typeof BTN_VARIANTS;
  loading?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  if (!open) return null;

  const warningColors = {
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-800',
    danger: 'bg-red-50 border-red-200 text-red-800',
    info: 'bg-blue-50 border-blue-200 text-blue-800',
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="max-w-md w-full mx-4 p-6 bg-white rounded-lg shadow-xl">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">{title}</h3>
        <p className="text-sm text-gray-600 mb-6">{message}</p>
        {warning && (
          <div className={`border rounded-lg p-4 mb-6 ${warningColors[warningType]}`}>
            <p className="text-sm">{warning}</p>
          </div>
        )}
        <div className="flex items-center gap-3">
          <AdminButton variant="outline" onClick={onCancel} disabled={loading} className="flex-1">
            取消
          </AdminButton>
          <AdminButton variant={confirmVariant} onClick={onConfirm} disabled={loading} className="flex-1">
            {loading ? '处理中...' : confirmText}
          </AdminButton>
        </div>
      </div>
    </div>
  );
}

// 交易状态提示
export function TxStatus({
  pending, confirming, success, error, hash, actionName,
}: {
  pending?: boolean;
  confirming?: boolean;
  success?: boolean;
  error?: Error | null;
  hash?: string;
  actionName: string;
}) {
  if (!pending && !confirming && !success && !error) return null;

  return (
    <div className="space-y-4">
      {pending && (
        <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-sm text-yellow-800">等待钱包确认{actionName}交易...</p>
        </div>
      )}
      {confirming && (
        <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg flex items-center gap-3">
          <div className="animate-spin h-4 w-4 border-2 border-blue-600 border-t-transparent rounded-full" />
          <div>
            <p className="text-sm font-medium text-blue-800">{actionName}交易确认中...</p>
            {hash && <p className="text-xs text-blue-600">交易: {hash.slice(0, 10)}...</p>}
          </div>
        </div>
      )}
      {success && (
        <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
          <p className="text-sm font-medium text-green-800">{actionName}成功！页面将在 3 秒后刷新...</p>
        </div>
      )}
      {error && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-sm font-medium text-red-800">{actionName}失败</p>
          <p className="text-xs text-red-600 mt-1">{error.message}</p>
        </div>
      )}
    </div>
  );
}

// 空状态
export function EmptyState({ icon, title, message }: { icon?: ReactNode; title: string; message: string }) {
  return (
    <div className="p-12 text-center">
      <div className="text-gray-400 mb-4">
        {icon || (
          <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
        )}
      </div>
      <h3 className="text-lg font-medium text-gray-900 mb-2">{title}</h3>
      <p className="text-sm text-gray-500">{message}</p>
    </div>
  );
}
