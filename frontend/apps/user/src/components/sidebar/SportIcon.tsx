'use client';

interface SportIconProps {
  type: string;
  className?: string;
}

export function SportIcon({ type, className = 'w-5 h-5' }: SportIconProps) {
  switch (type) {
    case 'football':
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
          <path d="M12 2a10 10 0 0 0 0 20" />
          <path d="M2 12h20" />
          <path d="M12 2c2.5 2.5 4 6 4 10s-1.5 7.5-4 10" />
          <path d="M12 2c-2.5 2.5-4 6-4 10s1.5 7.5 4 10" />
        </svg>
      );
    case 'basketball':
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
          <path d="M12 2v20" />
          <path d="M2 12h20" />
          <path d="M4.93 4.93c4.08 4.08 4.08 10.06 0 14.14" />
          <path d="M19.07 4.93c-4.08 4.08-4.08 10.06 0 14.14" />
        </svg>
      );
    case 'tennis':
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
          <path d="M5 5c5 5 9 5 14 0" />
          <path d="M5 19c5-5 9-5 14 0" />
        </svg>
      );
    case 'esports':
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect x="2" y="6" width="20" height="12" rx="2" />
          <path d="M6 12h4" />
          <path d="M8 10v4" />
          <circle cx="17" cy="10" r="1" fill="currentColor" />
          <circle cx="15" cy="12" r="1" fill="currentColor" />
          <circle cx="17" cy="14" r="1" fill="currentColor" />
        </svg>
      );
    default:
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
        </svg>
      );
  }
}
