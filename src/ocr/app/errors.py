"""OCR サービスのエラー定義。

フォールバック禁止。各失敗段階を明示的に分類し、SPEC/api/README.md 共通形式
（{"error":{"code","message","details"?,"trace_id"}}）へマッピングする。
"""
from __future__ import annotations

import uuid
from typing import Optional


# エラーコードと HTTP ステータスの対応（文字列キーは識別子でありメッセージではない）。
IMAGE_DECODE_FAILED = "IMAGE_DECODE_FAILED"
PREPROCESS_FAILED = "PREPROCESS_FAILED"
TESSERACT_FAILED = "TESSERACT_FAILED"

_STATUS_BY_CODE = {
    IMAGE_DECODE_FAILED: 400,
    PREPROCESS_FAILED: 422,
    TESSERACT_FAILED: 500,
}


class OcrError(Exception):
    """OCR 処理の分類済み例外。

    Attributes:
        code: エラーコード（上記定数のいずれか）。
        details: 追加情報のリスト（前処理失敗段階など）。任意。
        trace_id: サーバログと突合するための識別子（uuid4）。
    """

    def __init__(
        self,
        code: str,
        details: Optional[list[dict]] = None,
        trace_id: Optional[str] = None,
    ) -> None:
        super().__init__(code)
        self.code = code
        self.details = details
        self.trace_id = trace_id or str(uuid.uuid4())

    @property
    def http_status(self) -> int:
        """このエラーに対応する HTTP ステータスを返す。"""
        return _STATUS_BY_CODE[self.code]
