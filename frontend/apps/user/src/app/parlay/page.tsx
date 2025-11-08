import { Metadata } from 'next';
import { ParlayPageClient } from './ParlayPageClient';

export const metadata: Metadata = {
  title: '串关 | PitchOne',
  description: '创建和管理你的串关投注',
};

export default function ParlayPage() {
  return <ParlayPageClient />;
}
