import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { Providers } from "@pitchone/web3";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "PitchOne - 去中心化足球博彩平台",
  description: "链上透明、非托管资产、自动化结算的足球博彩平台",
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
          {children}
        </Providers>
      </body>
    </html>
  );
}
