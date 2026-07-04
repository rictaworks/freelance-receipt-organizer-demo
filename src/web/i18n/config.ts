// i18n 設定。文言はコードに埋め込まず locales/<lang>/common.json に分離する（CLAUDE.md §8）。
// 7 言語（日英仏中露西亜）の器を用意し、既定は日本語。アラビア語は RTL。
import ja from "@/locales/ja/common.json";
import en from "@/locales/en/common.json";
import fr from "@/locales/fr/common.json";
import zh from "@/locales/zh/common.json";
import ru from "@/locales/ru/common.json";
import es from "@/locales/es/common.json";
import ar from "@/locales/ar/common.json";

export const LOCALES = ["ja", "en", "fr", "zh", "ru", "es", "ar"] as const;
export type Locale = (typeof LOCALES)[number];

// 右書き（RTL）言語。dir 切替の器。
export const RTL_LOCALES: Locale[] = ["ar"];

// ja を基準の型とする（全キーを網羅）。
export type Messages = typeof ja;

export const MESSAGES: Record<Locale, Messages> = {
  ja,
  // 型は ja に合わせる（構造は同一。JSON リテラル型の相違を避けるため unknown 経由でキャスト）。
  en: en as unknown as Messages,
  fr: fr as unknown as Messages,
  zh: zh as unknown as Messages,
  ru: ru as unknown as Messages,
  es: es as unknown as Messages,
  ar: ar as unknown as Messages,
};

export const DEFAULT_LOCALE: Locale = ((): Locale => {
  const env = process.env.NEXT_PUBLIC_DEFAULT_LOCALE;
  if (env && (LOCALES as readonly string[]).includes(env)) {
    return env as Locale;
  }
  return "ja";
})();

export function isLocale(value: string): value is Locale {
  return (LOCALES as readonly string[]).includes(value);
}

export function dirFor(locale: Locale): "ltr" | "rtl" {
  return RTL_LOCALES.includes(locale) ? "rtl" : "ltr";
}
