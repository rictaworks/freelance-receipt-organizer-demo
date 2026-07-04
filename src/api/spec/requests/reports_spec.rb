# frozen_string_literal: true

require "rails_helper"

# 帳票 API（F5/F6）。
RSpec.describe "Reports API", type: :request do
  describe "POST /reports" do
    it "帳票を生成し 201・注記・PDFリンクを返す" do
      post "/reports", params: { target_year: 2026 }, as: :json

      expect(response).to have_http_status(:created)
      expect(json_body.dig("report", "target_year")).to eq(2026)
      expect(json_body.dig("report", "pdf_url")).to match(%r{\A/reports/\d+\.pdf\z})
      expect(json_body.dig("report", "notice")).to include("参考様式")
      expect(json_body["preview_html"]).to include("参考様式")
      expect(Report.count).to eq(1)
    end

    it "領収書 0 件でも経費 0 円で 201 を返す" do
      post "/reports", params: { target_year: 2026 }, as: :json
      expect(response).to have_http_status(:created)
      expect(json_body.dig("report", "grand_total_yen")).to eq(0)
    end

    it "target_year が整数でなければ 400 INVALID_YEAR" do
      post "/reports", params: { target_year: "abc" }, as: :json
      expect(response).to have_http_status(:bad_request)
      expect(json_body.dig("error", "code")).to eq("INVALID_YEAR")
    end
  end

  describe "GET /reports/:id.pdf" do
    it "生成済み帳票の PDF を application/pdf で返す" do
      post "/reports", params: { target_year: 2026 }, as: :json
      report_id = json_body.dig("report", "id")

      get "/reports/#{report_id}.pdf"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
    end

    it "他セッションの帳票は 404 REPORT_NOT_FOUND（存在秘匿）" do
      other = Session.create!(session_id: SecureRandom.uuid, created_at: Time.current, last_accessed_at: Time.current)
      foreign = Report.create!(session_id: other.session_id, target_year: 2026,
                               pdf_path: "/nonexistent/x.pdf", generated_at: Time.current)

      get "/session"
      get "/reports/#{foreign.id}.pdf"

      expect(response).to have_http_status(:not_found)
      expect(json_body.dig("error", "code")).to eq("REPORT_NOT_FOUND")
    end

    it "PDF 実体が日次リセットで消えていれば 410 REPORT_EXPIRED" do
      post "/reports", params: { target_year: 2026 }, as: :json
      report_id = json_body.dig("report", "id")
      allow_any_instance_of(Report).to receive(:pdf_available?).and_return(false)

      get "/reports/#{report_id}.pdf"

      expect(response).to have_http_status(:gone)
      expect(json_body.dig("error", "code")).to eq("REPORT_EXPIRED")
    end
  end
end
