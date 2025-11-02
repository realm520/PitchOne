import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
    "../../packages/ui/src/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        // Web3 霓虹色系
        neon: {
          blue: '#00D4FF',
          purple: '#A855F7',
          green: '#10B981',
          pink: '#EC4899',
          cyan: '#06B6D4',
          yellow: '#FBBF24',
        },
        // 深色背景系
        dark: {
          bg: '#0a0a0a',
          card: '#1a1a1a',
          border: '#2a2a2a',
          hover: '#252525',
        },
      },
      backgroundImage: {
        'gradient-neon': 'linear-gradient(135deg, #00D4FF 0%, #A855F7 100%)',
        'gradient-card': 'linear-gradient(145deg, #1a1a1a 0%, #0f0f0f 100%)',
      },
      boxShadow: {
        'neon-sm': '0 0 10px rgba(0, 212, 255, 0.3)',
        'neon': '0 0 20px rgba(0, 212, 255, 0.5)',
        'neon-lg': '0 0 30px rgba(0, 212, 255, 0.7)',
        'purple-glow': '0 0 20px rgba(168, 85, 247, 0.5)',
        'card': '0 4px 6px -1px rgba(0, 0, 0, 0.3), 0 2px 4px -1px rgba(0, 0, 0, 0.2)',
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'glow': 'glow 2s ease-in-out infinite alternate',
        'slide-up': 'slideUp 0.3s ease-out',
        'fade-in': 'fadeIn 0.5s ease-out',
      },
      keyframes: {
        glow: {
          '0%': { boxShadow: '0 0 10px rgba(0, 212, 255, 0.3)' },
          '100%': { boxShadow: '0 0 20px rgba(0, 212, 255, 0.8)' },
        },
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
