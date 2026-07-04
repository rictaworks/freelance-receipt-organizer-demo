import Link from "next/link";
import type { Metadata } from "next";

// 全デモ共通の /legal ページ。内容（デモ目的・データ削除ポリシー・Ricta Works 名刺情報）は
// 全デモで共通、デザインは本デモのテーマ（ネイビー系トークン）に合わせる。
// 文言は正式な契約・連絡先情報のため日本語固定（参考実装：clinic-finder-demo と同方針）。
export const metadata: Metadata = {
  title: "利用規約・免責事項・連絡先 | Recepto 領収書オーガナイザー（デモ）",
  robots: { index: false, follow: false },
};

const contacts: { label: string; value: React.ReactNode }[] = [
  { label: "屋号", value: "Ricta Works" },
  { label: "住所", value: "〒190-0022 東京都立川市錦町1丁目4-20 TSCビル5階" },
  { label: "電話", value: "070-5148-0380" },
  {
    label: "メール",
    value: (
      <a href="mailto:info@rictaworks.jp" className="legal__link">
        info@rictaworks.jp
      </a>
    ),
  },
  {
    label: "Web",
    value: (
      <a
        href="https://rictaworks.jp"
        target="_blank"
        rel="noopener noreferrer"
        className="legal__link"
      >
        https://rictaworks.jp
      </a>
    ),
  },
  {
    label: "X",
    value: (
      <a
        href="https://x.com/rictaworks"
        target="_blank"
        rel="noopener noreferrer"
        className="legal__link"
      >
        @rictaworks
      </a>
    ),
  },
  {
    label: "GitHub",
    value: (
      <a
        href="https://github.com/rictaworks"
        target="_blank"
        rel="noopener noreferrer"
        className="legal__link"
      >
        github.com/rictaworks
      </a>
    ),
  },
];

export default function LegalPage() {
  return (
    <div className="page legal">
      <Link href="/" className="legal__back">
        ← ホームに戻る
      </Link>

      <h1 className="legal__title">利用規約・免責事項・連絡先</h1>

      <section className="legal__section">
        <h2 className="legal__heading">利用規約</h2>
        <ul className="legal__list">
          <li>
            本サービスはデモンストレーション目的のみで提供されます。商用利用・再配布は禁止します。
          </li>
          <li>サービスの内容は予告なく変更・停止する場合があります。</li>
          <li>
            アップロードした画像・登録データは毎日 JST 03:00 に自動削除されます。
          </li>
          <li>本サービスの利用に際し、本規約に同意したものとみなします。</li>
        </ul>
      </section>

      <section className="legal__section">
        <h2 className="legal__heading">免責事項</h2>
        <ul className="legal__list">
          <li>
            OCR による読み取り結果および自動分類はデモ用の参考値であり、正確性を保証するものではありません。
          </li>
          <li>
            生成される帳票は参考様式であり、実際の税務申告・確定申告には使用できません。
          </li>
          <li>
            本サービスの利用により生じた損害について、Ricta Works は一切の責任を負いません。
          </li>
          <li>サービスの可用性・正確性・継続性を保証しません。</li>
        </ul>
      </section>

      <section className="legal__section">
        <h2 className="legal__heading">連絡先</h2>
        <dl className="legal__contacts">
          {contacts.map(({ label, value }) => (
            <div key={label} className="legal__contact-row">
              <dt className="legal__contact-label">{label}</dt>
              <dd className="legal__contact-value">{value}</dd>
            </div>
          ))}
        </dl>
      </section>
    </div>
  );
}
