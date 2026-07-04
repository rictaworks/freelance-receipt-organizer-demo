"use client";

// 帳票プレビュー/PDF（UC5/UC6）。POST /reports で preview_html を取得して表示し、
// PDF ダウンロードリンク（GET /reports/:id.pdf）を提供する。
// 注記「本帳票は参考様式であり…」を常に表示する（F5 免責・必須）。
import { useCallback, useState } from "react";
import { Icon } from "./ui/Icon";
import { useI18n } from "@/i18n/I18nProvider";
import { createReport, reportPdfUrl } from "@/lib/api";
import type { ReportResponse } from "@/lib/types";
import { formatYen, formatDateTimeJst } from "@/lib/format";
import { useApiError } from "@/lib/useApiError";

export function ReportPanel() {
  const { t, locale } = useI18n();
  const handleError = useApiError();
  const currentYear = new Date().getFullYear();
  const [year, setYear] = useState<number>(currentYear);
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<ReportResponse | null>(null);

  const yearOptions = [currentYear, currentYear - 1, currentYear - 2, currentYear - 3];

  const onGenerate = useCallback(async () => {
    setBusy(true);
    try {
      const res = await createReport(year);
      setResult(res);
    } catch (err) {
      handleError(err);
    } finally {
      setBusy(false);
    }
  }, [year, handleError]);

  return (
    <section className="card" aria-labelledby="report-heading">
      <div className="card__header">
        <div>
          <h2 id="report-heading" className="card__title">
            <Icon name="report" /> {t("reports.title")}
          </h2>
          <p className="card__subtitle">{t("reports.subtitle")}</p>
        </div>
        <div className="card__header-aside">
          <label className="year-select">
            <span>{t("reports.yearLabel")}</span>
            <select
              value={year}
              onChange={(e) => setYear(Number(e.target.value))}
              disabled={busy}
            >
              {yearOptions.map((y) => (
                <option key={y} value={y}>
                  {y}
                </option>
              ))}
            </select>
          </label>
          <button
            type="button"
            className="btn btn--primary btn--sm"
            onClick={onGenerate}
            disabled={busy}
          >
            {busy ? (
              <>
                <Icon name="spinner" spin /> {t("reports.generating")}
              </>
            ) : (
              <>
                <Icon name="report" /> {t("reports.generate")}
              </>
            )}
          </button>
        </div>
      </div>

      {/* 免責注記は常に表示する（生成前でも案内）。 */}
      <p className="notice" role="note">
        <Icon name="info" />{" "}
        {result?.report.notice ?? t("reports.notice")}
      </p>

      {result ? (
        <div className="report-result">
          <div className="report-result__meta">
            <span className="stat">
              <span className="stat__label">{t("reports.grandTotalLabel")}</span>
              <span className="stat__value">
                {formatYen(result.report.grand_total_yen, locale)}
                <span className="unit"> {t("common.yen")}</span>
              </span>
            </span>
            <span className="stat">
              <span className="stat__label">{t("reports.generatedAt")}</span>
              <span className="stat__value stat__value--sm">
                {formatDateTimeJst(result.report.generated_at)}
              </span>
            </span>
            <a
              className="btn btn--secondary btn--sm"
              href={reportPdfUrl(result.report.id)}
              target="_blank"
              rel="noopener noreferrer"
            >
              <Icon name="pdf" /> {t("reports.downloadPdf")}
            </a>
          </div>

          <h3 className="report-result__preview-title">{t("reports.previewTitle")}</h3>
          {/*
            preview_html は自社バックエンドが生成する信頼済み HTML。
            隔離コンテナ内で描画する。将来的にサニタイズ層を挟む余地を残す。
          */}
          <div
            className="report-preview"
            dangerouslySetInnerHTML={{ __html: result.preview_html }}
          />
        </div>
      ) : null}
    </section>
  );
}
