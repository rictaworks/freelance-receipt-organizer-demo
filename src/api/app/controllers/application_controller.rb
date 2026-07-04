# frozen_string_literal: true

# API 共通基底。セッション解決（F6）・エラー整形（trace_id 付与・構造化ログ）を担う。
# フォールバック禁止: 例外は握りつぶさず明示的に分類して返す（CLAUDE.md §4 / SPEC/api/README.md）。
class ApplicationController < ActionController::API
  include ActionController::Cookies

  before_action :ensure_session

  # rescue_from は後に定義したものが優先される。
  # 想定外の例外を先に登録し、明示的な ApiError を後に登録して優先させる。
  rescue_from StandardError, with: :render_unexpected_error
  rescue_from ApiError, with: :render_api_error

  private

  # 現在のセッション（Cookie の session_id から解決。無ければ新規発行）。
  def current_session
    @current_session ||= resolve_session
  end

  def session_is_new?
    ensure_session
    @session_is_new
  end

  def ensure_session
    current_session
  end

  def resolve_session
    session_id = cookies[:session_id]
    if session_id.present?
      existing = Session.find_by(session_id: session_id)
      if existing
        existing.touch_access!
        @session_is_new = false
        return existing
      end
    end
    create_new_session
  end

  # 新規セッション発行（F6）。UUID v4 / HttpOnly Cookie。
  # 本番はフロント（Vercel）と API（Railway）が別オリジンのため SameSite=None・Secure が必須
  #（クロスサイト fetch で Cookie を送るため）。開発は同一オリジン相当のため Lax。
  def create_new_session
    session_id = SecureRandom.uuid
    now = Time.current
    session = Session.create!(session_id: session_id, created_at: now, last_accessed_at: now)
    set_session_cookie(session_id)
    @session_is_new = true
    session
  rescue ActiveRecord::ActiveRecordError => e
    raise ApiError.new("SESSION_CREATE_FAILED", cause_message: e.message)
  end

  def set_session_cookie(session_id)
    cookies[:session_id] = {
      value: session_id,
      httponly: true,
      same_site: EnvironmentPolicy.production? ? :none : :lax,
      path: "/",
      secure: EnvironmentPolicy.production?
    }
  end

  # 対象年のパース（F4/F5）。省略時は当年（JST）。不正・範囲外は 400 INVALID_YEAR。
  VALID_YEAR_RANGE = (2000..2100).freeze

  def parse_year(value, field: "year")
    return Time.zone.today.year if value.blank?

    year = begin
      Integer(value.to_s, 10)
    rescue ArgumentError
      nil
    end

    if year.nil? || !VALID_YEAR_RANGE.cover?(year)
      raise ApiError.new("INVALID_YEAR", details: [{ "field" => field, "reason" => "invalid_year" }])
    end

    year
  end

  # --- エラー整形 -------------------------------------------------------

  def render_api_error(error)
    log_error(error.code, error.trace_id, error.message, error.details, cause_message(error))
    render json: error.to_response, status: error.status
  end

  def render_unexpected_error(exception)
    trace_id = SecureRandom.uuid
    log_error("INTERNAL_ERROR", trace_id, exception.message, nil, exception.backtrace&.first(10)&.join("\n"))
    api_error = ApiError.new("INTERNAL_ERROR", trace_id: trace_id)
    render json: api_error.to_response, status: api_error.status
  end

  def cause_message(error)
    error.instance_variable_get(:@cause_message)
  end

  # 構造化ログ（trace_id でサーバログと突合可能にする: CLAUDE.md §4）。
  def log_error(code, trace_id, message, details, cause)
    Rails.logger.error(
      {
        event: "api_error",
        code: code,
        trace_id: trace_id,
        message: message,
        details: details,
        cause: cause,
        path: request&.fullpath,
        method: request&.request_method
      }.compact.to_json
    )
  end
end
