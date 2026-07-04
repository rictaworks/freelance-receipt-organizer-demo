"use client";

// ルートセグメントのエラーバウンダリ（QC10）。例外を握りつぶさず再試行導線を出す。
import { useEffect } from "react";
import { Icon } from "@/components/ui/Icon";
import { useI18n } from "@/i18n/I18nProvider";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const { t } = useI18n();

  useEffect(() => {
    // デバッグ可能にするため構造化してログへ出す（トレース用の digest を含む）。
    console.error("[route-error]", { message: error.message, digest: error.digest });
  }, [error]);

  return (
    <div className="page-state">
      <span className="page-state__icon" aria-hidden="true">
        <Icon name="error" />
      </span>
      <h1 className="page-state__title">{t("errors.genericTitle")}</h1>
      <p className="page-state__body">{t("errors.unknown")}</p>
      {error.digest ? (
        <p className="page-state__trace">
          {t("errors.traceLabel")}: <code>{error.digest}</code>
        </p>
      ) : null}
      <button type="button" className="btn btn--primary" onClick={() => reset()}>
        <Icon name="retry" /> {t("common.retry")}
      </button>
    </div>
  );
}
