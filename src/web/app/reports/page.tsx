"use client";

// 帳票ページ（UC5/UC6）。
import { ReportPanel } from "@/components/ReportPanel";
import { useI18n } from "@/i18n/I18nProvider";
import { Icon } from "@/components/ui/Icon";

export default function ReportsPage() {
  const { t } = useI18n();
  return (
    <div className="page">
      <section className="hero hero--compact">
        <h1 className="hero__title">
          <Icon name="report" /> {t("reports.title")}
        </h1>
        <p className="hero__tagline">{t("reports.subtitle")}</p>
      </section>
      <ReportPanel />
    </div>
  );
}
