"use client";

// アプリ共通シェル：ヘッダー（ブランド＋言語切替）とサイドナビ。
// ナビ項目はリピート（Repetition）と近接（Proximity）を意識して統一スタイルにする。
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";
import { Icon } from "./ui/Icon";
import type { IconName } from "@/lib/icons";
import { LanguageSwitcher } from "./LanguageSwitcher";
import { useI18n } from "@/i18n/I18nProvider";

interface NavItem {
  href: string;
  icon: IconName;
  labelKey: string;
}

const NAV_ITEMS: NavItem[] = [
  { href: "/", icon: "home", labelKey: "nav.home" },
  { href: "/receipts", icon: "receipt", labelKey: "nav.receipts" },
  { href: "/aggregations", icon: "chart", labelKey: "nav.aggregations" },
  { href: "/reports", icon: "report", labelKey: "nav.reports" },
];

export function AppShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const { t } = useI18n();

  return (
    <div className="app-shell">
      {/* 全デモ共通：デモ版アンバーバナー（ヘッダー外・最上部） */}
      <div className="demo-banner" role="note">
        <Icon name="warning" />
        <span>{t("layout.demoBanner")}</span>
      </div>

      <header className="app-header">
        <div className="app-header__brand">
          <span className="app-header__logo" aria-hidden="true">
            <Icon name="receipt" />
          </span>
          <span className="app-header__title">{t("app.title")}</span>
          <span className="badge badge--demo">{t("app.demoBadge")}</span>
        </div>
        <div className="app-header__actions">
          {/* 全デモ共通：デモ一覧へ戻る導線 */}
          <a
            href="https://rictaworks.jp/#demos"
            className="app-header__demos-link"
          >
            <Icon name="back" />
            <span>{t("layout.backToDemos")}</span>
          </a>
          <LanguageSwitcher />
        </div>
      </header>

      <div className="app-body">
        <nav className="app-nav" aria-label={t("a11y.mainNav")}>
          <ul className="app-nav__list">
            {NAV_ITEMS.map((item) => {
              const active =
                item.href === "/"
                  ? pathname === "/"
                  : pathname.startsWith(item.href);
              return (
                <li key={item.href}>
                  <Link
                    href={item.href}
                    className={`app-nav__link${active ? " app-nav__link--active" : ""}`}
                    aria-current={active ? "page" : undefined}
                  >
                    <span className="app-nav__icon" aria-hidden="true">
                      <Icon name={item.icon} />
                    </span>
                    <span>{t(item.labelKey)}</span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>

        <main className="app-main">{children}</main>
      </div>

      {/* 全デモ共通：フッター（/legal への導線） */}
      <footer className="app-footer">
        <Link href="/legal" className="app-footer__link">
          {t("layout.footerLegal")}
        </Link>
        <span className="app-footer__sep" aria-hidden="true">
          |
        </span>
        <span>{t("layout.copyright")}</span>
      </footer>

      {/* 全デモ共通：右下固定のご相談ボタン */}
      <a
        href="https://rictaworks.jp/"
        target="_blank"
        rel="noopener noreferrer"
        className="consult-fab"
      >
        <Icon name="consult" />
        <span>{t("layout.consult")}</span>
      </a>
    </div>
  );
}
