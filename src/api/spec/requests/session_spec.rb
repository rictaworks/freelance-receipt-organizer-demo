# frozen_string_literal: true

require "rails_helper"

# GET /session（F6）。
RSpec.describe "GET /session", type: :request do
  it "初回アクセスで UUID セッションを新規発行し Cookie を付与する" do
    get "/session"

    expect(response).to have_http_status(:ok)
    expect(json_body["is_new"]).to be(true)
    expect(json_body["session_id"]).to match(/\A[0-9a-f-]{36}\z/)
    expect(response.headers["Set-Cookie"]).to include("session_id")
    expect(response.headers["Set-Cookie"]).to match(/httponly/i)
    expect(response.headers["Set-Cookie"]).to match(/samesite=lax/i)
    expect(Session.count).to eq(1)
  end

  it "既存 Cookie があれば同一セッションを touch し is_new=false" do
    existing = Session.create!(
      session_id: SecureRandom.uuid,
      created_at: 1.day.ago,
      last_accessed_at: 1.day.ago
    )
    set_session_cookie(existing.session_id)

    get "/session"

    expect(response).to have_http_status(:ok)
    expect(json_body["is_new"]).to be(false)
    expect(json_body["session_id"]).to eq(existing.session_id)
  end
end
