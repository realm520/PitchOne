import type { Metadata } from "next";
import { Inter } from "next/font/google";
import Link from "next/link";
import { Providers, ConnectButton } from "@pitchone/web3";
import { Header, Footer } from "@pitchone/ui";
import { Toaster } from 'react-hot-toast';
import { ParlayProvider } from "../lib/parlay-store";
import { ParlayCart } from "../components/parlay";
import { ReferralBinder } from "../components/referral";
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
    <html lang="zh-CN">
      <body className={inter.className}>
        <Providers>
          <ParlayProvider>
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
              navigation={
                <div className="flex items-center gap-6">
                  <Link href="/markets" className="text-gray-300 hover:text-neon-blue transition-colors">
                    市场
                  </Link>
                  <Link href="/portfolio" className="text-gray-300 hover:text-neon-purple transition-colors">
                    我的
                  </Link>
{/* 暂时隐藏串关功能
                  <Link href="/parlay" className="text-gray-300 hover:text-neon-green transition-colors">
                    串关
                  </Link>
*/}
                  <Link href="/referral" className="text-gray-300 hover:text-orange-400 transition-colors">
                    推荐
                  </Link>
                </div>
              }
              actions={<ConnectButton />}
            />
              <main className="flex-1">{children}</main>
              <Footer />
              <ParlayCart />
            </div>
          </ParlayProvider>
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
