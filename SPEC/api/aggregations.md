# 集計 API

セッション配下の領収書を月×勘定科目で集計する。関連機能: **F4 集計 / F6 セッション分離**。

## エンドポイント

| 項目 | 値 |
|---|---|
| メソッド | GET |
| パス | `/aggregations` |

## 概要

Cookie の `session_id` 配下の `RECEIPTS` を対象に、`WHERE session_id = ?` で強制フィルタ（F6）した上で、「**月×勘定科目**」でグルーピング合計し、科目別年間合計・総合計を算出する。金額はすべて **整数円** で扱う（F4）。未分類（`category_id = null`）も独立した区分として集計する。

## リクエスト

| クエリ | 型 | 必須 | 説明 |
|---|---|---|---|
| `year` | integer | 任意 | 対象年（例: `2026`）。省略時は当年（JST 基準） |

## レスポンス（200 OK）

```json
{
  "target_year": 2026,
  "months": [
    {
      "month": 6,
      "categories": [
        { "category_id": 2, "category_name": "旅費交通費", "total_yen": 1480 },
        { "category_id": 3, "category_name": "通信費", "total_yen": 5980 }
      ],
      "month_total_yen": 7460
    }
  ],
  "category_yearly_totals": [
    { "category_id": 2, "category_name": "旅費交通費", "total_yen": 1480 },
    { "category_id": 3, "category_name": "通信費", "total_yen": 5980 },
    { "category_id": null, "category_name": "未分類", "total_yen": 0 }
  ],
  "grand_total_yen": 7460
}
```

- `months`: 対象年で領収書が存在する月のみ含む（データが無い月は省略）。
- `category_yearly_totals`: 科目別の年間合計。
- `grand_total_yen`: 総合計（整数円）。
- 領収書 0 件の場合は `months` は空配列、`grand_total_yen` は `0` を返す（200）。

## エラー

| ステータス | code | 条件 |
|---|---|---|
| 400 | `INVALID_YEAR` | `year` が整数でない、または妥当な範囲外 |

```json
{
  "error": {
    "code": "INVALID_YEAR",
    "message": "year は西暦の整数で指定してください。",
    "details": [{ "field": "year", "reason": "not_an_integer" }],
    "trace_id": "b1f2c3d4-e5a6-4789-9abc-0123456789ab"
  }
}
```

## 備考

- 本集計値は帳票生成（F5, [reports.md](./reports.md)）の経費欄へ自動転記される。
- 集計対象は常にリクエスト元セッションのデータのみ。他セッションのデータは一切混入しない。
