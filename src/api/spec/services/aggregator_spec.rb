# frozen_string_literal: true

require "rails_helper"

# F4 集計の単体テスト。
RSpec.describe Aggregator do
  subject(:aggregator) { described_class.new }

  let(:session) do
    Session.create!(session_id: SecureRandom.uuid, created_at: Time.current, last_accessed_at: Time.current)
  end

  def create_receipt(category_id:, issued_on:, amount_yen:)
    Receipt.create!(
      session_id: session.session_id,
      category_id: category_id,
      issued_on: issued_on,
      amount_yen: amount_yen,
      store_name: "店",
      manually_edited: false,
      created_at: Time.current
    )
  end

  let(:ryohi) { AccountCategory.find_by!(code: "RYOHI").id }
  let(:tsushin) { AccountCategory.find_by!(code: "TSUSHIN").id }

  it "月×科目で集計し、科目別年間合計・総合計を返す" do
    create_receipt(category_id: ryohi,   issued_on: Date.new(2026, 6, 10), amount_yen: 1480)
    create_receipt(category_id: tsushin, issued_on: Date.new(2026, 6, 20), amount_yen: 5980)
    create_receipt(category_id: tsushin, issued_on: Date.new(2026, 7, 1),  amount_yen: 3000)

    result = aggregator.aggregate(session_id: session.session_id, year: 2026)

    expect(result["target_year"]).to eq(2026)
    expect(result["grand_total_yen"]).to eq(10_460)

    june = result["months"].find { |m| m["month"] == 6 }
    expect(june["month_total_yen"]).to eq(7460)
    expect(june["categories"]).to include(
      "category_id" => ryohi, "category_name" => "旅費交通費", "total_yen" => 1480
    )
  end

  it "未分類（category_id=null）も独立区分として集計する" do
    create_receipt(category_id: nil, issued_on: Date.new(2026, 5, 5), amount_yen: 800)
    result = aggregator.aggregate(session_id: session.session_id, year: 2026)

    uncategorized = result["category_yearly_totals"].find { |c| c["category_id"].nil? }
    expect(uncategorized["category_name"]).to eq("未分類")
    expect(uncategorized["total_yen"]).to eq(800)
  end

  it "0件のときは months 空・grand_total 0" do
    result = aggregator.aggregate(session_id: session.session_id, year: 2026)
    expect(result["months"]).to eq([])
    expect(result["grand_total_yen"]).to eq(0)
  end

  it "対象年以外の領収書は集計しない" do
    create_receipt(category_id: ryohi, issued_on: Date.new(2025, 6, 10), amount_yen: 999)
    result = aggregator.aggregate(session_id: session.session_id, year: 2026)
    expect(result["grand_total_yen"]).to eq(0)
  end
end
