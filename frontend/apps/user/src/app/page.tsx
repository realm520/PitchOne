'use client';

import dynamic from 'next/dynamic';

const HomeClient = dynamic(
  () => import('./HomeClient').then((mod) => ({ default: mod.HomeClient })),
  {
    ssr: false,
    loading: () => (
      <main className="relative flex min-h-screen flex-col items-center justify-center p-8 md:p-24 overflow-hidden">
        <div className="text-center text-gray-400">加载中...</div>
      </main>
    ),
  }
);

export default function HomePage() {
  return <HomeClient />;
}
