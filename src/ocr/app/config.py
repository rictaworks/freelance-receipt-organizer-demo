"""OCR サービスの設定。

設定は環境変数から読み込む（グローバル変数を使わず、明示的に生成する）。
APP_ENV により開発／本番の分岐余地を残す。文字列リテラルの既定値のみを持つ。
"""
from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    """実行時設定（不変）。

    Attributes:
        app_env: 実行環境識別子（development / production 等）。
        tesseract_lang: pytesseract に渡す言語指定。
        locale: メッセージリソースのロケール。
        min_confidence_floor: 信頼度の下限（0.0〜1.0 に丸める際の床）。
    """

    app_env: str
    tesseract_lang: str
    locale: str
    min_confidence_floor: float

    @staticmethod
    def from_env() -> "Settings":
        """環境変数から設定を構築する。

        欠落時は既定値を用いるが、これはフォールバックではなく明示的な既定である
        （抽出・分類結果の握りつぶしは行わない）。
        """
        return Settings(
            app_env=os.environ.get("APP_ENV", "development"),
            tesseract_lang=os.environ.get("TESSERACT_LANG", "jpn+eng"),
            locale=os.environ.get("OCR_MESSAGE_LOCALE", "ja"),
            min_confidence_floor=float(os.environ.get("OCR_MIN_CONFIDENCE_FLOOR", "0.0")),
        )
