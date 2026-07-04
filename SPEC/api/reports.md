# 帳票 API

収支内訳書（白色申告）風の帳票を生成し、PDF をダウンロードする。関連機能: **F5 帳票生成 / F6 セッション分離**。

---

## POST /reports（帳票生成）

セッション配下の集計（F4）をもとに帳票を生成し、ReportLab で PDF を出力する。

### エンドポイント

| 項目 | 値 |
|---|---|
| メソッド | POST |
| パス | `/reports` |
| Content-Type | `application/json` |

### 概要

`WHERE session_id = ?`（F6）で対象年の領収書を月×科目集計し、**経費欄のみ**に集計値を自動転記する。売上・氏名・住所欄は空欄（またはダミー「（見本）」）とする。個人情報は一切出力しない。

帳票には注記「**本帳票は参考様式であり、実際の税務申告には使用できません**」を **必ず** 出力する（F5 / 免責）。**領収書 0 件の場合も経費 0 円の帳票を正常に生成**する。

### リクエスト（application/json）

```json
{ "target_year": 2026 }
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `target_year` | integer | 任意 | 対象年。省略時は当年（JST 基準） |

### 処理フロー

1. 対象年の集計を算出（aggregations.md と同一ロジック）。
2. ReportLab で収支内訳書（白色）風テンプレート（帳票テンプレートマスタ 1 件）へ描画。注記を必ず埋め込む。
3. PDF を保存し `pdf_path` を記録。`REPORTS` へ INSERT（`session_id` 付与）。
4. プレビュー用 HTML と PDF ダウンロードリンクを返す。

### レスポンス（201 Created）

```json
{
  "report": {
    "id": 7,
    "target_year": 2026,
    "generated_at": "2026-07-04T10:30:00+09:00",
    "pdf_url": "/reports/7.pdf",
    "grand_total_yen": 7460,
    "notice": "本帳票は参考様式であり、実際の税務申告には使用できません。"
  },
  "preview_html": "<section>...収支内訳書風プレビュー...</section>"
}
```

領収書 0 件でも `grand_total_yen` が `0` の帳票を 201 で返す（`notice` は常に含む）。

### エラー

| ステータス | code | 条件 |
|---|---|---|
| 400 | `INVALID_YEAR` | `target_year` が整数でない |
| 500 | `PDF_GENERATION_FAILED` | ReportLab での PDF 生成に失敗。フォールバック（空PDF等）はせず明示エラーとし `trace_id` をログ突合可能にする |

```json
{
  "error": {
    "code": "PDF_GENERATION_FAILED",
    "message": "帳票PDFの生成に失敗しました。",
    "trace_id": "b1f2c3d4-e5a6-4789-9abc-0123456789ab"
  }
}
```

---

## GET /reports/:id.pdf（PDFダウンロード）

生成済み帳票の PDF バイナリを返す。

### エンドポイント

| 項目 | 値 |
|---|---|
| メソッド | GET |
| パス | `/reports/:id.pdf` |

### レスポンス（200 OK）

- `Content-Type: application/pdf`
- `Content-Disposition: attachment; filename="report-2026.pdf"`
- ボディ: PDF バイナリ。

### エラー

| ステータス | code | 条件 |
|---|---|---|
| 404 | `REPORT_NOT_FOUND` | 指定IDが存在しない、**または他セッションの帳票**（F6。存在有無を漏らさない） |
| 410 | `REPORT_EXPIRED` | 日次リセット（F7, JST 03:00）で `pdf_path` の実体が削除済み。DB レコードとファイル不整合を握りつぶさず明示 |

```json
{
  "error": {
    "code": "REPORT_NOT_FOUND",
    "message": "指定された帳票は存在しません。",
    "trace_id": "b1f2c3d4-e5a6-4789-9abc-0123456789ab"
  }
}
```

他セッションのIDを直打ちされた場合も、存在するIDと同じ 404 `REPORT_NOT_FOUND` を返し、存在有無を漏らさない。

## 備考

- 生成された帳票・PDF は F7 日次リセット（JST 03:00）で全削除される。永続利用は対象外。
