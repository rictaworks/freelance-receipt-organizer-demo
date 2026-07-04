# SPEC ディレクトリ

本ディレクトリは、freelance-receipt-organizer-demo（デモ版）の **仕様書・API仕様・リバースエンジニアリング図** を一元管理します。

## 役割

- **仕様の正典管理**: 設計の正典はリポジトリ直下の `freelance-receipt-organizer-demo_設計書.md`。本ディレクトリはそれを実装・運用の観点で分割・具体化した仕様群を保持する。
- **API仕様**: 各エンドポイントのメソッド・リクエスト/レスポンス例・エラー設計・セッション分離を機能仕様（F1〜F8）に紐づけて記述する。
- **リバースエンジニアリング図**: 設計書の mermaid 図を `.mmd` ソースとして分割保存し、mmdc で SVG 化できるようにする。

## ディレクトリ構成と索引

| パス | 内容 |
|---|---|
| [`api/README.md`](./api/README.md) | API 索引（エンドポイント一覧・共通方針・共通エラー形式） |
| [`api/session.md`](./api/session.md) | GET `/session` セッション発行（UUID v4 / HttpOnly・SameSite=Lax Cookie） |
| [`api/receipts.md`](./api/receipts.md) | POST / GET / PATCH `/receipts` アップロード・一覧・手動修正（ハニーポット含む） |
| [`api/categories.md`](./api/categories.md) | GET `/categories` 勘定科目マスタ 12 件 |
| [`api/aggregations.md`](./api/aggregations.md) | GET `/aggregations` 月×科目集計・年間合計 |
| [`api/reports.md`](./api/reports.md) | POST `/reports`・GET `/reports/:id.pdf` 帳票生成・PDFダウンロード |
| [`api/ocr.md`](./api/ocr.md) | POST `/ocr` FastAPI 内部 OCR（OpenCV→pytesseract） |
| [`reverse-engineering/README.md`](./reverse-engineering/README.md) | 6 図の一覧・説明・SVG 化手順 |
| [`reverse-engineering/er.mmd`](./reverse-engineering/er.mmd) | ER図（erDiagram） |
| [`reverse-engineering/dfd.mmd`](./reverse-engineering/dfd.mmd) | DFD（flowchart LR） |
| [`reverse-engineering/sequence.mmd`](./reverse-engineering/sequence.mmd) | シーケンス図（sequenceDiagram） |
| [`reverse-engineering/class.mmd`](./reverse-engineering/class.mmd) | クラス図（classDiagram） |
| [`reverse-engineering/state.mmd`](./reverse-engineering/state.mmd) | 状態遷移図（stateDiagram-v2） |
| [`reverse-engineering/usecase.mmd`](./reverse-engineering/usecase.mmd) | ユースケース図（flowchart TB） |

## 更新方針（図とコードの追従）

- **正典は設計書**: 仕様の一次情報は `freelance-receipt-organizer-demo_設計書.md`。齟齬が生じた場合は設計書を基準に本ディレクトリを更新する。
- **コード変更に図を追従させる**: DBスキーマ・エンドポイント・処理フローを変更したら、同一 PR 内で `SPEC/` 配下の該当図・API仕様を更新する。図（`.mmd`）を更新したら `npm run docs:render` で SVG を再生成する（手順は `reverse-engineering/README.md`）。
- **機能仕様（F1〜F8）との対応を保つ**: 各 API 仕様は関連する機能番号を明記し、トレーサビリティを維持する。
- **セッション分離の原則を徹底**: 所有リソースは常に `session_id` で強制フィルタし、他セッションのアクセスは 404（存在有無を漏らさない）で遮断する方針を全 API 仕様で守る。

## デモ版の制約（要点）

- 外部API・APIキー不使用（OCR・PDF生成ともローカルライブラリ）。
- ユーザー認証・認可なし。セッションは Cookie（HttpOnly）＋ SQLite。
- DB・アップロード画像は JST 03:00 に毎日自動リセット。
- 個人情報（氏名・住所・電話番号等）は収集・保存しない。電話番号パターンは OCR 結果から破棄する。
- 文字コードは UTF-8、時刻は JST。
