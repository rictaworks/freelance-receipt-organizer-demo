"use client";

// クライアント側プロバイダの合成。
// 依存順：I18n（文言）→ Toast（i18n を使用）→ AppData（両方を使用）。
import type { ReactNode } from "react";
import { I18nProvider } from "@/i18n/I18nProvider";
import { ToastProvider } from "@/components/ui/Toast";
import { AppDataProvider } from "@/components/AppDataProvider";
import { AppShell } from "@/components/AppShell";

export function Providers({ children }: { children: ReactNode }) {
  return (
    <I18nProvider>
      <ToastProvider>
        <AppDataProvider>
          <AppShell>{children}</AppShell>
        </AppDataProvider>
      </ToastProvider>
    </I18nProvider>
  );
}
