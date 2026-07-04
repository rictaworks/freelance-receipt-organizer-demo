import type { Metadata, Viewport } from "next";
import Script from "next/script";
import "@fortawesome/fontawesome-svg-core/styles.css";
// icons.ts で config.autoAddCss = false を設定してから FA を使う（上の CSS を明示 import 済み）。
import "@/lib/icons";
import "./globals.css";
import { Providers } from "./providers";

// SEO 基礎（QC02）。文言はデモ用途のため最小限に固定。
export const metadata: Metadata = {
  title: "Recepto 領収書オーガナイザー（デモ）",
  description:
    "領収書をアップロードして自動整理し、月別・科目別集計から収支内訳書風の帳票プレビューまで行うデモ。",
  robots: { index: false, follow: false },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // 初期は ja / ltr。クライアントで I18nProvider が lang/dir を同期する。
  return (
    <html lang="ja" dir="ltr">
      <head>
        {/* GA4（RictaWorks 全デモ共通タグ） */}
        <Script
          src="https://www.googletagmanager.com/gtag/js?id=G-C04W1XKS16"
          strategy="afterInteractive"
        />
        <Script id="ga4" strategy="afterInteractive">
          {`
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', 'G-C04W1XKS16');
          `}
        </Script>
      </head>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
