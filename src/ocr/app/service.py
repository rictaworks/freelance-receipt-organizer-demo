"""OCR サービスのオーケストレーション（F1／F2 前段・個人情報保護）。

デコード→前処理→OCR→電話番号スクラブ の各段を順に実行し、SPEC の 200 レスポンス
形状を組み立てる。各段の失敗は分類済み OcrError として送出する（フォールバック禁止）。
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass

import cv2
import numpy as np

from .config import Settings
from .errors import OcrError, IMAGE_DECODE_FAILED
from .ocr_engine import TesseractEngine
from .phone_filter import PhoneNumberScrubber
from .preprocessing import ImagePreprocessor


@dataclass(frozen=True)
class OcrResponse:
    """/ocr の 200 レスポンス本体。"""

    full_text: str
    confidence: float
    preprocess: dict
    discarded: dict

    def to_dict(self) -> dict:
        return {
            "full_text": self.full_text,
            "confidence": self.confidence,
            "preprocess": self.preprocess,
            "discarded": self.discarded,
        }


class OcrService:
    """画像バイト列を受け取り OCR 結果を返すサービス。"""

    def __init__(
        self,
        settings: Settings,
        preprocessor: ImagePreprocessor,
        engine: TesseractEngine,
        scrubber: PhoneNumberScrubber,
    ) -> None:
        self._settings = settings
        self._preprocessor = preprocessor
        self._engine = engine
        self._scrubber = scrubber

    @classmethod
    def build(cls, settings: Settings) -> "OcrService":
        """設定から依存を組み立てた既定のサービスを生成する。"""
        return cls(
            settings=settings,
            preprocessor=ImagePreprocessor(),
            engine=TesseractEngine(
                lang=settings.tesseract_lang,
                confidence_floor=settings.min_confidence_floor,
            ),
            scrubber=PhoneNumberScrubber(),
        )

    def process(self, image_bytes: bytes, trace_id: str | None = None) -> OcrResponse:
        """画像バイト列を処理して OcrResponse を返す。

        Args:
            image_bytes: JPEG/PNG のバイト列。
            trace_id: 呼び出し側から引き継ぐトレースID（無ければ生成）。
        """
        tid = trace_id or str(uuid.uuid4())
        image = self._decode(image_bytes, tid)
        pre = self._preprocessor.run(image, tid)
        ocr = self._engine.recognize(pre.image, tid)
        scrubbed = self._scrubber.scrub(ocr.full_text)
        return OcrResponse(
            full_text=scrubbed.text,
            confidence=ocr.confidence,
            preprocess=pre.trace.to_dict(),
            discarded={"phone_numbers": scrubbed.removed_count},
        )

    def _decode(self, image_bytes: bytes, trace_id: str) -> np.ndarray:
        """バイト列を画像へデコードする。失敗は IMAGE_DECODE_FAILED。"""
        if not image_bytes:
            raise OcrError(code=IMAGE_DECODE_FAILED, trace_id=trace_id)
        buffer = np.frombuffer(image_bytes, dtype=np.uint8)
        image = cv2.imdecode(buffer, cv2.IMREAD_COLOR)
        if image is None:
            raise OcrError(code=IMAGE_DECODE_FAILED, trace_id=trace_id)
        return image
