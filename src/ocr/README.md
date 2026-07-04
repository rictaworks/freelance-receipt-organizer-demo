# OCR サービス（FastAPI 内部 API）

領収書画像を OCR し、全文テキストと信頼度を返す FastAPI 内部 API（機能 F1／F2 前段）。
Rails からのローカル間通信でのみ呼び出す。外部公開しない。外部 API・API キーは不使用で、
OpenCV＋pytesseract のローカルライブラリのみで完結する。正典契約は
`SPEC/api/ocr.md`、共通エラー形式は `SPEC/api/README.md` を参照。

## 契約要約（POST /ocr）

- 入力: `multipart/form-data` の `file`（JPEG/PNG）。
- 処理: OpenCV 前処理（グレースケール化→傾き補正(deskew)→二値化→ノイズ除去）→
  pytesseract（`jpn+eng`）で全文テキストと信頼度（0.0〜1.0）を取得。
- 個人情報保護（設計書 1.4）: 電話番号パターンを `full_text` から破棄し、レスポンスにも
  ログにも残さない。破棄件数のみ `discarded.phone_numbers` に返す。金額（¥1,480 等）は保持。
- 200 レスポンス:

  ```json
  {
    "full_text": "…",
    "confidence": 0.82,
    "preprocess": {"grayscale": true, "deskew_applied": true, "binarized": true, "denoised": true},
    "discarded": {"phone_numbers": 1}
  }
  ```

- エラー（フォールバック禁止・段階特定可能・全て `trace_id` 付き）:
  - 400 `IMAGE_DECODE_FAILED`: OpenCV でデコード不能（破損・非画像）。
  - 422 `PREPROCESS_FAILED`: 前処理段階の例外。`details[0].stage` に
    `grayscale`/`deskew`/`binarize`/`denoise` を格納。
  - 500 `TESSERACT_FAILED`: pytesseract 実行失敗（バイナリ／言語データ欠落等）。
  - 形式: `{"error": {"code", "message", "details"?, "trace_id"}}`。

## 依存の前提

- Python 3.12、tesseract 5.x（言語データ `jpn`・`eng`）が導入済みであること。
- Python 依存は `requirements.txt` 参照（`pip install -r requirements.txt`）。

## 起動

```bash
cd src/ocr
uvicorn app.main:app --port 8000
```

## テスト

```bash
cd src/ocr
python3 -m pytest -q
```

- 実画像 OCR テストは PIL（DejaVuSans）で生成した英数字画像を使用する
  （実行環境に日本語フォントが無いため）。
- 電話番号スクラブと金額保持は文字列処理の単体テストで担保する。
- `tests/test_no_hardcoded_messages.py` で、`app/*.py` に利用者向け日本語メッセージが
  ベタ書きされていないこと（docstring・コメントは対象外）を検証する。

## 設定（環境変数）

| 変数 | 既定 | 説明 |
|---|---|---|
| `APP_ENV` | `development` | 実行環境（開発／本番分岐の余地） |
| `TESSERACT_LANG` | `jpn+eng` | pytesseract 言語指定 |
| `OCR_MESSAGE_LOCALE` | `ja` | メッセージリソースのロケール |
| `OCR_MIN_CONFIDENCE_FLOOR` | `0.0` | 信頼度の下限 |

## 責務分割

| ファイル | 責務 |
|---|---|
| `app/config.py` | 環境変数からの設定生成 |
| `app/resources.py` | メッセージ外部リソース読み込み |
| `app/logging_setup.py` | 構造化ログ（trace_id 付き） |
| `app/errors.py` | エラー分類とコード／HTTP ステータス対応 |
| `app/phone_filter.py` | 電話番号スクラブ（個人情報保護） |
| `app/preprocessing.py` | OpenCV 前処理と段階トレース |
| `app/ocr_engine.py` | pytesseract 実行と信頼度算出 |
| `app/service.py` | デコード→前処理→OCR→スクラブのオーケストレーション |
| `app/main.py` | FastAPI アプリとエラー→共通形式マッピング |
| `resources/messages.<locale>.json` | 利用者向けメッセージ（多言語化構造） |
