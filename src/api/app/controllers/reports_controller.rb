# frozen_string_literal: true

# 帳票 API（F5/F6 / SPEC/api/reports.md）。
class ReportsController < ApplicationController
  # POST /reports（帳票生成）。0件でも経費0円で 201。
  def create
    year = parse_year(params[:target_year], field: "target_year")
    result = ReportGenerator.new.generate(session: current_session, year: year)

    render json: {
      "report" => {
        "id" => result.report.id,
        "target_year" => result.report.target_year,
        "generated_at" => result.report.generated_at&.iso8601,
        "pdf_url" => "/reports/#{result.report.id}.pdf",
        "grand_total_yen" => result.summary["grand_total_yen"],
        "notice" => AppConfig.report.fetch("notice")
      },
      "preview_html" => result.preview_html
    }, status: :created
  end

  # GET /reports/:id.pdf（PDF ダウンロード）。
  def download
    report = Report.find_by(session_id: current_session.session_id, id: params[:id])
    # 存在しない or 他セッション → 一律 404（存在秘匿, F6）。
    raise ApiError.new("REPORT_NOT_FOUND") if report.nil?
    # 日次リセットで実体が消えている → 410（握りつぶさない）。
    raise ApiError.new("REPORT_EXPIRED") unless report.pdf_available?

    send_file report.pdf_path,
              type: "application/pdf",
              disposition: "attachment",
              filename: "report-#{report.target_year}.pdf"
  end
end
