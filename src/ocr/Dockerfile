# syntax = docker/dockerfile:1
# OCR サービス（FastAPI + OpenCV + pytesseract）本番イメージ。
# 外部 API 不使用。tesseract 5.x（jpn/eng 言語データ）をシステムに導入する。

FROM python:3.12-slim

WORKDIR /app

# システム依存:
# - tesseract-ocr 本体 + jpn/eng 言語データ（pytesseract が呼び出す）
# - libGL/libglib は OpenCV(headless) の実行時共有ライブラリ
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      tesseract-ocr tesseract-ocr-jpn tesseract-ocr-eng \
      libglib2.0-0 libgomp1 && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Python 依存
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# アプリ本体
COPY . .

# 実行環境（Rails からのローカル間通信のみ想定・外部公開しない）
ENV APP_ENV=production \
    TESSERACT_LANG=jpn+eng \
    PYTHONUNBUFFERED=1

# Railway は $PORT を注入する。未設定時は 8000。
ENV PORT=8000
EXPOSE 8000

# 非 root 実行
RUN useradd --create-home --uid 1000 appuser
USER 1000:1000

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
