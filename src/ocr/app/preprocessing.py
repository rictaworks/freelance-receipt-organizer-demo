"""OpenCV による前処理（F1）。

グレースケール化→傾き補正(deskew)→二値化→ノイズ除去 の順で処理し、各段階の
適用トレースを返す。段階ごとの例外は失敗段階を特定できる形で送出する
（フォールバック禁止：暗黙のスキップや原画像への無言復帰をしない）。
"""
from __future__ import annotations

from dataclasses import dataclass, asdict

import cv2
import numpy as np

from .errors import OcrError, PREPROCESS_FAILED


# 前処理段階の識別子（メッセージではなく段階名の識別子）。
STAGE_GRAYSCALE = "grayscale"
STAGE_DESKEW = "deskew"
STAGE_BINARIZE = "binarize"
STAGE_DENOISE = "denoise"


@dataclass(frozen=True)
class PreprocessTrace:
    """前処理トレース（レスポンス preprocess に対応）。"""

    grayscale: bool
    deskew_applied: bool
    binarized: bool
    denoised: bool

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass(frozen=True)
class PreprocessResult:
    """前処理結果。"""

    image: np.ndarray
    trace: PreprocessTrace


class ImagePreprocessor:
    """領収書画像の前処理器。

    各段階を明示メソッドに分割し、失敗段階を OcrError.details[0].stage で示す。
    """

    def __init__(self, min_deskew_angle: float = 0.1) -> None:
        # この閾値未満の傾きは回転を適用しない（deskew_applied=False とする）。
        self._min_deskew_angle = min_deskew_angle

    def run(self, image: np.ndarray, trace_id: str) -> PreprocessResult:
        """前処理を順に適用し、画像とトレースを返す。"""
        gray = self._grayscale(image, trace_id)
        deskewed, deskew_applied = self._deskew(gray, trace_id)
        binarized = self._binarize(deskewed, trace_id)
        denoised = self._denoise(binarized, trace_id)
        trace = PreprocessTrace(
            grayscale=True,
            deskew_applied=deskew_applied,
            binarized=True,
            denoised=True,
        )
        return PreprocessResult(image=denoised, trace=trace)

    def _fail(self, stage: str, trace_id: str) -> OcrError:
        return OcrError(
            code=PREPROCESS_FAILED,
            details=[{"stage": stage}],
            trace_id=trace_id,
        )

    def _grayscale(self, image: np.ndarray, trace_id: str) -> np.ndarray:
        try:
            if image.ndim == 2:
                return image
            return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        except Exception as exc:  # noqa: BLE001 段階特定のため明示再送出
            raise self._fail(STAGE_GRAYSCALE, trace_id) from exc

    def _deskew(self, gray: np.ndarray, trace_id: str) -> tuple[np.ndarray, bool]:
        try:
            # 前景画素の最小外接矩形から傾きを推定する。
            inverted = cv2.bitwise_not(gray)
            coords = np.column_stack(np.where(inverted > 0))
            if coords.shape[0] == 0:
                # 前景が無い（真っ白等）場合は回転不要（明示的に非適用）。
                return gray, False
            angle = cv2.minAreaRect(coords)[-1]
            if angle < -45:
                angle = 90 + angle
            if abs(angle) < self._min_deskew_angle:
                return gray, False
            (h, w) = gray.shape[:2]
            matrix = cv2.getRotationMatrix2D((w / 2, h / 2), angle, 1.0)
            rotated = cv2.warpAffine(
                gray,
                matrix,
                (w, h),
                flags=cv2.INTER_CUBIC,
                borderMode=cv2.BORDER_REPLICATE,
            )
            return rotated, True
        except Exception as exc:  # noqa: BLE001
            raise self._fail(STAGE_DESKEW, trace_id) from exc

    def _binarize(self, gray: np.ndarray, trace_id: str) -> np.ndarray:
        try:
            _, binary = cv2.threshold(
                gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU
            )
            return binary
        except Exception as exc:  # noqa: BLE001
            raise self._fail(STAGE_BINARIZE, trace_id) from exc

    def _denoise(self, binary: np.ndarray, trace_id: str) -> np.ndarray:
        try:
            return cv2.medianBlur(binary, 3)
        except Exception as exc:  # noqa: BLE001
            raise self._fail(STAGE_DENOISE, trace_id) from exc
