# frozen_string_literal: true

# リクエストスペック共通ヘルパ。
module ApiHelpers
  FIXTURES_DIR = Rails.root.join("spec", "fixtures", "files")

  def json_body
    JSON.parse(response.body)
  end

  def png_upload
    Rack::Test::UploadedFile.new(FIXTURES_DIR.join("receipt.png"), "image/png")
  end

  def jpg_upload
    Rack::Test::UploadedFile.new(FIXTURES_DIR.join("receipt.jpg"), "image/jpeg")
  end

  def txt_upload
    Rack::Test::UploadedFile.new(FIXTURES_DIR.join("note.txt"), "text/plain")
  end

  # 10MB を超える一時ファイルを PNG として扱うアップロードを生成する（413 検証用）。
  def oversized_png_upload
    tempfile = Tempfile.new(["oversized", ".png"])
    tempfile.binmode
    tempfile.write("0" * (10 * 1024 * 1024 + 1))
    tempfile.rewind
    Rack::Test::UploadedFile.new(tempfile.path, "image/png")
  end

  # OCR クライアントをスタブする（実 OCR 起動に依存しない）。
  def stub_ocr(full_text:, confidence: 0.82)
    allow(OcrClient).to receive(:call).and_return(
      "full_text" => full_text,
      "confidence" => confidence,
      "preprocess" => { "grayscale" => true },
      "discarded" => { "phone_numbers" => 0 }
    )
  end

  # 指定 session_id の Cookie を張った状態を作る。
  def set_session_cookie(session_id)
    cookies[:session_id] = session_id
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
