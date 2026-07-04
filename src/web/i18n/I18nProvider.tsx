"use client";

// i18n プロバイダ。ロケール状態を保持し、t(key, params) と言語切替を提供する。
// - key はドット区切りパス（例: "reports.notice"）。
// - params で {count} / {month} 等の簡易補間に対応。
// - 未定義キーはフォールバックで握りつぶさず、キー文字列をそのまま返して検知しやすくする。
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  DEFAULT_LOCALE,
  MESSAGES,
  dirFor,
  isLocale,
  type Locale,
} from "./config";

type TParams = Record<string, string | number>;

interface I18nContextValue {
  locale: Locale;
  setLocale: (next: Locale) => void;
  t: (key: string, params?: TParams) => string;
  dir: "ltr" | "rtl";
}

const I18nContext = createContext<I18nContextValue | null>(null);

const STORAGE_KEY = "recepto.locale";

function resolvePath(obj: unknown, path: string): string | undefined {
  const segments = path.split(".");
  let cursor: unknown = obj;
  for (const seg of segments) {
    if (cursor && typeof cursor === "object" && seg in (cursor as object)) {
      cursor = (cursor as Record<string, unknown>)[seg];
    } else {
      return undefined;
    }
  }
  return typeof cursor === "string" ? cursor : undefined;
}

function interpolate(template: string, params?: TParams): string {
  if (!params) return template;
  return template.replace(/\{(\w+)\}/g, (match, name: string) => {
    const value = params[name];
    return value === undefined ? match : String(value);
  });
}

export function I18nProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(DEFAULT_LOCALE);

  // 初期化：保存済みロケールを復元（クライアントのみ）。
  useEffect(() => {
    const saved = window.localStorage.getItem(STORAGE_KEY);
    if (saved && isLocale(saved)) {
      setLocaleState(saved);
    }
  }, []);

  // <html> の lang / dir を同期する。
  useEffect(() => {
    document.documentElement.lang = locale;
    document.documentElement.dir = dirFor(locale);
  }, [locale]);

  const setLocale = useCallback((next: Locale) => {
    setLocaleState(next);
    window.localStorage.setItem(STORAGE_KEY, next);
  }, []);

  const t = useCallback(
    (key: string, params?: TParams): string => {
      const table = MESSAGES[locale];
      const found = resolvePath(table, key);
      if (found !== undefined) return interpolate(found, params);
      // 現在ロケールに無ければ ja を試す（英語キー器の補完）。それも無ければキーを返す。
      const jaFound = resolvePath(MESSAGES.ja, key);
      if (jaFound !== undefined) return interpolate(jaFound, params);
      return key;
    },
    [locale],
  );

  const value = useMemo<I18nContextValue>(
    () => ({ locale, setLocale, t, dir: dirFor(locale) }),
    [locale, setLocale, t],
  );

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useI18n(): I18nContextValue {
  const ctx = useContext(I18nContext);
  if (!ctx) {
    throw new Error("useI18n は I18nProvider の内側で使用してください。");
  }
  return ctx;
}
