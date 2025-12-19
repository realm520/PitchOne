'use client';

import { Icon, Gamepad2 } from 'lucide-react';
import { soccerBall, basketball, tennisBall } from '@lucide/lab';

interface SportIconProps {
  type: string;
  className?: string;
}

export function SportIcon({ type, className = 'w-5 h-5' }: SportIconProps) {
  switch (type) {
    case 'football':
      return <Icon iconNode={soccerBall} className={className} />;
    case 'basketball':
      return <Icon iconNode={basketball} className={className} />;
    case 'tennis':
      return <Icon iconNode={tennisBall} className={className} />;
    case 'esports':
      return <Gamepad2 className={className} />;
    default:
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10" />
        </svg>
      );
  }
}
