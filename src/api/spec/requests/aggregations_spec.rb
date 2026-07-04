# frozen_string_literal: true

require "rails_helper"

# GET /aggregations（F4/F6）。
RSpec.describe "GET /aggregations", type: :request do
  def establish_session
    get "/session"
    json_body["session_id"]
  end

  def create_receipt(session_id, category_code:, issued_on:, amount_yen:)
    category_id = category_code && AccountCategory.find_by!(code: category_code).id
    Receipt.create!(session_id: session_id, category_id: category_id, issued_on: issued_on,
                    amount_yen: amount_yen, store_name: "店", manually_edited: false, created_at: Time.current)
  end

  it "月×科目で集計し総合計を返す" do
    sid = establish_session
    create_receipt(sid, category_code: "RYOHI", issued_on: Date.new(2026, 6, 10), amount_yen: 1480)
    create_receipt(sid, category_code: "TSUSHIN", issued_on: Date.new(2026, 6, 20), amount_yen: 5980)

    get "/aggregations", params: { year: 2026 }

    expect(response).to have_http_status(:ok)
    expect(json_body["grand_total_yen"]).to eq(7460)
    expect(json_body["target_year"]).to eq(2026)
  end

  it "0 件なら months 空・grand_total 0" do
    establish_session
    get "/aggregations", params: { year: 2026 }
    expect(json_body["months"]).to eq([])
    expect(json_body["grand_total_yen"]).to eq(0)
  end

  it "year が整数でなければ 400 INVALID_YEAR" do
    get "/aggregations", params: { year: "abc" }
    expect(response).to have_http_status(:bad_request)
    expect(json_body.dig("error", "code")).to eq("INVALID_YEAR")
  end

  it "他セッションのデータは混入しない（F6）" do
    other = Session.create!(session_id: SecureRandom.uuid, created_at: Time.current, last_accessed_at: Time.current)
    create_receipt(other.session_id, category_code: "RYOHI", issued_on: Date.new(2026, 6, 10), amount_yen: 9999)

    establish_session
    get "/aggregations", params: { year: 2026 }

    expect(json_body["grand_total_yen"]).to eq(0)
  end
end
