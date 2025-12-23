import type { Metadata } from "next";
import { Suspense } from "react";
import { Inter } from "next/font/google";
import Link from "next/link";
import { Providers } from "@pitchone/web3";
import { I18nProvider } from "@pitchone/i18n";
import { Header } from "@pitchone/ui";
import { Toaster } from 'react-hot-toast';
import { ParlayProvider } from "../lib/parlay-store";
import { BetSlipProvider } from "../lib/betslip-store";
import { SidebarProvider } from "../lib/sidebar-store";
import { ParlayCart } from "../components/parlay";
import { ReferralBinder } from "../components/referral";
import { Navigation, HeaderActions } from "../components/Navigation";
import { AppFooter } from "../components/AppFooter";
import { DynamicHead } from "../components/DynamicHead";
import { RouteProgressBar } from "../components/RouteProgressBar";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "PitchOne - Decentralized Football Prediction Platform",
  description: "On-chain transparency, non-custodial assets, automated settlement football prediction platform",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <RouteProgressBar />
        <Providers>
          <I18nProvider>
            <DynamicHead />
            <SidebarProvider>
              <ParlayProvider>
              <BetSlipProvider>
                <Suspense fallback={null}>
                  <ReferralBinder />
                </Suspense>

                <div className="flex flex-col min-h-screen">
                  <Header
                    logo={
                      <Link href="/" className="flex items-center gap-2">
                        <span className="text-2xl font-bold">
                          <span className="text-accent">Pitch</span>
                          <span className="text-white">One</span>
                        </span>
                        <span className="text-xl">⚽</span>
                      </Link>
                    }
                    navigation={<Navigation />}
                    actions={<HeaderActions />}
                  />
                  <main className="flex-1 overflow-auto">{children}</main>
                  <AppFooter />
                  <ParlayCart />
                </div>
              </BetSlipProvider>
              </ParlayProvider>
            </SidebarProvider>
          </I18nProvider>
          <Toaster
            position="top-center"
            reverseOrder={false}
            toastOptions={{
              style: {
                background: '#18181b',
                color: '#fff',
                border: '1px solid #27272a',
                borderRadius: '8px',
                fontSize: '14px',
                padding: '12px 16px',
              },
            }}
          />
        </Providers>
      </body>
    </html>
  );
}
