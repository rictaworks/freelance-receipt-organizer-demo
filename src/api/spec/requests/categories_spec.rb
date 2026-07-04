# frozen_string_literal: true

require "rails_helper"

# GET /categories（F3）。
RSpec.describe "GET /categories", type: :request do
  it "勘定科目マスタ 12 件を id 昇順で返す" do
    get "/categories"

    expect(response).to have_http_status(:ok)
    expect(json_body["count"]).to eq(12)
    first = json_body["categories"].first
    expect(first["id"]).to eq(1)
    expect(first["code"]).to eq("SHOMOHIN")
    expect(first["name"]).to eq("消耗品費")
  end

  it "マスタが 12 件未満なら 500 MASTER_NOT_SEEDED" do
    allow(AccountCategory).to receive(:ordered).and_return(AccountCategory.order(:id).limit(3))

    get "/categories"

    expect(response).to have_http_status(:internal_server_error)
    expect(json_body.dig("error", "code")).to eq("MASTER_NOT_SEEDED")
    expect(json_body.dig("error", "trace_id")).to be_present
  end
end
