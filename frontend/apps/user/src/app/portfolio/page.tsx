'use client';

import { useState, useEffect } from 'react';
import {
  useAccount,
} from '@pitchone/web3';
import {
  Container,
} from '@pitchone/ui';
import { AnimatePresence, motion } from 'framer-motion';
import UnConnected from './UnConnected';
import MyTickets from './MyTickets';

const pageVariants = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -20 },
};

const pageTransition = {
  duration: 0.3,
  ease: 'easeInOut',
};

export default function PortfolioPage() {
  const { isConnected, isConnecting } = useAccount();
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    setMounted(true);
  }, []);

  const showMyTickets = isConnected && mounted;

  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="lg">
        <AnimatePresence mode="wait">
          {!showMyTickets ? (
            <motion.div
              key="unconnected"
              variants={pageVariants}
              initial="initial"
              animate="animate"
              exit="exit"
              transition={pageTransition}
            >
              <UnConnected isConnecting={isConnecting} />
            </motion.div>
          ) : (
            <motion.div
              key="mytickets"
              variants={pageVariants}
              initial="initial"
              animate="animate"
              exit="exit"
              transition={pageTransition}
            >
              <MyTickets />
            </motion.div>
          )}
        </AnimatePresence>
      </Container>
    </div>
  );
}
