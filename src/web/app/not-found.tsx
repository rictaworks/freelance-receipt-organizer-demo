"use client";

// 404 ページ（QC10）。ホームへの復帰導線を提供する。
import Link from "next/link";
import { Icon } from "@/components/ui/Icon";
import { useI18n } from "@/i18n/I18nProvider";

export default function NotFound() {
  const { t } = useI18n();
  return (
    <div className="page-state">
      <span className="page-state__icon" aria-hidden="true">
        <Icon name="exclamation" />
      </span>
      <h1 className="page-state__title">404</h1>
      <p className="page-state__body">{t("errors.RECEIPT_NOT_FOUND")}</p>
      <Link href="/" className="btn btn--primary">
        <Icon name="home" /> {t("nav.home")}
      </Link>
    </div>
  );
}
