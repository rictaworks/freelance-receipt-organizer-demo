# frozen_string_literal: true

# セッション発行（F6 / SPEC/api/session.md）。GET /session。
class SessionsController < ApplicationController
  def show
    session = current_session
    render json: {
      "session_id" => session.session_id,
      "created_at" => session.created_at&.iso8601,
      "last_accessed_at" => session.last_accessed_at&.iso8601,
      "is_new" => session_is_new?
    }, status: :ok
  end
end
