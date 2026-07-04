"use client";

// 集計ページ（UC4）。
import { AggregationPanel } from "@/components/AggregationPanel";
import { useI18n } from "@/i18n/I18nProvider";
import { Icon } from "@/components/ui/Icon";

export default function AggregationsPage() {
  const { t } = useI18n();
  return (
    <div className="page">
      <section className="hero hero--compact">
        <h1 className="hero__title">
          <Icon name="chart" /> {t("aggregations.title")}
        </h1>
        <p className="hero__tagline">{t("aggregations.subtitle")}</p>
      </section>
      <AggregationPanel />
    </div>
  );
}
