"""ハードコード文字列検出テスト（CLAUDE.md §4 準拠）。

利用者向けメッセージはコードに埋め込まず resources へ分離する方針を守るため、
app/*.py の文字列リテラルに日本語（利用者向けメッセージ）が無いことを検出する。
docstring・コメントは対象外（日本語ドキュメントは方針上許容）。
"""
from __future__ import annotations

import ast
from pathlib import Path

_APP_DIR = Path(__file__).resolve().parent.parent / "app"

# 日本語（ひらがな・カタカナ・CJK 統合漢字）の範囲。
_JP_RANGES = (
    (0x3040, 0x309F),  # ひらがな
    (0x30A0, 0x30FF),  # カタカナ
    (0x4E00, 0x9FFF),  # CJK 統合漢字
)


def _contains_japanese(text: str) -> bool:
    for ch in text:
        code = ord(ch)
        for lo, hi in _JP_RANGES:
            if lo <= code <= hi:
                return True
    return False


def _docstring_nodes(tree: ast.AST) -> set[int]:
    """モジュール／関数／クラスの docstring となる文字列ノードの id 集合。"""
    ids: set[int] = set()
    for node in ast.walk(tree):
        if isinstance(
            node,
            (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef),
        ):
            body = getattr(node, "body", [])
            if (
                body
                and isinstance(body[0], ast.Expr)
                and isinstance(body[0].value, ast.Constant)
                and isinstance(body[0].value.value, str)
            ):
                ids.add(id(body[0].value))
    return ids


def test_no_japanese_string_literals_in_app_sources():
    offenders: list[str] = []
    for py in sorted(_APP_DIR.glob("*.py")):
        source = py.read_text(encoding="utf-8")
        tree = ast.parse(source)
        doc_ids = _docstring_nodes(tree)
        for node in ast.walk(tree):
            if isinstance(node, ast.Constant) and isinstance(node.value, str):
                if id(node) in doc_ids:
                    continue
                if _contains_japanese(node.value):
                    offenders.append(f"{py.name}:{node.lineno}: {node.value!r}")
    assert not offenders, (
        "日本語メッセージのハードコードを検出しました:\n" + "\n".join(offenders)
    )
