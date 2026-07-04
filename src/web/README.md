# フロントエンド（Next.js / App Router）

フリーランス向け「領収書自動整理＋申告書作成」デモの Web フロント。
デザインは `app-ui/`（読み取り専用モック）の配色・構成を踏襲。CLAUDE.md §5 UI/UX 規約・§8 i18n を厳守する。

## セットアップ

```bash
cd src/web
cp .env.example .env.local   # 実値は .env.local に置く（コミット禁止）
npm install
npm run dev                  # http://localhost:3000
```

バックエンド（Rails API）は既定で `http://localhost:4000`。`NEXT_PUBLIC_API_BASE` で変更する。
バックエンド未起動でもトップページは描画される（API 失敗は独自 UI のトーストで通知）。

## ビルド / Lint

```bash
npm run build   # 型・lint を含むプロダクションビルド
npm run lint
```

## ディレクトリ構成

| パス | 役割 |
|---|---|
| `app/` | App Router のページ（`/`, `/receipts`, `/aggregations`, `/reports`）＋ `layout` / `error` / `not-found` |
| `app/providers.tsx` | I18n → Toast → AppData（session/categories）→ AppShell のプロバイダ合成 |
| `components/` | 画面部品（アップロード・一覧・集計・帳票・シェル・言語切替） |
| `components/ui/` | 汎用 UI（Icon / Toast / Modal） |
| `lib/` | API クライアント（`api.ts`）・型（`types.ts`）・整形（`format.ts`）・アイコン集約（`icons.ts`）・エラー表示フック |
| `i18n/` | i18n 設定とプロバイダ |
| `locales/<lang>/common.json` | 翻訳リソース（ja/en/fr/zh/ru/es/ar） |

## 主要な設計方針

- **API 契約**は `SPEC/api/*` を正典とし、`lib/api.ts` に集約。全リクエストに `credentials: "include"`（HttpOnly Cookie を送受信）。
- **エラーは握りつぶさない**。サーバの `{error:{code,message,trace_id}}` を `ApiError` として保持し、`trace_id` 付きでトースト表示。
- **ハニーポット（F8）**：アップロードフォームに不可視 `website` フィールドを設置（`tabindex=-1` / `autocomplete=off` / 視覚・スクリーンリーダーから隠蔽）。
- **アイコンは Font Awesome を自己ホスト**（`@fortawesome/*`）。外部 CDN 非依存。**絵文字は不使用**。
- **ネイティブ `alert()/confirm()/prompt()` は不使用**。通知は Toast、確認/入力は Modal（`components/ui/Modal.tsx`）で代替。
- **i18n**：文言はコードに埋め込まず翻訳リソースへ分離。既定 `ja`。アラビア語は `dir=rtl` を `<html>` に同期。
- **帳票注記**「本帳票は参考様式であり、実際の税務申告には使用できません。」を帳票画面で常時表示。

## 動作確認の観点（QC10 抜粋）

- QC02 SEO 基礎：`metadata`（title/description、`robots: noindex`）。
- QC04 モバイル：サイドナビの横スクロール化・テーブル横スクロール。
- QC07 アクセシビリティ：フォーカスリング、`aria-live` トースト、`role=dialog` モーダル、ラベル付け。
- QC10 エラーハンドリング：`error.tsx` / `not-found.tsx`、API エラーのトースト表示。
