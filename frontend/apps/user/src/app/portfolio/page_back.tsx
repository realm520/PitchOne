// 'use client';

// import { Suspense } from 'react';
// import dynamic from 'next/dynamic';
// import { LoadingFallback } from '../../components/LoadingFallback';

// const PortfolioClient = dynamic(
//   () => import('./page').then((mod) => ({ default: mod.PortfolioClient })),
//   {
//     ssr: false,
//     loading: () => <LoadingFallback type="position" height="100vh" />,
//   }
// );

// export default function PortfolioPage() {
//   return (
//     <Suspense fallback={<LoadingFallback type="position" height="100vh" />}>
//       <PortfolioClient />
//     </Suspense>
//   );
// }
