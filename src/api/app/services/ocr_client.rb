# frozen_string_literal: true

require "net/http"
require "securerandom"

# OCR サービス（FastAPI）呼び出しクライアント（設計書 4 シーケンス / SPEC/api/ocr.md）。
# POST {OCR_SERVICE_URL}/ocr へ multipart で画像を送り {full_text, confidence, ...} を得る。
# 呼び出し失敗はフォールバックせず 502 OCR_SERVICE_UNAVAILABLE として明示する（CLAUDE.md §4）。
class OcrClient
  DEFAULT_BASE_URL = "http://localhost:8000"
  OPEN_TIMEOUT_SEC = 5
  READ_TIMEOUT_SEC = 30

  def self.call(file_path:, content_type:, filename:)
    new.call(file_path: file_path, content_type: content_type, filename: filename)
  end

  def call(file_path:, content_type:, filename:)
    uri = URI.parse("#{base_url}/ocr")
    boundary = "----RctOcrBoundary#{SecureRandom.hex(12)}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = OPEN_TIMEOUT_SEC
    http.read_timeout = READ_TIMEOUT_SEC

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = build_multipart_body(boundary, file_path, content_type, filename)

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError.new("OCR_SERVICE_UNAVAILABLE", details: [{ "reason" => "http_status", "status" => response.code }])
    end

    JSON.parse(response.body)
  rescue ApiError
    raise
  rescue JSON::ParserError => e
    raise ApiError.new("OCR_SERVICE_UNAVAILABLE", details: [{ "reason" => "invalid_json" }], cause_message: e.message)
  rescue StandardError => e
    # 接続不能・タイムアウト等はすべて 502 に分類（握りつぶさない）。
    raise ApiError.new("OCR_SERVICE_UNAVAILABLE", details: [{ "reason" => e.class.name }], cause_message: e.message)
  end

  private

  def base_url
    ENV.fetch("OCR_SERVICE_URL", DEFAULT_BASE_URL)
  end

  def build_multipart_body(boundary, file_path, content_type, filename)
    binary = File.binread(file_path)
    body = +""
    body << "--#{boundary}\r\n"
    body << %(Content-Disposition: form-data; name="file"; filename="#{filename}"\r\n)
    body << "Content-Type: #{content_type}\r\n\r\n"
    body << binary
    body << "\r\n--#{boundary}--\r\n"
    body.force_encoding(Encoding::ASCII_8BIT)
  end
end
