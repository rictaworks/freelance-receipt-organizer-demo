"use client";

// アプリ横断のデータ供給：初回に GET /session（Cookie 発行）し、GET /categories を取得する。
// エラーは握りつぶさずトーストで通知しつつ、状態として保持する。
import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { getCategories, getSession } from "@/lib/api";
import type { Category, SessionInfo } from "@/lib/types";
import { useApiError } from "@/lib/useApiError";
import { useToast } from "./ui/Toast";
import { useI18n } from "@/i18n/I18nProvider";

interface AppDataValue {
  session: SessionInfo | null;
  categories: Category[];
  ready: boolean;
}

const AppDataContext = createContext<AppDataValue | null>(null);

export function AppDataProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<SessionInfo | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [ready, setReady] = useState(false);
  const handleError = useApiError();
  const { showToast } = useToast();
  const { t } = useI18n();

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const s = await getSession();
        if (!active) return;
        setSession(s);
        showToast({
          type: "info",
          title: t("app.title"),
          message: s.is_new ? t("session.statusNew") : t("session.statusExisting"),
        });
      } catch (e) {
        if (active) handleError(e);
      }
      try {
        const c = await getCategories();
        if (!active) return;
        setCategories(c.categories);
      } catch (e) {
        if (active) handleError(e);
      }
      if (active) setReady(true);
    })();
    return () => {
      active = false;
    };
    // 初回のみ実行する（依存を空に固定）。
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const value = useMemo<AppDataValue>(
    () => ({ session, categories, ready }),
    [session, categories, ready],
  );

  return <AppDataContext.Provider value={value}>{children}</AppDataContext.Provider>;
}

export function useAppData(): AppDataValue {
  const ctx = useContext(AppDataContext);
  if (!ctx) {
    throw new Error("useAppData は AppDataProvider の内側で使用してください。");
  }
  return ctx;
}
