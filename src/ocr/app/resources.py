"""利用者向けメッセージの外部リソース読み込み。

メッセージ文字列はコードに埋め込まず、resources/messages.<locale>.json から読み込む。
将来の多言語化のためロケール指定で切り替えられる構造にする。
"""
from __future__ import annotations

import json
from pathlib import Path


class MessageCatalog:
    """メッセージカタログ。

    ロケール別の JSON からメッセージを読み込み、キーで参照する。
    リソース不在・キー不在はフォールバックせず明示的に例外を送出する。
    """

    def __init__(self, messages: dict) -> None:
        self._messages = messages

    @classmethod
    def load(cls, locale: str) -> "MessageCatalog":
        """指定ロケールのメッセージリソースを読み込む。"""
        resource_dir = Path(__file__).resolve().parent.parent / "resources"
        path = resource_dir / f"messages.{locale}.json"
        if not path.exists():
            raise FileNotFoundError(
                f"message resource not found: {path}"
            )
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
        return cls(data)

    def error_message(self, code: str) -> str:
        """エラーコードに対応する利用者向けメッセージを返す。

        未定義コードはフォールバックせず KeyError を送出する。
        """
        return self._messages["errors"][code]
