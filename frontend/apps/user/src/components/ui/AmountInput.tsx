"use client";

import { useCallback } from "react";

interface AmountInputProps {
  value: string;
  onChange: (value: string) => void;
  min?: number;
  max?: number;
  placeholder?: string;
  className?: string;
  suffix?: string;
}

/**
 * 金额输入组件
 * - 只允许输入数字和小数点
 * - 最多2位小数
 * - 支持最小值和最大值限制
 */
export function AmountInput({
  value,
  onChange,
  min = 1,
  max = 100000,
  placeholder = "",
  className = "",
  suffix,
}: AmountInputProps) {
  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      let input = e.target.value;

      // 允许空值
      if (input === "") {
        onChange("");
        return;
      }

      // 正则：只允许数字和小数点，最多2位小数
      const regex = /^\d*\.?\d{0,2}$/;
      if (!regex.test(input)) {
        return;
      }

      // 去掉前导零（但保留 "0." 的情况）
      if (input.length > 1 && input.startsWith("0") && input[1] !== ".") {
        input = input.replace(/^0+/, "") || "0";
      }

      // 阻止超过最大值的输入
      const num = parseFloat(input);
      if (!isNaN(num) && num > max) {
        return;
      }

      onChange(input);
    },
    [onChange, max]
  );

  // 失焦时格式化（可选：补齐小数位）
  const handleBlur = useCallback(() => {
    if (value === "" || value === ".") {
      return;
    }

    const num = parseFloat(value);
    if (isNaN(num)) {
      onChange("");
      return;
    }

    // 如果小于最小值，设置为最小值
    if (num < min) {
      onChange(min.toFixed(2));
    }
  }, [value, onChange, min]);

  return (
    <div className="flex items-center border border-zinc-700 rounded bg-zinc-900 focus-within:border-white/40 overflow-hidden">
      <input
        type="text"
        inputMode="decimal"
        placeholder={placeholder}
        value={value}
        onChange={handleChange}
        onBlur={handleBlur}
        className={`flex-1 min-w-0 px-2 py-1.5 bg-transparent text-white placeholder-zinc-500 focus:outline-none text-sm ${className}`}
      />
      {suffix && (
        <span className="flex-shrink-0 px-2 py-1.5 text-xs text-zinc-400">
          {suffix}
        </span>
      )}
    </div>
  );
}
