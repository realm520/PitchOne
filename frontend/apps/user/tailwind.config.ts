import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
    "../../packages/ui/src/**/*.{js,ts,jsx,tsx,mdx}",
    "../../packages/i18n/src/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        // 强调色 - 白色（极简黑白主题）
        accent: {
          DEFAULT: '#ffffff',
          hover: '#e4e4e7',
          muted: 'rgba(255, 255, 255, 0.15)',
          light: '#fafafa',
        },
        // 深色背景系 - zinc 灰色
        dark: {
          bg: '#09090b',
          card: '#18181b',
          border: '#27272a',
          hover: '#3f3f46',
        },
        // 状态色 - 灰度系（不使用彩色）
        status: {
          success: '#ffffff',
          'success-bg': '#27272a',
          error: '#a1a1aa',
          'error-bg': '#27272a',
          warning: '#d4d4d8',
          'warning-bg': '#3f3f46',
          info: '#a1a1aa',
          'info-bg': '#27272a',
        },
      },
      boxShadow: {
        'card': '0 4px 6px -1px rgba(0, 0, 0, 0.3), 0 2px 4px -1px rgba(0, 0, 0, 0.2)',
        'card-hover': '0 10px 15px -3px rgba(0, 0, 0, 0.3), 0 4px 6px -2px rgba(0, 0, 0, 0.2)',
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'slide-up': 'slideUp 0.3s ease-out',
        'fade-in': 'fadeIn 0.5s ease-out',
      },
      keyframes: {
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
      },
      fontFamily: {
        mono: ['JetBrains Mono', 'monospace'],
      },
    },
  },
  plugins: [],
};
export default config;
