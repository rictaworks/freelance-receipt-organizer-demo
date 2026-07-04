"""/ocr エンドポイントの結合テスト（SPEC/api/ocr.md 準拠）。

実画像 OCR は PIL 生成画像を用いる（日本語フォント非依存のため英数字中心）。
"""


def test_ocr_success_returns_text_and_confidence(client, receipt_png):
    resp = client.post(
        "/ocr", files={"file": ("receipt.png", receipt_png, "image/png")}
    )
    assert resp.status_code == 200
    body = resp.json()
    # 金額・日付が本文に含まれること（OCR 精度に依存するため部分一致で確認）。
    assert "1480" in body["full_text"].replace(" ", "")
    assert "2026" in body["full_text"]
    assert body["confidence"] > 0.0
    assert 0.0 <= body["confidence"] <= 1.0


def test_ocr_preprocess_flags_present(client, receipt_png):
    resp = client.post(
        "/ocr", files={"file": ("receipt.png", receipt_png, "image/png")}
    )
    pre = resp.json()["preprocess"]
    assert pre["grayscale"] is True
    assert pre["binarized"] is True
    assert pre["denoised"] is True
    assert "deskew_applied" in pre
    assert isinstance(pre["deskew_applied"], bool)


def test_ocr_discarded_shape(client, receipt_png):
    resp = client.post(
        "/ocr", files={"file": ("receipt.png", receipt_png, "image/png")}
    )
    discarded = resp.json()["discarded"]
    assert "phone_numbers" in discarded
    assert isinstance(discarded["phone_numbers"], int)


def test_image_decode_failed_returns_400(client):
    resp = client.post(
        "/ocr",
        files={"file": ("broken.png", b"this-is-not-an-image", "image/png")},
    )
    assert resp.status_code == 400
    body = resp.json()
    assert body["error"]["code"] == "IMAGE_DECODE_FAILED"
    assert "trace_id" in body["error"]
    assert body["error"]["message"]


def test_error_response_has_trace_id_uuid(client):
    resp = client.post(
        "/ocr", files={"file": ("broken.png", b"xxxx", "image/png")}
    )
    trace_id = resp.json()["error"]["trace_id"]
    # uuid4 形式（36文字・ハイフン4本）であること。
    assert len(trace_id) == 36
    assert trace_id.count("-") == 4
