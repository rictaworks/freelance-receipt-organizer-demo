"""構造化ログの設定。

全エラーで trace_id を含む JSON 風ログを出力し、レスポンスの trace_id と
サーバログを突合可能にする。グローバル変数は使わず、ロガーを取得して返す。
"""
from __future__ import annotations

import json
import logging
import sys


class _JsonFormatter(logging.Formatter):
    """ログレコードを JSON 文字列へ整形するフォーマッタ。"""

    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        # 構造化フィールド（trace_id / stage / code 等）を付与する。
        for key in ("trace_id", "stage", "code", "event"):
            value = getattr(record, key, None)
            if value is not None:
                payload[key] = value
        if record.exc_info:
            payload["exc"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False)


def get_logger(name: str = "ocr") -> logging.Logger:
    """JSON フォーマッタ付きロガーを取得する（多重ハンドラを避ける）。"""
    logger = logging.getLogger(name)
    if not logger.handlers:
        handler = logging.StreamHandler(stream=sys.stderr)
        handler.setFormatter(_JsonFormatter())
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
        logger.propagate = False
    return logger
