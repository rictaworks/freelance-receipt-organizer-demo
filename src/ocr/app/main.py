"""FastAPI 内部 API（POST /ocr）。

Rails からのローカル間通信でのみ呼ばれる内部 API。外部公開しない。
エラーは分類済み OcrError を共通形式へマッピングし、全エラーで trace_id を
レスポンスとサーバログの双方へ出力して突合可能にする（フォールバック禁止）。
"""
from __future__ import annotations

from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse

from .config import Settings
from .errors import OcrError
from .logging_setup import get_logger
from .resources import MessageCatalog
from .service import OcrService


def create_app() -> FastAPI:
    """アプリを生成する（グローバル状態を持たず app.state に依存を格納）。"""
    settings = Settings.from_env()
    catalog = MessageCatalog.load(settings.locale)
    service = OcrService.build(settings)
    logger = get_logger("ocr")

    app = FastAPI(title="ocr-internal-api", docs_url=None, redoc_url=None)
    app.state.settings = settings
    app.state.catalog = catalog
    app.state.service = service
    app.state.logger = logger

    def _error_response(err: OcrError) -> JSONResponse:
        message = catalog.error_message(err.code)
        logger.error(
            "ocr_error",
            extra={
                "trace_id": err.trace_id,
                "code": err.code,
                "event": "ocr_error",
                "stage": (err.details[0].get("stage") if err.details else None),
            },
        )
        body: dict = {
            "error": {
                "code": err.code,
                "message": message,
                "trace_id": err.trace_id,
            }
        }
        if err.details:
            body["error"]["details"] = err.details
        return JSONResponse(status_code=err.http_status, content=body)

    @app.post("/ocr")
    async def ocr(file: UploadFile = File(...)) -> JSONResponse:
        image_bytes = await file.read()
        try:
            result = service.process(image_bytes)
        except OcrError as err:
            return _error_response(err)
        return JSONResponse(status_code=200, content=result.to_dict())

    return app


app = create_app()
