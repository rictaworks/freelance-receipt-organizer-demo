"use client";

// 領収書一覧パネル（UC2/UC3）。GET /receipts で取得し、行ごとに編集・科目変更する。
// 外部から refreshToken を変えることで再取得する（アップロード直後など）。
import { useCallback, useEffect, useState } from "react";
import { Icon } from "./ui/Icon";
import { ReceiptRow } from "./ReceiptRow";
import { useI18n } from "@/i18n/I18nProvider";
import { listReceipts } from "@/lib/api";
import type { Category, Receipt } from "@/lib/types";
import { useApiError } from "@/lib/useApiError";

interface Props {
  categories: Category[];
  refreshToken?: number;
}

export function ReceiptsPanel({ categories, refreshToken = 0 }: Props) {
  const { t } = useI18n();
  const handleError = useApiError();
  const [receipts, setReceipts] = useState<Receipt[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await listReceipts();
      setReceipts(res.receipts);
    } catch (err) {
      handleError(err);
    } finally {
      setLoading(false);
    }
  }, [handleError]);

  useEffect(() => {
    load();
  }, [load, refreshToken]);

  const onUpdated = (updated: Receipt) => {
    setReceipts((prev) =>
      prev.map((r) => (r.id === updated.id ? { ...r, ...updated } : r)),
    );
  };

  return (
    <section className="card" aria-labelledby="receipts-heading">
      <div className="card__header">
        <div>
          <h2 id="receipts-heading" className="card__title">
            <Icon name="receipt" /> {t("receipts.title")}
          </h2>
          <p className="card__subtitle">{t("receipts.subtitle")}</p>
        </div>
        <div className="card__header-aside">
          <span className="count-pill">{t("receipts.count", { count: receipts.length })}</span>
          <button
            type="button"
            className="btn btn--ghost btn--sm"
            onClick={load}
            disabled={loading}
          >
            <Icon name="retry" spin={loading} /> {t("common.retry")}
          </button>
        </div>
      </div>

      {loading ? (
        <p className="state-note">
          <Icon name="spinner" spin /> {t("common.loading")}
        </p>
      ) : receipts.length === 0 ? (
        <p className="state-note">{t("receipts.empty")}</p>
      ) : (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th scope="col">{t("receipts.colDate")}</th>
                <th scope="col">{t("receipts.colStore")}</th>
                <th scope="col">{t("receipts.colAmount")}</th>
                <th scope="col">{t("receipts.colCategory")}</th>
                <th scope="col">{t("receipts.colConfidence")}</th>
                <th scope="col">{t("receipts.colEdited")}</th>
                <th scope="col">{t("receipts.colActions")}</th>
              </tr>
            </thead>
            <tbody>
              {receipts.map((r) => (
                <ReceiptRow
                  key={r.id}
                  receipt={r}
                  categories={categories}
                  onUpdated={onUpdated}
                />
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
