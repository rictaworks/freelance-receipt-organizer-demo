"use client";

// 領収書ページ（UC2/UC3）。一覧の確認・修正と勘定科目変更に特化。
import { ReceiptsPanel } from "@/components/ReceiptsPanel";
import { useAppData } from "@/components/AppDataProvider";
import { useI18n } from "@/i18n/I18nProvider";
import { Icon } from "@/components/ui/Icon";

export default function ReceiptsPage() {
  const { t } = useI18n();
  const { categories } = useAppData();

  return (
    <div className="page">
      <section className="hero hero--compact">
        <h1 className="hero__title">
          <Icon name="receipt" /> {t("receipts.title")}
        </h1>
        <p className="hero__tagline">{t("receipts.subtitle")}</p>
      </section>
      <ReceiptsPanel categories={categories} />
    </div>
  );
}
