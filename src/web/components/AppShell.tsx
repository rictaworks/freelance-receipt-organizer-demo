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
      <header className="app-header">
        <div className="app-header__brand">
          <span className="app-header__logo" aria-hidden="true">
            <Icon name="receipt" />
          </span>
          <span className="app-header__title">{t("app.title")}</span>
          <span className="badge badge--demo">{t("app.demoBadge")}</span>
        </div>
        <LanguageSwitcher />
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
    </div>
  );
}
