# セッション発行 API

初回アクセス時にセッションを発行する。関連機能: **F6 セッション分離**。

## エンドポイント

| 項目 | 値 |
|---|---|
| メソッド | GET |
| パス | `/session` |
| 認証 | なし（デモ版はユーザー認証・認可を持たない） |

## 概要

初回アクセス時に **UUID v4** のセッションIDを発行し、`SESSIONS` テーブルへ INSERT する。セッションIDは **HttpOnly・SameSite=Lax** の Cookie に保存する。既に有効な Cookie を持つ場合は既存セッションの `last_accessed_at` を更新（touch）し、同一セッションIDを返す。

セッションIDは端末識別子として扱い、個人情報は一切含めない。Cookie が削除された場合は次アクセスで新規セッションが発行され、旧データへは到達不能となる。

## リクエスト

- ボディなし。
- Cookie（任意）: `session_id=<UUID v4>`

## レスポンス（200 OK）

`Set-Cookie` ヘッダでセッションCookieを付与する。

```
Set-Cookie: session_id=3f8b1c2a-9d4e-4a1b-8c7f-2e5d6a7b8c9d; HttpOnly; SameSite=Lax; Path=/
```

```json
{
  "session_id": "3f8b1c2a-9d4e-4a1b-8c7f-2e5d6a7b8c9d",
  "created_at": "2026-07-04T10:15:00+09:00",
  "last_accessed_at": "2026-07-04T10:15:00+09:00",
  "is_new": true
}
```

- `is_new`: 新規発行なら `true`、既存セッションの touch なら `false`。

## Cookie 属性

| 属性 | 値 | 理由 |
|---|---|---|
| HttpOnly | 有効 | JavaScript からの読み取りを禁止しトークン漏洩を防ぐ |
| SameSite | Lax | CSRF 低減。通常遷移では送信、クロスサイトの副作用リクエストでは抑制 |
| Secure | 本番相当環境で有効 | HTTPS 経由のみ送信（デモ環境の設定に従う） |
| Path | `/` | 全 API で共有 |

## エラー

フォールバックは行わず、生成失敗時も握りつぶさず明示的に返す。

| ステータス | code | 条件 |
|---|---|---|
| 500 | `SESSION_CREATE_FAILED` | UUID 発行または `SESSIONS` INSERT に失敗（DB例外等）。`trace_id` をログと突合可能にする |

```json
{
  "error": {
    "code": "SESSION_CREATE_FAILED",
    "message": "セッションの作成に失敗しました。",
    "trace_id": "b1f2c3d4-e5a6-4789-9abc-0123456789ab"
  }
}
```

## 備考

- 発行済みセッション配下のデータは **F7 日次リセット（JST 03:00）** で全削除される。リセット直後のアクセスは新規セッションと同等に動作する。
