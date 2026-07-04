"""前処理器の単体テスト（F1）。

トレースフラグと段階失敗の分類（PREPROCESS_FAILED + stage）を検証する。
"""
import numpy as np
import pytest

from app.errors import OcrError, PREPROCESS_FAILED
from app.preprocessing import ImagePreprocessor


def test_trace_flags_true_for_normal_image():
    img = np.full((100, 200, 3), 255, dtype=np.uint8)
    img[40:60, 20:180] = 0  # 前景（文字相当）を置く。
    result = ImagePreprocessor().run(img, trace_id="t-1")
    assert result.trace.grayscale is True
    assert result.trace.binarized is True
    assert result.trace.denoised is True
    assert isinstance(result.trace.deskew_applied, bool)


def test_preprocess_failure_reports_stage():
    # None を渡すとグレースケール段で例外となり、stage が特定されること。
    with pytest.raises(OcrError) as exc:
        ImagePreprocessor().run(None, trace_id="t-2")
    assert exc.value.code == PREPROCESS_FAILED
    assert exc.value.details[0]["stage"] == "grayscale"
    assert exc.value.trace_id == "t-2"
