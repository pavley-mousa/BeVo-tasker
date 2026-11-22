import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import "./globals.css";

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "https://bevo-tasker.vercel.app";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "BeVo | البوابة الأكاديمية",
    template: "%s | BeVo",
  },
  description: "BeVo بوابة أكاديمية لتنظيم المواد والمحاضرات والجروبات والسكاشن والمهام والأدلة الدراسية.",
  applicationName: "BeVo",
  manifest: "/manifest.webmanifest",
  icons: { icon: "/icon.svg" },
  ...(process.env.NEXT_PUBLIC_ADSENSE_CLIENT_ID
    ? { other: { "google-adsense-account": process.env.NEXT_PUBLIC_ADSENSE_CLIENT_ID } }
    : {}),
  openGraph: {
    type: "website",
    locale: "ar_EG",
    siteName: "BeVo",
    title: "BeVo | البوابة الأكاديمية",
    description: "تنظيم أكاديمي أوضح للطلاب والفرق التعليمية.",
  },
};

export const viewport: Viewport = {
  themeColor: "#172e4f",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="ar" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
