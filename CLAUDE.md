# CLAUDE.md

このファイルは Claude Code（claude.ai/code）がこのリポジトリで作業する際の指針を与える。
毎セッションの冒頭で読み込まれるため、記述は簡潔に保つ。詳細は各参照ファイルへ委譲する。

- 時刻はすべて **JST**、文字エンコードはすべて **UTF-8** を前提とする。
- 応答・ドキュメント・コメントは日本語で書く（多言語対応の方針は下記 i18n を参照）。

---

## 0. 安全ルール（最優先・全会話で厳守）

### 削除系コマンドの禁止（重要）
- Claude はファイルまたはディレクトリを削除するコマンドを一切生成してはならない。
  例：`rm`, `rm -rf`, `rm *`, `rmdir`, `unlink`, `cache --delete`,
  `lftp mirror --delete`, `rsync --delete`, `git clean -df`, `find -delete` 等。
- 削除が必要な場合でも削除コマンドを提案せず、「手動で削除してください」という説明に留める。
- 削除の推奨・削除操作の自動判断も禁止。
- ssh / lftp / デプロイ系スクリプトを生成する場合でも削除コマンドの生成は禁止。
- 不要ファイルは削除せず **`DELETE/`（ゴミ箱）へ移動** する運用とする。

### シークレット管理（重要）
- `config/master.key` など機密ファイルを `git add` するコードを生成してはならない（デプロイ・セットアップ手順でも同様）。
- シークレットは必ず環境変数（`RAILS_MASTER_KEY` 等）で渡す。詳細は @.claude/development-principles.md のセキュリティ原則に従う。
- `.gitignore` への追加を確認する手順を必ずコードに含める。
- 初回コミット前に `git status` でステージング確認を促す。

---

## 1. プロジェクト概要

フリーランス向け「領収書自動整理＋申告書作成」サービスのデモ版（ショーケース）。
仕様・データモデル・各種図（ER/DFD/シーケンス/クラス/状態遷移/ユースケース）は
`freelance-receipt-organizer-demo_設計書.md` および `SPEC/` を正典とする。

- 技術構成：フロント Next.js／バック Rails（API・集計・帳票）／OCR FastAPI（OpenCV＋pytesseract、外部API不使用）／DB SQLite（デモ版固定）／PDF ReportLab。
- 認証なし・セッションID（UUID v4, HttpOnly Cookie）を全テーブルのオーナーキーとし全クエリで強制フィルタ。他セッション参照は 404。
- 個人情報は一切収集・保存しない。DBと画像は JST 03:00 に日次リセット。

---

## 2. ブランチ・PR 運用（厳守）

- **`main` ブランチでの作業を禁止**する。作業は必ずブランチを切って行う。
- `src/*` **以外**の変更（ドキュメント・設定・図・タスク等）は `main` への push を許可する。
- `src/*` の変更は **必ず PR を作成**する（`main` への直接 push 禁止）。
- **commit する前に必ず security review** を行う（@.claude/OWASP10.md 準拠、`/security-review`）。
- PR 本文はすべて日本語。**非エンジニア向けのユーザーテスト手順を丁寧に書く**（@.claude/agents/pr-checker.md）。

---

## 3. 開発プロセス：TDD 厳守

ワークフローは **plan → red test → coding → green test** の順を厳守する。

- テストフレームワーク：Rails=RSpec、JS=Jest、Python=pytest 等（@.claude/TM.md）。
- テストは `test/pr***/`（PR番号ごと）に作成し、**対象は開発サーバー**とする。
- フロントの動作確認は `curl` / `wget --mirror` / Playwright で行う。
- テスト観点は @.claude/TM.md、品質は @.claude/QC10.md（QC01〜QC10）を満たす。

---

## 4. コーディング規約（厳守）

- **フォールバック禁止**。例外処理を明示的にしっかり書く（握りつぶし・暗黙のデフォルト復帰をしない）。
- **デバッグトレース可能に書く**（構造化ログ・トレースID・十分な文脈を残す）。
- 制御構文・条件構文以外のロジックは **必ずクラスまたは関数** に収める。
- **グローバル変数を禁止**（セキュリティ観点）。
- **文字列リテラルは設定ファイル／DB に分離**する。ハードコードを検出するテストを書く。
- 設計原則は @.claude/development-principles.md（YAGNI/KISS/DRY/SOLID/Fail Fast 等）に従う。
- 環境変数は `.env` を参照する（@ENV/DEVELOPMENT.md ／ @ENV/PRODUCTION.md）。

