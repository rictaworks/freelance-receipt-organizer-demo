"use client";

// ホーム（UC1 起点）。アップロード → 直近の領収書一覧を同一画面で確認・修正できる導線。
import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { ReceiptUpload } from "@/components/ReceiptUpload";
import { ReceiptsPanel } from "@/components/ReceiptsPanel";
import { WarningBanner } from "@/components/WarningBanner";
import { useAppData } from "@/components/AppDataProvider";
import { useI18n } from "@/i18n/I18nProvider";
import type { ReceiptWarning } from "@/lib/types";

export default function HomePage() {
  const { t } = useI18n();
  const { categories } = useAppData();
  const [warnings, setWarnings] = useState<ReceiptWarning[]>([]);
  const [refreshToken, setRefreshToken] = useState(0);

  return (
    <div className="page">
      <section className="hero">
        <h1 className="hero__title">{t("app.title")}</h1>
        <p className="hero__tagline">{t("app.tagline")}</p>
        <p className="hero__notice">
          <Icon name="info" /> {t("session.resetNotice")}
        </p>
      </section>

      <section className="card" aria-labelledby="upload-heading">
        <div className="card__header">
          <h2 id="upload-heading" className="card__title">
            <Icon name="upload" /> {t("upload.title")}
          </h2>
        </div>
        <ReceiptUpload
          onUploaded={(res) => {
            setWarnings(res.warnings ?? []);
            setRefreshToken((n) => n + 1);
          }}
        />
        <WarningBanner warnings={warnings} />
      </section>

      <ReceiptsPanel categories={categories} refreshToken={refreshToken} />
    </div>
  );
}
