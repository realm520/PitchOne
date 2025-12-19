import type { Metadata } from "next";
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
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "PitchOne - 去中心化足球预测平台",
  description: "链上透明、非托管资产、自动化结算的足球预测平台",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN" suppressHydrationWarning>
      <body className={inter.className}>
        <Providers>
          <I18nProvider>
            <SidebarProvider>
              <ParlayProvider>
              <BetSlipProvider>
                {/* 推荐系统 - URL 参数检测和自动绑定 */}
                <ReferralBinder />

                <div className="flex flex-col min-h-screen">
                  <Header
                    logo={
                      <Link href="/" className="flex items-center gap-2">
                        <span className="text-2xl font-bold">
                          <span className="text-neon">Pitch</span>
                          <span className="text-neon-purple">One</span>
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
            position="top-right"
            reverseOrder={false}
            toastOptions={{
              style: {
                background: '#1a1a2e',
                color: '#fff',
                border: '1px solid #2a2a3e',
                borderRadius: '8px',
              },
            }}
          />
        </Providers>
      </body>
    </html>
  );
}