---

## 5. UI / UX 規約（厳守）

- デフォルトアイコンは **Font Awesome** を使用する。**絵文字は禁止**。
- ネイティブの `alert()` / `confirm()` / `prompt()` は **プロジェクト全体で使用禁止**（独自 UI に置き換える）。
- 事前デザイン指定がある場合は `app-ui/` のモックに従う（`app-ui/` は読み取り専用）。
- デザイン4原則 @.claude/CRAP.md（Contrast/Repetition/Alignment/Proximity）を満たす。

---

## 6. 環境判定・認証

- 環境判定を**必ず実装**し、開発／本番で分岐できるようにする。
- テスト可能にするため、**開発環境は「認証済み」に分岐**する。
- 本番の認証は **Google ログイン**（自社開発方針）。

---

## 7. アーキテクチャ・デプロイ（自社開発方針）

- 規模に応じてマイクロサービス／MVC／API Gateway／メッセージングを意識する。
- 安全なライブラリ・OSS・SaaS を優先し、車輪の再発明を避けオリジナルコードを最小化する。
- 基本スタックは **Next + Rails + PostgreSQL**（本デモの DB は SQLite 固定）。
  必要に応じ AI・解析・画像加工は **FastAPI**、高速並列・リアルタイム通信は **Gin** で API を作ってよい。
- デプロイ：フロントは無料 **Vercel**、バックエンド・管理画面は無料 **Railway（または Render）**。
- ドメインは原則 **rictaworks.jp のサブドメイン**。
- ウェブはデプロイ以降、デスクトップ／スマホはビルド以降、ESP32 は焼き込み以降を Claude Desktop で作業する。
- 画像は AI 生成。プロのライティングは writer エージェントに担当させる。

---

## 8. 多言語対応（i18n）

- 当初から多言語で開発する：**日本語・英語・フランス語・中国語・ロシア語・スペイン語・アラビア語**。
- ただし開発者用の管理画面は **日本語のみ**。
- 文字列はコードに埋め込まず、翻訳リソース／設定ファイル／DB に分離する（§4 と整合）。

---

## 9. ドキュメント・ディレクトリ管理

各ディレクトリを継続的に管理・更新する（各 `README.md` に運用を記載）。

| ディレクトリ | 用途 |
|---|---|
| `TASKS/` | タスク管理 |
| `DEBUG/` | バグ報告 |
| `CLIENT/` | クライアント要望等 |
| `WORK/` | 作業報告 |
| `ENV/` | 開発環境（DEVELOPMENT.md）・本番環境（PRODUCTION.md） |
| `SPEC/` | 仕様書＋リバースエンジニアリング（ER図・DFD・シーケンス図・クラス図・状態遷移図・ユースケース図） |
| `DELETE/` | ゴミ箱（削除の代わりにここへ移動） |
| `test/` | PR ごとのテスト（`test/pr***/`） |
| `app-ui/` | デザインモック（読み取り専用） |

- 図解は **mermaid** で記述し（`SPEC/`）、`@mermaid-js/mermaid-cli`（`mmdc`）でレンダリングする。
- リバースエンジニアリング図はコードの変更に追従して更新する。

---

## 10. エージェント運用

規模に応じて次のサブエージェントを使い分ける（定義は `.claude/agents/`）：
director / project-manager / designer / debugger / tester / data-scientist / deployer / writer / service-manager / pr-checker。

---

## 参照ファイル
- 設計原則：@.claude/development-principles.md
- デザイン4原則（DC）：@.claude/CRAP.md
- 品質10項目：@.claude/QC10.md
- テスト手法：@.claude/TM.md
- セキュリティ（QA/OWASP Top 10）：@.claude/OWASP10.md
- CLAUDE.md 自動最適化：@.claude/auto-optimizer.md
