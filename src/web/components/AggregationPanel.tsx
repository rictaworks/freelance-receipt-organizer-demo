"use client";

// 集計閲覧（UC4）。月×勘定科目のクロス表＋科目別年間合計＋総合計を表示する。
import { useCallback, useEffect, useMemo, useState } from "react";
import { Icon } from "./ui/Icon";
import { useI18n } from "@/i18n/I18nProvider";
import { getAggregations } from "@/lib/api";
import type { AggregationResponse } from "@/lib/types";
import { formatYen } from "@/lib/format";
import { useApiError } from "@/lib/useApiError";

function keyOf(categoryId: number | null): string {
  return categoryId === null ? "null" : String(categoryId);
}

export function AggregationPanel({ refreshToken = 0 }: { refreshToken?: number }) {
  const { t, locale } = useI18n();
  const handleError = useApiError();
  const currentYear = new Date().getFullYear();
  const [year, setYear] = useState<number>(currentYear);
  const [data, setData] = useState<AggregationResponse | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(
    async (targetYear: number) => {
      setLoading(true);
      try {
        const res = await getAggregations(targetYear);
        setData(res);
      } catch (err) {
        handleError(err);
      } finally {
        setLoading(false);
      }
    },
    [handleError],
  );

  useEffect(() => {
    load(year);
  }, [load, year, refreshToken]);

  // クロス表用のセル辞書 `${month}:${categoryKey}` -> total。
  const cellMap = useMemo(() => {
    const map = new Map<string, number>();
    data?.months.forEach((m) => {
      m.categories.forEach((c) => {
        map.set(`${m.month}:${keyOf(c.category_id)}`, c.total_yen);
      });
    });
    return map;
  }, [data]);

  const months = data?.months.map((m) => m.month) ?? [];
  const categories = data?.category_yearly_totals ?? [];
  const hasData = (data?.months.length ?? 0) > 0;

  const yearOptions = [currentYear, currentYear - 1, currentYear - 2, currentYear - 3];

  return (
    <section className="card" aria-labelledby="agg-heading">
      <div className="card__header">
        <div>
          <h2 id="agg-heading" className="card__title">
            <Icon name="chart" /> {t("aggregations.title")}
          </h2>
          <p className="card__subtitle">{t("aggregations.subtitle")}</p>
        </div>
        <label className="year-select">
          <span>{t("aggregations.yearLabel")}</span>
          <select
            value={year}
            onChange={(e) => setYear(Number(e.target.value))}
            disabled={loading}
          >
            {yearOptions.map((y) => (
              <option key={y} value={y}>
                {y}
              </option>
            ))}
          </select>
        </label>
      </div>

      {loading ? (
        <p className="state-note">
          <Icon name="spinner" spin /> {t("common.loading")}
        </p>
      ) : !hasData ? (
        <p className="state-note">{t("aggregations.empty")}</p>
      ) : (
        <div className="table-wrap">
          <table className="data-table data-table--matrix">
            <thead>
              <tr>
                <th scope="col">{t("aggregations.categoryColumn")}</th>
                {months.map((m) => (
                  <th key={m} scope="col" className="num">
                    {t("aggregations.monthShort", { month: m })}
                  </th>
                ))}
                <th scope="col" className="num total-col">
                  {t("aggregations.grandTotal")}
                </th>
              </tr>
            </thead>
            <tbody>
              {categories.map((cat) => (
                <tr key={keyOf(cat.category_id)}>
                  <th scope="row">
                    {cat.category_id === null
                      ? t("common.uncategorized")
                      : cat.category_name}
                  </th>
                  {months.map((m) => {
                    const v = cellMap.get(`${m}:${keyOf(cat.category_id)}`);
                    return (
                      <td key={m} className="num">
                        {v !== undefined ? formatYen(v, locale) : "-"}
                      </td>
                    );
                  })}
                  <td className="num total-col">
                    {formatYen(cat.total_yen, locale)}
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <th scope="row">{t("aggregations.monthTotal")}</th>
                {data?.months.map((m) => (
                  <td key={m.month} className="num">
                    {formatYen(m.month_total_yen, locale)}
                  </td>
                ))}
                <td className="num grand-total">
                  {formatYen(data?.grand_total_yen ?? 0, locale)}
                  <span className="unit"> {t("common.yen")}</span>
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      )}
    </section>
  );
}
