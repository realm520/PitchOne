'use client';

import { useState, useEffect } from 'react';
import {
  useAccount,
} from '@pitchone/web3';
import {
  Container,

} from '@pitchone/ui';
import UnLogin from './un-login';
import MyTickets from './MyTickets';


export function PortfolioClient() {
  const { isConnected } = useAccount();
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    setMounted(true);
  }, []);


  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="lg">
        {/* Header */}
        {!isConnected || !mounted ? (
          <UnLogin />
        ) : (
          <MyTickets />
        )}
      </Container>
    </div>
  );
}
