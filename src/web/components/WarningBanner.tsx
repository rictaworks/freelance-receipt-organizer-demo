"use client";

// 抽出時の warnings（duplicate / non_positive_amount / uncategorized / low_confidence_manual_input）を
// 独自 UI のバナーで表示する（CLAUDE.md §5：alert 不使用）。
import { Icon } from "./ui/Icon";
import { useI18n } from "@/i18n/I18nProvider";
import type { ReceiptWarning } from "@/lib/types";

export function WarningBanner({ warnings }: { warnings: ReceiptWarning[] }) {
  const { t } = useI18n();
  if (warnings.length === 0) return null;

  return (
    <div className="warning-banner" role="alert">
      <div className="warning-banner__head">
        <span className="warning-banner__icon" aria-hidden="true">
          <Icon name="warning" />
        </span>
        <p className="warning-banner__title">{t("warnings.title")}</p>
      </div>
      <ul className="warning-banner__list">
        {warnings.map((w) => (
          <li key={w.code} className="warning-banner__item">
            {/* サーバ message ではなく翻訳キーを優先。未知コードは素の message にフォールバック */}
            {t(`warnings.${w.code}`) === `warnings.${w.code}`
              ? w.message
              : t(`warnings.${w.code}`)}
          </li>
        ))}
      </ul>
    </div>
  );
}
