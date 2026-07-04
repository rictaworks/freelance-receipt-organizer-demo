"""pytesseract による OCR 実行（F1）。

前処理済み画像から全文テキストと信頼度スコア（0.0〜1.0）を取得する。
pytesseract の実行失敗（バイナリ未導入・言語データ欠落等）は TESSERACT_FAILED として
明示的に送出する（握りつぶさない）。
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np
import pytesseract
from pytesseract import Output

from .errors import OcrError, TESSERACT_FAILED


@dataclass(frozen=True)
class OcrOutput:
    """OCR 出力。

    Attributes:
        full_text: 認識した全文テキスト（電話番号スクラブ前）。
        confidence: 0.0〜1.0 の信頼度スコア（語単位 conf の平均）。
    """

    full_text: str
    confidence: float


class TesseractEngine:
    """pytesseract ラッパ。"""

    def __init__(self, lang: str, confidence_floor: float = 0.0) -> None:
        self._lang = lang
        self._confidence_floor = confidence_floor

    def recognize(self, image: np.ndarray, trace_id: str) -> OcrOutput:
        """画像を OCR し、全文テキストと平均信頼度を返す。"""
        try:
            data = pytesseract.image_to_data(
                image, lang=self._lang, output_type=Output.DICT
            )
        except Exception as exc:  # noqa: BLE001 実行失敗を明示分類
            raise OcrError(code=TESSERACT_FAILED, trace_id=trace_id) from exc

        full_text = self._compose_text(data)
        confidence = self._average_confidence(data)
        return OcrOutput(full_text=full_text, confidence=confidence)

    def _compose_text(self, data: dict) -> str:
        """image_to_data の結果を行構造を保ったテキストへ再構成する。"""
        words = data.get("text", [])
        line_ids = data.get("line_num", [])
        block_ids = data.get("block_num", [])
        par_ids = data.get("par_num", [])

        lines: list[str] = []
        current_key = None
        current_words: list[str] = []
        for i, word in enumerate(words):
            token = word.strip()
            key = (
                block_ids[i] if i < len(block_ids) else 0,
                par_ids[i] if i < len(par_ids) else 0,
                line_ids[i] if i < len(line_ids) else 0,
            )
            if key != current_key:
                if current_words:
                    lines.append(" ".join(current_words))
                current_words = []
                current_key = key
            if token:
                current_words.append(token)
        if current_words:
            lines.append(" ".join(current_words))
        return "\n".join(line for line in lines if line)

    def _average_confidence(self, data: dict) -> float:
        """語単位 conf（0〜100）の平均を 0.0〜1.0 に正規化する。"""
        confs = data.get("conf", [])
        valid: list[float] = []
        for c in confs:
            try:
                value = float(c)
            except (TypeError, ValueError):
                continue
            # tesseract は非テキスト領域に -1 を返す。これは除外する。
            if value >= 0:
                valid.append(value)
        if not valid:
            return self._confidence_floor
        normalized = (sum(valid) / len(valid)) / 100.0
        return max(self._confidence_floor, min(1.0, normalized))
