# frozen_string_literal: true

# API エラー（フォールバック禁止・明示分類: CLAUDE.md §4 / SPEC/api/README.md）。
# code から status/message を config/api_errors.yml で解決し、trace_id を付与する。
class ApiError < StandardError
  attr_reader :code, :status, :details, :trace_id

  def initialize(code, details: nil, trace_id: nil, cause_message: nil)
    definition = AppConfig.api_errors[code]
    raise "未定義のエラーコードです: #{code}" if definition.nil?

    @code = code
    @status = definition.fetch("status")
    @message_text = definition.fetch("message")
    @details = details
    @trace_id = trace_id || SecureRandom.uuid
    @cause_message = cause_message
    super(@message_text)
  end

  # レスポンス本文（SPEC/api/README.md エラー共通形式）。
  def to_response
    body = {
      "code" => @code,
      "message" => @message_text,
      "trace_id" => @trace_id
    }
    body["details"] = @details if @details.present?
    { "error" => body }
  end
end
