"""pytest 共通設定・フィクスチャ。

src/ocr をパッケージルートとして解決できるよう sys.path を通す。
テスト用画像は PIL で生成する（英数字＋記号中心。日本語フォント非依存）。
"""
from __future__ import annotations

import io
import sys
from pathlib import Path

import pytest
from PIL import Image, ImageDraw, ImageFont

# src/ocr をインポートパスに追加する。
_OCR_ROOT = Path(__file__).resolve().parent.parent
if str(_OCR_ROOT) not in sys.path:
    sys.path.insert(0, str(_OCR_ROOT))

_FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def _render_png(lines: list[str], size=(700, 360)) -> bytes:
    """複数行テキストを描画した PNG バイト列を生成する。

    OCR が認識可能な十分な文字サイズで描画する（TrueType フォント）。
    """
    img = Image.new("RGB", size, color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(_FONT_PATH, 40)
    y = 20
    for line in lines:
        draw.text((30, y), line, fill=(0, 0, 0), font=font)
        y += 70
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


@pytest.fixture
def receipt_png() -> bytes:
    """日付・金額を含むレシート風画像（英数字）。"""
    return _render_png(
        [
            "TAXI CO LTD",
            "2026/06/30",
            "TOTAL 1480",
        ]
    )


@pytest.fixture
def client():
    """FastAPI TestClient。"""
    from fastapi.testclient import TestClient
    from app.main import create_app

    return TestClient(create_app())
