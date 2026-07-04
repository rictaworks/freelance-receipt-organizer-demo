# freelance-receipt-organizer-demo

フリーランス向け「領収書自動整理＋申告書作成」サービスのデモ版（ショーケース）。

- 時刻はすべて **JST（Asia/Tokyo）**、文字エンコードはすべて **UTF-8**。
- 仕様の正典：[`freelance-receipt-organizer-demo_設計書.md`](./freelance-receipt-organizer-demo_設計書.md) / [`SPEC/`](./SPEC/)
- 開発・運用ルール：[`CLAUDE.md`](./CLAUDE.md)

---

## 自動ログイン（開発環境）

本デモはエンドユーザー認証を持たない（セッションIDのみで分離）。
開発・テストを容易にするため、**環境判定により開発環境では「認証済み」状態に自動分岐**する。

| 環境 | 判定 | ログイン状態 |
|---|---|---|
| development | `APP_ENV=development` | **自動ログイン（認証済みに固定）**。初回アクセスで UUID v4 セッションを自動発行し HttpOnly Cookie に保存 |
| production | `APP_ENV=production` | 管理画面のみ **Google ログイン**。エンドユーザー画面は認証なし（セッションIDで分離） |

- 環境変数は `.env` を参照する（[`ENV/DEVELOPMENT.md`](./ENV/DEVELOPMENT.md) / [`ENV/PRODUCTION.md`](./ENV/PRODUCTION.md)）。
- 開発サーバーは自動ログイン済みのため、`curl` / `wget --mirror` / Playwright でそのまま主要導線を検証できる。

---

## ページ一覧

デプロイ前のため URL は開発サーバー（`http://localhost:3000`）基準。デプロイ後は Vercel サブドメインに置き換える。

| ページ名 | URL |
|---|---|
| トップ／領収書アップロード | [`/`](http://localhost:3000/) |
| 抽出結果の確認・修正 | [`/receipts/review`](http://localhost:3000/receipts/review) |
| 領収書一覧 | [`/receipts`](http://localhost:3000/receipts) |
| 月別・科目別 集計 | [`/aggregations`](http://localhost:3000/aggregations) |
| 収支内訳書風 帳票プレビュー | [`/reports/preview`](http://localhost:3000/reports/preview) |
| 手動入力フォーム（OCR認識不能時） | [`/receipts/manual`](http://localhost:3000/receipts/manual) |
| 管理画面（開発者用・日本語のみ・Googleログイン） | [`/admin`](http://localhost:3000/admin) |

---

## API 一覧

各 API の詳細仕様は [`SPEC/api/`](./SPEC/api/) を正典とする。エンドポイントは Rails API（`http://localhost:4000`）基準。

| タイトル | エンドポイントURL | 仕様 |
|---|---|---|
| セッション発行 | `GET /session` | [SPEC/api/session.md](./SPEC/api/session.md) |
| 領収書アップロード | `POST /receipts` | [SPEC/api/receipts.md](./SPEC/api/receipts.md) |
| 領収書一覧取得 | `GET /receipts` | [SPEC/api/receipts.md](./SPEC/api/receipts.md) |
| 領収書 手動修正・科目変更 | `PATCH /receipts/:id` | [SPEC/api/receipts.md](./SPEC/api/receipts.md) |
| 勘定科目マスタ取得 | `GET /categories` | [SPEC/api/categories.md](./SPEC/api/categories.md) |
| 月別・科目別 集計取得 | `GET /aggregations` | [SPEC/api/aggregations.md](./SPEC/api/aggregations.md) |
| 帳票生成 | `POST /reports` | [SPEC/api/reports.md](./SPEC/api/reports.md) |
| 帳票PDFダウンロード | `GET /reports/:id.pdf` | [SPEC/api/reports.md](./SPEC/api/reports.md) |
| OCR 抽出（内部・FastAPI） | `POST /ocr` | [SPEC/api/ocr.md](./SPEC/api/ocr.md) |

> API一覧・ページ一覧は実装の追加・変更に追従して**漏れなく更新**する。

---

## ディレクトリ構成

| ディレクトリ | 用途 |
|---|---|
| `SPEC/` | 仕様書・API仕様・リバースエンジニアリング図（ER/DFD/シーケンス/クラス/状態遷移/ユースケース） |
| `TASKS/` | タスク管理 |
| `DEBUG/` | バグ報告 |
| `CLIENT/` | クライアント要望等 |
| `WORK/` | 作業報告 |
| `ENV/` | 開発環境・本番環境の定義 |
| `DELETE/` | ゴミ箱（削除の代わりに移動） |
| `test/` | PRごとのテスト（`test/pr***/`） |
| `app-ui/` | デザインモック（読み取り専用） |
| `.claude/agents/` | サブエージェント定義 |

---

## セットアップ（図解ツール）

```bash
npm install          # @mermaid-js/mermaid-cli を導入
npm run docs:render  # SPEC/reverse-engineering の .mmd を SVG 化
```
