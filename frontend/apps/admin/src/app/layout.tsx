import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "./providers";
import { AdminHeader } from "@/components/AdminHeader";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "PitchOne Admin - 运营风控管理后台",
  description: "PitchOne 平台运营管理、风险控制、数据分析后台",
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
          <AdminHeader />
          {children}
        </Providers>
      </body>
    </html>
  );
}
