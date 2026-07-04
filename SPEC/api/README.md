# API 仕様

本ディレクトリは、freelance-receipt-organizer-demo（デモ版）の API 仕様を管理します。仕様は設計書（`freelance-receipt-organizer-demo_設計書.md`）のシーケンス図・機能仕様（F1〜F8）・ER図を正典とします。

## 共通方針

- **セッション分離（F6）**: 全リクエストは Cookie の `session_id` により所有者を判定する。所有リソース（receipts / reports）へのアクセスは常に `WHERE session_id = ?` で強制フィルタし、他セッションのリソースID指定・直打ちは存在有無を漏らさず一律 **404** を返す。Cookie 削除時は新規セッション扱いとし旧データへは到達不能。
- **エラー設計（CLAUDE.md 準拠）**: フォールバック禁止。エラーは握りつぶさず明示的に返却し、例外は分類してレスポンスへ反映する。デバッグ用に `trace_id` を全エラーレスポンスへ付与し、サーバログと突合できるようにする。
- **バリデーション**: 入力不正は 400、意味的に処理不能な内容は 422、リソース不明・他セッションは 404 を返す。
- **文字コード/時刻**: UTF-8、時刻は JST。日次リセット（F7）で全データが JST 03:00 に消える点に留意。

## エラーレスポンス共通形式

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "ファイル形式が不正です。JPEG または PNG を指定してください。",
    "details": [
      { "field": "file", "reason": "unsupported_content_type" }
    ],
    "trace_id": "b1f2c3d4-e5a6-4789-9abc-0123456789ab"
  }
}
```

## エンドポイント一覧

| タイトル | メソッド | エンドポイント | 仕様書 | 関連機能 |
|---|---|---|---|---|
| セッション発行 | GET | `/session` | [session.md](./session.md) | F6 |
| 領収書アップロード | POST | `/receipts` | [receipts.md](./receipts.md) | F1 / F2 / F3 / F8 |
| 領収書一覧 | GET | `/receipts` | [receipts.md](./receipts.md) | F2 / F6 |
| 領収書手動修正 | PATCH | `/receipts/:id` | [receipts.md](./receipts.md) | F2 / F3 |
| 勘定科目マスタ取得 | GET | `/categories` | [categories.md](./categories.md) | F3 |
| 集計取得 | GET | `/aggregations` | [aggregations.md](./aggregations.md) | F4 |
| 帳票生成 | POST | `/reports` | [reports.md](./reports.md) | F5 |
| 帳票PDFダウンロード | GET | `/reports/:id.pdf` | [reports.md](./reports.md) | F5 / F6 |
| OCR（内部API） | POST | `/ocr` | [ocr.md](./ocr.md) | F1 / F2 |

`/ocr` は FastAPI の内部 API であり、Rails からのローカル間通信でのみ呼び出される（外部公開しない）。
