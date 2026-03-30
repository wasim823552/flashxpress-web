import type { Metadata } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const inter = Inter({ variable: "--font-inter", subsets: ["latin"], display: "swap" });
const jetbrainsMono = JetBrains_Mono({ variable: "--font-jetbrains", subsets: ["latin"], display: "swap" });

export const metadata: Metadata = {
  metadataBase: new URL("https://wp.flashxpress.cloud"),
  title: { default: "FlashXpress — Lightning-Fast WordPress Stack", template: "%s | FlashXpress" },
  description: "Deploy NGINX, MariaDB 11.4, PHP 8.4, Redis — one command. Professional WordPress stack installer.",
  icons: { icon: "/logo.png", apple: "/logo.png" },
  keywords: ["WordPress", "NGINX", "FastCGI Cache", "MariaDB", "PHP 8.4", "Redis", "SSL", "FlashXpress"],
  authors: [{ name: "Wasim Akram" }],
  creator: "Wasim Akram",
  openGraph: { type: "website", locale: "en_US", url: "https://wp.flashxpress.cloud", siteName: "FlashXpress" },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${inter.variable} ${jetbrainsMono.variable} antialiased`}>
      <body className="min-h-screen flex flex-col bg-black text-white">{children}</body>
    </html>
  );
}
