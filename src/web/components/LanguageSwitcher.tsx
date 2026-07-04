"use client";

// 言語切り替え。7 言語を select で提供し、選択で即時反映（dir も同期）。
import { useI18n } from "@/i18n/I18nProvider";
import { LOCALES, isLocale } from "@/i18n/config";
import { Icon } from "./ui/Icon";

export function LanguageSwitcher() {
  const { locale, setLocale, t } = useI18n();

  return (
    <label className="lang-switcher">
      <span className="lang-switcher__icon" aria-hidden="true">
        <Icon name="language" />
      </span>
      <span className="visually-hidden">{t("a11y.languageSwitcher")}</span>
      <select
        className="lang-switcher__select"
        value={locale}
        onChange={(e) => {
          const next = e.target.value;
          if (isLocale(next)) setLocale(next);
        }}
      >
        {LOCALES.map((code) => (
          <option key={code} value={code}>
            {t(`language.${code}`)}
          </option>
        ))}
      </select>
    </label>
  );
}
