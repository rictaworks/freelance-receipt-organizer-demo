"""電話番号スクラブ（個人情報保護・設計書 1.4）。

日本の電話番号（0始まり10〜11桁、ハイフン／括弧／スペース区切り）を full_text から
破棄し、破棄件数のみを返す。金額（¥1,480 等）を誤って除去しないよう、電話番号の
桁数・区切り特徴に限定する。フォールバックせず、除去は明示的なパターンのみで行う。
"""
from __future__ import annotations

import re
from dataclasses import dataclass


# 電話番号パターン（設計意図をコメントで明示）。
# - 市外局番括弧形式:  (03)1234-5678 / (0120)00-0000
# - ハイフン/スペース区切り: 03-1234-5678 / 090-1234-5678 / 0120-000-000 / 03 1234 5678
# 先頭は 0、全体の数字桁数は 10〜11 桁。¥や「円」に隣接する金額を避けるため、
# 数字列の前後に金額文脈（¥ / 円 / , 直後の連続数字）が来ないよう境界で制限する。
_SEP = r"[-\s]"

_PATTERNS = (
    # 括弧つき市外局番: (03)1234-5678 など。
    re.compile(
        r"\(0\d{1,4}\)\s?\d{1,4}" + _SEP + r"?\d{3,4}"
    ),
    # 区切りありの標準形: 0AA-BBBB-CCCC / 090-1234-5678 / 0120-000-000。
    # 3ブロック（区切りが2つ）で 0 始まり合計 10〜11 桁。
    re.compile(
        r"(?<![\d¥￥])0\d{1,4}" + _SEP + r"\d{1,4}" + _SEP + r"\d{3,4}(?![\d])"
    ),
    # 区切り無しの連続形: 0 始まり 10〜11 桁。金額は先頭 0 になりにくく、通貨記号／
    # カンマ境界で除外するため、¥1,480 等の金額は保持される。
    re.compile(r"(?<![\d¥￥,])0\d{9,10}(?![\d])"),
)


@dataclass(frozen=True)
class ScrubResult:
    """スクラブ結果。

    Attributes:
        text: 電話番号を除去したテキスト。
        removed_count: 除去した電話番号の件数。
    """

    text: str
    removed_count: int


class PhoneNumberScrubber:
    """電話番号を検出・除去するスクラバ。"""

    def scrub(self, text: str) -> ScrubResult:
        """text から電話番号パターンを除去し、除去件数とともに返す。

        金額表記（¥1,480 / 1,480円）は桁数・区切り・通貨記号境界により保持される。
        """
        removed = 0
        result = text
        for pattern in _PATTERNS:
            result, count = pattern.subn("", result)
            removed += count
        return ScrubResult(text=result, removed_count=removed)
