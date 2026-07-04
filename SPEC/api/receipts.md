# 領収書 API

領収書のアップロード・一覧・手動修正を提供する。関連機能: **F1 画像受付＋前処理 / F2 項目抽出 / F3 勘定科目分類 / F8 ハニーポット / F6 セッション分離**。

すべての操作は Cookie の `session_id` で強制フィルタされ、他セッションのリソースID指定は **404** を返す（存在有無を漏らさない）。

---

## POST /receipts（アップロード）

領収書画像を受け付け、前処理→OCR→項目抽出→科目分類→登録までを実行する。

### エンドポイント

| 項目 | 値 |
|---|---|
| メソッド | POST |
| パス | `/receipts` |
| Content-Type | `multipart/form-data` |

### リクエスト（multipart/form-data）

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `file` | file | 必須 | 領収書画像。**JPEG または PNG のみ**、1ファイル **10MB 以下**（F1） |
| `website` | string | 任意 | **ハニーポット用不可視フィールド（F8）**。通常ユーザーは空。値が入っていれば Bot とみなす |

### ハニーポット挙動（F8）

`website`（不可視フィールド）に値がある場合、サーバは **HTTP 200 を返しつつ処理を無言で破棄**する。DB への登録・OCR 呼び出しは一切行わない。レスポンス本文は正常時と区別できない体裁とし、Bot に破棄を悟らせない。

```json
{ "status": "accepted" }
```

### 正常処理フロー

1. サイズ/形式検証（F1）。超過・非対応形式は即時拒否。
2. 原本画像を画像ストレージへ保存し `image_path` を記録。
3. FastAPI 内部 API `POST /ocr`（[ocr.md](./ocr.md)）へローカル間通信で画像送信。全文テキスト＋信頼度を取得。
4. 項目抽出（F2）: 日付（西暦/和暦、年省略補完）・金額（ラベル辞書優先、¥/カンマ/円除去）・店名（先頭3行の最長行）。抽出不能な項目は `null`。
5. 科目分類（F3）: 店名＋OCR全文にキーワードルールをマッチ。優先度→出現回数→科目コード昇順でタイ解決。マッチなしは `category_id = null`（未分類）。
6. 重複検知（F2）: 日付＋金額＋店名が既存レコードと完全一致なら警告（登録可否はユーザー判断）。
7. `RECEIPTS` へ INSERT（`session_id` を付与）。

### 警告（warnings）

登録は行いつつ、以下を `warnings` に付して確認フローへ回す。

| コード | 条件（機能） |
|---|---|
| `duplicate` | 日付＋金額＋店名が既存と完全一致（F2） |
| `non_positive_amount` | 金額が 0 円以下＝返品等。自動登録扱いだが要確認（F2） |
| `uncategorized` | 分類キーワードにマッチせず未分類（F3） |
| `low_confidence_manual_input` | 信頼度低かつ日付・金額とも抽出不能。手動入力フォームへ誘導（F1） |

### レスポンス（201 Created）

```json
{
  "receipt": {
    "id": 42,
    "issued_on": "2026-06-30",
    "amount_yen": 1480,
    "store_name": "タクシー株式会社",
    "category_id": 2,
    "category_name": "旅費交通費",
    "ocr_confidence": 0.82,
    "image_path": "/uploads/3f8b1c2a/42.png",
    "manually_edited": false,
    "created_at": "2026-07-04T10:20:00+09:00"
  },
  "warnings": [
    { "code": "duplicate", "message": "同一の日付・金額・店名のレコードが既に存在します。" }
  ]
}
```

日付・金額の抽出に失敗した場合は該当フィールドが `null` となり、`warnings` に `low_confidence_manual_input` を含めてフロントの手動入力フォームへ誘導する。

### エラー

| ステータス | code | 条件 |
|---|---|---|
| 400 | `FILE_MISSING` | `file` が未指定 |
| 413 | `FILE_TOO_LARGE` | 10MB 超過（F1） |
| 415 | `UNSUPPORTED_MEDIA_TYPE` | JPEG/PNG 以外（F1） |
| 422 | `OCR_UNRECOGNIZABLE` | 「レシートとして認識できません」。信頼度未満かつ日付・金額とも抽出不能で手動入力にも誘導不能な場合（F1） |
| 502 | `OCR_SERVICE_UNAVAILABLE` | FastAPI 内部 API 呼び出し失敗。フォールバック分類はせず明示エラー |

```json
{
  "error": {
    "code": "UNSUPPORTED_MEDIA_TYPE",
    "message": "JPEG または PNG のみ対応しています。",
    "details": [{ "field": "file", "reason": "unsupported_content_type" }],
    "trace_id": "b1f2c3d4-e5a6-4789-9abc-0123456789ab"
  }
}
```

---

## GET /receipts（一覧）

セッション配下の領収書一覧を取得する。`WHERE session_id = ?` で強制フィルタ（F6）。

### リクエスト

| クエリ | 型 | 必須 | 説明 |
|---|---|---|---|
| `year` | integer | 任意 | 対象年で絞り込み（例: `2026`） |
| `category_id` | integer | 任意 | 科目で絞り込み。`0` または `null` 指定で未分類 |

### レスポンス（200 OK）

```json
{
  "receipts": [
    {
      "id": 42,
      "issued_on": "2026-06-30",
      "amount_yen": 1480,
      "store_name": "タクシー株式会社",
      "category_id": 2,
      "category_name": "旅費交通費",
      "ocr_confidence": 0.82,
      "manually_edited": false
    }
  ],
  "count": 1
}
```

0 件でも 200 で空配列を返す。

---

## PATCH /receipts/:id（手動修正・科目変更）

抽出結果や勘定科目をユーザーが手動修正する（F2 / F3）。修正時は `manually_edited = true` にする。

### リクエスト（application/json）

```json
{
  "issued_on": "2026-06-30",
  "amount_yen": 1480,
  "store_name": "タクシー株式会社",
  "category_id": 3
}
```

- いずれのフィールドも任意（部分更新）。`category_id` の変更で科目を切り替える。`null` を指定すると未分類に戻す。

### レスポンス（200 OK）

```json
{
  "receipt": {
    "id": 42,
    "issued_on": "2026-06-30",
    "amount_yen": 1480,
    "store_name": "タクシー株式会社",
    "category_id": 3,
    "category_name": "通信費",
    "manually_edited": true
  }
}
```

### エラー

| ステータス | code | 条件 |
|---|---|---|
| 404 | `RECEIPT_NOT_FOUND` | 指定IDが存在しない、**または他セッションのリソース**（F6。存在有無を漏らさない） |
| 422 | `INVALID_CATEGORY` | `category_id` が `ACCOUNT_CATEGORIES`（12件）に存在しない |
| 422 | `INVALID_AMOUNT` | `amount_yen` が整数でない。0 円以下は警告扱いだが手動確定は許容 |
| 400 | `INVALID_DATE_FORMAT` | `issued_on` が `YYYY-MM-DD` 形式でない |

```json
{
  "error": {
    "code": "RECEIPT_NOT_FOUND",
    "message": "指定された領収書は存在しません。",
    "trace_id": "b1f2c3d4-e5a6-4789-9abc-0123456789ab"
  }
}
```

他セッションのIDを直打ちされた場合も、存在するIDと同じ 404 `RECEIPT_NOT_FOUND` を返し、リソースの存在有無を漏らさない。
