'use client';

import NextTopLoader from 'nextjs-toploader';

export function RouteProgressBar() {
  return (
    <NextTopLoader
      color="#ffffff"
      height={3}
      showSpinner={false}
      shadow="0 0 10px #ffffff, 0 0 5px #ffffff"
    />
  );
}
