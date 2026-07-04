# OCR API（FastAPI 内部API）

領収書画像を OCR し、全文テキストと信頼度を返す。関連機能: **F1 画像受付＋前処理 / F2 項目抽出**。

本 API は **FastAPI の内部 API** であり、Rails からの **ローカル間通信**でのみ呼び出される。外部公開しない（ブラウザから直接叩かせない）。外部API・APIキーは一切使用せず、OpenCV＋pytesseract のローカルライブラリで完結する。

## エンドポイント

| 項目 | 値 |
|---|---|
| メソッド | POST |
| パス | `/ocr` |
| Content-Type | `multipart/form-data` または `application/octet-stream` |
| 公開範囲 | 内部（Rails からのみ） |

## 概要

受け取った画像に対し **OpenCV で前処理**（グレースケール化→傾き補正→二値化→ノイズ除去）を行い、**pytesseract（jpn＋eng）**で全文テキストと信頼度スコアを取得する（F1）。

個人情報保護（設計書 1.4）のため、**電話番号パターンに一致する文字列は抽出結果から破棄し、レスポンスにも DB にも残さない**。郵便番号等の識別子も後段（F2 店名抽出）で除外対象として扱う。

## リクエスト

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `file` | file/binary | 必須 | 前処理対象の領収書画像（JPEG/PNG）。サイズ・形式の一次検証は呼び出し元 Rails（F1）で実施済み |

## レスポンス（200 OK）

```json
{
  "full_text": "タクシー株式会社\n2026/06/30\n合計 ¥1,480\n...",
  "confidence": 0.82,
  "preprocess": {
    "grayscale": true,
    "deskew_applied": true,
    "binarized": true,
    "denoised": true
  },
  "discarded": {
    "phone_numbers": 1
  }
}
```

- `full_text`: OCR 全文テキスト（電話番号パターンは除去済み）。
- `confidence`: 0.0〜1.0 の信頼度スコア。呼び出し元は閾値未満かつ日付・金額とも抽出不能なら「レシートとして認識できません」を返す（F1）。
- `preprocess`: 適用した前処理のトレース（デバッグ可能性のため明示）。
- `discarded.phone_numbers`: 破棄した電話番号パターンの件数（保存はしない、件数のみ）。

## エラー

フォールバック禁止。前処理・OCR の失敗は握りつぶさず、段階を特定できる形で明示的に返す（CLAUDE.md 準拠）。

| ステータス | code | 条件 |
|---|---|---|
| 400 | `IMAGE_DECODE_FAILED` | OpenCV で画像デコード不能（破損・非画像バイト列） |
| 422 | `PREPROCESS_FAILED` | 前処理段階での例外（傾き補正・二値化等）。失敗した段階を `details.stage` で示す |
| 500 | `TESSERACT_FAILED` | pytesseract 実行失敗（バイナリ未導入・言語データ欠落等） |

```json
{
  "error": {
    "code": "PREPROCESS_FAILED",
    "message": "画像の前処理に失敗しました。",
    "details": [{ "stage": "deskew" }],
    "trace_id": "b1f2c3d4-e5a6-4789-9abc-0123456789ab"
  }
}
```

## 備考

- 本 API は分類（F3）・集計（F4）を行わない。抽出は呼び出し元 Rails 側の FieldExtractor が `full_text` を用いて実施する。
- 認識できないケース（信頼度低＋日付金額とも抽出不可）の最終判定は Rails 側（F1）が担い、手動入力フォームへ誘導する。
